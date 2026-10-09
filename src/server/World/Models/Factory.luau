-- Модели сектора 2: фабричный корпус и автономные модули-множители

local Kit = require(script.Parent.Parent.ModelKit)

type Builder = Kit.Builder

local V = Vector3.new
local C = Kit.C
local M = Enum.Material

local Models = {}

local function steam(part: BasePart, opacity: number?)
	local s = Instance.new("Smoke")
	s.Color = Color3.fromRGB(245, 245, 245)
	s.Opacity = opacity or 0.12
	s.RiseVelocity = 3
	s.Size = 1.2
	s.Parent = part
end

local function particles(part: BasePart, color: Color3, rate: number, speed: number, size: number)
	local p = Instance.new("ParticleEmitter")
	p.Color = ColorSequence.new(color)
	p.Size = NumberSequence.new(size, size * 0.3)
	p.Transparency = NumberSequence.new(0.2, 1)
	p.Lifetime = NumberRange.new(0.6, 1.2)
	p.Rate = rate
	p.Speed = NumberRange.new(speed * 0.6, speed)
	p.SpreadAngle = Vector2.new(30, 30)
	p.Parent = part
	return p
end

local function sign(b: Builder, text: string, color: Color3, pos: Vector3)
	local s = b:box(V(3.2, 0.6, 0.08), pos, C.black, M.SmoothPlastic, { collide = false })
	b:label(s, Enum.NormalId.Back, text, { color = color })
end

-- Корпус цеха 78x19 (overlay): стены, окна, ворота, стеклянная крыша, колонны, мостик, лампы
function Models.FactoryHall(b: Builder)
	local W, D, H = 78, 19, 9
	local wallColor = Color3.fromRGB(185, 190, 196)
	local hw, hd = W / 2, D / 2
	-- пол
	b:box(V(W, 0.2, D), V(0, 0.1, 0), Color3.fromRGB(150, 150, 150), M.Concrete, { collide = false })
	-- торцевые стены
	b:box(V(0.5, H, D), V(-hw, H / 2, 0), wallColor, M.Metal)
	b:box(V(0.5, H, D), V(hw, H / 2, 0), wallColor, M.Metal)
	-- южная (к энергоблоку) и северная стены с проёмами на дорожке x ∈ [-4, 4]
	for _, z in ipairs({ hd, -hd }) do
		for _, sx in ipairs({ -1, 1 }) do
			local len = hw - 4
			local cx = sx * (4 + len / 2)
			b:box(V(len, 3, 0.5), V(cx, 1.5, z), wallColor, M.Metal)
			-- панорамные окна (ГДД 159)
			b:box(V(len, 2.6, 0.2), V(cx, 4.3, z), C.glass, M.Glass, { transparency = 0.55 })
			b:box(V(len, H - 5.6, 0.5), V(cx, 5.6 + (H - 5.6) / 2, z), wallColor, M.Metal)
		end
		-- над воротами
		b:box(V(8, H - 6, 0.5), V(0, 6 + (H - 6) / 2, z), wallColor, M.Metal)
		-- рама ворот ангара (ГДД 160)
		b:box(V(0.6, 6, 0.7), V(-4.1, 3, z), C.yellow, M.Metal)
		b:box(V(0.6, 6, 0.7), V(4.1, 3, z), C.yellow, M.Metal)
		b:box(V(8.8, 0.6, 0.7), V(0, 6, z), C.yellow, M.Metal)
	end
	-- стеклянная крыша с фонарями верхнего света (ГДД 162–163)
	b:box(
		V(W, 0.2, D),
		V(0, H + 0.1, 0),
		Color3.fromRGB(200, 230, 245),
		M.Glass,
		{ transparency = 0.7, collide = false, shadow = false }
	)
	for x = -hw + 2, hw - 2, 6.5 do
		b:box(V(0.4, 0.5, D), V(x, H + 0.25, 0), C.metalDark, M.Metal, { collide = false })
		-- двутавровые колонны (ГДД 164)
		b:box(V(0.5, H, 0.5), V(x, H / 2, hd - 0.6), C.metalDark, M.Metal)
		b:box(V(0.5, H, 0.5), V(x, H / 2, -hd + 0.6), C.metalDark, M.Metal)
		-- цеховые лампы (ГДД 182)
		local lamp = b:box(V(0.4, 0.15, 3), V(x + 3.2, H - 0.4, 0), C.white, M.Neon, { collide = false })
		if math.floor((x + hw) / 6.5) % 2 == 0 then
			b:light(lamp, Color3.fromRGB(240, 245, 255), 16, 1, true)
		end
	end
	-- мостик инспектора вдоль северной стены и лестница (ГДД 165–166)
	b:box(V(W - 2, 0.25, 1.4), V(0, 6.4, -hd + 1.2), C.metal, M.DiamondPlate, { collide = false })
	b:box(V(W - 2, 0.1, 0.1), V(0, 7.4, -hd + 1.85), C.yellow, M.Metal, { collide = false })
	for i = 0, 8 do
		b:box(
			V(1.2, 0.2, 0.7),
			V(-hw + 1.6, 0.7 * i + 0.3, -hd + 2.4 + (8 - i) * 0.55),
			C.metal,
			M.DiamondPlate,
			{ collide = false }
		)
	end
	-- пожарный щит и аптечка (ГДД 178–179)
	local fire =
		b:box(V(1.6, 2, 0.15), V(-hw + 0.4, 2.2, 3), C.red, M.SmoothPlastic, { rot = V(0, 90, 0), collide = false })
	b:label(fire, Enum.NormalId.Back, "🧯", { color = C.white })
	local aid =
		b:box(V(0.9, 0.9, 0.2), V(hw - 0.4, 2.4, 3), C.white, M.SmoothPlastic, { rot = V(0, -90, 0), collide = false })
	b:label(aid, Enum.NormalId.Back, "✚", { color = C.red })
	-- отбойники у ворот (ГДД 169)
	for _, x in ipairs({ -5.5, 5.5 }) do
		local barrier = b:box(V(1.5, 0.9, 0.6), V(x, 0.45, hd + 1), C.yellow, M.Concrete)
		b:box(V(0.3, 0.9, 0.62), V(x - 0.4, 0.45, hd + 1), C.black, M.Concrete, { collide = false })
		b:box(V(0.3, 0.9, 0.62), V(x + 0.4, 0.45, hd + 1), C.black, M.Concrete, { collide = false })
		local _ = barrier
	end
	-- вывеска
	local s = b:box(V(12, 1.4, 0.3), V(0, H - 1.1, hd + 0.4), C.blue, M.SmoothPlastic, { collide = false })
	b:label(s, Enum.NormalId.Back, "ЗАВОД ПЕРЕРАБОТКИ", { color = C.white })
	-- декор: ящики чипсов и мешки (ГДД 183–184)
	for i = 0, 2 do
		local box = b:box(V(1.2, 0.9, 0.9), V(hw - 1.4, 0.55 + i * 0.9, -hd + 3.2), C.yellow, M.Cardboard)
		b:label(box, Enum.NormalId.Back, "CHIPS", { color = C.red })
	end
	for i = 0, 1 do
		b:ellipsoid(V(1.3, 1.6, 1.1), V(-hw + 1.2 + i * 1.3, 0.8, hd - 2.5), Color3.fromRGB(176, 150, 105), M.Fabric)
	end
