-- Модели сектора 3: энергетика, дрон-сервис, офис менеджера

local Kit = require(script.Parent.Parent.ModelKit)

type Builder = Kit.Builder

local V = Vector3.new
local C = Kit.C
local M = Enum.Material

local Models = {}

local function smoke(part: BasePart, color: Color3?, opacity: number?)
	local s = Instance.new("Smoke")
	s.Color = color or Color3.fromRGB(90, 90, 90)
	s.Opacity = opacity or 0.15
	s.RiseVelocity = 4
	s.Size = 1.5
	s.Parent = part
end

local function openMenu(part: BasePart, menu: string, text: string, object: string)
	local p = Instance.new("ProximityPrompt")
	p.Name = "Prompt"
	p.ActionText = text
	p.ObjectText = object
	p.HoldDuration = 0
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p:SetAttribute("Action", "OpenMenu")
	p:SetAttribute("Menu", menu)
	p.Parent = part
end
Models.openMenu = openMenu

local function grille(b: Builder, w: number, h: number, pos: Vector3, color: Color3)
	for y = -h / 2 + 0.2, h / 2 - 0.2, 0.35 do
		b:box(V(w, 0.12, 0.08), pos + V(0, y, 0), color, M.Metal, { collide = false })
	end
end

function Models.GenPetrol(b: Builder)
	-- трубчатая рама
	for _, x in ipairs({ -1.1, 1.1 }) do
		b:pipe(V(x, 0.1, -1), V(x, 0.1, 1), 0.2, C.black)
		b:pipe(V(x, 0.1, -1), V(x, 1.9, -1), 0.2, C.black)
		b:pipe(V(x, 0.1, 1), V(x, 1.9, 1), 0.2, C.black)
		b:pipe(V(x, 1.9, -1), V(x, 1.9, 1), 0.2, C.black)
	end
	b:box(V(1.8, 1.2, 1.7), V(0, 0.9, 0), C.red, M.SmoothPlastic)
	b:box(V(1.5, 0.5, 1.2), V(0, 1.75, 0), C.red, M.SmoothPlastic)
	b:box(V(0.6, 0.6, 0.05), V(-0.3, 0.95, 0.86), C.black, M.SmoothPlastic, { collide = false })
	local exhaust = b:cylX(0.6, 0.25, V(1.25, 0.7, -0.6), C.metal, M.Metal, { collide = false })
	smoke(exhaust, nil, 0.08)
	local led = b:box(V(0.15, 0.15, 0.05), V(0.5, 1.1, 0.86), C.green, M.Neon, { collide = false })
	b:tag(led, "Pulse", { Speed = 2 })
end

function Models.GenDiesel25(b: Builder)
	b:box(V(3.8, 0.3, 3.6), V(0, 0.15, 0), C.metalDark, M.Metal)
	b:box(V(3.4, 2.4, 3.2), V(0, 1.5, 0), Color3.fromRGB(60, 120, 70), M.Metal)
	grille(b, 2.8, 1.6, V(0, 1.5, 1.62), Color3.fromRGB(40, 80, 50))
	local stack = b:cyl(1.6, 0.4, V(1.1, 3.4, -1), C.metal, M.Metal)
	smoke(stack)
	local label = b:box(V(1.6, 0.5, 0.05), V(-0.8, 2.4, 1.63), C.white, M.SmoothPlastic, { collide = false })
	b:label(label, Enum.NormalId.Back, "25 kW", { color = C.black })
end

function Models.GenDiesel100(b: Builder)
	b:box(V(6, 0.4, 4.8), V(0, 0.2, 0), C.metalDark, M.DiamondPlate)
	b:box(V(5.6, 3, 4.2), V(0, 1.9, 0), C.yellow, M.Metal)
	grille(b, 1.4, 2.4, V(-2.81, 1.9, 0) + V(0, 0, 0), C.black)
	b:box(V(0.1, 2.4, 3.6), V(2.81, 1.9, 0), C.black, M.Metal, { collide = false })
	for _, x in ipairs({ -1.2, 1.2 }) do
		local stack = b:cyl(2, 0.5, V(x, 4.4, -1.2), C.metal, M.Metal)
		smoke(stack, nil, 0.2)
	end
	local label = b:box(V(2.4, 0.7, 0.05), V(0, 2.6, 2.11), C.black, M.SmoothPlastic, { collide = false })
	b:label(label, Enum.NormalId.Back, "100 kW", { color = C.yellow })
