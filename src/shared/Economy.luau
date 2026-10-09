-- Экономика и формулы (ГДД, раздел 2). «Чистый» модуль: конфиг передаётся параметром,
-- поэтому те же формулы использует и сервер, и клиент, и симулятор баланса (tools/simulate.luau).
--
-- Доход ($/сек) = Урожай (кг/сек) * Цена сорта * Суммарный множитель цехов
--                 * Энергоэффективность * Множитель Rebirth * Бонусы

local Economy = {}

export type Passes = {
	x2cash: boolean?,
	infiniteEnergy: boolean?,
	magnateDrone: boolean?,
	vip: boolean?,
}

export type Context = {
	passes: Passes?,
	boom: boolean?,
}

local function starLevel(profile, id: string): number
	return (profile.starTech and profile.starTech[id]) or 0
end

local function starValue(profile, Config, id: string): number
	local tech = Config.StarTech.ById[id]
	return starLevel(profile, id) * tech.perLevel
end

function Economy.owns(profile, itemId: string): boolean
	return profile.owned[itemId] == true
end

function Economy.isManual(profile): boolean
	return profile.owned.tower ~= true
end

function Economy.stage(profile, Config): number
	local stage = 1
	for _, milestone in ipairs(Config.Items.StageMilestones) do
		if profile.owned[milestone.item] then
			stage = math.max(stage, milestone.stage)
		end
	end
	return stage
end

function Economy.rebirthMultiplier(rebirths: number, Config): number
	return Config.Game.Rebirth.MultiplierBase ^ rebirths
end

function Economy.rebirthCost(rebirths: number, Config): number
	local r = Config.Game.Rebirth
	return r.BaseCost * r.CostGrowth ^ rebirths
end

