-- Проверка раскладки базы 80x80: границы, центральная дорожка, пересечения построек и кнопок.
-- Запуск: luau tools/layout.luau            — отчёт об ошибках
--         luau tools/layout.luau -a dump    — прямоугольники для tools/render_layout.py

local Items = require("../src/shared/Config/Items")
local Game = require("../src/shared/Config/Game")

local args = { ... }
local dump = args[1] == "dump"

local HALF = 40
local PATH = 3
local BUTTON = 3.6
local VIP_PADS = Game.VipPads

type Rect = { x0: number, x1: number, z0: number, z1: number, id: string, kind: string }

local function rect(id: string, kind: string, x: number, z: number, w: number, d: number): Rect
	return { x0 = x - w / 2, x1 = x + w / 2, z0 = z - d / 2, z1 = z + d / 2, id = id, kind = kind }
end

local function overlap(a: Rect, b: Rect): boolean
	local eps = 0.05
	return a.x0 < b.x1 - eps and b.x0 < a.x1 - eps and a.z0 < b.z1 - eps and b.z0 < a.z1 - eps
end

-- все предки по requires (постройка появляется только после них)
local ancestors: { [string]: { [string]: boolean } } = {}
local function ancestorsOf(id: string): { [string]: boolean }
	if ancestors[id] then
		return ancestors[id]
	end
	local set = {}
	ancestors[id] = set
	local item = Items.ById[id]
	for _, req in ipairs(item.requires or {}) do
		set[req] = true
		for a in pairs(ancestorsOf(req)) do
			set[a] = true
		end
	end
	return set
end

local footprints: { Rect } = {}
local buttons: { Rect } = {}
local errors = 0

local function fail(msg: string)
	errors += 1
	print("✗ " .. msg)
end

for _, item in ipairs(Items.List) do
	local r =
		rect(item.id, if item.overlay then "overlay" else "item", item.pos[1], item.pos[2], item.size[1], item.size[2])
	if dump then
		print(string.format("RECT %s %s %.2f %.2f %.2f %.2f %s", r.kind, item.id, r.x0, r.z0, r.x1, r.z1, item.sector))
	end
	if not item.overlay then
		if r.x0 < -HALF or r.x1 > HALF or r.z0 < -HALF or r.z1 > HALF then
			fail(item.id .. " выходит за границы базы")
		end
		if r.x0 < PATH and r.x1 > -PATH then
			fail(item.id .. " стоит на центральной дорожке")
		end
		table.insert(footprints, r)
	end
	if not item.prebuilt then
		local spot = item.button or item.pos
		local b = rect(item.id, "button", spot[1], spot[2], BUTTON, BUTTON)
		if dump then
			print(string.format("RECT button %s %.2f %.2f %.2f %.2f %s", item.id, b.x0, b.z0, b.x1, b.z1, item.sector))
		end
		if b.x0 < -HALF or b.x1 > HALF or b.z0 < -HALF or b.z1 > HALF then
			fail("кнопка " .. item.id .. " выходит за границы базы")
		end
		table.insert(buttons, b)
	end
end

for i, pad in ipairs(VIP_PADS) do
	local b = rect("vip" .. i, "vip", pad[1], pad[2], BUTTON, BUTTON)
	table.insert(buttons, b)
	if dump then
		print(string.format("RECT vip vip%d %.2f %.2f %.2f %.2f Agro", i, b.x0, b.z0, b.x1, b.z1))
	end
end

-- постройки не пересекаются между собой
for i = 1, #footprints do
	for j = i + 1, #footprints do
		if overlap(footprints[i], footprints[j]) then
			fail(string.format("пересекаются %s и %s", footprints[i].id, footprints[j].id))
		end
	end
end

-- кнопка не должна лежать под постройкой, которая видна одновременно с ней
for _, b in ipairs(buttons) do
	for _, f in ipairs(footprints) do
		if b.id ~= f.id and overlap(b, f) then
			local dependent = Items.ById[b.id] and Items.ById[f.id] and ancestorsOf(f.id)[b.id]
			if not dependent then
				fail(string.format("кнопка %s под постройкой %s", b.id, f.id))
			end
		end
	end
	for _, other in ipairs(buttons) do
		if other ~= b and other.id < b.id and overlap(b, other) then
			fail(string.format("кнопки %s и %s пересекаются", b.id, other.id))
		end
	end
end

if not dump then
	print(
		if errors == 0
			then "✓ Раскладка в порядке"
			else string.format("Найдено проблем: %d", errors)
	)
	if errors > 0 then
		error("раскладка базы содержит ошибки")
	end
end
