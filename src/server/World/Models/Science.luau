-- Модели сектора 4: НИИ квантовой селекции, космодром и Rebirth

local Kit = require(script.Parent.Parent.ModelKit)
local Energy = require(script.Parent.Energy)

type Builder = Kit.Builder

local V = Vector3.new
local C = Kit.C
local M = Enum.Material

local Models = {}

local function beakers(b: Builder, x0: number, y: number, z: number)
	local colors = { C.green, C.cyan, C.purple, C.orange }
	for i, color in ipairs(colors) do
		b:cyl(0.5, 0.3, V(x0 + i * 0.45, y + 0.25, z), color, M.Neon, { collide = false, transparency = 0.2 })
	end
end

function Models.Lab(b: Builder)
	local white = Color3.fromRGB(240, 242, 245)
	b:box(V(12, 0.3, 8), V(0, 0.15, 0), white, M.Marble)
	-- каркас и стеклянные стены
	for _, x in ipairs({ -5.9, 5.9 }) do
		for _, z in ipairs({ -3.9, 3.9 }) do
			b:box(V(0.3, 4.5, 0.3), V(x, 2.4, z), white, M.SmoothPlastic)
		end
	end
	b:box(V(12, 4.2, 0.15), V(0, 2.4, -3.9), C.glass, M.Glass, { transparency = 0.6 })
	b:box(V(0.15, 4.2, 8), V(-5.9, 2.4, 0), C.glass, M.Glass, { transparency = 0.6 })
	b:box(V(4.5, 4.2, 0.15), V(-3.6, 2.4, 3.9), C.glass, M.Glass, { transparency = 0.6 })
	b:box(V(4.5, 4.2, 0.15), V(3.6, 2.4, 3.9), C.glass, M.Glass, { transparency = 0.6 })
	b:box(V(0.15, 4.2, 8), V(5.9, 2.4, 0), C.glass, M.Glass, { transparency = 0.6 })
	b:box(V(12.4, 0.4, 8.4), V(0, 4.75, 0), white, M.SmoothPlastic)
	local sign = b:box(V(5, 0.9, 0.1), V(0, 5.4, 4.2), C.white, M.SmoothPlastic, { collide = false })
	b:label(sign, Enum.NormalId.Back, "🧬 DNA LAB", { color = C.blue })
	-- дверь со сканером отпечатка (ГДД 161)
	local scanner = b:box(V(0.4, 0.6, 0.1), V(1.6, 1.8, 4.0), C.black, M.SmoothPlastic, { collide = false })
	b:box(V(0.25, 0.3, 0.05), V(1.6, 1.8, 4.06), C.green, M.Neon, { collide = false })
	local _ = scanner
	-- лабораторный стол с мензурками (ГДД 131)
	b:box(V(4, 0.2, 1.4), V(-3.2, 1.3, -2.8), white, M.SmoothPlastic)
	b:box(V(4, 1.2, 1.2), V(-3.2, 0.6, -2.8), C.metal, M.Metal)
	beakers(b, -5, 1.4, -2.8)
	-- электронный микроскоп (ГДД 132)
	b:box(V(1.2, 0.8, 1.2), V(-1.8, 1.8, -2.8), C.white, M.SmoothPlastic, { collide = false })
	b:cyl(1.4, 0.4, V(-1.8, 2.8, -2.8), C.metalDark, M.Metal, { collide = false })
	-- серверный шкаф нейросети (ГДД 138)
	b:box(V(1.4, 3.4, 1.2), V(4.8, 1.9, -2.9), C.black, M.Metal)
	for y = 0.8, 3.2, 0.4 do
		local led = b:box(V(1, 0.08, 0.05), V(4.8, y, -2.28), C.cyan, M.Neon, { collide = false })
		b:tag(led, "Pulse", { Speed = 1 + y })
	end
	-- лазерный стимулятор деления клеток (ГДД 139)
	b:box(V(1.4, 1, 1), V(2.6, 0.8, -2.8), C.metal, M.Metal)
	local beam = b:box(V(0.1, 0.1, 1.6), V(2.6, 1.6, -2.2), C.red, M.Neon, { collide = false })
	b:tag(beam, "Pulse", { Speed = 6 })
	-- терминал исследований
	local terminal = b:box(V(1.6, 1.2, 0.2), V(0, 1.8, 1.4), C.black, M.SmoothPlastic, { rot = V(-20, 0, 0) })
	b:label(terminal, Enum.NormalId.Back, "VARIETIES", { color = C.green, background = C.black })
	b:box(V(0.3, 1.2, 0.3), V(0, 0.75, 1.4), C.metal, M.Metal)
	Energy.openMenu(terminal, "Research", "Seed Research", "Terminal")
