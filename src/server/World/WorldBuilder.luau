-- Генерация мира: центральная площадь, дорожки и 6 баз игроков 80x80 по кругу.
-- Локальная система базы: x вправо (восток), z к входу (к площади), пол на y = 0.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Kit = require(script.Parent.ModelKit)
local Misc = require(script.Parent.Models.Misc)
local Templates = require(script.Parent.Templates)

local V = Vector3.new
local C = Kit.C
local M = Enum.Material

local FLOOR_Y = 0.2

local World = {}

export type PlotInfo = {
	index: number,
	cframe: CFrame,
	folder: Model,
	items: Folder,
	buttons: Folder,
	staff: Folder,
	bugs: Folder,
	sign: TextLabel,
	spawn: CFrame,
}

World.plots = {} :: { PlotInfo }

local SECTORS = {
	{
		name = "СЕКТОР 1: АГРО-БЛОК",
		z0 = 14,
		z1 = 40,
		color = Color3.fromRGB(105, 165, 75),
		material = M.Grass,
	},
	{
		name = "СЕКТОР 3: ЭНЕРГЕТИКА И ДРОН-СЕРВИС",
		z0 = -2,
		z1 = 14,
		color = Color3.fromRGB(80, 82, 88),
		material = M.Asphalt,
	},
	{
		name = "СЕКТОР 2: ЗАВОД ПЕРЕРАБОТКИ",
		z0 = -22,
		z1 = -2,
		color = Color3.fromRGB(165, 165, 160),
		material = M.Concrete,
	},
	{
		name = "СЕКТОР 4: НАУКА, КОСМОДРОМ И REBIRTH",
		z0 = -40,
		z1 = -22,
		color = Color3.fromRGB(215, 222, 235),
		material = M.CeramicTiles,
	},
}

local function floorText(b: Kit.Builder, text: string, pos: Vector3, width: number)
	local p = b:box(V(width, 0.05, 1.6), pos, C.white, M.SmoothPlastic, { collide = false, transparency = 1 })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0.3
	gui.Parent = p
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 230, 120)
	label.TextStrokeTransparency = 0.4
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = text
	label.Parent = gui
end

local function buildPlotBase(index: number, cf: CFrame): PlotInfo
	local folder = Instance.new("Model")
	folder.Name = "Plot" .. index
	folder:SetAttribute("PlotIndex", index)
	folder.WorldPivot = cf

	local b = Kit.new("Base", cf * CFrame.new(0, -FLOOR_Y, 0))
	-- полы секторов
	for _, s in ipairs(SECTORS) do
		local depth = s.z1 - s.z0
		b:box(V(80, 0.2, depth), V(0, 0.1, (s.z0 + s.z1) / 2), s.color, s.material)
	end
	-- центральная дорожка
	b:box(V(6, 0.06, 80), V(0, 0.23, 0), Color3.fromRGB(125, 125, 128), M.Pavement, { collide = false })
	for _, s in ipairs(SECTORS) do
		floorText(b, s.name, V(0, 0.27, s.z1 - 1.4), 6)
	end
	-- сетчатый забор с колючей проволокой (ГДД 168) вокруг индустриальной части
	local fence = Color3.fromRGB(150, 155, 160)
	local function fenceLine(a: Vector3, c: Vector3)
		local mid = (a + c) / 2
		local len = (c - a).Magnitude
		local alongX = math.abs(c.X - a.X) > 0.1
		b:box(
			if alongX then V(len, 2.8, 0.1) else V(0.1, 2.8, len),
			mid + V(0, 1.6, 0),
			fence,
			M.DiamondPlate,
			{ transparency = 0.55 }
		)
		b:pipe(a + V(0, 3.1, 0), c + V(0, 3.1, 0), 0.12, Color3.fromRGB(90, 90, 95))
		local n = math.max(1, math.floor(len / 8))
		for i = 0, n do
			b:box(V(0.25, 3.3, 0.25), a:Lerp(c, i / n) + V(0, 1.85, 0), Color3.fromRGB(90, 90, 95), M.Metal)
		end
	end
	fenceLine(V(-40, 0, 14), V(-40, 0, -40))
	fenceLine(V(40, 0, 14), V(40, 0, -40))
	fenceLine(V(-40, 0, -40), V(-4, 0, -40))
	fenceLine(V(4, 0, -40), V(40, 0, -40))

	-- табличка владельца у входа
	b:box(V(0.4, 4, 0.4), V(-7, 2.2, 41.5), C.woodDark, M.Wood)
	local board = b:box(V(7, 2.2, 0.3), V(-7, 4.6, 41.5), C.woodLight, M.WoodPlanks, { name = "OwnerSign" })
	local sign = b:label(board, Enum.NormalId.Back, "Free Base", { color = C.woodDark })
	local base = b.model
	base.Parent = folder

	local function sub(name: string, class: string)
		local f = Instance.new(class)
		f.Name = name
		f.Parent = folder
		return f
	end

	local info: PlotInfo = {
		index = index,
		cframe = cf,
		folder = folder,
		items = sub("Items", "Folder") :: Folder,
		buttons = sub("Buttons", "Folder") :: Folder,
		staff = sub("Staff", "Folder") :: Folder,
		bugs = sub("Bugs", "Folder") :: Folder,
		sign = sign,
		spawn = cf * CFrame.new(0, 3, 37), -- лицом вглубь базы (-Z)
	}
	return info
