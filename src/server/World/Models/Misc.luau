-- Кнопки покупки, вредители, персонал, лопата и объекты центральной площади

local Kit = require(script.Parent.Parent.ModelKit)

type Builder = Kit.Builder

local V = Vector3.new
local C = Kit.C
local M = Enum.Material

local Models = {}

local BUTTON_COLORS = {
	Buy = Color3.fromRGB(60, 210, 90), -- ГДД 189: зелёная «Купить»
	Locked = Color3.fromRGB(215, 60, 55), -- ГДД 191: красная «Закрыто»
	Vip = Color3.fromRGB(255, 200, 40), -- ГДД 190: жёлтая VIP за робуксы
}
Models.ButtonColors = BUTTON_COLORS

-- Напольная кнопка покупки
function Models.Button(b: Builder, title: string, price: string, kind: string)
	b:box(V(3.6, 0.2, 3.6), V(0, 0.1, 0), C.black, M.Metal, { collide = false })
	local pad = b:box(
		V(3, 0.3, 3),
		V(0, 0.3, 0),
		if kind == "Vip" then BUTTON_COLORS.Vip else BUTTON_COLORS.Locked,
		M.Neon,
		{ collide = false, name = "Pad" }
	)
	pad.CanTouch = true
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.Size = UDim2.fromOffset(220, 64)
	gui.StudsOffset = V(0, 2.6, 0)
	gui.MaxDistance = 48
	gui.LightInfluence = 0
	gui.Parent = pad
	local name = Instance.new("TextLabel")
	name.Name = "Title"
	name.Size = UDim2.fromScale(1, 0.55)
	name.BackgroundTransparency = 1
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.2
	name.Font = Enum.Font.GothamBold
	name.TextScaled = true
	name.Text = title
	name.Parent = gui
	local cost = Instance.new("TextLabel")
	cost.Name = "Price"
	cost.Position = UDim2.fromScale(0, 0.55)
	cost.Size = UDim2.fromScale(1, 0.45)
	cost.BackgroundTransparency = 1
	cost.TextColor3 = if kind == "Vip" then BUTTON_COLORS.Vip else BUTTON_COLORS.Buy
	cost.TextStrokeTransparency = 0.2
	cost.Font = Enum.Font.GothamBlack
	cost.TextScaled = true
	cost.Text = price
	cost.Parent = gui
	return pad
end

-- Колорадский жук (ГДД 122–124). boss = Гигантский Жук-Мутант
function Models.Bug(b: Builder, boss: boolean)
	local s = if boss then 3 else 1
	local shell = Color3.fromRGB(240, 205, 110)
	b:ellipsoid(V(1.5, 0.9, 1.9) * s, V(0, 0.55 * s, 0), shell, M.SmoothPlastic, { collide = false })
	for i = -2, 2 do
		b:box(
			V(0.12, 0.08, 1.5) * s,
			V(i * 0.26 * s, 0.98 * s, -0.05 * s),
			C.black,
			M.SmoothPlastic,
			{ collide = false, rot = V(-8, 0, 0) }
		)
	end
	b:ellipsoid(
		V(0.9, 0.55, 0.6) * s,
		V(0, 0.5 * s, 1.05 * s),
		Color3.fromRGB(230, 130, 40),
		M.SmoothPlastic,
		{ collide = false }
	)
	local eyeColor = if boss then Color3.fromRGB(120, 255, 60) else C.black
	local eyeMat = if boss then M.Neon else M.SmoothPlastic
	b:ball(0.2 * s, V(-0.25 * s, 0.6 * s, 1.32 * s), eyeColor, eyeMat, { collide = false })
	b:ball(0.2 * s, V(0.25 * s, 0.6 * s, 1.32 * s), eyeColor, eyeMat, { collide = false })
	for _, side in ipairs({ -1, 1 }) do
		for k = -1, 1 do
			b:box(
				V(0.7, 0.1, 0.1) * s,
				V(side * 0.85 * s, 0.25 * s, k * 0.5 * s),
				C.black,
				M.SmoothPlastic,
				{ collide = false, rot = V(0, k * 20 * side, side * -25) }
			)
		end
	end
	local hitbox = b:box(
		V(2.6, 1.6, 2.8) * s,
		V(0, 0.7 * s, 0.1 * s),
		C.black,
		M.SmoothPlastic,
		{ collide = false, transparency = 1, name = "Hitbox", shadow = false }
	)
	b.model.PrimaryPart = hitbox
	if boss then
		local sparks = Instance.new("Sparkles")
		sparks.SparkleColor = Color3.fromRGB(120, 255, 60)
		sparks.Parent = hitbox
		b:billboard(hitbox, "🪲 MUTANT BEETLE", 3.5, Color3.fromRGB(150, 255, 90), 120)
	end
	return hitbox
