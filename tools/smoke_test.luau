-- Смоук-тест серверной части в Lune (https://lune-org.github.io/docs) без Roblox Studio.
-- Загружает собранное место, выполняет настоящие модули игры и проверяет, что:
--   * мир и все 6 баз генерируются без ошибок;
--   * каждая модель из каталога строится;
--   * покупки, исследования, найм, жуки и Rebirth проходят на «фейковом» игроке.
--
-- Запуск:
--   mkdir -p build && rojo build default.project.json -o build/PotatoTycoon.rbxlx
--   lune run tools/smoke_test.luau build/PotatoTycoon.rbxlx

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox") :: any
local task = require("@lune/task")

local placePath = process.args[1] or "build/PotatoTycoon.rbxlx"
local game = roblox.deserializePlace(fs.readFile(placePath))
local Instance = roblox.Instance
local CFrame = roblox.CFrame
local Vector3 = roblox.Vector3

------------------------------------------------------------------
-- Недостающее в Lune поведение Roblox
------------------------------------------------------------------
-- в Lune каждая ссылка на Instance — новый userdata, поэтому сигналы храним по полному пути объекта
local signals = {}
local function signal(inst, name)
	local key = inst:GetFullName() .. "#" .. inst.ClassName
	signals[key] = signals[key] or {}
	local s = signals[key][name]
	if not s then
		local handlers = {}
		s = {
			Connect = function(_, fn)
				table.insert(handlers, fn)
				return { Disconnect = function() end }
			end,
			Once = function(_, fn)
				table.insert(handlers, fn)
				return { Disconnect = function() end }
			end,
			Wait = function()
				return nil
			end,
			Fire = function(_, ...)
				for _, fn in ipairs(handlers) do
					fn(...)
				end
			end,
			count = function()
				return #handlers
			end,
		}
		signals[key][name] = s
	end
	return s
end

local EVENTS = {
	Instance = { "Destroying" },
	BasePart = { "Touched" },
	ProximityPrompt = { "Triggered" },
	RemoteEvent = { "OnServerEvent" },
	Players = { "PlayerAdded", "PlayerRemoving" },
	MarketplaceService = { "PromptGamePassPurchaseFinished" },
}
for className, names in pairs(EVENTS) do
	for _, name in ipairs(names) do
		roblox.implementProperty(className, name, function(self)
			return signal(self, name)
		end)
	end
end

local fired = { client = 0, all = 0 }
local lastPayload: { [string]: { any } } = {}
roblox.implementMethod("RemoteEvent", "FireClient", function(remote, _player, ...)
	fired.client += 1
	lastPayload[remote.Name] = { ... }
end)
roblox.implementMethod("RemoteEvent", "FireAllClients", function()
	fired.all += 1
end)

local function getPivot(model)
	if model.PrimaryPart then
		return model.PrimaryPart.CFrame
	end
	return model.WorldPivot
end
roblox.implementMethod("Model", "GetPivot", getPivot)
roblox.implementMethod("Model", "PivotTo", function(model, cf)
	local delta = cf * getPivot(model):Inverse()
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CFrame = delta * d.CFrame
		end
	end
	model.WorldPivot = delta * model.WorldPivot
end)
roblox.implementMethod("Workspace", "GetServerTimeNow", function()
	return os.clock()
end)
roblox.implementMethod("RunService", "IsStudio", function()
	return true
end)
roblox.implementMethod("RunService", "IsServer", function()
	return true
end)
roblox.implementMethod("Players", "GetPlayers", function()
	return {}
end)
roblox.implementMethod("Players", "GetPlayerFromCharacter", function()
	return nil
end)
roblox.implementMethod("Instance", "WaitForChild", function(self, name)
	local child = self:FindFirstChild(name)
	assert(child, "WaitForChild: нет " .. name .. " в " .. self:GetFullName())
	return child
end)

local function getService(name: string)
	return game:GetService(name)
end

local workspace = getService("Workspace")

------------------------------------------------------------------
-- require для ModuleScript из места
------------------------------------------------------------------
local Random = {}
Random.__index = Random
function Random.new(_seed)
	return setmetatable({}, Random)
end
function Random:NextNumber(a, b)
	a, b = a or 0, b or 1
	return a + math.random() * (b - a)
end
function Random:NextInteger(a, b)
	return math.random(a, b)
end

local TweenInfo = {
	new = function(...)
		return { ... }
	end,
}
local RaycastParams = {
	new = function()
		return {}
	end,
}

local cache = {}
local requireModule
local baseEnv = {
	TweenInfo = TweenInfo,
	RaycastParams = RaycastParams,
	game = game,
	workspace = workspace,
	Instance = Instance,
	Vector3 = Vector3,
	Vector2 = roblox.Vector2,
	CFrame = CFrame,
	Color3 = roblox.Color3,
	ColorSequence = roblox.ColorSequence,
	NumberSequence = roblox.NumberSequence,
	NumberRange = roblox.NumberRange,
	UDim = roblox.UDim,
	UDim2 = roblox.UDim2,
	Enum = roblox.Enum,
	Random = Random,
	task = task,
	warn = function(...)
		print("[warn]", ...)
	end,
}

function requireModule(module)
	-- в Lune каждая ссылка на Instance — новый userdata, поэтому ключ кэша — полный путь
	local key = module:GetFullName()
	if cache[key] ~= nil then
		return cache[key]
	end
	-- Lune не смотрит в метатаблицу окружения, поэтому копируем глобалы явно
	local env = table.clone(baseEnv)
	env.script = module
	env.require = requireModule
	local fn = luau.load(module.Source, { debugName = module:GetFullName(), environment = env })
	local result = fn()
	cache[key] = result
	return result
end

------------------------------------------------------------------
-- Тесты
------------------------------------------------------------------
local passed, failed = 0, 0
local function check(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
		print("✓ " .. name)
	else
		failed += 1
		print("✗ " .. name .. "\n    " .. tostring(err))
	end
end

local ReplicatedStorage = getService("ReplicatedStorage")
local gameState = Instance.new("Folder")
gameState.Name = "GameState"
gameState.Parent = ReplicatedStorage

local Shared = ReplicatedStorage:FindFirstChild("Shared")
local Server = getService("ServerScriptService"):FindFirstChild("Server")
local Config = requireModule(Shared.Config)
local Economy = requireModule(Shared.Economy)

local World, Library, Misc, Kit
check("Генерация мира (площадь + 6 баз)", function()
	World = requireModule(Server.World.WorldBuilder)
	World.build()
	assert(#World.plots == Config.Game.PlotCount, "неверное число баз")
end)

check("Каждая модель каталога строится", function()
	Library = requireModule(Server.World.ModelLibrary)
	local folder = Instance.new("Folder")
	folder.Parent = workspace
	local total = 0
	for _, item in ipairs(Config.Items.List) do
		assert(Library.has(item.model), "нет строителя для " .. item.model)
		local ok, err = pcall(Library.build, item, CFrame.new(0, 0, 0), folder)
		assert(ok, item.id .. ": " .. tostring(err))
	end
	for _, d in ipairs(folder:GetDescendants()) do
		if d:IsA("BasePart") then
			total += 1
		end
	end
	print(string.format("    %d моделей, %d деталей", #Config.Items.List, total))
	folder:Destroy()
end)

check("Кнопки, жуки, персонал, лопата", function()
	Kit = requireModule(Server.World.ModelKit)
	Misc = requireModule(Server.World.Models.Misc)
	local b = Kit.new("T", CFrame.new())
	Misc.Button(b, "Тест", "$1", "Item")
	Misc.Bug(Kit.new("Bug", CFrame.new()), false)
	Misc.Bug(Kit.new("Boss", CFrame.new()), true)
	Misc.Drone(Kit.new("Drone", CFrame.new()), roblox.Color3.new(1, 1, 1), 6)
	Misc.Robot(Kit.new("Robot", CFrame.new()), roblox.Color3.new(1, 1, 1))
	Misc.StaffNpc(Kit.new("Npc", CFrame.new()), roblox.Color3.new(1, 1, 1), "Тест")
	local tool = Misc.Shovel(true)
	assert(tool:FindFirstChild("Handle"), "у лопаты нет Handle")
end)

check("Модели из Blender: имена деталей и шаблоны", function()
	local AssetName = requireModule(Shared.AssetName)
	local Palette = requireModule(Shared.Config.Palette)
	local info = AssetName.parse("Bush/Plant0__LeafDark@sway_x_2.5_3.14_0.15#-0.05,0.85,-2")
	assert(info and info.key == "LeafDark" and #info.path == 2 and info.path[2] == "Plant0", "parse: путь/ключ")
	assert(
		info.anim == "sway_x_2.5_3.14_0.15" and info.pivot and info.pivot.Z == -2,
		"parse: анимация/точка"
	)
	local body = AssetName.parse("Body__Wood")
	assert(body and #body.path == 0 and body.anim == nil and body.pivot == nil, "parse: Body")
	local tag, attrs = AssetName.animation("spin_z_-180")
	assert(tag == "Spin" and attrs.Axis == "Z" and attrs.Speed == -180, "spin")
	tag, attrs = AssetName.animation("bob_0.12_3.14")
	assert(tag == "Bob" and math.abs(attrs.Speed - 1.57) < 1e-6 and attrs.Amplitude == 0.12, "bob")
	tag, attrs = AssetName.animation("sway_z_14_12.57_0.5")
	assert(tag == "Sway" and attrs.Phase == 0.5 and attrs.Amplitude == 14, "sway")

	-- «импорт» в сантиметрах (маркер 100x100x100) со сдвигом — как бывает после 3D Importer
	local assets = Instance.new("Folder")
	assets.Name = "Assets"
	assets.Parent = getService("ServerStorage")
	local tpl = Instance.new("Model")
	tpl.Name = "BedWood"
	tpl.Parent = assets
	local off = Vector3.new(50, 3, 50)
	local function part(name: string, size, pos)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = CFrame.new(off + pos)
		p.Parent = tpl
	end
	part("Origin__Pivot", Vector3.new(100, 100, 100), Vector3.zero)
	part("Body__Wood", Vector3.new(400, 90, 600), Vector3.new(0, 45, 0))
	part("Bush/Plant0__Leaf@sway_x_2.5_3.14_0.15#0,0.8,-2", Vector3.new(120, 100, 120), Vector3.new(0, 130, -200))
	part("Tubers__Potato", Vector3.new(50, 30, 40), Vector3.new(70, 90, -200))
	part("Lamp__NeonRed@pulse_1.5", Vector3.new(10, 10, 10), Vector3.new(150, 60, 290))
	part("Body__NeonYellow!1", Vector3.new(200, 40, 4), Vector3.new(0, 150, 300))
	local ModelText = requireModule(Shared.Config.ModelText)
	ModelText.BedWood = { [1] = { text = "TEST SIGN", face = "Back" } }
	local labelInfo = AssetName.parse("Flag__Red@sway_y_12_3.14#0,11,0!2")
	assert(labelInfo and labelInfo.label == 2 and labelInfo.pivot and labelInfo.key == "Red", "parse: надпись")
	local Templates = requireModule(Server.World.Templates)
	Templates.reset()
	local item
	for _, it in ipairs(Config.Items.List) do
		if it.model == "BedWood" then
			item = it
			break
		end
	end
	local folder = Instance.new("Folder")
	folder.Parent = workspace
	local model = Library.build(item, CFrame.new(10, 0, 0), folder)
	assert(model:GetAttribute("Template") == "BedWood", "шаблон не применён")
	local plant = model:FindFirstChild("Bush") and model.Bush:FindFirstChild("Plant0")
	assert(
		plant and plant:HasTag("Sway") and plant:GetAttribute("Axis") == "X",
		"куст без покачивания"
	)
	assert(
		(plant.WorldPivot.Position - Vector3.new(10, 0.8, -2)).Magnitude < 1e-3,
		"точка вращения куста"
	)
	local leaf = plant:FindFirstChildWhichIsA("BasePart")
	assert(leaf and (leaf.CFrame.Position - Vector3.new(10, 1.3, -2)).Magnitude < 1e-3, "позиция листа")
	assert(
		math.abs(leaf.Size.X - 1.2) < 1e-3 and leaf.Color == Palette.Leaf.color,
		"масштаб/цвет листа"
	)
	assert(leaf.Material == Palette.Leaf.material and not leaf.CanCollide, "материал/коллизия")
	local lamp = model:FindFirstChild("Lamp") and model.Lamp:FindFirstChildWhichIsA("BasePart")
	assert(lamp and lamp:HasTag("Pulse"), "лампа не мигает")
	local soil = model:FindFirstChild("Soil") :: any
	assert(
		soil and soil.Transparency == 1 and soil:FindFirstChild("Prompt"),
		"подсказка грядки потерялась"
	)
	assert(not soil.CanCollide, "невидимая почва осталась стеной")
	local bodyPart = model:FindFirstChild("Body__Wood") :: any
	assert(bodyPart and bodyPart.CanCollide, "корпус из Blender без коллизии")
	assert(model.Tubers:FindFirstChildWhichIsA("BasePart"), "нет клубней")
	local sign = model:FindFirstChild("Body__NeonYellow!1") :: any
	local gui = sign and sign:FindFirstChild("ModelText")
	assert(
		gui and gui.Text.Text == "TEST SIGN" and sign.Transparency == 1,
		"надпись не стала текстом Roblox"
	)
	ModelText.BedWood = nil
	-- жук-босс: шаблон в 3 раза крупнее
	local bugTpl = Instance.new("Model")
	bugTpl.Name = "Bug"
	bugTpl.Parent = assets
	tpl = bugTpl
	off = Vector3.zero
	part("Origin__Pivot", Vector3.new(1, 1, 1), Vector3.zero)
	part("Hip0-1__BugOrange@sway_z_14_12.57_0#-0.5,0.32,0.72", Vector3.new(0.5, 0.2, 0.2), Vector3.new(-0.7, 0.3, 0.7))
	Templates.reset()
	local boss = Kit.new("Boss", CFrame.new())
	Misc.Bug(boss, true)
	Templates.dress(boss.model, "Bug", CFrame.new(), { scale = 3 })
	local hip = boss.model:FindFirstChild("Hip0-1")
	assert(hip and hip:GetAttribute("Phase") ~= nil, "фаза лапы не задана")
	assert((hip.WorldPivot.Position - Vector3.new(-1.5, 0.96, 2.16)).Magnitude < 1e-3, "масштаб босса")
	assert(boss.model:FindFirstChild("Hitbox"), "хитбокс жука удалён")
	folder:Destroy()
	assets:Destroy()
	Templates.reset()
end)

-- Сервисы на фейковом игроке
local Sessions, PlotService, ManualFarm, PurchaseService, EventService, RebirthService
check("Загрузка сервисов", function()
	local S = Server.Services
	Sessions = requireModule(S.Sessions)
	PlotService = requireModule(S.PlotService)
	ManualFarm = requireModule(S.ManualFarm)
	PurchaseService = requireModule(S.PurchaseService)
	EventService = requireModule(S.EventService)
	RebirthService = requireModule(S.RebirthService)
	requireModule(S.IncomeService)
	requireModule(S.PassService)
	requireModule(S.DataService)
	ManualFarm.init()
	PurchaseService.init()
	RebirthService.init()
end)

-- «Игрок»: Folder с атрибутами + поля Player, которых нет у Folder
local player = Instance.new("Folder")
player.Name = "TestPlayer"
player.Parent = getService("Players")
local fakePlayer = setmetatable({ UserId = 101, DisplayName = "Tester", Name = "Tester", Character = false }, {
	__index = function(_, key)
		local ok, value = pcall(function()
			return player[key]
		end)
		if not ok then
			return nil
		end
		if type(value) == "function" then
			return function(_, ...)
				return value(player, ...)
			end
		end
		return value
	end,
})
rawset(fakePlayer, "Character", nil)

local session
check("Вход игрока: база, грядки, лопата", function()
	local profile = Economy.newProfile(Config)
	session = Sessions.create(fakePlayer, profile, false)
	Sessions.recompute(session)
	assert(PlotService.assign(session), "база не выдана")
	PlotService.buildAll(session)
	ManualFarm.setupBeds(session)
	session.loaded = true
	local buttons = #session.plot.buttons:GetChildren()
	assert(buttons > 0, "нет кнопок покупки")
	print(string.format("    кнопок на старте: %d", buttons))
end)

check("Сдача урожая скупщику", function()
	session.profile.bag = 10
	ManualFarm.sell(session)
	assert(session.profile.cash == 10, "ожидалось $10, получено " .. session.profile.cash)
	assert(session.profile.bag == 0, "мешок не опустел")
end)

check("Покупка всего каталога по порядку", function()
	local bought = 0
	for _, item in ipairs(Config.Items.List) do
		if not item.prebuilt and not session.profile.owned[item.id] then
			session.profile.cash = 1e13
			assert(PurchaseService.buyItem(fakePlayer, item.id), "не удалось купить " .. item.id)
			bought += 1
		end
	end
	assert(
		#session.plot.buttons:GetChildren() == 0,
		"остались кнопки после покупки всего"
	)
	print(string.format("    куплено построек: %d, этап: %d", bought, session.stats.stage))
	assert(session.stats.stage == 5, "ожидался этап 5")
end)

check("Исследования, выбор сорта, персонал, технологии", function()
	session.profile.cash = 1e13
	for _, v in ipairs(Config.Varieties) do
		PurchaseService.buyResearch(fakePlayer, v.id)
	end
	for _, v in ipairs(Config.Varieties) do
		assert(session.profile.varieties[v.id], "не открыт сорт " .. v.id)
	end
	assert(
		session.stats.variety.id == "void",
		"автовыбор должен выбрать самый выгодный сорт"
	)
	PurchaseService.selectVariety(fakePlayer, "gala")
	assert(session.stats.variety.id == "gala", "сорт не переключился на Гала")
	PurchaseService.selectVariety(fakePlayer, nil)
	for _, s in ipairs(Config.Staff.List) do
		for _ = 1, s.max do
			session.profile.cash = 1e13
			PurchaseService.hireStaff(fakePlayer, s.id)
		end
	end
	local staffModels = #session.plot.staff:GetChildren()
	print(
		string.format(
			"    персонала на базе: %d, доход: $%.3g/с",
			staffModels,
			session.stats.incomePerSec
		)
	)
	session.profile.stars = 1e6
	for _, t in ipairs(Config.StarTech.List) do
		PurchaseService.buyStarTech(fakePlayer, t.id)
	end
end)

check("Нашествие жуков: поимка и награда", function()
	EventService.startBugs()
	local bugs = session.plot.bugs:GetChildren()
	assert(#bugs == Config.Game.Events.Bugs.Count + 1, "неверное число жуков")
	local before = session.profile.cash
	for _, bug in ipairs(bugs) do
		for _ = 1, 10 do
			if bug.Parent then
				EventService.clickBug(fakePlayer, bug)
			end
		end
	end
	assert(session.bugs.rewarded, "награда не выдана")
	assert(session.profile.cash > before, "деньги за жуков не начислены")
end)

check("Rebirth: сброс базы, звёзды, множитель", function()
	session.profile.cash = 1e13
	local stars = session.profile.stars
	RebirthService.request(fakePlayer)
	assert(session.profile.rebirths == 1, "rebirth не засчитан")
	assert(session.profile.stars == stars + 100, "звёзды не начислены")
	assert(session.profile.owned.tower == nil, "постройки не сброшены")
	assert(
		session.profile.owned.star_terminal,
		"терминал звёзд должен появиться после Rebirth"
	)
	assert(
		session.plot.items:FindFirstChild("star_terminal"),
		"модель терминала не построена"
	)
	assert(session.stats.rebirthMult == 3, "множитель Rebirth должен быть x3")
end)

------------------------------------------------------------------
-- Клиент: интерфейс, окна и эффекты
------------------------------------------------------------------
local localPlayer = Instance.new("Player")
localPlayer.Name = "ClientPlayer"
localPlayer.UserId = 101
local playerGui = Instance.new("Folder")
playerGui.Name = "PlayerGui"
playerGui.Parent = localPlayer
-- у камеры в Lune нет значения ViewportSize по умолчанию — задаём экран 1280x720
workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(1280, 720)
-- LocalPlayer — родное свойство: в Lune его можно просто присвоить
localPlayer.Parent = getService("Players")
getService("Players").LocalPlayer = localPlayer
roblox.implementMethod("Instance", "GetAttributeChangedSignal", function(self, name)
	return signal(self, "Attr_" .. name)
end)
roblox.implementMethod("Instance", "GetPropertyChangedSignal", function(self, name)
	return signal(self, "Prop_" .. name)
end)
for className, names in pairs({
	GuiButton = { "Activated" },
	RemoteEvent = { "OnClientEvent" },
	RunService = { "Heartbeat", "RenderStepped" },
	UserInputService = { "InputBegan" },
	ProximityPromptService = { "PromptTriggered" },
}) do
	for _, name in ipairs(names) do
		roblox.implementProperty(className, name, function(self)
			return signal(self, name)
		end)
	end
end
roblox.implementProperty("BindableEvent", "Event", function(self)
	return signal(self, "Event")
end)
roblox.implementMethod("BindableEvent", "Fire", function(self, ...)
	signal(self, "Event"):Fire(...)
end)
roblox.implementMethod("TweenService", "Create", function(_, inst, _info, goal)
	return {
		Play = function()
			for k, v in pairs(goal) do
				inst[k] = v
			end
		end,
		Cancel = function() end,
		Completed = signal(inst, "TweenCompleted"),
	}
end)
roblox.implementMethod("SoundService", "PlayLocalSound", function() end)
roblox.implementMethod("ParticleEmitter", "Emit", function() end)
roblox.implementMethod("MarketplaceService", "PromptGamePassPurchase", function() end)
roblox.implementMethod("RemoteEvent", "FireServer", function() end)
roblox.implementMethod("CollectionService", "GetTagged", function(_, tag)
	local list = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:HasTag(tag) then
			table.insert(list, d)
		end
	end
	return list
end)
roblox.implementMethod("CollectionService", "GetInstanceAddedSignal", function(self, tag)
	return signal(self, "Added_" .. tag)
end)
roblox.implementMethod("CollectionService", "GetInstanceRemovedSignal", function(self, tag)
	return signal(self, "Removed_" .. tag)
end)
local chatCallback
roblox.implementProperty("TextChatService", "OnIncomingMessage", function()
	return chatCallback
end, function(_, fn)
	chatCallback = fn
end)
for _, className in ipairs({ "Folder", "Model", "Workspace" }) do
	roblox.implementProperty(className, "DescendantAdded", function(self)
		return signal(self, "DescendantAdded")
	end)
end

local Client = getService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"):FindFirstChild("Client")
local Windows, Effects, Toasts, Remotes
check("Клиент: загрузка интерфейса и контроллеров", function()
	for name, value in pairs(player:GetAttributes()) do
		localPlayer:SetAttribute(name, value)
	end
	local main = Client:FindFirstChild("Main")
	local env = table.clone(baseEnv)
	env.script = main
	env.require = requireModule
	luau.load(main.Source, { debugName = "Client.Main", environment = env })()
	Windows = requireModule(Client.UI.Windows)
	Effects = requireModule(Client.Controllers.Effects)
	Toasts = requireModule(Client.UI.Toasts)
	Remotes = requireModule(Shared.Remotes)
	assert(playerGui:FindFirstChild("PotatoUI"), "ScreenGui не создан")
end)

check("Клиент: синхронизация и все окна меню", function()
	session.clientReady = true
	Sessions.sync(session)
	local payload = lastPayload.Sync
	assert(payload, "сервер не отправил Sync")
	signal(Remotes.get("Sync"), "OnClientEvent"):Fire(table.unpack(payload))
	assert(requireModule(Client.State).data ~= nil, "клиент не принял Sync")
	for _, name in ipairs({ "Research", "Staff", "StarTech", "Rebirth", "Shop", "Stats" }) do
		Windows.open(name)
		local gui = playerGui:FindFirstChild("PotatoUI")
		local window = gui:FindFirstChild("Window")
		assert(window, "окно " .. name .. " не открылось")
		Windows.close()
	end
	Windows.offline(3600, 1e6)
end)

check("Клиент: HUD реагирует на атрибуты", function()
	for _, name in ipairs({ "Cash", "Income", "EnergyGen", "Overloaded", "Stage", "Bag" }) do
		signal(localPlayer, "Attr_" .. name):Fire()
	end
	localPlayer:SetAttribute("Overloaded", true)
	signal(localPlayer, "Attr_Overloaded"):Fire()
end)

check("Клиент: все эффекты и уведомления", function()
	local items = session.plot.items
	local bed = items:FindFirstChild("bed_wood_1")
	local pos = Vector3.new(0, 1, 0)
	for _, data in ipairs({
		{ type = "Float", position = pos, text = "+$1" },
		{ type = "Dig", position = pos, amount = 3 },
		{ type = "Sell", position = pos, amount = 15 },
		{ type = "Golden", target = bed, amount = 25, glow = 1 },
		{ type = "Confetti", big = true },
		{ type = "Launch", plotIndex = session.plot.index },
		{ type = "Squash", position = pos, dead = true },
		{ type = "Purchase", itemId = "tower" },
		{ type = "Stage", stage = 3 },
		{ type = "Sound", sound = "Cash" },
	}) do
		Effects.handle(data)
	end
	for _, kind in ipairs({ "info", "success", "error", "gold", "stage", "event", "tip" }) do
		Toasts.show("Проверка уведомления " .. kind, kind)
	end
end)

check("Клиент: чат-тег VIP", function()
	assert(chatCallback, "OnIncomingMessage не задан")
end)

------------------------------------------------------------------
-- Сервер целиком: Main.server, вход игрока через PlayerAdded, рукопожатие Ready
------------------------------------------------------------------
roblox.implementMethod("DataModel", "BindToClose", function() end)
roblox.implementProperty("Player", "CharacterAdded", function(self)
	return signal(self, "CharacterAdded")
end)

check("Сервер: Main.server и вход нового игрока", function()
	local main = Server:FindFirstChild("Main")
	local env = table.clone(baseEnv)
	env.script = main
	env.require = requireModule
	luau.load(main.Source, { debugName = "Server.Main", environment = env })()
	local newcomer = Instance.new("Player")
	newcomer.Name = "Newcomer"
	newcomer.DisplayName = "Newcomer"
	newcomer.UserId = 202
	newcomer.Parent = getService("Players")
	signal(getService("Players"), "PlayerAdded"):Fire(newcomer)
	local s = Sessions.get(newcomer)
	assert(s and s.loaded, "сессия нового игрока не загрузилась")
	assert(s.plot, "новому игроку не выдана база")
	assert(#s.plot.buttons:GetChildren() == 3, "на старте должно быть 3 кнопки")
	assert(newcomer:FindFirstChild("leaderstats"), "нет leaderstats")
	lastPayload.Sync = nil
	signal(Remotes.get("Ready"), "OnServerEvent"):Fire(newcomer)
	assert(lastPayload.Sync, "после Ready сервер не прислал Sync")
	signal(getService("Players"), "PlayerRemoving"):Fire(newcomer)
	assert(Sessions.get(newcomer) == nil, "сессия не удалена после выхода")
end)

print(
	string.format(
		"\nИтог: %d ✓, %d ✗ (событий клиентам: %d адресных, %d всем)",
		passed,
		failed,
		fired.client,
		fired.all
	)
)
if failed > 0 then
	process.exit(1)
end
process.exit(0)
