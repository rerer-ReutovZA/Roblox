-- Экспорт геометрии моделей игры в JSON для рендера (tools/render/render.mjs).
-- Модели строятся настоящим кодом игры (ModelKit + Models/*), как в смоук-тесте.
--
-- Запуск: lune run tools/render/export.luau build/PotatoTycoon.rbxlx build/render/scenes.json

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox") :: any
local serde = require("@lune/serde")
local task = require("@lune/task")

local placePath = process.args[1] or "build/PotatoTycoon.rbxlx"
local outPath = process.args[2] or "build/render/scenes.json"
local game = roblox.deserializePlace(fs.readFile(placePath))
local Vector3 = roblox.Vector3

-- CFrame.lookAt в Lune 0.10 считает ориентацию неверно (например, (0,0,-1) → взгляд в +Z),
-- поэтому подставляем реализацию, совпадающую с Roblox
local function lookAt(at, target, up)
	up = up or Vector3.new(0, 1, 0)
	local look = (target - at).Unit
	local right = look:Cross(up)
	if right.Magnitude < 1e-6 then
		right = look:Cross(Vector3.new(0, 0, 1))
	end
	right = right.Unit
	local upv = right:Cross(look).Unit
	local back = -look
	return roblox.CFrame.new(at.X, at.Y, at.Z, right.X, upv.X, back.X, right.Y, upv.Y, back.Y, right.Z, upv.Z, back.Z)
end
local CFrame = setmetatable({ lookAt = lookAt }, { __index = roblox.CFrame })

------------------------------------------------------------------
-- Минимальные заглушки Roblox API (см. tools/smoke_test.luau)
------------------------------------------------------------------
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
roblox.implementMethod("Instance", "WaitForChild", function(self, name)
	return assert(self:FindFirstChild(name), "нет " .. name)
end)

local Random = {}
Random.__index = Random
function Random.new(_seed)
	return setmetatable({}, Random)
end
function Random:NextNumber(a, b)
	a, b = a or 0, b or 1
	return a + math.random() * (b - a)
end

local baseEnv = {
	game = game,
	workspace = game:GetService("Workspace"),
	Instance = roblox.Instance,
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
	warn = print,
}

local cache = {}
local function requireModule(module)
	local key = module:GetFullName()
	if cache[key] == nil then
		local env = table.clone(baseEnv)
		env.script = module
		env.require = requireModule
		cache[key] = luau.load(module.Source, { debugName = key, environment = env })()
	end
	return cache[key]
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local gameState = roblox.Instance.new("Folder")
gameState.Name = "GameState"
gameState.Parent = ReplicatedStorage

local Server = game:GetService("ServerScriptService"):FindFirstChild("Server")
local Config = requireModule(ReplicatedStorage.Shared.Config)
local Library = requireModule(Server.World.ModelLibrary)
local World = requireModule(Server.World.WorldBuilder)

------------------------------------------------------------------
-- Сериализация деталей
------------------------------------------------------------------
local function round(x: number): number
	return math.floor(x * 1000 + 0.5) / 1000
end

local function serializePart(part)
	local cf = part.CFrame
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	local shape = "box"
	if part.ClassName == "WedgePart" then
		shape = "wedge"
	elseif part.Shape == roblox.Enum.PartType.Cylinder then
		shape = "cyl"
	elseif part.Shape == roblox.Enum.PartType.Ball then
		shape = "ball"
	end
	local mesh = part:FindFirstChildOfClass("SpecialMesh")
	if mesh and mesh.MeshType == roblox.Enum.MeshType.Sphere then
		shape = "ell"
	end
	local c = part.Color
	local size = part.Size
	return {
		s = shape,
		p = { round(x), round(y), round(z) },
		r = { r00, r01, r02, r10, r11, r12, r20, r21, r22 },
		z = { round(size.X), round(size.Y), round(size.Z) },
		c = { round(c.R), round(c.G), round(c.B) },
		m = part.Material.Name,
		t = round(part.Transparency),
	}
end

local function serializeLabel(gui)
	local part = gui.Parent
	local label = gui:FindFirstChildOfClass("TextLabel")
	if not (part and part:IsA("BasePart") and label) then
		return nil
	end
	local base = serializePart(part)
	local tc = label.TextColor3
	local bg = nil
	if label.BackgroundTransparency < 1 then
		local b = label.BackgroundColor3
		bg = { round(b.R), round(b.G), round(b.B) }
	end
	return {
		p = base.p,
		r = base.r,
		z = base.z,
		face = gui.Face.Name,
		text = label.Text,
		color = { round(tc.R), round(tc.G), round(tc.B) },
		bg = bg,
		font = label.Font.Name,
	}
end

local function serialize(root)
	local parts, labels = {}, {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			if d.Transparency < 1 then
				table.insert(parts, serializePart(d))
			end
		elseif d:IsA("SurfaceGui") then
			local l = serializeLabel(d)
			if l then
				table.insert(labels, l)
			end
		end
	end
	return parts, labels
end

------------------------------------------------------------------
-- Сцены
------------------------------------------------------------------
local scenes = {}

-- entries: id постройки или { id = ..., pos = { x, z }, rot = градусы } для своей позиции в кадре
local function addScene(id: string, title: string, ground: string, entries: { any }, view: { [string]: number }?)
	local folder = roblox.Instance.new("Folder")
	for _, entry in ipairs(entries) do
		local itemId = if type(entry) == "table" then entry.id else entry
		local item = Config.Items.ById[itemId]
		assert(item, "нет постройки " .. itemId)
		local pos = if type(entry) == "table" and entry.pos then entry.pos else item.pos
		local rot = if type(entry) == "table" and entry.rot then entry.rot else (item.rot or 0)
		local cf = CFrame.new(pos[1], item.y or 0, pos[2]) * CFrame.Angles(0, math.rad(rot), 0)
		Library.build(item, cf, folder)
	end
	local parts, labels = serialize(folder)
	scenes[id] = { title = title, ground = ground, parts = parts, labels = labels, view = view or {} }
	print(string.format("%-12s %4d деталей, %2d надписей — %s", id, #parts, #labels, title))
end

addScene(
	"tower",
	"Авто-вышка сбора + контракт с торговой сетью",
	"grass",
	{ "tower" }
)
addScene(
	"stand",
	"Лоток деревенского скупщика, Дед Матвей и стартовая грядка",
	"grass",
	{
		"stand",
		{ id = "matvey", pos = { 2.8, 37 }, rot = 25 },
		{ id = "bed_wood_1", pos = { -2.5, 31 } },
	},
	{ yaw = 28, pitch = 20 }
)
addScene(
	"chips_line",
	"Цеха-множители: специи x6, фритюр x4, слайсер x2.5, пилер +0.5, мойка x1.5",
	"concrete",
	{
		"washer",
		"peeler",
		"slicer",
		"fryer",
		"spices",
	},
	{ yaw = 20, pitch = 22 }
)
addScene(
	"cosmodrome",
	"Космодром: стартовая площадка, пусковая вышка и шаттл",
	"tiles",
	{
		"launch_pad",
		"launch_tower",
		"shuttle",
	},
	{ yaw = 30, pitch = 14 }
)
addScene(
	"quantum",
	"Квантовый преобразователь x100",
	"concrete",
	{ "quantum_converter" },
	{ yaw = 15 }
)

-- Вся база в конце игры
do
	World.build()
	local info = World.plots[1]
	for _, item in ipairs(Config.Items.List) do
		if not (item.minRebirths and item.minRebirths > 0) then
			Library.build(item, World.localCFrame(info, item.pos[1], item.pos[2], item.rot, item.y), info.items)
		end
	end
	-- переводим в локальные координаты базы, чтобы рендер был независим от её места на круге
	local inverse = info.cframe:Inverse()
	for _, d in ipairs(info.folder:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CFrame = inverse * d.CFrame
		end
	end
	local parts, labels = serialize(info.folder)
	scenes.base = {
		title = "База игрока 80x80 в конце игры",
		ground = "grass",
		parts = parts,
		labels = labels,
		view = { yaw = 32, pitch = 40, zoom = 1.3 },
	}
	print(string.format("%-12s %4d деталей, %2d надписей — вся база", "base", #parts, #labels))
end

local dir = string.match(outPath, "^(.*)/[^/]*$")
if dir and not fs.isDir(dir) then
	fs.writeDir(dir)
end
fs.writeFile(outPath, serde.encode("json", scenes))
print("Сохранено: " .. outPath)