end

-- Дроны (ГДД 106–109)
function Models.Drone(b: Builder, color: Color3, rotors: number)
	b:box(V(1.4, 0.5, 1.4), V(0, 0, 0), color, M.SmoothPlastic, { collide = false })
	b:ball(0.5, V(0, -0.1, 0.7), C.black, M.Glass, { collide = false })
	local led = b:box(V(0.3, 0.1, 0.1), V(0, 0.1, 0.72), C.cyan, M.Neon, { collide = false })
	b:tag(led, "Pulse", { Speed = 3 })
	for i = 0, rotors - 1 do
		local a = math.rad(i * 360 / rotors + 45)
		local tip = V(math.cos(a) * 1.4, 0.15, math.sin(a) * 1.4)
		b:pipe(V(0, 0.1, 0), tip, 0.15, C.black)
		local rotor = b:group("Rotor" .. i, tip + V(0, 0.15, 0))
		rotor:box(V(1.4, 0.05, 0.2), tip + V(0, 0.15, 0), C.metalDark, M.SmoothPlastic, { collide = false })
		b:tag(rotor:groupModel(), "Spin", { Axis = "Y", Speed = 900 })
	end
	-- клешня
	b:box(V(0.1, 0.6, 0.1), V(0, -0.5, 0), C.metal, M.Metal, { collide = false })
	b:box(V(0.6, 0.1, 0.1), V(0, -0.8, 0), C.metal, M.Metal, { collide = false })
end

-- Роботы (ГДД 111–113, 125, 128, 129)
function Models.Robot(b: Builder, color: Color3)
	b:box(V(1.6, 1.2, 1.4), V(0, 0.9, 0), color, M.SmoothPlastic, { collide = false })
	for _, x in ipairs({ -0.75, 0.75 }) do
		b:cylX(0.3, 0.7, V(x, 0.35, 0.4), C.black, M.Rubber, { collide = false })
		b:cylX(0.3, 0.7, V(x, 0.35, -0.4), C.black, M.Rubber, { collide = false })
	end
	b:box(V(1, 0.7, 0.9), V(0, 1.85, 0), C.white, M.SmoothPlastic, { collide = false })
	local eye = b:box(V(0.6, 0.18, 0.05), V(0, 1.9, 0.46), C.cyan, M.Neon, { collide = false })
	b:tag(eye, "Pulse", { Speed = 2 })
	b:cyl(0.5, 0.06, V(0.3, 2.45, 0), C.metal, M.Metal, { collide = false })
	b:ball(0.15, V(0.3, 2.72, 0), C.red, M.Neon, { collide = false })
end

function Models.StaffNpc(b: Builder, color: Color3, title: string)
	local fig =
		b:figure(V(0, 0, 0), { shirt = color, pants = Color3.fromRGB(50, 55, 65), hat = nil, avatar = true }, 0, 0.85)
	local head = fig:FindFirstChild("Head") :: BasePart
	b:billboard(head, title, 1.8, Color3.fromRGB(255, 240, 180), 30)
end