end

function Models.Centrifuge(b: Builder)
	b:cyl(1.6, 3.4, V(0, 0.8, 0), C.white, M.SmoothPlastic)
	b:cyl(0.2, 3.5, V(0, 1.7, 0), C.metal, M.Metal)
	b:cyl(0.6, 3, V(0, 2.05, 0), C.glass, M.Glass, { transparency = 0.5, collide = false })
	local rotor = b:group("Rotor", V(0, 1.95, 0))
	for i = 0, 5 do
		local a = math.rad(i * 60)
		rotor:cyl(0.4, 0.35, V(math.cos(a) * 1, 1.95, math.sin(a) * 1), C.cyan, M.Neon, { collide = false })
	end
	b:tag(rotor:groupModel(), "Spin", { Axis = "Y", Speed = 720 })
	local led = b:box(V(0.6, 0.3, 0.05), V(0, 1, 1.71), C.green, M.Neon, { collide = false })
	b:tag(led, "Pulse", { Speed = 2 })
end

function Models.Mutagenesis(b: Builder)
	b:box(V(4.6, 3.6, 4.6), V(0, 1.8, 0), Color3.fromRGB(70, 75, 80), M.Metal)
	b:box(V(4.8, 0.4, 4.8), V(0, 3.8, 0), C.yellow, M.Metal)
	local window = b:box(
		V(1.8, 1.4, 0.1),
		V(0, 2, 2.31),
		Color3.fromRGB(120, 255, 60),
		M.Neon,
		{ collide = false, transparency = 0.3 }
	)
	b:light(window, Color3.fromRGB(120, 255, 60), 10, 2)
	local sign = b:box(V(1.4, 1.4, 0.05), V(0, 3.0, 2.33), C.yellow, M.SmoothPlastic, { collide = false })
	b:label(sign, Enum.NormalId.Back, "☢", { color = C.black })
	local sparks = Instance.new("Sparkles")
	sparks.SparkleColor = Color3.fromRGB(120, 255, 60)
	sparks.Parent = window
end

function Models.Incubator(b: Builder)
	b:box(V(3.6, 0.3, 4.6), V(0, 0.15, 0), C.white, M.SmoothPlastic)
	b:box(V(3.6, 3.6, 4.6), V(0, 2.1, 0), C.glass, M.Glass, { transparency = 0.55 })
	for y = 1, 3, 1 do
		b:box(V(3.2, 0.1, 4.2), V(0, y, 0), C.white, M.SmoothPlastic, { collide = false })
		for z = -1.6, 1.6, 0.8 do
			b:ellipsoid(V(0.4, 0.5, 0.4), V(-0.8, y + 0.3, z), C.leaf, M.Grass, { collide = false })
			b:ellipsoid(V(0.4, 0.5, 0.4), V(0.8, y + 0.3, z), C.leaf, M.Grass, { collide = false })
		end
	end
	local lamp = b:box(V(3.4, 0.15, 4.4), V(0, 3.85, 0), Color3.fromRGB(255, 200, 120), M.Neon, { collide = false })
	b:light(lamp, Color3.fromRGB(255, 200, 120), 8, 1)
end

function Models.QuantumIrradiator(b: Builder)
	b:cyl(0.5, 4.4, V(0, 0.25, 0), C.metalDark, M.Metal)
	b:cyl(4.4, 0.8, V(0, 2.7, 0), C.black, M.Metal)
	local rings = b:group("Rings", V(0, 2.8, 0))
	for i, y in ipairs({ 1.6, 2.8, 4 }) do
		rings:cyl(0.15, 2.8 - i * 0.3, V(0, y, 0), C.cyan, M.Neon, { collide = false, transparency = 0.15 })
	end
	b:tag(rings:groupModel(), "Bob", { Amplitude = 0.4, Speed = 2 })
	local emitter = b:ellipsoid(V(2.4, 0.6, 2.4), V(0, 5.2, 0), C.white, M.SmoothPlastic, { rot = V(25, 0, 0) })
	b:light(emitter, C.cyan, 16, 2, true)