end

function Models.Washer(b: Builder)
	b:machine(6, 5, 1.6, C.blue, C.cyan)
	local drum = b:group("Drum", V(-0.3, 3.9, -0.2))
	drum:cylX(4.6, 2.2, V(-0.3, 3.9, -0.2), Color3.fromRGB(80, 150, 220), M.DiamondPlate, { collide = false })
	for x = -2, 1.4, 0.8 do
		drum:cylX(0.15, 2.3, V(x, 3.9, -0.2), C.metal, M.Metal, { collide = false })
	end
	b:tag(drum:groupModel(), "Spin", { Axis = "X", Speed = 90 })
	local spray = b:box(V(4, 0.2, 0.2), V(-0.3, 5.3, -0.2), C.metal, M.Metal, { collide = false })
	local p = particles(spray, Color3.fromRGB(150, 210, 255), 25, 4, 0.3)
	p.EmissionDirection = Enum.NormalId.Bottom
	sign(b, "МОЙКА x1.5", C.cyan, V(-0.8, 2.6, 1.76))
end

function Models.Peeler(b: Builder)
	b:machine(6, 5, 1, C.metal, C.orange)
	b:cyl(2.8, 2.6, V(-0.6, 3.8, -0.4), C.steel, M.Metal)
	b:cyl(1, 1.6, V(-0.6, 5.7, -0.4), C.steel, M.Metal)
	local valve = b:cyl(0.6, 0.4, V(-0.6, 6.5, -0.4), C.red, M.Metal, { collide = false })
	steam(valve, 0.2)
	local gauge = b:cylZ(0.15, 0.8, V(0.8, 4.2, 1.0), C.white, M.SmoothPlastic, { collide = false })
	local _ = gauge
	sign(b, "ПИЛЕР +0.5", C.orange, V(-0.8, 2.6, 1.76))