end

function Models.Biogas(b: Builder)
	b:cyl(3.4, 5.2, V(0, 1.7, 0), Color3.fromRGB(150, 150, 140), M.Concrete)
	b:ellipsoid(V(5.2, 3.2, 5.2), V(0, 3.4, 0), Color3.fromRGB(60, 140, 70), M.Fabric)
	b:pipe(V(2.4, 1, 0), V(3, 1, 0), 0.4, C.yellow)
	b:pipe(V(3, 1, 0), V(3, 1, 2.8), 0.4, C.yellow)
	local flare = b:cyl(4.5, 0.35, V(-2.6, 2.25, 2.6), C.metal, M.Metal)
	local tip = b:cyl(0.3, 0.5, V(-2.6, 4.6, 2.6), C.black, M.Metal, { collide = false })
	local fire = Instance.new("Fire")
	fire.Size = 2
	fire.Heat = 6
	fire.Color = Color3.fromRGB(255, 140, 30)
	fire.SecondaryColor = Color3.fromRGB(255, 220, 80)
	fire.Parent = tip
	local _ = flare
	local label = b:box(V(2.6, 0.7, 0.05), V(0, 1.6, 2.62), C.white, M.SmoothPlastic, { collide = false })
	b:label(label, Enum.NormalId.Back, "BIOGAS", { color = Color3.fromRGB(40, 120, 50) })
end

function Models.BiogasTurbine(b: Builder)
	b:box(V(7, 0.4, 6), V(0, 0.2, 0), C.metalDark, M.DiamondPlate)
	b:cylX(4, 2.6, V(-1, 2, 0), C.white, M.Metal)
	b:cylX(0.4, 2.9, V(1.1, 2, 0), C.blue, M.Metal)
	b:box(V(2.2, 2.6, 2.6), V(2.4, 1.7, 0), C.blue, M.Metal)
	b:cylX(1.2, 1.4, V(-3.4, 2, 0), C.metalDark, M.Metal)
	local stack = b:cyl(3.4, 0.7, V(-1.5, 4.6, -1.8), C.metal, M.Metal)
	smoke(stack, Color3.fromRGB(200, 200, 200), 0.1)
	local label = b:box(V(2, 0.6, 0.05), V(2.4, 2.4, 1.31), C.white, M.SmoothPlastic, { collide = false })
	b:label(label, Enum.NormalId.Back, "250 kW", { color = C.blue })
end

local function panel(b: Builder, w: number, d: number, pos: Vector3, tilt: number)
	local p =
		b:box(V(w, 0.12, d), pos, Color3.fromRGB(25, 45, 110), M.Glass, { rot = V(tilt, 0, 0), reflectance = 0.2 })
	b:box(V(w + 0.15, 0.08, d + 0.15), pos - V(0, 0.07, 0), C.metal, M.Metal, { rot = V(tilt, 0, 0), collide = false })
	for i = 1, 2 do
		b:box(
			V(0.04, 0.13, d),
			pos + V(-w / 2 + i * w / 3, 0.01, 0),
			C.metal,
			M.Metal,
			{ rot = V(tilt, 0, 0), collide = false }
		)
	end
	return p
end

function Models.SolarSmall(b: Builder)
	-- скатная «крыша» с панелями
	b:box(V(3.8, 1, 3.8), V(0, 0.5, 0), C.woodDark, M.WoodPlanks)
	b:wedge(V(3.8, 1.6, 3.8), V(0, 1.8, 0), Color3.fromRGB(150, 70, 50), M.Slate)
	panel(b, 3.4, 1.7, V(0, 2.05, 0.8), 22)
	panel(b, 3.4, 1.7, V(0, 1.4, -0.75), 22)
end

function Models.SolarMono(b: Builder)
	b:cyl(0.4, 1.4, V(0, 0.2, 0), C.concrete, M.Concrete)
	b:cyl(2.2, 0.35, V(0, 1.3, 0), C.metal, M.Metal)
	local array = b:group("Array", V(0, 2.5, 0))
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -0.85, 0.85 }) do
			array:box(
				V(1.9, 0.1, 1.6),
				V(x, 2.5 + z * 0.4, z),
				Color3.fromRGB(20, 30, 80),
				M.Glass,
				{ rot = V(25, 0, 0), reflectance = 0.3 }
			)
		end
	end
	array:box(V(4.1, 0.08, 3.6), V(0, 2.42, 0), C.metal, M.Metal, { rot = V(25, 0, 0), collide = false })
	b:tag(array:groupModel(), "Sway", { Axis = "Y", Amplitude = 20, Speed = 0.2 })