end

function Models.HoloTerminal(b: Builder)
	b:box(V(2.6, 1.2, 1.6), V(0, 0.6, 0), C.black, M.Metal)
	b:box(V(2.4, 0.1, 1.4), V(0, 1.25, 0), C.cyan, M.Neon, { collide = false, transparency = 0.3 })
	local holo = b:group("Holo", V(0, 2.5, 0))
	holo:cyl(2.2, 0.15, V(0, 2.4, 0), C.cyan, M.Neon, { collide = false, transparency = 0.3 })
	for i = 0, 5 do
		local a = math.rad(i * 60)
		local y = 1.8 + i * 0.25
		holo:pipe(V(0, y, 0), V(math.cos(a) * 0.9, y + 0.6, math.sin(a) * 0.9), 0.08, C.cyan, M.Neon)
		holo:ball(
			0.3,
			V(math.cos(a) * 0.9, y + 0.6, math.sin(a) * 0.9),
			C.cyan,
			M.Neon,
			{ collide = false, transparency = 0.2 }
		)
	end
	b:tag(holo:groupModel(), "Spin", { Axis = "Y", Speed = 40 })
end

function Models.SeedVault(b: Builder)
	b:box(V(3.8, 3.4, 3.8), V(0, 1.7, 0), Color3.fromRGB(225, 235, 245), M.Metal)
	local door = b:cylZ(0.3, 2.4, V(0, 1.7, 1.95), C.metal, M.Metal)
	b:box(V(1.6, 0.2, 0.15), V(0, 1.7, 2.15), C.metalDark, M.Metal, { collide = false })
	b:box(V(4, 0.3, 4), V(0, 3.55, 0), Color3.fromRGB(200, 230, 250), M.Ice)
	local mist = Instance.new("ParticleEmitter")
	mist.Color = ColorSequence.new(Color3.new(1, 1, 1))
	mist.Transparency = NumberSequence.new(0.6, 1)
	mist.Size = NumberSequence.new(0.6, 1.4)
	mist.Lifetime = NumberRange.new(1, 2)
	mist.Rate = 5
	mist.Speed = NumberRange.new(0.3, 0.8)
	mist.Acceleration = V(0, -0.5, 0)
	mist.Parent = door
end

function Models.GodMonument(b: Builder)
	b:box(V(4, 1, 6), V(0, 0.5, 0), C.stone, M.Marble)
	b:box(V(3, 1.2, 5), V(0, 1.6, 0), C.stoneDark, M.Marble)
	local idol = b:group("Idol", V(0, 4.5, 0))
	idol:potato(V(0, 4.6, 0), 4.2, C.gold, { rot = V(0, 0, 90) }).Material = M.Foil
	idol:box(V(1.6, 0.6, 1.6), V(0, 6.9, 0), C.gold, M.Foil, { collide = false })
	for i = 0, 4 do
		local a = math.rad(i * 72)
		idol:box(V(0.3, 0.6, 0.3), V(math.cos(a) * 0.65, 7.4, math.sin(a) * 0.65), C.gold, M.Foil, { collide = false })
	end
	idol:ball(0.5, V(-0.5, 5.2, 1.0), C.white, M.SmoothPlastic, { collide = false })
	idol:ball(0.5, V(0.5, 5.2, 1.0), C.white, M.SmoothPlastic, { collide = false })
	b:tag(idol:groupModel(), "Bob", { Amplitude = 0.3, Speed = 1 })
	local plaque = b:box(V(2.4, 0.6, 0.05), V(0, 1.6, 2.53), C.gold, M.Foil, { collide = false })
	b:label(plaque, Enum.NormalId.Back, "POTATO GOD", { color = C.black })
	local glow = b:ball(0.2, V(0, 4.6, 0), C.gold, M.Neon, { collide = false, transparency = 1 })
	b:light(glow, C.gold, 14, 2)
end

