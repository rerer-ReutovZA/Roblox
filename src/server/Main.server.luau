-- Potato Tycoon — точка входа сервера: мир, сервисы, жизненный цикл игроков, сохранения

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- общее состояние событий (таймеры) для клиентов
local gameState = Instance.new("Folder")
gameState.Name = "GameState"
gameState.Parent = ReplicatedStorage

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local World = require(script.Parent.World.WorldBuilder)
local Services = script.Parent.Services
local DataService = require(Services.DataService)
local Sessions = require(Services.Sessions)
local PlotService = require(Services.PlotService)
local ManualFarm = require(Services.ManualFarm)
local PurchaseService = require(Services.PurchaseService)
local IncomeService = require(Services.IncomeService)
local EventService = require(Services.EventService)
local RebirthService = require(Services.RebirthService)
local PassService = require(Services.PassService)

type Session = Sessions.Session

World.build()
ManualFarm.init()
PurchaseService.init()
IncomeService.init()
EventService.init()
RebirthService.init()
PassService.init()

local function save(session: Session)
	local profile = session.profile
	profile.lastOnline = os.time()
	if session.stats then
		profile.lastIncome = if session.stats.manual then 0 else session.stats.incomeNoEvent
	end
	DataService.save(session.player, profile, session.persistent)
end

RebirthService.onRebirth = function(session)
	task.spawn(save, session)
end

local function createLeaderstats(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Value = "$0"
	cash.Parent = stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirth"
	rebirths.Parent = stats
	stats.Parent = player
end

-- Офлайн-прогресс: 50% дохода до 3 часов (прокачивается звёздами до 100% и 8 часов)
local function applyOffline(session: Session)
	local profile = session.profile
	if profile.lastOnline <= 0 or profile.lastIncome <= 0 then
		return
	end
	local stats = session.stats
	local elapsed = math.clamp(os.time() - profile.lastOnline, 0, stats.offlineHours * 3600)
	if elapsed < Config.Game.Offline.MinSeconds then
		return
	end
	local amount = elapsed * profile.lastIncome * stats.offlineRate
	Sessions.addCash(session, amount)
	session.pendingOffline = { seconds = elapsed, amount = amount }
end

local function onCharacter(session: Session, character: Model)
	task.defer(function()
		if session.plot and character.Parent then
			character:WaitForChild("HumanoidRootPart", 10)
			character:PivotTo(session.plot.spawn)
		end
		PassService.applyCharacter(session, character)
	end)
end

local readyPlayers: { [Player]: boolean } = {}
local deliver: (Session) -> ()

local function onPlayerAdded(player: Player)
	createLeaderstats(player)
	local profile, persistent = DataService.load(player)
	if player.Parent == nil then
		return
	end
	if RunService:IsStudio() and Config.Game.Debug.StartCash > 0 then
		profile.cash = math.max(profile.cash, Config.Game.Debug.StartCash)
	end
	local session = Sessions.create(player, profile, persistent)
	PassService.load(session)
	if not persistent then
		Sessions.notify(player, "Saving is unavailable — progress from this session won't be saved", "error")
	end

	Sessions.recompute(session)
	applyOffline(session)
	if PlotService.assign(session) then
		PlotService.buildAll(session)
		ManualFarm.setupBeds(session)
	else
		Sessions.notify(player, "All bases are taken — please wait for a free spot", "error")
	end
	Sessions.recompute(session)
	session.loaded = true

	player.CharacterAdded:Connect(function(character)
		onCharacter(session, character)
		-- лопата из StarterGear выдаётся автоматически при возрождении
	end)
	if player.Character then
		onCharacter(session, player.Character)
	end
	ManualFarm.giveShovel(session)
	-- клиент мог прислать Ready раньше, чем загрузился профиль
	if readyPlayers[player] then
		session.clientReady = true
		deliver(session)
	end
end

-- клиент построил интерфейс: отправляем состояние и отчёт об офлайн-доходе
function deliver(session: Session)
	Sessions.sync(session)
	if session.pendingOffline then
		Remotes.get("Offline"):FireClient(session.player, session.pendingOffline)
		session.pendingOffline = nil
	end
end

local function onReady(player: Player)
	readyPlayers[player] = true
	local session = Sessions.get(player)
	if session then
		session.clientReady = true
		if session.loaded then
			deliver(session)
		end
	end
end

local function onPlayerRemoving(player: Player)
	readyPlayers[player] = nil
	local session = Sessions.get(player)
	if not session then
		return
	end
	Sessions.remove(player)
	if session.loaded then
		save(session)
	end
	PlotService.release(session)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Remotes.get("Ready").OnServerEvent:Connect(onReady)
Remotes.get("GoHome").OnServerEvent:Connect(function(player)
	PlotService.teleportHome(player)
end)

-- автосохранение
task.spawn(function()
	while true do
		task.wait(Config.Game.AutosaveInterval)
		for _, session in pairs(Sessions.all) do
			if session.loaded then
				task.spawn(save, session)
			end
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for _, session in pairs(Sessions.all) do
		if session.loaded then
			pending += 1
			task.spawn(function()
				save(session)
				pending -= 1
			end)
		end
	end
	local started = os.clock()
	while pending > 0 and os.clock() - started < 25 do
		task.wait(0.2)
	end
end)

print(
	string.format(
		"[Potato Tycoon] server started: %d bases, %d buildings, starting cash %s",
		#World.plots,
		#Config.Items.List,
		Format.money(Config.Game.StartCash)
	)
)
