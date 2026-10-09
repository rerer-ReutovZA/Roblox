-- Пассивный доход (Direct Auto-Harvest & Instant Auto-Sell), золотые клубни, табло и Зал Славы

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local Sessions = require(script.Parent.Sessions)
local PlotService = require(script.Parent.PlotService)
local World = require(script.Parent.Parent.World.WorldBuilder)

type Session = Sessions.Session

local IncomeService = {}

local function tick(dt: number)
	for _, session in pairs(Sessions.all) do
		local stats = session.stats
		if session.loaded and session.plot and stats and not stats.manual then
			local earned = stats.incomePerSec * dt
			if earned > 0 then
				Sessions.addCash(session, earned)
				session.profile.totalKg += stats.yieldKg * dt
			end
		end
	end
end

local function goldenRoll()
	local G = Config.Game.Golden
	for _, session in pairs(Sessions.all) do
		local stats = session.stats
		if session.loaded and session.plot and stats and not stats.manual and stats.incomePerSec > 0 then
			local chance = G.Chance * (if session.passes.magnateDrone then G.PassMultiplier else 1)
			if math.random() < chance then
				-- выбираем случайную грядку-источник урожая
				local sources = {}
				for _, model in ipairs(session.plot.items:GetChildren()) do
					if model:GetAttribute("Yield") then
						table.insert(sources, model)
					end
				end
				local target = if #sources > 0 then sources[math.random(1, #sources)] else nil
				local bonus = stats.incomePerSec * G.IncomeSeconds
				Sessions.addCash(session, bonus)
				Sessions.notify(
					session.player,
					"✨ Золотой клубень на поле! +" .. Format.money(bonus),
					"gold"
				)
				Sessions.effect(
					session.player,
					{ type = "Golden", target = target, amount = bonus, glow = G.GlowSeconds }
				)
			end
		end
	end
end

local function updateBoards()
	for _, session in pairs(Sessions.all) do
		Sessions.updateLeaderstats(session)
		session.player:SetAttribute("TotalKg", session.profile.totalKg)
		local board = session.plot and PlotService.findItem(session, "led_board")
		if board then
			local label = board:FindFirstChild("BoardText", true) :: TextLabel?
			if label then
				label.Text = string.format(
					"ВЫРАБОТКА: %s\n%s/сек",
					Format.mass(session.profile.totalKg),
					Format.money(session.stats and session.stats.incomePerSec or 0)
				)
			end
		end
	end
end

local function updateHallOfFame()
	local model = (World :: any).hallOfFame
	if not model then
		return
	end
	local entries = {}
	for _, session in pairs(Sessions.all) do
		table.insert(entries, {
			name = session.player.DisplayName,
			rebirths = session.profile.rebirths,
			earned = session.profile.totalEarned,
		})
	end
	table.sort(entries, function(a, b)
		if a.rebirths ~= b.rebirths then
			return a.rebirths > b.rebirths
		end
		return a.earned > b.earned
	end)
	local lines = {}
	for i = 1, math.min(5, #entries) do
		local e = entries[i]
		table.insert(lines, string.format("%d. %s — ⭐%d, %s", i, e.name, e.rebirths, Format.money(e.earned)))
	end
	local text = if #lines > 0 then table.concat(lines, "\n") else "Пока пусто"
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("TextLabel") and d.Name == "List" then
			d.Text = text
		end
	end
end

function IncomeService.init()
	task.spawn(function()
		local last = os.clock()
		local goldenTimer, boardTimer, fameTimer = 0, 0, 0
		while true do
			task.wait(Config.Game.TickSeconds)
			local t = os.clock()
			local dt = math.min(t - last, 5)
			last = t
			tick(dt)
			goldenTimer += dt
			boardTimer += dt
			fameTimer += dt
			if goldenTimer >= Config.Game.Golden.Interval then
				goldenTimer = 0
				goldenRoll()
			end
			if boardTimer >= 2 then
				boardTimer = 0
				updateBoards()
			end
			if fameTimer >= 10 then
				fameTimer = 0
				updateHallOfFame()
			end
		end
	end)
	Players.PlayerRemoving:Connect(function()
		task.defer(updateHallOfFame)
	end)
end

return IncomeService