function Models.LaunchPad(b: Builder)
	b:box(V(14, 1, 14), V(0, 0.5, 0), C.concrete, M.Concrete, { name = "Pad" })
	b:box(V(4, 0.06, 4), V(0, 1.03, 0), C.black, M.Concrete, { collide = false })
	for _, r in ipairs({ 5, 6.4 }) do
		b:box(V(r * 2, 0.06, 0.3), V(0, 1.04, r), C.yellow, M.SmoothPlastic, { collide = false })
		b:box(V(r * 2, 0.06, 0.3), V(0, 1.04, -r), C.yellow, M.SmoothPlastic, { collide = false })
		b:box(V(0.3, 0.06, r * 2), V(r, 1.04, 0), C.yellow, M.SmoothPlastic, { collide = false })
		b:box(V(0.3, 0.06, r * 2), V(-r, 1.04, 0), C.yellow, M.SmoothPlastic, { collide = false })
	end
	for _, x in ipairs({ -6.5, 6.5 }) do
		for _, z in ipairs({ -6.5, 6.5 }) do
			local lamp = b:cyl(0.6, 0.5, V(x, 1.3, z), C.red, M.Neon, { collide = false })
			b:tag(lamp, "Pulse", { Speed = 1.5 })
		end
	end
	-- газоотводный лоток
	b:box(V(3, 0.8, 4), V(0, 0.4, 8.6), C.stoneDark, M.Concrete, { collide = false })
end

function Models.LaunchTower(b: Builder)
	b:box(V(4, 0.6, 6), V(0, 0.3, 0), C.concrete, M.Concrete)
	local h = 22
	for _, x in ipairs({ -1.2, 1.2 }) do
		for _, z in ipairs({ -1.2, 1.2 }) do
			b:box(V(0.35, h, 0.35), V(x, h / 2, z), C.red, M.Metal)
		end
	end
	for y = 2, h - 2, 2 do
		b:box(
			V(2.6, 0.2, 0.2),
			V(0, y, 1.2),
			C.red,
			M.Metal,
			{ collide = false, rot = V(0, 0, if y % 4 == 0 then 30 else -30) }
		)
		b:box(V(2.6, 0.2, 0.2), V(0, y, -1.2), C.red, M.Metal, { collide = false })
		b:box(V(0.2, 0.2, 2.6), V(1.2, y, 0), C.red, M.Metal, { collide = false })
	end
	-- руки обслуживания к шаттлу (шаттл стоит на площадке западнее, x = -10)
	for _, y in ipairs({ 8, 14, 19 }) do
		b:box(V(6, 0.4, 1), V(-4, y, 0), C.metalDark, M.Metal, { collide = false })
	end
	b:pipe(V(-1.2, 12, 0.8), V(-7, 9, 0.8), 0.25, C.black, M.Rubber)
	b:pipe(V(-1.2, 16, -0.8), V(-7, 13, -0.8), 0.25, C.black, M.Rubber)
	local top = b:ball(0.5, V(0, h + 0.5, 0), C.red, M.Neon, { collide = false })
	b:tag(top, "Pulse", { Speed = 1 })
end

