-- Модели агро-блока (сектор 1). Каждая функция строит модель в своей локальной системе:
-- (0, 0, 0) — центр пятна на уровне пола, +Z — к входу на базу.

local Kit = require(script.Parent.Parent.ModelKit)

type Builder = Kit.Builder

local V = Vector3.new
local C = Kit.C
local M = Enum.Material

local Models = {}

local function prompt(parent: BasePart, action: string, text: string, object: string?, hold: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.Name = "Prompt"
	p.ActionText = text
	p.ObjectText = object or ""
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = 10
	p.RequiresLineOfSight = false
	p:SetAttribute("Action", action)
	p.Parent = parent
	return p
end
Models.prompt = prompt

-- Кусты картофеля: 3 куста вдоль грядки (клиент анимирует рост) и клубни на почве
local function bushes(b: Builder, soilTop: number, length: number)
	local bush = b:group("Bush", V(0, soilTop, 0))
	for i = -1, 1 do
		local z = i * length / 3
		bush:cyl(0.8, 0.25, V(0, soilTop + 0.4, z), C.leafDark, M.Grass, { collide = false })
		bush:ellipsoid(V(1.9, 1.3, 1.6), V(0, soilTop + 1.0, z), C.leaf, M.Grass, { collide = false })
		bush:ellipsoid(V(1.1, 0.9, 1.1), V(0.45, soilTop + 1.45, z + 0.3), C.leafDark, M.Grass, { collide = false })
	end
	local tubers = b:group("Tubers", V(0, soilTop, 0))
	for i = -1, 1 do
		local z = i * length / 3
		tubers:potato(V(-0.9, soilTop + 0.15, z + 0.6), 0.9, nil, { collide = false, rot = V(0, 30, 0) })
		tubers:potato(V(0.95, soilTop + 0.15, z - 0.5), 0.8, nil, { collide = false, rot = V(0, -20, 0) })
	end
end

local function soil(b: Builder, w: number, d: number, y: number): Part
	local s = b:box(V(w, 0.3, d), V(0, y, 0), C.soil, M.Ground, { name = "Soil" })
	-- борозды
	for i = -1, 1, 2 do
		b:box(V(0.25, 0.08, d - 0.3), V(i * w / 4, y + 0.17, 0), C.soilDark, M.Ground, { collide = false })
	end
	return s
end

local function manualBed(b: Builder, item)
	b.model:SetAttribute("ManualBed", true)
	local s = b.model:FindFirstChild("Soil") :: BasePart
	prompt(s, "Dig", "Выкопать", item.name)
end

function Models.BedWood(b: Builder, item)
	b:box(V(0.4, 0.9, 6), V(-1.8, 0.45, 0), C.wood, M.WoodPlanks)
	b:box(V(0.4, 0.9, 6), V(1.8, 0.45, 0), C.wood, M.WoodPlanks)
	b:box(V(3.2, 0.9, 0.4), V(0, 0.45, 2.8), C.wood, M.WoodPlanks)
	b:box(V(3.2, 0.9, 0.4), V(0, 0.45, -2.8), C.wood, M.WoodPlanks)
	soil(b, 3.2, 5.2, 0.6)
	bushes(b, 0.75, 5.2)
	manualBed(b, item)
end

function Models.BedStone(b: Builder, item)
	for z = -2.5, 2.5, 1.25 do
		b:box(V(0.5, 1.0, 1.2), V(-1.75, 0.5, z), if z % 2.5 == 0 then C.stone else C.stoneDark, M.Slate)
		b:box(V(0.5, 1.0, 1.2), V(1.75, 0.5, z), if z % 2.5 == 0 then C.stoneDark else C.stone, M.Slate)
	end
	b:box(V(3, 1.0, 0.5), V(0, 0.5, 2.75), C.stone, M.Slate)
	b:box(V(3, 1.0, 0.5), V(0, 0.5, -2.75), C.stone, M.Slate)
	soil(b, 3, 5, 0.75)
	bushes(b, 0.9, 5)
	manualBed(b, item)
end

function Models.BedMetal(b: Builder, item)
	b:box(V(0.35, 1.1, 6), V(-1.82, 0.55, 0), C.metal, M.DiamondPlate)
	b:box(V(0.35, 1.1, 6), V(1.82, 0.55, 0), C.metal, M.DiamondPlate)
	b:box(V(3.3, 1.1, 0.35), V(0, 0.55, 2.82), C.metal, M.DiamondPlate)
	b:box(V(3.3, 1.1, 0.35), V(0, 0.55, -2.82), C.metal, M.DiamondPlate)
	-- нагревательные полосы
	b:box(V(0.06, 0.18, 5.4), V(-2.02, 0.75, 0), C.orange, M.Neon, { collide = false })
	b:box(V(0.06, 0.18, 5.4), V(2.02, 0.75, 0), C.orange, M.Neon, { collide = false })
	b:box(V(0.8, 0.6, 0.6), V(1.2, 0.3, 3.3), C.metalDark, M.Metal)
	soil(b, 3.3, 5.3, 0.85)
	bushes(b, 1.0, 5.3)
	manualBed(b, item)
end

function Models.WateringCan(b: Builder)
	b:box(V(1.6, 0.7, 1.6), V(0, 0.35, 0), C.woodDark, M.WoodPlanks)
	b:cyl(1.0, 0.9, V(0, 1.2, 0), C.green, M.Metal)
	b:box(V(0.15, 0.6, 0.15), V(0, 1.9, 0), C.green, M.Metal)
	b:box(V(0.7, 0.12, 0.15), V(0, 2.2, 0), C.green, M.Metal)
	b:pipe(V(0.3, 1.0, 0), V(1.0, 1.6, 0), 0.18, C.green, M.Metal)
	b:cyl(0.15, 0.35, V(1.05, 1.65, 0), C.metal, M.Metal, { rot = V(0, 0, -50) })
	-- таймер авто-полива
	b:box(V(0.5, 0.4, 0.2), V(0, 1.2, 0.5), C.white, M.SmoothPlastic, { collide = false })
	local led = b:box(V(0.15, 0.15, 0.05), V(0.1, 1.25, 0.62), C.cyan, M.Neon, { collide = false })
	b:tag(led, "Pulse", { Speed = 3 })
end

function Models.BigSack(b: Builder)
	b:ellipsoid(V(1.7, 2.2, 1.5), V(0, 1.1, 0), Color3.fromRGB(176, 150, 105), M.Fabric)
	b:cyl(0.3, 0.8, V(0, 2.25, 0), Color3.fromRGB(150, 125, 85), M.Fabric)
	for i = 1, 4 do
		local a = math.rad(i * 90)
		b:potato(V(math.cos(a) * 0.35, 2.45, math.sin(a) * 0.35), 0.7, nil, { collide = false })
	end
	local tag = b:box(V(0.9, 0.6, 0.05), V(0, 1.2, 0.76), C.white, M.SmoothPlastic, { collide = false })
	b:label(tag, Enum.NormalId.Back, "XL", { color = C.red })
end

function Models.SellStand(b: Builder)
	-- прилавок
	local counter = b:box(V(6.6, 1.6, 1.4), V(0, 0.8, 2.2), C.wood, M.WoodPlanks, { name = "Counter" })
	b:box(V(6.8, 0.2, 1.6), V(0, 1.7, 2.2), C.woodLight, M.Wood)
	b:label(
		counter,
		Enum.NormalId.Back,
		"СКУПКА КАРТОФЕЛЯ",
		{ color = C.yellow, background = C.woodDark }
	)
	-- столбы и навес
	for _, x in ipairs({ -3.1, 3.1 }) do
		b:box(V(0.35, 5, 0.35), V(x, 2.5, 2.7), C.woodDark, M.Wood)
		b:box(V(0.35, 5.6, 0.35), V(x, 2.8, -2.5), C.woodDark, M.Wood)
	end
	for i = 0, 5 do
		local color = if i % 2 == 0 then C.red else C.white
		b:box(V(1.1, 0.15, 6.2), V(-2.75 + i * 1.1, 5.55, 0.1), color, M.Fabric, { rot = V(-6, 0, 0) })
	end
	-- ящики с картошкой
	for _, x in ipairs({ -2.2, 0, 2.2 }) do
		b:box(V(1.5, 0.8, 1.1), V(x, 0.4, -1.4), C.woodLight, M.WoodPlanks)
		for k = 1, 3 do
			b:potato(V(x - 0.45 + k * 0.3, 0.9, -1.4 + (k % 2) * 0.2), 0.7, nil, { collide = false })
		end
	end
	-- весы
	b:box(V(0.8, 0.25, 0.6), V(-2.2, 1.95, 2.2), C.metal, M.Metal, { collide = false })
	b:box(V(0.9, 0.05, 0.7), V(-2.2, 2.2, 2.2), C.metalDark, M.Metal, { collide = false })
	-- табличка цены
	local sign = b:box(V(2.4, 1, 0.15), V(1.6, 2.4, 2.9), C.white, M.SmoothPlastic, { collide = false })
	b:label(sign, Enum.NormalId.Back, "$1 EACH", { color = C.green })
	-- скупщик (ГДД 114)
	b:figure(
		V(0, 0, 0.6),
		{ shirt = Color3.fromRGB(70, 110, 160), pants = Color3.fromRGB(60, 60, 70), hat = C.woodDark, avatar = true },
		0
	)
	b:billboard(counter, "Village Buyer", 6, C.yellow)
	prompt(counter, "Sell", "Сдать картофель", "Скупщик", 0.2)
end

function Models.NpcMatvey(b: Builder)
	local fig = b:figure(V(0, 0, 0), {
		shirt = Color3.fromRGB(150, 60, 50),
		pants = Color3.fromRGB(70, 80, 120),
		hat = Color3.fromRGB(215, 185, 110),
		beard = C.white,
		avatar = true,
	}, 0, 0.95)
	local head = fig:FindFirstChild("Head") :: BasePart
	b:billboard(head, "Grandpa Matvey", 2.2, C.yellow)
	prompt(head, "Talk", "Поговорить", "Дед Матвей")
end

function Models.FenceWood(b: Builder)
	-- периметр агро-блока: z от -13 до +13 локально, x от -40 до 40
	local function rail(a: Vector3, c: Vector3)
		local len = (c - a).Magnitude
		local mid = (a + c) / 2
		local alongX = math.abs(c.X - a.X) > 0.1
		local size = if alongX then V(len, 0.3, 0.2) else V(0.2, 0.3, len)
		b:box(size, mid + V(0, 1.6, 0), C.woodLight, M.WoodPlanks)
		b:box(size, mid + V(0, 0.8, 0), C.woodLight, M.WoodPlanks)
	end
	local function posts(a: Vector3, c: Vector3)
		local n = math.floor((c - a).Magnitude / 4)
		for i = 0, n do
			local p = a:Lerp(c, i / n)
			b:box(V(0.4, 2.2, 0.4), p + V(0, 1.1, 0), C.woodDark, M.Wood)
		end
		rail(a, c)
	end
	posts(V(-39.8, 0, 12.8), V(-3.6, 0, 12.8))
	posts(V(3.6, 0, 12.8), V(39.8, 0, 12.8))
	posts(V(-39.8, 0, -13), V(-39.8, 0, 12.8))
	posts(V(39.8, 0, -13), V(39.8, 0, 12.8))
end

function Models.HarvestTower(b: Builder)
	local h = 11
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			b:pipe(V(sx * 2.6, 0, sz * 2.6), V(sx * 1.2, h, sz * 1.2), 0.35, C.red, M.Metal)
		end
	end
	for y = 2, h - 1, 3 do
		local k = 2.6 - (y / h) * 1.4
		b:box(V(k * 2, 0.2, 0.2), V(0, y, k), C.white, M.Metal, { collide = false })
		b:box(V(k * 2, 0.2, 0.2), V(0, y, -k), C.white, M.Metal, { collide = false })
		b:box(V(0.2, 0.2, k * 2), V(k, y, 0), C.white, M.Metal, { collide = false })
		b:box(V(0.2, 0.2, k * 2), V(-k, y, 0), C.white, M.Metal, { collide = false })
	end
	b:box(V(3.4, 0.4, 3.4), V(0, h, 0), C.metalDark, M.DiamondPlate)
	b:box(V(2, 1.6, 2), V(0, h + 1, 0), C.white, M.SmoothPlastic)
	local beacon = b:ball(0.8, V(0, h + 2.3, 0), C.yellow, M.Neon, { collide = false })
	b:light(beacon, C.yellow, 14, 2)
	b:tag(beacon, "Pulse", { Speed = 3 })
	-- радар-сканер урожая
	local dish = b:group("Dish", V(0, h + 1.9, 0))
	dish:cyl(0.6, 0.25, V(0, h + 2, 0), C.metal, M.Metal, { collide = false })
	dish:ellipsoid(
		V(2.6, 0.5, 1.4),
		V(0, h + 2.5, 0.4),
		C.white,
		M.SmoothPlastic,
		{ rot = V(-30, 0, 0), collide = false }
	)
	b:tag(dish:groupModel(), "Spin", { Axis = "Y", Speed = 60 })
	-- табличка контракта
	local board = b:box(V(4.4, 1.6, 0.2), V(0, 3, 2.9), C.blue, M.SmoothPlastic, { collide = false })
	b:label(board, Enum.NormalId.Back, "CONTRACT: AUTO-SELL", { color = C.white })
end

local function autoBedBase(b: Builder, frame: Color3, mat: Enum.Material)
	b:box(V(0.4, 1.1, 6), V(-1.8, 0.55, 0), frame, mat)
	b:box(V(0.4, 1.1, 6), V(1.8, 0.55, 0), frame, mat)
	b:box(V(3.2, 1.1, 0.4), V(0, 0.55, 2.8), frame, mat)
	b:box(V(3.2, 1.1, 0.4), V(0, 0.55, -2.8), frame, mat)
	soil(b, 3.2, 5.2, 0.85)
	bushes(b, 1.0, 5.2)
end

function Models.AutoBedT1(b: Builder)
	autoBedBase(b, C.metal, M.Metal)
	-- шнек авто-сбора
	local auger = b:group("Auger", V(-2.25, 0.7, 0))
	auger:cylZ(5.6, 0.5, V(-2.25, 0.7, 0), C.yellow, M.Metal, { collide = false })
	for z = -2.4, 2.4, 0.6 do
		auger:box(V(0.7, 0.1, 0.12), V(-2.25, 0.7, z), C.orange, M.Metal, { rot = V(0, 0, z * 60), collide = false })
	end
	b:tag(auger:groupModel(), "Spin", { Axis = "Z", Speed = 180 })
	b:box(V(1.2, 1.2, 0.9), V(-1.5, 0.6, 3.4), C.yellow, M.Metal)
end

function Models.AutoBedT2(b: Builder)
	autoBedBase(b, C.steel, M.DiamondPlate)
	-- вакуумный сборщик
	b:cyl(1.6, 1.2, V(0, 0.8, 3.45), C.blue, M.Metal)
	b:cyl(0.2, 1.3, V(0, 1.65, 3.45), C.black, M.Metal)
	b:pipe(V(0, 1.6, 3.2), V(0, 2.6, 1.5), 0.35, C.black, M.Fabric)
	b:pipe(V(0, 2.6, 1.5), V(0, 2.6, -2.5), 0.35, C.black, M.Fabric)
	local nozzle = b:box(V(2.8, 0.25, 0.5), V(0, 2.3, -1), C.blue, M.Metal, { collide = false })
	b:tag(nozzle, "Slide", { Axis = "Z", Amplitude = 1.8, Speed = 1.2 })
end

function Models.AutoBedT3(b: Builder)
	autoBedBase(b, C.black, M.Metal)
	-- портал лазерного среза ботвы
	for _, x in ipairs({ -1.9, 1.9 }) do
		b:box(V(0.25, 3, 0.25), V(x, 1.5, -2.9), C.metalDark, M.Metal)
		b:box(V(0.25, 3, 0.25), V(x, 1.5, 2.9), C.metalDark, M.Metal)
		b:box(V(0.2, 0.2, 6), V(x, 3, 0), C.metalDark, M.Metal, { collide = false })
	end
	local carriage = b:group("Laser", V(0, 3, 0))
	carriage:box(V(4, 0.35, 0.5), V(0, 3, 0), C.white, M.SmoothPlastic, { collide = false })
	local beam = carriage:box(V(3.4, 1.4, 0.05), V(0, 2.2, 0), C.red, M.Neon, { collide = false, transparency = 0.4 })
	b:light(beam, C.red, 6, 1)
	b:tag(carriage:groupModel(), "Slide", { Axis = "Z", Amplitude = 2.3, Speed = 0.8 })
end

function Models.Sprinkler(b: Builder)
	b:cyl(0.3, 1.4, V(0, 0.15, 0), C.metalDark, M.Metal)
	b:cyl(2.4, 0.3, V(0, 1.5, 0), C.metal, M.Metal)
	local head = b:group("Head", V(0, 2.8, 0))
	head:cyl(0.4, 0.5, V(0, 2.8, 0), C.yellow, M.Metal, { collide = false })
	head:box(V(2.4, 0.15, 0.15), V(0, 2.95, 0), C.metal, M.Metal, { collide = false })
	local nozzle = head:box(V(0.2, 0.2, 0.2), V(1.2, 2.95, 0), C.metal, M.Metal, { collide = false })
	local water = Instance.new("ParticleEmitter")
	water.Color = ColorSequence.new(Color3.fromRGB(150, 210, 255))
	water.Size = NumberSequence.new(0.25, 0.05)
	water.Transparency = NumberSequence.new(0.3, 1)
	water.Lifetime = NumberRange.new(0.6, 0.9)
	water.Rate = 40
	water.Speed = NumberRange.new(8, 11)
	water.SpreadAngle = Vector2.new(10, 10)
	water.EmissionDirection = Enum.NormalId.Right
	water.Acceleration = V(0, -25, 0)
	water.Parent = nozzle
	b:tag(head:groupModel(), "Spin", { Axis = "Y", Speed = 120 })
end

-- Столб с двумя светильниками над рядами грядок (±5 по Z)
local function lampPost(b: Builder, headColor: Color3, headMat: Enum.Material, lightColor: Color3, kind: string)
	b:box(V(1.2, 0.3, 1.2), V(0, 0.15, 0), C.metalDark, M.Metal)
	b:box(V(0.35, 6.4, 0.35), V(0, 3.2, 0), C.metalDark, M.Metal)
	b:box(V(0.25, 0.25, 10.5), V(0, 6.3, 0), C.metalDark, M.Metal, { collide = false })
	for _, z in ipairs({ -5, 5 }) do
		b:box(V(0.1, 0.8, 0.1), V(0, 5.9, z), C.black, M.Metal, { collide = false })
		local head
		if kind == "basic" then
			b:cyl(0.4, 1.2, V(0, 5.4, z), C.metalDark, M.Metal, { collide = false })
			head = b:ball(0.8, V(0, 5.05, z), headColor, headMat, { collide = false })
		elseif kind == "led" then
			head = b:box(V(3.2, 0.2, 4.6), V(0, 5.4, z), headColor, headMat, { collide = false })
			b:box(V(3.4, 0.25, 4.8), V(0, 5.6, z), C.black, M.Metal, { collide = false })
		else
			head = b:box(V(3.4, 0.25, 5), V(0, 5.4, z), headColor, headMat, { collide = false })
			local ring = b:group("Ring" .. z, V(0, 5.9, z))
			ring:cyl(0.1, 2.2, V(0, 6.1, z), C.cyan, M.Neon, { collide = false, transparency = 0.2 })
			b:tag(ring:groupModel(), "Spin", { Axis = "Y", Speed = 90 })
		end
		b:light(head, lightColor, 12, 2, true)
	end
end

function Models.LampBasic(b: Builder)
	lampPost(b, Color3.fromRGB(255, 220, 140), M.Neon, Color3.fromRGB(255, 210, 140), "basic")
end

function Models.LampLed(b: Builder)
	lampPost(b, Color3.fromRGB(255, 80, 200), M.Neon, Color3.fromRGB(255, 120, 220), "led")
end

function Models.LampQuantum(b: Builder)
	lampPost(b, Color3.fromRGB(80, 230, 255), M.Neon, Color3.fromRGB(120, 200, 255), "quantum")
end

function Models.NeonSign(b: Builder)
	for _, x in ipairs({ -4.3, 4.3 }) do
		b:box(V(0.7, 10, 0.7), V(x, 5, 0), C.black, M.Metal)
	end
	local board = b:box(V(9.6, 2.6, 0.4), V(0, 9, 0), C.black, M.SmoothPlastic, { collide = false })
	b:label(board, Enum.NormalId.Back, "POTATO TYCOON", { color = Color3.fromRGB(255, 220, 60) })
	b:label(board, Enum.NormalId.Front, "POTATO TYCOON", { color = Color3.fromRGB(255, 220, 60) })
	local trim = b:box(V(9.9, 0.15, 0.5), V(0, 10.35, 0), Color3.fromRGB(255, 90, 200), M.Neon, { collide = false })
	b:box(V(9.9, 0.15, 0.5), V(0, 7.65, 0), Color3.fromRGB(255, 90, 200), M.Neon, { collide = false })
	b:light(trim, Color3.fromRGB(255, 120, 200), 16, 2)
end

function Models.LedBoard(b: Builder)
	b:box(V(0.3, 3, 0.3), V(-2.2, 1.5, 0), C.metalDark, M.Metal)
	b:box(V(0.3, 3, 0.3), V(2.2, 1.5, 0), C.metalDark, M.Metal)
	local board = b:box(V(5, 2.4, 0.35), V(0, 3.9, 0), C.black, M.SmoothPlastic, { name = "Board" })
	local label = b:label(board, Enum.NormalId.Back, "OUTPUT: 0 kg", {
		color = Color3.fromRGB(255, 80, 60),
		font = Enum.Font.Arcade,
		name = "BoardGui",
	})
	label.Name = "BoardText"
	b:box(V(5.2, 0.15, 0.45), V(0, 5.15, 0), C.metal, M.Metal, { collide = false })
end

function Models.MoleTrap(b: Builder)
	b:cyl(1.6, 0.2, V(0, 0.8, 0), C.green, M.Metal)
	b:cyl(0.5, 0.9, V(0, 1.75, 0), C.green, M.SmoothPlastic)
	local ring = b:cyl(0.08, 1.4, V(0, 0.05, 0), C.cyan, M.Neon, { collide = false, transparency = 0.3 })
	b:tag(ring, "Pulse", { Speed = 2 })
	b:box(V(0.5, 0.05, 0.3), V(0, 1.9, 0.46), C.black, M.SmoothPlastic, { collide = false })
end

function Models.DripSystem(b: Builder)
	b:cyl(2.2, 2.2, V(0, 1.1, -0.2), C.blue, M.SmoothPlastic)
	b:cyl(0.2, 2.3, V(0, 2.25, -0.2), C.white, M.SmoothPlastic)
	b:box(V(0.8, 0.8, 0.6), V(0.8, 0.4, 1.1), C.black, M.Metal)
	b:pipe(V(0.8, 0.2, 1.4), V(0.8, 0.2, 3.2), 0.18, C.black, M.Rubber)
	b:pipe(V(-10, 0.15, 3.2), V(10, 0.15, 3.2), 0.18, C.black, M.Rubber)
	b:cyl(0.12, 0.5, V(0.8, 0.95, 1.1), C.red, M.Metal, { collide = false })
end

local function plants(b: Builder, y: number, w: number, d: number, color: Color3?)
	for x = -w / 2 + 0.5, w / 2 - 0.4, 0.9 do
		for z = -d / 2 + 0.5, d / 2 - 0.4, 1 do
			b:ellipsoid(V(0.7, 0.6, 0.7), V(x, y + 0.3, z), color or C.leaf, M.Grass, { collide = false })
		end
	end
end

local function tray(b: Builder, y: number, w: number, d: number)
	b:box(V(w, 0.3, d), V(0, y, 0), C.white, M.SmoothPlastic)
	b:box(
		V(w - 0.3, 0.05, d - 0.3),
		V(0, y + 0.16, 0),
		Color3.fromRGB(110, 180, 220),
		M.Glass,
		{ collide = false, transparency = 0.3 }
	)
	plants(b, y + 0.15, w - 0.6, d - 0.6)
end

function Models.HydroTray(b: Builder)
	for _, x in ipairs({ -1.6, 1.6 }) do
		for _, z in ipairs({ -2.6, 2.6 }) do
			b:box(V(0.2, 1.4, 0.2), V(x, 0.7, z), C.metal, M.Metal)
		end
	end
	tray(b, 1.5, 3.6, 5.6)
	b:pipe(V(1.8, 1.2, 2.8), V(1.8, 0.2, 3.3), 0.15, C.white, M.SmoothPlastic)
end

local function rack(b: Builder, tiers: number)
	for _, x in ipairs({ -2.2, 2.2 }) do
		for _, z in ipairs({ -2.7, 2.7 }) do
			b:box(V(0.25, tiers * 2 + 0.6, 0.25), V(x, (tiers * 2 + 0.6) / 2, z), C.metal, M.Metal)
		end
	end
	for t = 1, tiers do
		local y = t * 2 - 0.9
		tray(b, y, 4.2, 5.6)
		local lamp =
			b:box(V(3.6, 0.12, 4.8), V(0, y + 1.75, 0), Color3.fromRGB(230, 100, 255), M.Neon, { collide = false })
		if t == tiers then
			b:light(lamp, Color3.fromRGB(230, 120, 255), 8, 1)
		end
	end
end

function Models.HydroRack2(b: Builder)
	rack(b, 2)
end

function Models.HydroRack3(b: Builder)
	rack(b, 3)
end

function Models.HydroTower(b: Builder)
	b:cyl(1.2, 3.6, V(0, 0.6, 0), C.blue, M.SmoothPlastic)
	local tower = b:group("Tower", V(0, 5, 0))
	tower:cyl(8.5, 1.4, V(0, 5.4, 0), C.white, M.SmoothPlastic)
	for i = 0, 15 do
		local a = math.rad(i * 67)
		local y = 1.8 + i * 0.48
		tower:ellipsoid(
			V(0.9, 0.8, 0.9),
			V(math.cos(a) * 0.85, y, math.sin(a) * 0.85),
			C.leaf,
			M.Grass,
			{ collide = false }
		)
	end
	b:tag(tower:groupModel(), "Spin", { Axis = "Y", Speed = 12 })
	local top = b:ball(0.6, V(0, 9.9, 0), C.cyan, M.Neon, { collide = false })
	b:light(top, C.cyan, 8, 1)
end

function Models.Aeroponic(b: Builder)
	b:box(V(4.4, 0.5, 4.4), V(0, 0.25, 0), C.metalDark, M.DiamondPlate)
	b:ellipsoid(V(4, 4.2, 4), V(0, 2.5, 0), C.white, M.SmoothPlastic)
	local window = b:ellipsoid(
		V(3.2, 1.2, 4.1),
		V(0, 2.8, 0),
		Color3.fromRGB(120, 220, 255),
		M.Glass,
		{ transparency = 0.35, collide = false }
	)
	local strip = b:cyl(0.15, 4.1, V(0, 1.8, 0), C.cyan, M.Neon, { collide = false })
	b:light(strip, C.cyan, 8, 1)
	local mist = Instance.new("ParticleEmitter")
	mist.Color = ColorSequence.new(Color3.new(1, 1, 1))
	mist.Transparency = NumberSequence.new(0.6, 1)
	mist.Size = NumberSequence.new(0.6, 1.6)
	mist.Lifetime = NumberRange.new(1, 2)
	mist.Rate = 6
	mist.Speed = NumberRange.new(0.5, 1)
	mist.Parent = window
end

local function greenhouse(b: Builder, w: number, d: number, h: number, frame: Color3, plantColor: Color3?)
	local glass = Color3.fromRGB(200, 235, 245)
	b:box(V(w, 0.3, d), V(0, 0.15, 0), C.concrete, M.Concrete)
	b:box(V(w, h, 0.1), V(0, h / 2, -d / 2), glass, M.Glass, { transparency = 0.6 })
	b:box(V(w, h, 0.1), V(0, h / 2, d / 2), glass, M.Glass, { transparency = 0.6 })
	b:box(V(0.1, h, d), V(-w / 2, h / 2, 0), glass, M.Glass, { transparency = 0.6 })
	b:box(V(0.1, h, d), V(w / 2, h / 2, 0), glass, M.Glass, { transparency = 0.6 })
	local roofW = w / 2 / math.cos(math.rad(25))
	b:box(
		V(roofW, 0.1, d),
		V(-w / 4, h + w / 4 * math.tan(math.rad(25)), 0),
		glass,
		M.Glass,
		{ transparency = 0.55, rot = V(0, 0, 25), collide = false }
	)
	b:box(
		V(roofW, 0.1, d),
		V(w / 4, h + w / 4 * math.tan(math.rad(25)), 0),
		glass,
		M.Glass,
		{ transparency = 0.55, rot = V(0, 0, -25), collide = false }
	)
	for _, x in ipairs({ -w / 2, w / 2 }) do
		for _, z in ipairs({ -d / 2, d / 2 }) do
			b:box(V(0.2, h, 0.2), V(x, h / 2, z), frame, M.Metal)
		end
	end
	b:box(V(0.2, 0.2, d), V(0, h + w / 2 * math.tan(math.rad(25)), 0), frame, M.Metal, { collide = false })
	b:box(V(w - 1, 0.6, d - 1.2), V(0, 0.6, 0), C.soil, M.Ground)
	plants(b, 0.9, w - 1.4, d - 1.6, plantColor)
end

function Models.GreenhouseSmall(b: Builder)
	greenhouse(b, 5, 6, 3, C.woodDark)
end

function Models.GreenhousePro(b: Builder)
	b:box(V(14, 0.3, 6), V(0, 0.15, 0), C.concrete, M.Concrete)
	-- арочный тоннель из поликарбоната
	b:cylX(13.6, 6, V(0, 0, 0), Color3.fromRGB(220, 245, 230), M.Glass, { transparency = 0.55, collide = false })
	for x = -6.5, 6.5, 2.6 do
		b:cylX(0.2, 6.15, V(x, 0, 0), C.metal, M.Metal, { transparency = 0, collide = false })
	end
	b:box(V(12.8, 0.6, 4.4), V(0, 0.5, 0), C.soil, M.Ground)
	plants(b, 0.8, 12, 3.8, Color3.fromRGB(80, 170, 70))
	-- торцевые стенки как твёрдые преграды
	b:box(V(0.2, 2.6, 5.4), V(-6.9, 1.3, 0), C.white, M.SmoothPlastic, { transparency = 0.4 })
	b:box(V(0.2, 2.6, 5.4), V(6.9, 1.3, 0), C.white, M.SmoothPlastic, { transparency = 0.4 })
end

function Models.Fertilizer(b: Builder)
	b:box(V(2.6, 0.3, 2.6), V(0, 0.15, 0), C.metalDark, M.DiamondPlate)
	b:cyl(2.2, 1.8, V(-0.3, 1.4, -0.2), C.white, M.SmoothPlastic)
	b:cyl(0.3, 1.9, V(-0.3, 2.6, -0.2), C.blue, M.SmoothPlastic)
	b:box(V(0.9, 0.9, 0.7), V(0.8, 0.75, 0.7), C.blue, M.Metal)
	b:pipe(V(0.8, 1.0, 1.05), V(0.8, 0.3, 1.6), 0.15, C.black, M.Rubber)
	local led = b:box(V(0.2, 0.2, 0.05), V(0.8, 1.0, 1.06), C.green, M.Neon, { collide = false })
	b:tag(led, "Pulse", { Speed = 4 })
end

function Models.BiohumusTank(b: Builder)
	b:cyl(3, 2.6, V(0, 1.5, 0), Color3.fromRGB(95, 70, 45), M.Metal)
	b:cyl(0.25, 2.7, V(0, 3.1, 0), C.metalDark, M.Metal)
	b:cyl(0.1, 2.3, V(0, 3.25, 0), C.soilDark, M.Ground, { collide = false })
	for y = 0.4, 3, 0.5 do
		b:box(V(0.5, 0.08, 0.08), V(1.35, y, 0), C.metal, M.Metal, { collide = false })
	end
	b:box(V(0.08, 3.2, 0.08), V(1.35, 1.6, 0.25), C.metal, M.Metal, { collide = false })
	b:box(V(0.08, 3.2, 0.08), V(1.35, 1.6, -0.25), C.metal, M.Metal, { collide = false })
end

function Models.Fogger(b: Builder)
	b:box(V(1.4, 1, 1.4), V(0, 0.5, 0), C.white, M.SmoothPlastic)
	local nozzle = b:cyl(0.6, 0.5, V(0, 1.3, 0), C.metal, M.Metal)
	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(230, 240, 255)
	smoke.Opacity = 0.12
	smoke.RiseVelocity = 1
	smoke.Size = 2
	smoke.Parent = nozzle
	b:box(V(0.4, 0.2, 0.05), V(0, 0.7, 0.71), C.cyan, M.Neon, { collide = false })
end

function Models.SoilSensor(b: Builder)
	b:cyl(1.4, 0.15, V(0, 0.7, 0), C.metal, M.Metal)
	b:box(V(0.9, 0.7, 0.25), V(0, 1.6, 0), C.white, M.SmoothPlastic)
	local screen = b:box(V(0.7, 0.45, 0.05), V(0, 1.62, 0.14), C.green, M.Neon, { collide = false })
	b:label(screen, Enum.NormalId.Back, "pH 6.5", { color = C.black })
	b:box(V(0.8, 0.05, 0.5), V(0, 2.0, 0), C.blue, M.Glass, { rot = V(20, 0, 0), collide = false })
end

function Models.Ionizer(b: Builder)
	b:cyl(0.4, 2.4, V(0, 0.2, 0), C.metalDark, M.Metal)
	b:cyl(3.2, 0.5, V(0, 2, 0), Color3.fromRGB(190, 110, 60), M.Metal)
	local rings = b:group("Rings", V(0, 2, 0))
	for y = 1, 3, 0.7 do
		rings:cyl(0.12, 1.6, V(0, y, 0), C.cyan, M.Neon, { collide = false, transparency = 0.2 })
	end
	b:tag(rings:groupModel(), "Spin", { Axis = "Y", Speed = 45 })
	local orb = b:ball(0.8, V(0, 3.8, 0), C.cyan, M.Neon, { collide = false })
	b:light(orb, C.cyan, 10, 1.5)
	b:tag(orb, "Pulse", { Speed = 2 })
end

function Models.ForceDome(b: Builder, item)
	b:cyl(0.5, 2.6, V(0, 0.25, 0), C.metalDark, M.Metal)
	b:cyl(3.4, 0.8, V(0, 2, 0), C.black, M.Metal)
	local orb = b:ball(1.3, V(0, 4.2, 0), Color3.fromRGB(120, 200, 255), M.Neon, { collide = false })
	b:light(orb, Color3.fromRGB(120, 200, 255), 16, 2)
	b:tag(orb, "Pulse", { Speed = 1.5 })
	-- купол над всем агро-блоком (центр агро-блока — x=0, z=27)
	local center = V(-item.pos[1], 0, 27 - item.pos[2])
	local dome = b:ellipsoid(
		V(84, 26, 32),
		center,
		Color3.fromRGB(110, 190, 255),
		M.ForceField,
		{ collide = false, shadow = false, name = "Dome" }
	)
	dome.CanQuery = false
	dome:SetAttribute("KeepVisible", true) -- купол остаётся и у модели из Blender
end

function Models.Flagpole(b: Builder)
	b:cyl(0.4, 1.4, V(0, 0.2, 0), C.concrete, M.Concrete)
	b:cyl(12, 0.25, V(0, 6, 0), C.metal, M.Metal)
	b:ball(0.4, V(0, 12.1, 0), C.gold, M.Metal, { collide = false })
	local flag = b:group("Flag", V(0, 11, 0))
	local cloth = flag:box(V(0.08, 1.8, 2.8), V(0, 11, -1.5), C.yellow, M.Fabric, { collide = false })
	flag:potato(V(-0.08, 11, -1.5), 1.2, C.woodDark, { collide = false, rot = V(0, 90, 0) })
	b:label(cloth, Enum.NormalId.Right, "POTATO INC", { color = C.red, scale = 0.6 })
	b:tag(flag:groupModel(), "Sway", { Axis = "Y", Amplitude = 12, Speed = 1.5 })
end

function Models.Mascot(b: Builder)
	local body = b:group("Body", V(0, 0, 0))
	body:potato(V(0, 1.6, 0), 3.4, Color3.fromRGB(200, 155, 95), { rot = V(0, 0, 90) })
	body:ball(0.45, V(-0.4, 2.4, 0.95), C.white, M.SmoothPlastic, { collide = false })
	body:ball(0.45, V(0.4, 2.4, 0.95), C.white, M.SmoothPlastic, { collide = false })
	body:ball(0.22, V(-0.4, 2.4, 1.15), C.black, M.SmoothPlastic, { collide = false })
	body:ball(0.22, V(0.4, 2.4, 1.15), C.black, M.SmoothPlastic, { collide = false })
	body:box(V(0.7, 0.12, 0.1), V(0, 1.9, 1.05), C.red, M.SmoothPlastic, { collide = false })
	body:cyl(0.5, 1.5, V(0, 3.35, 0), C.red, M.Fabric, { collide = false })
	body:box(V(1.2, 0.12, 0.8), V(0, 3.15, 0.7), C.red, M.Fabric, { collide = false })
	b:tag(body:groupModel(), "Bob", { Amplitude = 0.25, Speed = 2 })
end

return Models