end

local function rotor(b: Builder, hub: Vector3, length: number, width: number, color: Color3, speed: number)
	local g = b:group("Rotor", hub)
	g:cylZ(0.6, 0.7, hub + V(0, 0, 0.2), C.white, M.SmoothPlastic, { collide = false })
	for i = 0, 2 do
		local a = i * 120
		local dir = V(math.cos(math.rad(a + 90)), math.sin(math.rad(a + 90)), 0)
		g:box(
			V(width, length, 0.15),
			hub + dir * (length / 2 + 0.3) + V(0, 0, 0.35),
			color,
			M.SmoothPlastic,
			{ rot = V(0, 0, a), collide = false }
		)
	end
	b:tag(g:groupModel(), "Spin", { Axis = "Z", Speed = speed })
end

function Models.WindSmall(b: Builder)
	b:box(V(2, 0.3, 2), V(0, 0.15, 0), C.concrete, M.Concrete)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			b:pipe(V(sx * 0.9, 0.3, sz * 0.9), V(sx * 0.2, 9, sz * 0.2), 0.18, C.metal, M.Metal)
		end
	end
	b:box(V(0.7, 0.6, 1.4), V(0, 9.3, 0), C.white, M.SmoothPlastic)
	b:box(V(0.1, 1, 1.4), V(0, 9.5, -1.3), C.red, M.SmoothPlastic, { collide = false })
	rotor(b, V(0, 9.3, 0.8), 3.2, 0.5, C.white, 160)
end

function Models.Wind50(b: Builder)
	b:cyl(0.5, 3, V(0, 0.25, 0), C.concrete, M.Concrete)
	b:cyl(17, 0.9, V(0, 8.9, 0), C.white, M.SmoothPlastic)
	b:box(V(1.4, 1.3, 3), V(0, 17.9, 0), C.white, M.SmoothPlastic)
	rotor(b, V(0, 17.9, 1.8), 7.5, 0.9, C.white, 70)
	local blink = b:ball(0.35, V(0, 18.7, -0.8), C.red, M.Neon, { collide = false })
	b:tag(blink, "Pulse", { Speed = 1 })
end

function Models.Geothermal(b: Builder)
	b:box(V(5.6, 0.3, 5.6), V(0, 0.15, 0), C.concrete, M.Concrete)
	b:box(V(3.4, 3.2, 3), V(-0.8, 1.9, -0.8), C.white, M.Metal)
	b:box(V(3.6, 0.3, 3.2), V(-0.8, 3.65, -0.8), C.red, M.Metal)
	-- скважины и трубы горячего пара
	for i, x in ipairs({ 1.4, 2.2 }) do
		b:cyl(0.6, 0.9, V(x, 0.3, 1.8), C.metalDark, M.Metal)
		b:pipe(V(x, 0.5, 1.8), V(x, 2.6, 1.8), 0.4, if i == 1 then C.red else C.blue)
		b:pipe(V(x, 2.6, 1.8), V(0.9, 2.6, 0), 0.4, if i == 1 then C.red else C.blue)
	end
	local vent = b:cyl(1.2, 0.8, V(-1.8, 4.3, -1.6), C.metal, M.Metal)
	smoke(vent, Color3.fromRGB(240, 240, 240), 0.2)
	local label = b:box(V(2.6, 0.6, 0.05), V(-0.8, 2.6, 0.71), C.white, M.SmoothPlastic, { collide = false })
	b:label(label, Enum.NormalId.Back, "GEOTHERMAL 300 kW", { color = C.red })
end