-- Шаттл ставится поверх стартовой площадки (overlay)
function Models.Shuttle(b: Builder)
	local stack = b:group("Stack", V(0, 1, 0))
	local white = Color3.fromRGB(245, 245, 245)
	-- ракета-носитель «Спуд-1» (ГДД 145)
	stack:cyl(12, 3.2, V(0, 7, -0.6), Color3.fromRGB(230, 120, 40), M.SmoothPlastic)
	stack:ellipsoid(V(3.2, 3, 3.2), V(0, 13, -0.6), Color3.fromRGB(230, 120, 40), M.SmoothPlastic)
	for _, x in ipairs({ -2.1, 2.1 }) do
		stack:cyl(10, 1.2, V(x, 6, -0.6), white, M.SmoothPlastic)
		stack:ellipsoid(V(1.2, 1.6, 1.2), V(x, 11.4, -0.6), white, M.SmoothPlastic)
	end
	-- орбитальный корабль «Галактический Картофель» (ГДД 146)
	stack:cyl(9, 2.2, V(0, 7.5, 1.8), white, M.SmoothPlastic)
	stack:ellipsoid(V(2.2, 3, 2.2), V(0, 12.4, 1.8), C.black, M.SmoothPlastic)
	stack:wedge(V(0.4, 4, 3.4), V(-2.2, 4.4, 1.8), white, M.SmoothPlastic, { rot = V(0, 0, 0) })
	stack:wedge(V(0.4, 4, 3.4), V(2.2, 4.4, 1.8), white, M.SmoothPlastic, { rot = V(0, 0, 0) })
	stack:box(V(4.4, 0.3, 3), V(0, 3.4, 1.8), white, M.SmoothPlastic)
	local logo = stack:box(V(1.6, 1.6, 0.1), V(0, 8, 2.92), white, M.SmoothPlastic, { collide = false })
	stack:label(logo, Enum.NormalId.Back, "🥔", { color = C.black })
	-- двигатели
	for i, x in ipairs({ -2.1, 0, 2.1 }) do
		local nozzle = stack:cyl(0.8, 1, V(x, 0.6, -0.6), C.metalDark, M.Metal, { name = "Engine" .. i })
		local fire = Instance.new("Fire")
		fire.Name = "Flame"
		fire.Enabled = false
		fire.Size = 6
		fire.Heat = -10
		fire.Color = Color3.fromRGB(255, 150, 40)
		fire.SecondaryColor = Color3.fromRGB(255, 240, 120)
		fire.Parent = nozzle
		local smoke = Instance.new("Smoke")
		smoke.Name = "Exhaust"
		smoke.Enabled = false
		smoke.Size = 6
		smoke.Opacity = 0.4
		smoke.RiseVelocity = -4
		smoke.Color = Color3.fromRGB(220, 220, 220)
		smoke.Parent = nozzle
	end
	stack:groupModel():SetAttribute("Shuttle", true)
	local plaque = b:box(V(0.1, 0.1, 0.1), V(0, 14.5, 0), white, M.SmoothPlastic, { collide = false, transparency = 1 })
	b:billboard(plaque, "🚀 Shuttle ready for Rebirth", 2, C.yellow, 80)
	Energy.openMenu(plaque, "Rebirth", "Launch Rebirth", "Shuttle")
	local prompt = plaque:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.MaxActivationDistance = 22
	end
end

function Models.Beacon(b: Builder)
	b:cyl(0.4, 1.6, V(0, 0.2, 0), C.concrete, M.Concrete)
	b:cyl(10, 0.3, V(0, 5.2, 0), C.white, M.Metal)
	local lamp = b:ball(0.8, V(0, 10.4, 0), C.red, M.Neon, { collide = false })
	b:light(lamp, C.red, 20, 2)
	b:tag(lamp, "Pulse", { Speed = 1.2 })
end

function Models.Satellite(b: Builder)
	b:box(V(2.6, 0.6, 2.6), V(0, 0.3, 0), C.concrete, M.Concrete)
	b:cyl(2.6, 0.5, V(0, 1.9, 0), C.metal, M.Metal)
	local dish = b:group("Dish", V(0, 3.4, 0))
	dish:ellipsoid(V(3.2, 0.8, 3.2), V(0, 3.6, 0), C.white, M.SmoothPlastic, { rot = V(40, 0, 0), collide = false })
	dish:pipe(V(0, 3.6, 0), V(0, 4.6, 0.9), 0.1, C.metalDark)
	dish:ball(0.3, V(0, 4.6, 0.9), C.red, M.Neon, { collide = false })
	b:tag(dish:groupModel(), "Spin", { Axis = "Y", Speed = 15 })
end

function Models.StarTerminal(b: Builder)
	b:box(V(2.6, 0.4, 2.6), V(0, 0.2, 0), C.purple, M.Metal)
	b:box(V(1.6, 2.4, 1), V(0, 1.6, -0.3), C.gold, M.Foil)
	local screen = b:box(V(1.4, 1, 0.1), V(0, 2.2, 0.22), C.black, M.SmoothPlastic)
	b:label(screen, Enum.NormalId.Back, "⭐ STARS", { color = C.yellow, background = C.black })
	local star = b:ball(0.7, V(0, 3.4, -0.3), C.yellow, M.Neon, { collide = false })
	b:tag(star, "Bob", { Amplitude = 0.3, Speed = 2 })
	b:light(star, C.yellow, 10, 2)
	Energy.openMenu(screen, "StarTech", "Star Tech", "Star Terminal")
end

return Models
