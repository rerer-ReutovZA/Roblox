-- Форматирование чисел и времени для интерфейса

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Format.number(n: number): string
	if n ~= n then
		return "0"
	end
	local negative = n < 0
	n = math.abs(n)
	local i = 1
	while n >= 1000 and i < #SUFFIXES do
		n /= 1000
		i += 1
	end
	local text
	if i == 1 then
		text = if n >= 100 or n == math.floor(n) then string.format("%d", math.floor(n)) else string.format("%.1f", n)
	elseif n >= 100 then
		text = string.format("%d%s", math.floor(n), SUFFIXES[i])
	elseif n >= 10 then
		text = string.format("%.1f%s", math.floor(n * 10) / 10, SUFFIXES[i])
	else
		text = string.format("%.2f%s", math.floor(n * 100) / 100, SUFFIXES[i])
	end
	return (if negative then "-" else "") .. text
end

function Format.money(n: number): string
	return "$" .. Format.number(n)
end

-- Масса: граммы, килограммы, тонны
function Format.mass(kg: number): string
	if kg < 1 then
		return string.format("%d г", math.floor(kg * 1000 + 0.5))
	elseif kg < 1000 then
		return string.format("%.1f кг", kg)
	end
	return Format.number(kg / 1000) .. " т"
end

function Format.time(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = seconds // 3600
	local m = (seconds % 3600) // 60
	local s = seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

function Format.percent(x: number): string
	local p = x * 100
	if p >= 10 then
		return string.format("%d%%", math.floor(p + 0.5))
	elseif p >= 1 then
		return string.format("%.1f%%", p)
	elseif p >= 0.1 then
		return string.format("%.2f%%", p)
	end
	return string.format("%.3f%%", p)
end

return Format