function Models.Substation(b: Builder)
	b:box(V(6, 0.3, 5), V(0, 0.15, 0), C.concrete, M.Concrete)
	for _, x in ipairs({ -1.5, 1.5 }) do
		b:box(V(2, 2.4, 2), V(x, 1.5, -0.5), C.metalDark, M.Metal, { name = "Transformer" })
		for k = -2, 2 do
			b:box(V(0.1, 2, 2.2), V(x + k * 0.22, 1.4, -0.5), C.metal, M.Metal, { collide = false })
		end
		for k = -1, 1 do
			local ix = x + k * 0.6
			for y = 0, 3 do
				b:cyl(0.18, 0.4 - y * 0.03, V(ix, 2.85 + y * 0.22, -0.5), C.white, M.SmoothPlastic, { collide = false })
			end
		end
	end
	b:pipe(V(-2.1, 3.7, -0.5), V(2.1, 3.7, -0.5), 0.08, C.black)
	-- ограждение
	for _, x in ipairs({ -2.9, 2.9 }) do
		b:box(V(0.1, 2, 4.8), V(x, 1, 0), C.metal, M.DiamondPlate, { transparency = 0.5, collide = false })
	end
	local sign = b:box(V(1.4, 1, 0.05), V(0, 1.3, 2.4), C.yellow, M.SmoothPlastic, { collide = false })
	b:label(sign, Enum.NormalId.Back, "⚡ DANGER", { color = C.black })
	b.model:SetAttribute("Sparks", true)
end

function Models.Battery(b: Builder)
	b:box(V(4, 0.3, 4), V(0, 0.15, 0), C.concrete, M.Concrete)
	for _, x in ipairs({ -1, 1 }) do
		b:box(V(1.6, 2.6, 3.4), V(x, 1.6, 0), C.white, M.SmoothPlastic)
		for z = -1.2, 1.2, 0.6 do
			local led = b:box(V(0.05, 0.15, 0.3), V(x + 0.82 * x, 2.4, z), C.green, M.Neon, { collide = false })
			b:tag(led, "Pulse", { Speed = 1 + z })
		end
	end
	local sign = b:box(V(1.8, 0.5, 0.05), V(0, 3.1, 1.71), C.white, M.SmoothPlastic, { collide = false })
	b:label(sign, Enum.NormalId.Back, "50 kWh", { color = C.green })
end

function Models.Megapack(b: Builder)
	b:box(V(6, 0.3, 3.8), V(0, 0.15, 0), C.concrete, M.Concrete)
	local body = b:box(V(5.8, 2.8, 3.2), V(0, 1.7, 0), Color3.fromRGB(215, 218, 222), M.Metal)
	for x = -2.2, 2.2, 1.1 do
		b:box(V(0.05, 2.4, 3.3), V(x, 1.7, 0), C.metal, M.Metal, { collide = false })
	end
	b:label(body, Enum.NormalId.Back, "MEGAPACK", { color = C.red, background = Color3.fromRGB(215, 218, 222) })
	local led = b:box(V(5, 0.12, 0.05), V(0, 3.0, 1.62), C.cyan, M.Neon, { collide = false })
	b:tag(led, "Pulse", { Speed = 0.7 })
end

function Models.PotatoReactor(b: Builder)
	b:cyl(0.6, 4.4, V(0, 0.3, 0), C.metalDark, M.Metal)
	b:cyl(3.6, 3.6, V(0, 2.4, 0), Color3.fromRGB(150, 255, 150), M.Glass, { transparency = 0.6 })
	b:cyl(2.8, 3.4, V(0, 2.0, 0), Color3.fromRGB(110, 255, 90), M.Neon, { transparency = 0.6, collide = false })
	local tuber = b:potato(V(0, 2.3, 0), 3.2, Color3.fromRGB(190, 140, 70), { collide = false, rot = V(0, 0, 20) })
	b:tag(tuber, "Bob", { Amplitude = 0.3, Speed = 1.2 })
	b:cyl(0.5, 4.2, V(0, 4.45, 0), C.metalDark, M.Metal)
	for _, x in ipairs({ -1, 1 }) do
		b:cyl(2.2, 0.25, V(x, 3.5, 0), Color3.fromRGB(200, 120, 60), M.Metal, { collide = false })
	end
	local sparks = Instance.new("Sparkles")
	sparks.SparkleColor = Color3.fromRGB(150, 255, 120)
	sparks.Parent = tuber
	b:light(tuber, Color3.fromRGB(140, 255, 120), 12, 2)
end