-- Лопата (инструмент этапа 1)
function Models.Shovel(golden: boolean): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Shovel"
	tool.ToolTip = "Click a ripe bed"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("Shovel", true)
	tool.Grip = CFrame.fromMatrix(V(0, 0, -1.3), V(0, 1, 0), V(0, 0, -1))

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = V(0.3, 0.3, 4)
	handle.Color = if golden then C.gold else C.wood
	handle.Material = if golden then M.Foil else M.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local function attach(size: Vector3, offset: CFrame, color: Color3, material: Enum.Material)
		local p = Instance.new("Part")
		p.Size = size
		p.Color = color
		p.Material = material
		p.CanCollide = false
		p.Massless = true
		p.CFrame = handle.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = p
		weld.Parent = p
		p.Parent = tool
	end
	attach(
		V(1.2, 0.12, 1.3),
		CFrame.new(0, 0, 2.55),
		if golden then C.gold else C.metal,
		if golden then M.Foil else M.Metal
	)
	attach(V(1, 0.25, 0.25), CFrame.new(0, 0, -2.05), if golden then C.gold else C.woodDark, M.Wood)
	return tool
end

------------------------------------------------------------------
-- Центральная площадь
------------------------------------------------------------------

-- Статуя «Основатель Картофельной Империи» (ГДД 150)
function Models.FounderStatue(b: Builder)
	b:cyl(1.2, 9, V(0, 0.6, 0), C.stone, M.Marble)
	b:cyl(1.6, 6.5, V(0, 2, 0), C.stoneDark, M.Marble)
	local fig = b:figure(V(0, 2.8, 0), { shirt = C.stone, pants = C.stone, skin = C.stone, hat = C.stone }, 0, 1.8)
	fig.Name = "Statue" -- у модели из Blender статуя своя, эту фигуру прячем
	for _, d in ipairs(fig:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Material = M.Marble
			d.Color = Color3.fromRGB(220, 218, 210)
		end
	end
	b:potato(V(3, 8.3, 0.8), 2, C.gold, { collide = false }).Material = M.Foil
	local plaque = b:box(V(4.2, 0.9, 0.1), V(0, 2, 3.26), C.gold, M.Foil, { collide = false })
	b:label(plaque, Enum.NormalId.Back, "FOUNDER OF THE POTATO EMPIRE", { color = C.black })
end

-- Зал Славы игроков сервера (ГДД 151)
function Models.HallOfFame(b: Builder)
	b:box(V(10, 0.6, 2), V(0, 0.3, 0), C.stone, M.Marble)
	b:box(V(0.6, 8, 0.6), V(-4.6, 4, 0), C.gold, M.Foil)
	b:box(V(0.6, 8, 0.6), V(4.6, 4, 0), C.gold, M.Foil)
	local board = b:box(V(8.6, 6.4, 0.4), V(0, 4.4, 0), C.black, M.SmoothPlastic, { name = "Board" })
	local gui = Instance.new("SurfaceGui")
	gui.Name = "FameGui"
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = board
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.18)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = C.gold
	title.TextScaled = true
	title.Text = "🏆 HALL OF FAME"
	title.Parent = gui
	local list = Instance.new("TextLabel")
	list.Name = "List"
	list.Position = UDim2.fromScale(0.05, 0.2)
	list.Size = UDim2.fromScale(0.9, 0.78)
	list.BackgroundTransparency = 1
	list.Font = Enum.Font.GothamBold
	list.TextColor3 = Color3.new(1, 1, 1)
	list.TextScaled = true
	list.TextXAlignment = Enum.TextXAlignment.Left
	list.TextYAlignment = Enum.TextYAlignment.Top
	list.Text = "No records yet"
	list.Parent = gui
	local back = gui:Clone()
	back.Face = Enum.NormalId.Front
	back.Parent = board
end