end

function Models.Slicer(b: Builder)
	b:machine(6, 5, 1.4, C.yellow, C.red)
	b:wedge(V(2.4, 1.6, 2), V(-1.2, 4.1, -0.4), C.metal, M.Metal, { rot = V(0, 180, 0) })
	local blade = b:group("Blade", V(1, 3.6, -0.2))
	blade:cylX(0.2, 2.6, V(1, 3.8, -0.2), C.metal, M.Metal, { rot = V(0, 0, 90), collide = false })
	for i = 0, 3 do
		blade:box(V(0.05, 0.2, 2.4), V(1, 3.85, -0.2), C.white, M.Metal, { rot = V(0, i * 45, 0), collide = false })
	end
	b:tag(blade:groupModel(), "Spin", { Axis = "Y", Speed = 400 })
	-- готовые чипсы
	for i = 1, 6 do
		b:cyl(
			0.05,
			0.5,
			V(1.6 + (i % 3) * 0.3, 3.05, 1.2 + (i % 2) * 0.3),
			C.yellow,
			M.SmoothPlastic,
			{ collide = false }
		)
	end
	sign(b, "ЧИПСЫ x2.5", C.yellow, V(-0.8, 2.6, 1.76))
	b.model:SetAttribute("Sound", "Blade")
end

function Models.Fryer(b: Builder)
	b:machine(6, 5, 1, C.metal, C.orange)
	b:box(V(5, 1.2, 3.2), V(0, 3, -0.2), C.steel, M.Metal)
	b:box(
		V(4.6, 0.1, 2.8),
		V(0, 3.62, -0.2),
		Color3.fromRGB(240, 160, 40),
		M.Neon,
		{ collide = false, transparency = 0.2 }
	)
	b:wedge(V(5, 1.4, 1.6), V(0, 4.4, -1.1), C.metal, M.Metal, { rot = V(0, 180, 0), collide = false })
	local hood = b:box(V(5, 0.3, 1.6), V(0, 5.2, -0.9), C.metal, M.Metal, { collide = false })
	local chimney = b:cyl(1.6, 0.6, V(0, 6, -1.2), C.metal, M.Metal)
	steam(chimney, 0.18)
	local _ = hood
	sign(b, "ФРИТЮР x4", C.orange, V(-0.8, 2.6, 1.76))
	b.model:SetAttribute("Sound", "Sizzle")
end

function Models.SpiceDrum(b: Builder)
	b:machine(6, 5, 1, Color3.fromRGB(150, 70, 40), C.yellow)
	local drum = b:group("Drum", V(0, 4, -0.2))
	drum:cylX(4.4, 2.4, V(0, 4, -0.2), C.orange, M.Metal, { rot = V(0, 0, 8), collide = false })
	drum:cylX(0.2, 2.5, V(-1.5, 4.2, -0.2), C.red, M.Metal, { rot = V(0, 0, 8), collide = false })
	drum:cylX(0.2, 2.5, V(1.5, 3.8, -0.2), C.red, M.Metal, { rot = V(0, 0, 8), collide = false })
	b:tag(drum:groupModel(), "Spin", { Axis = "X", Speed = 60 })
	local hopper =
		b:wedge(V(1.2, 1.4, 1.2), V(-1.6, 5.9, -0.2), C.red, M.Metal, { rot = V(180, 0, 0), collide = false })
	particles(hopper, Color3.fromRGB(230, 120, 40), 10, 2, 0.15)
	sign(b, "СПЕЦИИ x6", C.yellow, V(-0.8, 2.6, 1.76))
end

function Models.PureeVat(b: Builder)
	b:machine(6, 5, 0.6, C.metal, C.yellow)
	b:cyl(2.6, 3.6, V(-0.4, 3.3, -0.3), C.steel, M.Metal)
	b:cyl(0.1, 3.3, V(-0.4, 4.62, -0.3), Color3.fromRGB(250, 235, 170), M.SmoothPlastic, { collide = false })
	local mixer = b:group("Mixer", V(-0.4, 5.2, -0.3))
	mixer:cyl(1.6, 0.25, V(-0.4, 5.4, -0.3), C.metal, M.Metal, { collide = false })
	mixer:box(V(2.6, 0.15, 0.3), V(-0.4, 4.8, -0.3), C.metal, M.Metal, { collide = false })
	b:tag(mixer:groupModel(), "Spin", { Axis = "Y", Speed = 70 })
	b:box(V(0.6, 1.2, 0.6), V(-0.4, 6.6, -0.3), C.blue, M.Metal, { collide = false })
	sign(b, "ПЮРЕ +1", C.yellow, V(-0.8, 2.6, 1.76))
