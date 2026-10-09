-- Симулятор баланса Potato Tycoon.
-- Запуск:  luau tools/simulate.luau               (типичный игрок: бум + 70% пойманных жуков)
--          luau tools/simulate.luau -a noevents     (без событий)
--          luau tools/simulate.luau -a bugs=1       (ловит всех жуков)
--          luau tools/simulate.luau -a verbose      (лог каждой покупки, включая персонал)
--          luau tools/simulate.luau -a machine      (вывод для tools/tune.py)
--
-- «Игрок» каждый раз выбирает покупку с наименьшим (время накопления + окупаемость),
-- на ручном этапе копает с эффективностью 60% и тратит 5 сек на поход к лотку.
-- Использует те же конфиги и формулы, что и игра.

local Config = {
	Game = require("../src/shared/Config/Game"),
	Items = require("../src/shared/Config/Items"),
	Varieties = require("../src/shared/Config/Varieties"),
	Staff = require("../src/shared/Config/Staff"),
	StarTech = require("../src/shared/Config/StarTech"),
}
local Economy = require("../src/shared/Economy")

local args = { ... }
local withEvents = true
local verbose = false
local machine = false
local bugShare = 0.7
for _, a in ipairs(args) do
	if a == "noevents" then
		withEvents = false
	elseif a == "verbose" then
		verbose = true
	elseif a == "machine" then
		machine = true
	elseif string.sub(a, 1, 5) == "bugs=" then
		bugShare = tonumber(string.sub(a, 6)) or bugShare
	end
end

local MANUAL_EFFICIENCY = 0.6
local TRIP_SECONDS = 5
local GATEWAY_SHARE = 0.15
local MAX_TIME = 6 * 3600

local function fmt(n: number): string
	local suffixes = { "", "K", "M", "B", "T" }
	local i = 1
	while math.abs(n) >= 1000 and i < #suffixes do
		n /= 1000
		i += 1
	end
	return string.format(if i == 1 then "%.1f" else "%.2f%s", n, suffixes[i])
end