end

local function hubObject(builderName: string, parent: Instance, cf: CFrame, ...)
	local b = Kit.new(builderName, cf)
	Misc[builderName](b, ...)
	Templates.dress(b.model, builderName, cf)
	return b:finish(parent)
end

local function tree(parent: Instance, pos: Vector3, scale: number)
	local b = Kit.new("Tree", CFrame.new(pos))
	b:cyl(5 * scale, 1.2 * scale, V(0, 2.5 * scale, 0), C.woodDark, M.Wood)
	b:ellipsoid(V(7, 6, 7) * scale, V(0, 6.5 * scale, 0), C.leafDark, M.Grass)
	b:ellipsoid(V(5, 4.5, 5) * scale, V(0.8 * scale, 9 * scale, 0.5 * scale), C.leaf, M.Grass)
	Templates.dress(b.model, "Tree", CFrame.new(pos), { scale = scale * 1.3 })
	b:finish(parent)
end

function World.build()
	local G = Config.Game
	local root = Instance.new("Folder")
	root.Name = "World"
	root.Parent = workspace

	-- центральная площадь
	local hub = Instance.new("Folder")
	hub.Name = "Hub"
	hub.Parent = root
	local plaza = Kit.new("Plaza", CFrame.new())
	plaza:cyl(0.3, G.HubRadius * 2, V(0, 0.15, 0), Color3.fromRGB(190, 185, 175), M.Pavement)
	plaza:cyl(0.32, G.HubRadius * 2 - 6, V(0, 0.16, 0), Color3.fromRGB(205, 200, 190), M.Cobblestone)
	plaza:finish(hub)
	hubObject("FounderStatue", hub, CFrame.new(0, 0.3, 0) * CFrame.Angles(0, math.rad(180), 0))

	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = workspace

	local count = G.PlotCount
	local R = G.PlotRingRadius
	for i = 1, count do
		local angle = (i - 1) * 2 * math.pi / count
		local dir = V(math.sin(angle), 0, math.cos(angle))
		local center = dir * R + V(0, FLOOR_Y, 0)
		local cf = CFrame.lookAt(center, center + dir)
		local info = buildPlotBase(i, cf)
		info.folder.Parent = plotsFolder
		World.plots[i] = info

		-- дорожка от площади к входу на базу
		local inner = G.HubRadius - 2
		local outer = R - 40
		local mid = dir * ((inner + outer) / 2)
		local path = Kit.new("Path" .. i, CFrame.lookAt(mid, mid + dir))
		path:box(V(8, 0.24, outer - inner), V(0, 0.12, 0), Color3.fromRGB(150, 145, 140), M.Pavement)
		path:finish(hub)
		-- фонари вдоль дорожки
		for d = inner + 8, outer - 4, 16 do
			for _, side in ipairs({ -1, 1 }) do
				local perp = dir:Cross(Vector3.yAxis) * side
				local p = dir * d + perp * 5.5
				-- +Z модели (стрела фонаря) смотрит на дорожку
				hubObject("StreetLight", hub, CFrame.lookAt(p, p + perp))
			end
		end
	end

	-- объекты площади между дорожками
	local decor = { "HallOfFame", "RebirthGate", "GoldenPedestal", "CryoCapsule", "Bench", "TrashBin" }
	for i, name in ipairs(decor) do
		local angle = (i - 0.5) * 2 * math.pi / count
		local p = V(math.sin(angle), 0, math.cos(angle)) * (G.HubRadius - 12) + V(0, 0.3, 0)
		-- +Z модели смотрит в центр площади
		local model = hubObject(name, hub, CFrame.lookAt(p, p + (p - V(0, 0.3, 0))))
		if name == "HallOfFame" then
			World.hallOfFame = model
		end
	end

	-- деревья по внешнему кольцу
	local rng = Random.new(42)
	local trees = Instance.new("Folder")
	trees.Name = "Trees"
	trees.Parent = root
	for i = 1, 36 do
		local angle = i / 36 * math.pi * 2 + rng:NextNumber(-0.05, 0.05)
		local r = R + 75 + rng:NextNumber(-10, 25)
		tree(trees, V(math.sin(angle) * r, 0, math.cos(angle) * r), rng:NextNumber(0.9, 1.5))
	end
end

-- CFrame точки (x, z) базы с поворотом rot (градусы) и подъёмом y
function World.localCFrame(info: PlotInfo, x: number, z: number, rot: number?, y: number?): CFrame
	return info.cframe * CFrame.new(x, y or 0, z) * CFrame.Angles(0, math.rad(rot or 0), 0)
end

return World
