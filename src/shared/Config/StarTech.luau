-- Древо звёздных технологий (открывается после Rebirth, валюта — Картофельные Звезды).
-- cost(level) = baseCost * (level + 1)

local StarTech = {
	{
		id = "star_income",
		name = "Star Revenue",
		desc = "+25% to all income per level",
		baseCost = 40,
		max = 10,
		perLevel = 0.25,
	},
	{
		id = "start_cash",
		name = "Starting Capital",
		desc = "Start with $1,500 per level after Rebirth",
		baseCost = 60,
		max = 5,
		perLevel = 1_500,
	},
	{
		id = "offline_rate",
		name = "Offline Farm",
		desc = "+10% offline income (50% → 100%)",
		baseCost = 40,
		max = 5,
		perLevel = 0.1,
	},
	{
		id = "offline_hours",
		name = "Tycoon's Long Sleep",
		desc = "+1 hour of offline income (3 → 8 hours)",
		baseCost = 40,
		max = 5,
		perLevel = 1,
	},
	{
		id = "discount",
		name = "Supplier Connections",
		desc = "-5% building cost per level",
		baseCost = 80,
		max = 5,
		perLevel = 0.05,
	},
	{
		id = "energy_saver",
		name = "Energy Saving",
		desc = "-10% energy use per level",
		baseCost = 50,
		max = 5,
		perLevel = 0.1,
	},
	{
		id = "quick_hands",
		name = "Quick Hands",
		desc = "Manual beds ripen 20% faster",
		baseCost = 30,
		max = 3,
		perLevel = 0.2,
	},
}

local byId = {}
for index, t in ipairs(StarTech) do
	t.order = index
	byId[t.id] = t
end

local function costOf(t, level: number): number
	return t.baseCost * (level + 1)
end

return {
	List = StarTech,
	ById = byId,
	CostOf = costOf,
}