-- Ворота телепортации Rebirth и пьедестал с Золотым Клубнем (ГДД 148–149)
function Models.RebirthGate(b: Builder)
	b:box(V(9, 0.5, 3), V(0, 0.25, 0), C.purple, M.Marble)
	for _, x in ipairs({ -3.8, 3.8 }) do
		b:box(V(1.2, 9, 1.2), V(x, 4.5, 0), C.black, M.Marble)
	end
	b:box(V(9, 1.2, 1.4), V(0, 9.4, 0), C.black, M.Marble)
	local portal = b:box(V(6.4, 8.4, 0.2), V(0, 4.7, 0), C.purple, M.ForceField, { collide = false })
	portal.CanQuery = false
	portal:SetAttribute("KeepVisible", true) -- силовое поле портала остаётся и у модели из Blender
	local swirl = b:group("Swirl", V(0, 4.7, 0))
	for i = 0, 5 do
		swirl:box(
			V(5.6, 0.25, 0.1),
			V(0, 4.7, 0),
			C.cyan,
			M.Neon,
			{ rot = V(0, 0, i * 30), collide = false, transparency = 0.4 }
		)
	end
	b:tag(swirl:groupModel(), "Spin", { Axis = "Z", Speed = 60 })
	b:light(portal, C.purple, 18, 2)
	local plaque = b:box(V(5, 0.8, 0.1), V(0, 9.4, 0.75), C.black, M.SmoothPlastic, { collide = false })
	b:label(plaque, Enum.NormalId.Back, "REBIRTH", { color = C.purple })
end

function Models.GoldenPedestal(b: Builder)
	b:cyl(2.4, 2.2, V(0, 1.2, 0), C.white, M.Marble)
	b:cyl(0.3, 2.6, V(0, 2.55, 0), C.gold, M.Foil)
	local tuber = b:potato(V(0, 3.6, 0), 1.8, C.gold, { collide = false })
	tuber.Material = M.Foil
	b:tag(tuber, "Bob", { Amplitude = 0.3, Speed = 1.5 })
	local sparks = Instance.new("Sparkles")
	sparks.SparkleColor = C.gold
	sparks.Parent = tuber
end

-- Капсула криосна магната (ГДД 153)
function Models.CryoCapsule(b: Builder)
	b:box(V(2.6, 0.6, 5), V(0, 0.3, 0), C.metalDark, M.Metal)
	b:ellipsoid(V(2.4, 2.2, 4.6), V(0, 1.4, 0), Color3.fromRGB(190, 230, 255), M.Glass, { transparency = 0.45 })
	b:figure(V(0, 0.9, -1.2), { shirt = C.white, pants = C.white }, 0, 0.7)
	local led = b:box(V(1.6, 0.1, 0.1), V(0, 0.55, 2.52), C.cyan, M.Neon, { collide = false })
	b:tag(led, "Pulse", { Speed = 0.8 })
end

-- Фонарь уличного освещения (ГДД 181)
function Models.StreetLight(b: Builder)
	b:cyl(0.4, 1, V(0, 0.2, 0), C.metalDark, M.Metal)
	b:cyl(9, 0.35, V(0, 4.6, 0), C.metalDark, M.Metal)
	b:box(V(0.3, 0.3, 2.2), V(0, 9, 0.9), C.metalDark, M.Metal, { collide = false })
	local lamp = b:box(V(0.9, 0.3, 1.2), V(0, 8.8, 1.8), Color3.fromRGB(255, 240, 200), M.Neon, { collide = false })
	b:light(lamp, Color3.fromRGB(255, 230, 190), 24, 1.6, true)
end

-- Мусорный контейнер переработки (ГДД 180)
function Models.TrashBin(b: Builder)
	b:box(V(2.2, 1.6, 1.4), V(0, 0.8, 0), C.green, M.Metal)
	b:box(V(2.3, 0.15, 1.5), V(0, 1.65, 0), Color3.fromRGB(40, 110, 50), M.Metal, { rot = V(-10, 0, 0) })
	local s = b:box(V(0.8, 0.8, 0.05), V(0, 0.9, 0.71), C.white, M.SmoothPlastic, { collide = false })
	b:label(s, Enum.NormalId.Back, "♻", { color = C.green })
end

function Models.Bench(b: Builder)
	b:box(V(4, 0.25, 1.2), V(0, 1.1, 0), C.wood, M.WoodPlanks)
	b:box(V(4, 1, 0.2), V(0, 1.8, -0.55), C.wood, M.WoodPlanks)
	for _, x in ipairs({ -1.7, 1.7 }) do
		b:box(V(0.2, 1, 1), V(x, 0.5, 0), C.metalDark, M.Metal)
	end
end

return Models