-- Сколько звёзд даст Rebirth с номером n (1, 2, 3...)
function Economy.rebirthStars(n: number, Config): number
	local r = Config.Game.Rebirth
	if r.Stars[n] then
		return r.Stars[n]
	end
	local last = r.Stars[#r.Stars]
	return math.floor(last * r.StarsGrowth ^ (n - #r.Stars))
end

function Economy.discount(profile, Config): number
	return math.clamp(starValue(profile, Config, "discount"), 0, 0.9)
end

function Economy.itemCost(item, profile, Config): number
	return math.floor(item.cost * (1 - Economy.discount(profile, Config)))
end

function Economy.varietyCost(variety, profile, Config): number
	return math.floor(variety.cost * (1 - Economy.discount(profile, Config)))
end

function Economy.staffCost(staff, profile, Config): number
	local owned = (profile.staff and profile.staff[staff.id]) or 0
	return math.floor(Config.Staff.CostOf(staff, owned) * (1 - Economy.discount(profile, Config)))
end

-- Сорт, который сейчас растёт на полях: выбранный игроком или самый выгодный из открытых
function Economy.activeVariety(profile, Config)
	local chosen = profile.activeVariety
	if chosen and profile.varieties[chosen] then
		for _, v in ipairs(Config.Varieties) do
			if v.id == chosen then
				return v
			end
		end
	end
	local best = Config.Varieties[1]
	for _, v in ipairs(Config.Varieties) do
		if profile.varieties[v.id] and v.price * v.growth > best.price * best.growth then
			best = v
		end
	end
	return best
end

function Economy.compute(profile, ctx: Context?, Config)
	local passes: Passes = (ctx and ctx.passes) or {}
	local boom = (ctx and ctx.boom) == true
	local manual = Economy.isManual(profile)

	local baseYield = 0
	local yieldBoost = 0
	local multSum = 0
	local factoryBoost = 0
	local gen = 0
	local use = 0
	local powerBoost = 0
	local incomeBoost = 0
	local priceBoost = 0
	local bugBoost = 0
	local plots = 0

	for _, item in ipairs(Config.Items.List) do
		if profile.owned[item.id] then
			if item.yield and not manual then
				baseYield += item.yield
				plots += 1
			end
			yieldBoost += item.boost or 0
			multSum += item.mult or 0
			local power = item.power or 0
			if power > 0 then
				gen += power
			else
				use -= power
			end
			powerBoost += item.powerBoost or 0
			incomeBoost += item.incomeBoost or 0
		end
	end

	for _, s in ipairs(Config.Staff.List) do
		local count = (profile.staff and profile.staff[s.id]) or 0
		if count > 0 then
			yieldBoost += (s.yieldBoost or 0) * count
			multSum += (s.factoryAdd or 0) * count
			factoryBoost += (s.factoryBoost or 0) * count
			gen += (s.powerGen or 0) * count
			powerBoost += (s.powerBoost or 0) * count
			incomeBoost += (s.incomeBoost or 0) * count
			priceBoost += (s.priceBoost or 0) * count
			bugBoost += (s.bugBoost or 0) * count
		end
	end

	local variety = Economy.activeVariety(profile, Config)
	local energyGen = gen * (1 + powerBoost)
	local energyUse = use * (1 - math.clamp(starValue(profile, Config, "energy_saver"), 0, 0.9))
	local overloaded = energyUse > energyGen + 1e-6 and not passes.infiniteEnergy
	local energyFactor = if overloaded then Config.Game.Energy.OverloadFactor else 1

	local factoryMult = math.max(1, multSum) * (1 + factoryBoost)
	local rebirthMult = Economy.rebirthMultiplier(profile.rebirths or 0, Config)

	local bonusNoEvent = (1 + incomeBoost)
		* (1 + starValue(profile, Config, "star_income"))
		* (if passes.x2cash then 2 else 1)
		* (if passes.vip then 1.25 else 1)
	local eventMult = if boom then Config.Game.Events.Boom.Multiplier else 1

	local yieldKg = baseYield * (1 + yieldBoost) * variety.growth
	local price = variety.price * (1 + priceBoost)
	local incomeNoEvent = yieldKg * price * factoryMult * energyFactor * rebirthMult * bonusNoEvent

	local m = Config.Game.Manual
	local ripen = if profile.owned.upg_watering_can then m.RipenTimeWatered else m.RipenTime
	ripen *= 1 - math.clamp(starValue(profile, Config, "quick_hands"), 0, 0.9)
	if passes.vip then
		ripen /= 1.25
	end

	return {
		stage = Economy.stage(profile, Config),
		manual = manual,
		plots = plots,
		baseYield = baseYield,
		yieldBoost = yieldBoost,
		yieldKg = yieldKg,
		variety = variety,
		price = price,
		factoryMult = factoryMult,
		energyGen = energyGen,
		energyUse = energyUse,
		overloaded = overloaded,
		energyFactor = energyFactor,
		rebirthMult = rebirthMult,
		bonusMult = bonusNoEvent * eventMult,
		bugBoost = bugBoost,
		incomePerSec = incomeNoEvent * eventMult,
		incomeNoEvent = incomeNoEvent,
		manualPrice = m.PricePerPotato * rebirthMult * bonusNoEvent * eventMult,
		ripenTime = ripen,
		bagCapacity = if profile.owned.upg_bag_xl then m.BagCapacityXL else m.BagCapacity,
		offlineRate = math.min(1, Config.Game.Offline.BaseRate + starValue(profile, Config, "offline_rate")),
		offlineHours = Config.Game.Offline.BaseHours + starValue(profile, Config, "offline_hours"),
	}
end

-- Можно ли купить постройку (без учёта денег)
function Economy.requirementsMet(item, profile): boolean
	if item.requires then
		for _, req in ipairs(item.requires) do
			if not profile.owned[req] then
				return false
			end
		end
	end
	return true
end

function Economy.newProfile(Config)
	local profile = {
		version = 1,
		cash = Config.Game.StartCash,
		stars = 0,
		rebirths = 0,
		owned = {},
		varieties = { wild = true },
		activeVariety = nil,
		staff = {},
		starTech = {},
		bag = 0,
		totalEarned = 0,
		totalKg = 0,
		lastOnline = 0,
		lastIncome = 0,
		bugEventsWon = 0,
	}
	Economy.applyPrebuilt(profile, Config)
	return profile
end

function Economy.applyPrebuilt(profile, Config)
	for _, item in ipairs(Config.Items.List) do
		if item.prebuilt and (profile.rebirths or 0) >= (item.minRebirths or 0) then
			profile.owned[item.id] = true
		end
	end
end

return Economy
