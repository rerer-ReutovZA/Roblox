-- Разбор имён деталей, экспортированных из Blender (art/blender/build.py):
--   «Путь/Групп__КлючПалитры[@анимация][#x,y,z][!номер надписи]»
-- Путь — вложенные группы (Bush/Plant0); ключ — цвет и материал из Config.Palette;
-- анимация — spin_<ось>_<град/с>, sway_<ось>_<град>_<рад/с>[_фаза], bob_<амплитуда>_<рад/с>[_фаза],
-- slide_<ось>_<расстояние>_<рад/с>[_фаза], pulse_<скорость>;
-- #x,y,z — точка вращения группы в координатах модели (тогда анимируется группа, а не деталь);
-- !n — метка надписи: текст берётся из Config.ModelText и рисуется на детали как текст Roblox.

local AssetName = {}

export type Parsed = {
	path: { string },
	key: string,
	anim: string?,
	pivot: Vector3?,
	label: number?,
}

function AssetName.parse(name: string): Parsed?
	local base, rest = string.match(name, "^(.-)__(.+)$")
	if not base or not rest then
		return nil
	end
	local key = string.match(rest, "^[^@#!]+")
	if not key then
		return nil
	end
	local anim = string.match(rest, "@([^#!]+)")
	local pivotText = string.match(rest, "#([^!]+)")
	local label = tonumber(string.match(rest, "!(%d+)$"))
	local pivot = nil
	if pivotText then
		local parts = string.split(pivotText, ",")
		local x, y, z = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
		if x and y and z then
			pivot = Vector3.new(x, y, z)
		end
	end
	local path = {}
	if base ~= "" and base ~= "Body" then
		for _, segment in ipairs(string.split(base, "/")) do
			if segment ~= "" then
				table.insert(path, segment)
			end
		end
	end
	return { path = path, key = key, anim = anim, pivot = pivot, label = label }
end

-- Анимация → тег CollectionService и атрибуты для клиентского Animator.
-- Animator: Spin — град/с; Sway — sin(t·Speed); Bob/Slide — sin(t·Speed·2), поэтому скорость делим на 2.
function AssetName.animation(anim: string): (string?, { [string]: any })
	local p = string.split(anim, "_")
	local kind = p[1]
	local n = function(i: number): number?
		return tonumber(p[i])
	end
	if kind == "spin" and n(3) then
		return "Spin", { Axis = string.upper(p[2]), Speed = n(3) }
	elseif kind == "sway" and n(3) and n(4) then
		return "Sway", { Axis = string.upper(p[2]), Amplitude = n(3), Speed = n(4), Phase = n(5) }
	elseif kind == "bob" and n(2) and n(3) then
		return "Bob", { Amplitude = n(2), Speed = (n(3) :: number) / 2, Phase = n(4) }
	elseif kind == "slide" and n(3) and n(4) then
		return "Slide", { Axis = string.upper(p[2]), Amplitude = n(3), Speed = (n(4) :: number) / 2, Phase = n(5) }
	elseif kind == "pulse" then
		return "Pulse", { Speed = n(2) or 1 }
	end
	return nil, {}
end

return AssetName