function Models.Fusion(b: Builder)
	b:box(V(6, 0.4, 6), V(0, 0.2, 0), C.metalDark, M.DiamondPlate)
	b:cyl(1.6, 2, V(0, 1.2, 0), C.metal, M.Metal)
	local ring = b:group("Torus", V(0, 3.2, 0))
	for i = 0, 15 do
		local a = math.rad(i * 22.5)
		ring:ball(1.3, V(math.cos(a) * 2.2, 3.2, math.sin(a) * 2.2), C.metal, M.Metal, { collide = false })
	end
	for i = 0, 7 do
		local a = math.rad(i * 45 + 11)
		ring:box(V(0.3, 1.5, 0.3), V(math.cos(a) * 2.2, 3.2, math.sin(a) * 2.2), C.orange, M.Neon, { collide = false })
	end
	b:tag(ring:groupModel(), "Spin", { Axis = "Y", Speed = 40 })
	local plasma = b:ball(1.6, V(0, 3.2, 0), Color3.fromRGB(255, 90, 220), M.Neon, { collide = false })
	b:light(plasma, Color3.fromRGB(255, 120, 230), 18, 3)
	b:tag(plasma, "Pulse", { Speed = 3 })
end

function Models.Office(b: Builder)
	local wall = Color3.fromRGB(205, 210, 215)
	b:box(V(7, 0.3, 6), V(0, 0.15, 0), C.concrete, M.Concrete)
	b:box(V(7, 4, 0.3), V(0, 2.15, -2.85), wall, M.Metal)
	b:box(V(0.3, 4, 6), V(-3.35, 2.15, 0), wall, M.Metal)
	b:box(V(0.3, 4, 6), V(3.35, 2.15, 0), wall, M.Metal)
	-- фасад с дверью и окном
	b:box(V(2.5, 4, 0.3), V(-2.25, 2.15, 2.85), wall, M.Metal)
	b:box(V(2.6, 1.2, 0.3), V(2.2, 0.75, 2.85), wall, M.Metal)
	b:box(V(2.6, 1.6, 0.15), V(2.2, 2.15, 2.85), C.glass, M.Glass, { transparency = 0.5 })
	b:box(V(2.6, 1.2, 0.3), V(2.2, 3.55, 2.85), wall, M.Metal)
	b:box(V(2, 1, 0.3), V(-0.1, 3.65, 2.85), wall, M.Metal)
	b:box(V(7.4, 0.3, 6.4), V(0, 4.3, 0), C.metalDark, M.Metal)
	local sign = b:box(V(3, 0.8, 0.1), V(0, 4.85, 3.0), C.blue, M.SmoothPlastic, { collide = false })
	b:label(sign, Enum.NormalId.Back, "OFFICE", { color = C.white })
	-- интерьер: стол, кресло, мониторинг биржи, кулер, шкаф (ГДД 173–177)
	b:box(V(2.6, 0.15, 1.2), V(0.6, 1.1, -1.6), C.woodDark, M.Wood)
	b:box(V(0.15, 0.95, 1.1), V(-0.6, 0.6, -1.6), C.woodDark, M.Wood)
	b:box(V(0.15, 0.95, 1.1), V(1.8, 0.6, -1.6), C.woodDark, M.Wood)
	b:box(V(0.9, 0.2, 0.9), V(0.6, 0.75, -0.5), C.black, M.Fabric)
	b:box(V(0.9, 1.1, 0.2), V(0.6, 1.4, -0.1), C.black, M.Fabric)
	local screen = b:box(V(1.4, 0.8, 0.08), V(0.6, 1.65, -2.05), C.black, M.SmoothPlastic, { collide = false })
	b:label(screen, Enum.NormalId.Back, "📈 MARKET", { color = C.green, background = C.black })
	b:cyl(1.3, 0.6, V(-2.6, 0.65, -2.2), C.white, M.SmoothPlastic)
	b:cyl(0.7, 0.55, V(-2.6, 1.65, -2.2), Color3.fromRGB(120, 190, 255), M.Glass, { transparency = 0.3 })
	b:box(V(1, 2.4, 0.7), V(2.6, 1.35, -2.3), C.metal, M.Metal)
	openMenu(sign, "Staff", "Hire Staff", "Manager's Office")
end

