-- Древо звёздных технологий (открывается после Rebirth, валюта — Картофельные Звезды).
-- cost(level) = baseCost * (level + 1)

local StarTech = {
	{
		id = "star_income",
		name = "Звёздная выручка",
		desc = "+25% ко всему доходу за уровень",
		baseCost = 40,
		max = 10,
		perLevel = 0.25,
	},
	{
		id = "start_cash",
		name = "Стартовый капитал",
		desc = "После Rebirth начинаешь с $1,500 за уровень",
		baseCost = 60,
		max = 5,
		perLevel = 1_500,
	},
	{
		id = "offline_rate",
		name = "Офлайн-ферма",
		desc = "+10% к офлайн-доходу (50% → 100%)",
		baseCost = 40,
		max = 5,
		perLevel = 0.1,
	},
	{
		id = "offline_hours",
		name = "Долгий сон магната",
		desc = "+1 час офлайн-дохода (3 → 8 часов)",
		baseCost = 40,
		max = 5,
		perLevel = 1,
	},
	{
		id = "discount",
		name = "Связи с поставщиками",
		desc = "-5% к цене построек за уровень",
		baseCost = 80,
		max = 5,
		perLevel = 0.05,
	},
	{
		id = "energy_saver",
		name = "Энергосбережение",
		desc = "-10% к потреблению энергии за уровень",
		baseCost = 50,
		max = 5,
		perLevel = 0.1,
	},
	{
		id = "quick_hands",
		name = "Быстрые руки",
		desc = "Ручные грядки созревают на 20% быстрее",
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