local function clock(t: number): string
	return string.format("%3d:%02d", t // 60, t % 60)
end

local function copy(t)
	local r = {}
	for k, v in pairs(t) do
		r[k] = if type(v) == "table" then copy(v) else v
	end
	return r
end

local profile = Economy.newProfile(Config)

local function income(p): number
	local stats = Economy.compute(p, nil, Config)
	if not stats.manual then
		local mult = 1
		if withEvents then
			-- Жуки: 10 минут дохода каждые 20 минут (+50% при поимке), бум: x3 на 3 мин из 30 (+20%)
			mult = 1 + 0.5 * bugShare + 0.2
		end
		return stats.incomePerSec * mult
	end
	-- Ручной этап
	local harvest = 0
	for _, item in ipairs(Config.Items.List) do
		if p.owned[item.id] and item.manualYield then
			harvest += item.manualYield / stats.ripenTime
		end
	end
	harvest *= MANUAL_EFFICIENCY
	local cap = stats.bagCapacity
	local perSec = cap / (cap / harvest + TRIP_SECONDS)
	-- золотые клубни при копке
	local digs = 0
	for _, item in ipairs(Config.Items.List) do
		if p.owned[item.id] and item.manualYield then
			digs += MANUAL_EFFICIENCY / stats.ripenTime
		end
	end
	local m = Config.Game.Manual
	digs *= perSec / harvest
	return perSec * stats.manualPrice + digs * m.GoldenChance * m.GoldenValue * stats.manualPrice
end

-- Все доступные покупки
local prereqOf = {}
for _, item in ipairs(Config.Items.List) do
	for _, r in ipairs(item.requires or {}) do
		prereqOf[r] = true
	end
end
for _, v in ipairs(Config.Varieties) do
	if v.requires then
		prereqOf[v.requires] = true
	end
end
for _, s in ipairs(Config.Staff.List) do
	prereqOf[s.requires] = true
end

local function candidates(p)
	local list = {}
	for _, item in ipairs(Config.Items.List) do
		if not p.owned[item.id] and not item.prebuilt and Economy.requirementsMet(item, p) then
			table.insert(list, {
				kind = "item",
				id = item.id,
				name = item.name,
				cost = Economy.itemCost(item, p, Config),
				gateway = prereqOf[item.id] or item.id == "shuttle",
				apply = function(q)
					q.owned[item.id] = true
				end,
			})
		end
	end
	for _, v in ipairs(Config.Varieties) do
		if not p.varieties[v.id] and (v.requires == nil or p.owned[v.requires]) then
			table.insert(list, {
				kind = "research",
				id = v.id,
				name = "Сорт: " .. v.name,
				cost = Economy.varietyCost(v, p, Config),
				apply = function(q)
					q.varieties[v.id] = true
				end,
			})
		end
	end
	for _, s in ipairs(Config.Staff.List) do
		local have = p.staff[s.id] or 0
		if not s.requiresPass and have < s.max and p.owned[s.requires] then
			table.insert(list, {
				kind = "staff",
				id = s.id,
				name = "Найм: " .. s.name,
				cost = Economy.staffCost(s, p, Config),
				apply = function(q)
					q.staff[s.id] = (q.staff[s.id] or 0) + 1
				end,
			})
		end
	end
	return list
end

local t = 0
local stageTimes = { [1] = 0 }
local lastStage = 1
local purchases = 0
local rebirthCost = Economy.rebirthCost(0, Config)

local function out(...)
	if not machine then
		print(...)
	end
end

out(string.format("Симуляция баланса (события: %s)", if withEvents then "да" else "нет"))
out(string.rep("-", 96))

while t < MAX_TIME do
	local inc = income(profile)
	local stats = Economy.compute(profile, nil, Config)

	-- Финал: шаттл построен — копим на Rebirth
	if profile.owned.shuttle then
		local need = rebirthCost - profile.cash
		if need > 0 then
			t += need / inc
			profile.cash = rebirthCost
		end
		break
	end

	local best, bestScore = nil, math.huge
	for _, c in ipairs(candidates(profile)) do
		local trial = copy(profile)
		c.apply(trial)
		local delta = income(trial) - inc
		local payback
		if delta > inc * 1e-4 then
			payback = c.cost / delta
		elseif c.gateway then
			payback = c.cost / math.max(inc * GATEWAY_SHARE, 1e-9)
		else
			payback = math.huge
		end
		local wait = math.max(0, (c.cost - profile.cash) / math.max(inc, 1e-9))
		local score = wait + payback
		if score < bestScore then
			best, bestScore = c, score
		end
	end

	if not best then
		print("Нет доступных покупок — тупик баланса!")
		break
	end

	local wait = math.max(0, (best.cost - profile.cash) / math.max(inc, 1e-9))
	t += wait
	profile.cash += wait * inc - best.cost
	best.apply(profile)
	purchases += 1

	local newStats = Economy.compute(profile, nil, Config)
	if machine then
		print(string.format("BUY %s %s %d %.1f", best.kind, best.id, lastStage, t))
	end
	if newStats.stage ~= lastStage then
		stageTimes[newStats.stage] = t
		lastStage = newStats.stage
		out(string.format("%s  ===== ЭТАП %d =====", clock(t), newStats.stage))
	end
	if verbose or best.kind ~= "staff" then
		out(
			string.format(
				"%s  %-58s $%-9s → $%s/с%s",
				clock(t),
				best.name,
				fmt(best.cost),
				fmt(income(profile)),
				if newStats.overloaded then "  ⚠ перегрузка" else ""
			)
		)
	end
	local _ = stats
end

if machine then
	for s = 1, 5 do
		print(string.format("STAGE %d %.1f", s, stageTimes[s] or -1))
	end
	print(string.format("END %.1f", t))
end
out(string.rep("-", 96))
for s = 1, 5 do
	if stageTimes[s] then
		out(string.format("Этап %d начат на %s", s, clock(stageTimes[s])))
	end
end
out(string.format("Rebirth ($%s) на %s, покупок: %d", fmt(rebirthCost), clock(t), purchases))
local final = Economy.compute(profile, nil, Config)
out(
	string.format(
		"Финал: $%s/с, сорт %s, множитель цехов x%.1f, энергия %d/%d кВт",
		fmt(final.incomePerSec),
		final.variety.name,
		final.factoryMult,
		final.energyUse,
		final.energyGen
	)
)