function Models.DroneStation(b: Builder)
	b:box(V(8, 0.3, 6), V(0, 0.15, 0), C.asphalt, M.Concrete)
	-- арочный ангар
	b:cylZ(4, 5, V(-1.6, 0.3, -0.8), C.metal, M.CorrodedMetal)
	b:box(V(5, 0.4, 4), V(-1.6, 0, -0.8), C.asphalt, M.Concrete)
	b:box(V(3, 2.2, 0.1), V(-1.6, 1.2, 1.25), C.black, M.Metal, { collide = false })
	-- посадочные площадки
	for i, z in ipairs({ -1.6, 1.4 }) do
		local pad = b:cyl(0.12, 2.4, V(2.6, 0.36, z), C.yellow, M.SmoothPlastic)
		b:label(pad, Enum.NormalId.Top, "H", { color = C.black })
		local ring = b:cyl(0.06, 2.6, V(2.6, 0.32, z), C.cyan, M.Neon, { collide = false })
		b:tag(ring, "Pulse", { Speed = 1 + i * 0.5 })
	end
	local sign = b:box(V(3.2, 0.7, 0.1), V(-1.6, 3.2, 1.2), C.white, M.SmoothPlastic, { collide = false })
	b:label(sign, Enum.NormalId.Back, "DRONES", { color = C.blue })
	openMenu(sign, "Staff", "Hire Drones", "Drone Station")
end

function Models.AiSorter(b: Builder)
	b:box(V(4, 0.3, 4), V(0, 0.15, 0), C.metalDark, M.DiamondPlate)
	b:box(V(2.8, 1.8, 2), V(0, 1.2, -0.6), C.white, M.SmoothPlastic)
	local eye = b:ball(0.8, V(0, 2.4, 0.4), C.black, M.SmoothPlastic, { collide = false })
	local lens = b:ball(0.35, V(0, 2.4, 0.75), C.red, M.Neon, { collide = false })
	b:tag(lens, "Pulse", { Speed = 2 })
	local _ = eye
	local arm = b:group("Arm", V(1.2, 2.1, 0))
	arm:box(V(0.3, 1.6, 0.3), V(1.2, 2.9, 0), C.orange, M.Metal, { collide = false })
	arm:box(V(1.4, 0.3, 0.3), V(0.6, 3.6, 0), C.orange, M.Metal, { collide = false })
	b:tag(arm:groupModel(), "Sway", { Axis = "Y", Amplitude = 50, Speed = 1.2 })
	for i, color in ipairs({ C.green, Color3.fromRGB(110, 80, 50) }) do
		b:box(V(1.2, 1, 1.2), V(-2 + i * 1.3, 0.8, 1.3), color, M.SmoothPlastic)
	end
	local label = b:box(V(2.2, 0.5, 0.05), V(0, 1.6, 0.41), C.black, M.SmoothPlastic, { collide = false })
	b:label(label, Enum.NormalId.Back, "AI QC", { color = C.cyan })
end

function Models.CoolingTower(b: Builder)
	local radii = { 4.6, 4.1, 3.6, 3.2, 3.0, 3.1, 3.4 }
	for i, d in ipairs(radii) do
		b:cyl(1, d, V(0, i - 0.5, 0), Color3.fromRGB(200, 200, 195), M.Concrete)
	end
	local top = b:cyl(0.2, 3.2, V(0, #radii + 0.1, 0), C.stoneDark, M.Concrete, { collide = false })
	local steam = Instance.new("Smoke")
	steam.Color = Color3.fromRGB(245, 245, 250)
	steam.Opacity = 0.25
	steam.RiseVelocity = 5
	steam.Size = 4
	steam.Parent = top
	b:box(V(0.2, 0.6, 3.4), V(0, 0.3, 0), C.red, M.SmoothPlastic, { collide = false, transparency = 1 })
end

function Models.Breaker(b: Builder)
	b:box(V(1.6, 2.6, 0.8), V(-0.6, 1.3, -0.4), C.metal, M.Metal)
	b:box(V(1.2, 0.3, 0.05), V(-0.6, 2.2, 0.01), C.yellow, M.SmoothPlastic, { collide = false })
	-- рубильник
	local lever = b:group("Lever", V(-0.6, 1.4, 0.1))
	lever:box(V(0.15, 0.8, 0.15), V(-0.6, 1.7, 0.15), C.metalDark, M.Metal, { collide = false })
	lever:box(V(0.5, 0.2, 0.2), V(-0.6, 2.1, 0.15), C.red, M.SmoothPlastic, { collide = false })
	-- шкаф автоматики
	b:box(V(1, 1.8, 0.6), V(0.8, 0.9, -0.5), Color3.fromRGB(80, 90, 110), M.Metal)
	for i = 0, 2 do
		local led = b:box(
			V(0.15, 0.15, 0.05),
			V(0.55 + i * 0.25, 1.5, -0.19),
			if i == 2 then C.red else C.green,
			M.Neon,
			{ collide = false }
		)
		b:tag(led, "Pulse", { Speed = 1 + i })
	end
end

return Models