end

function Models.Packer(b: Builder)
	b:machine(6, 5, 2.2, C.white, C.blue)
	b:box(V(1.4, 1.6, 1.4), V(-1.5, 5.2, -0.4), C.metal, M.Metal)
	-- пачки снеков
	local colors = { C.red, C.yellow, C.blue, C.green }
	for i = 0, 5 do
		b:box(
			V(0.7, 0.95, 0.3),
			V(1 + (i % 3) * 0.75, 4.15 + (i // 3) * 0.95, 0.4),
			colors[i % 4 + 1],
			M.Foil,
			{ collide = false }
		)
	end
	sign(b, "УПАКОВКА +0.5", C.blue, V(-0.8, 2.6, 1.76))
end

function Models.CryoTunnel(b: Builder)
	b:machine(6, 5, 1, C.white, C.cyan)
	b:box(V(5.4, 2.2, 3), V(0, 3.4, -0.2), Color3.fromRGB(225, 240, 250), M.Metal)
	b:box(V(5.6, 0.3, 3.2), V(0, 4.6, -0.2), Color3.fromRGB(190, 230, 250), M.Ice)
	b:box(V(1.6, 1.2, 0.1), V(0, 3.4, 1.31), C.cyan, M.Neon, { collide = false, transparency = 0.3 })
	for _, x in ipairs({ -2.2, -1.5 }) do
		b:cyl(2.6, 0.6, V(x, 6.0, -1.2), C.blue, M.Metal)
	end
	local frost = b:box(V(5, 0.2, 0.2), V(0, 2.3, 1.3), C.white, M.Ice, { collide = false })
	particles(frost, Color3.fromRGB(230, 245, 255), 15, 1, 0.6).Acceleration = V(0, -1, 0)
	sign(b, "КРИО x10", C.cyan, V(-0.8, 2.6, 1.76))
end

function Models.Sublimator(b: Builder)
	b:machine(6, 5, 0.6, C.metal, C.purple)
	b:cylX(4.6, 2.8, V(0, 3.6, -0.3), C.steel, M.Metal)
	local hatch = b:cylX(0.3, 2.2, V(2.4, 3.6, -0.3), C.metalDark, M.Metal)
	b:cylX(0.1, 1.2, V(2.6, 3.6, -0.3), C.purple, M.Neon, { collide = false, transparency = 0.2 })
	b:box(V(1.2, 1.2, 1.2), V(-1.8, 5.3, -0.3), C.purple, M.Metal)
	b:pipe(V(-1.8, 4.7, -0.3), V(-1.8, 4.9, -0.3), 0.3, C.black)
	b:light(hatch, C.purple, 8, 1)
	sign(b, "СУБЛИМАЦИЯ x18", C.purple, V(-0.8, 2.6, 1.76))
end

function Models.Autoclave(b: Builder)
	b:machine(6, 5, 0.6, C.metal, C.red)
	b:cylX(4.4, 2.8, V(-0.3, 3.6, -0.3), Color3.fromRGB(170, 170, 160), M.Metal)
	local door = b:cylX(0.4, 2.9, V(2.05, 3.6, -0.3), C.red, M.Metal)
	b:cylX(0.2, 0.8, V(2.35, 3.6, -0.3), C.yellow, M.Metal, { collide = false })
	local vent = b:cyl(0.8, 0.4, V(-1.2, 5.3, -0.3), C.metal, M.Metal)
	steam(vent, 0.2)
	local _ = door
	sign(b, "АВТОКЛАВ +1.5", C.red, V(-0.8, 2.6, 1.76))
end

function Models.StarchMill(b: Builder)
	b:machine(6, 5, 0.6, C.metal, C.white)
	local stones = b:group("Stones", V(-0.8, 3, -0.3))
	stones:cyl(0.8, 2.8, V(-0.8, 2.6, -0.3), C.stone, M.Granite, { collide = false })
	stones:cyl(0.8, 2.8, V(-0.8, 3.5, -0.3), C.stoneDark, M.Granite, { collide = false })
	b:tag(stones:groupModel(), "Spin", { Axis = "Y", Speed = 50 })
	b:box(V(1.8, 2.6, 1.8), V(1.6, 3.3, -0.3), C.steel, M.Metal)
	b:ellipsoid(V(1.6, 0.8, 1.2), V(1.6, 2.4, 1.3), C.white, M.Sand, { collide = false })
	sign(b, "КРАХМАЛ +2", C.white, V(-0.8, 2.6, 1.76))
end

function Models.Bioreactor(b: Builder)
	b:box(V(8, 0.4, 5), V(0, 0.2, 0), C.metalDark, M.DiamondPlate)
	for i, x in ipairs({ -2.6, 0 }) do
		b:cyl(5, 2.4, V(x, 2.9, -0.6), C.steel, M.Metal)
		b:ellipsoid(V(2.4, 1, 2.4), V(x, 5.4, -0.6), C.steel, M.Metal)
		local window = b:box(
			V(0.8, 2.6, 0.1),
			V(x, 2.9, 0.62),
			Color3.fromRGB(120, 255, 80),
			M.Neon,
			{ collide = false, transparency = 0.25 }
		)
		local bubbles = particles(window, Color3.fromRGB(200, 255, 180), 6, 1, 0.2)
		bubbles.EmissionDirection = Enum.NormalId.Top
		bubbles.Lifetime = NumberRange.new(1.5, 2.5)
		if i == 1 then
			b:light(window, Color3.fromRGB(120, 255, 80), 8, 1)
		end
	end
	-- ректификационная колонна биоэтанола (ГДД 76)
	b:cyl(7.5, 0.9, V(2.8, 4.15, -1), C.metal, M.Metal)
	for y = 1.2, 7.2, 1 do
		b:cyl(0.15, 1.2, V(2.8, y, -1), C.yellow, M.Metal, { collide = false })
	end
	b:pipe(V(0, 4.5, -0.6), V(2.8, 6.5, -1), 0.25, C.metal)
	sign(b, "БИОРЕАКТОР x35", Color3.fromRGB(120, 255, 80), V(-1.3, 1.6, 2.45))
end

function Models.Extruder(b: Builder)
	b:machine(6, 5, 0.6, C.metal, C.yellow)
	b:cylX(4.8, 1.2, V(-0.2, 3, -0.3), C.steel, M.Metal)
	local screw = b:group("Screw", V(-0.2, 3, -0.3))
	for x = -2, 2, 0.5 do
		screw:box(V(0.1, 1.15, 0.2), V(x, 3, -0.3), C.yellow, M.Metal, { rot = V(x * 70, 0, 0), collide = false })
	end
	b:tag(screw:groupModel(), "Spin", { Axis = "X", Speed = 200 })
	b:box(V(1.4, 2, 1.4), V(-2.2, 4.4, -0.3), C.yellow, M.Metal)
	for i = 0, 4 do
		b:cylX(1.6, 0.15, V(2.8, 2.5 + i * 0.15, 0.2 + (i % 2) * 0.2), C.potato, M.SmoothPlastic, { collide = false })
	end
	sign(b, "ПАЛОЧКИ +1", C.yellow, V(-0.8, 2.6, 1.76))
end

function Models.QuantumConverter(b: Builder)
	b:cyl(0.6, 9.4, V(0, 0.3, 0), C.metalDark, M.DiamondPlate)
	b:cyl(0.2, 8, V(0, 0.65, 0), C.purple, M.Neon, { collide = false, transparency = 0.4 })
	local ring = b:group("Ring", V(0, 4.3, 0))
	for i = 0, 19 do
		local a = math.rad(i * 18)
		ring:box(
			V(0.9, 0.9, 0.9),
			V(math.cos(a) * 3.4, 4.3 + math.sin(a) * 3.4, 0),
			if i % 2 == 0 then C.purple else C.cyan,
			M.Neon,
			{ rot = V(0, 0, i * 18), collide = false }
		)
	end
	b:tag(ring:groupModel(), "Spin", { Axis = "Z", Speed = 50 })
	for _, x in ipairs({ -3.8, 3.8 }) do
		b:box(V(0.8, 4.6, 1.4), V(x, 2.6, 0), C.black, M.Metal)
	end
	local core = b:potato(V(0, 4.3, 0), 2.2, C.gold, { collide = false })
	core.Material = M.Neon
	b:tag(core, "Bob", { Amplitude = 0.35, Speed = 1.5 })
	b:light(core, C.purple, 20, 3)
	local sparks = Instance.new("Sparkles")
	sparks.SparkleColor = C.purple
	sparks.Parent = core
	local s = b:box(V(4, 0.7, 0.1), V(0, 1.3, 4.3), C.black, M.SmoothPlastic, { collide = false })
	b:label(s, Enum.NormalId.Back, "КВАНТ x100", { color = C.purple })
end

return Models
