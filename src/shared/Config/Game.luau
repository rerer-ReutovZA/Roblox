-- Общие константы игры. Модуль «чистый» (без API Roblox), его читает и симулятор баланса.

return {
	PlotSize = 80, -- база игрока 80x80 стадов (ГДД, раздел 4)
	PlotCount = 6,
	PlotRingRadius = 130,
	HubRadius = 42,

	-- Жёлтые VIP-кнопки геймпассов у входа на базу (ГДД 190), координаты {x, z} базы
	VipPads = { { 17.7, 38.1 }, { 21.5, 38.1 }, { 25.3, 38.1 }, { 29.1, 38.1 } },

	TickSeconds = 1,
	StartCash = 0,
	AutosaveInterval = 60,
	DataStoreName = "PotatoTycoon_v1",

	-- Этап 1: ручной огород
	Manual = {
		RipenTime = 3, -- куст созревает каждые 3 секунды
		RipenTimeWatered = 1.5, -- с авто-лейкой
		BagCapacity = 15,
		BagCapacityXL = 50,
		PricePerPotato = 1, -- $ за штуку на лотке скупщика
		DigDistance = 18,
		GoldenChance = 0.02, -- шанс выкопать золотой клубень вручную
		GoldenValue = 25,
	},

	-- Золотые клубни на автоматических полях (геймпасс «Авто-дрон Магната» x3 к шансу)
	Golden = {
		Interval = 10,
		Chance = 0.02,
		PassMultiplier = 3,
		IncomeSeconds = 60, -- бонус = минута дохода
		GlowSeconds = 12,
	},

	Energy = {
		OverloadFactor = 0.5, -- «Перегрузка сети»: доход x0.5
	},

	Rebirth = {
		BaseCost = 500_000_000,
		CostGrowth = 2, -- каждый следующий Rebirth дороже в 2 раза
		MultiplierBase = 3, -- 3^N
		Stars = { 100, 250 }, -- Rebirth 1 и 2
		StarsGrowth = 1.5, -- дальше: 250 * 1.5^(N-2)
	},

	Events = {
		Bugs = {
			Interval = 20 * 60,
			FirstDelay = 6 * 60,
			Duration = 45,
			Goal = 15,
			Count = 20,
			RewardSeconds = 600, -- 10 минут дохода
			MinReward = 250,
			BossHealth = 8,
			BossValue = 5, -- босс засчитывается как 5 жуков
		},
		Boom = {
			Interval = 30 * 60,
			FirstDelay = 14 * 60,
			Duration = 180,
			Multiplier = 3,
		},
	},

	Offline = {
		BaseRate = 0.5,
		BaseHours = 3,
		MinSeconds = 60,
	},

	-- Только для тестов в Roblox Studio (в опубликованной игре игнорируется)
	Debug = {
		StartCash = 0, -- например 1e9, чтобы быстро проверить поздние этапы
		FastEvents = false, -- жуки через 20 сек и бум через 60 сек после старта
	},

	Stages = {
		{ name = "Hand-Tended Garden", goal = "Save $1,500 for the Auto Harvest Tower" },
		{ name = "Autonomous Farm Fields", goal = "Build the Factory Hall" },
		{ name = "Snack Factory", goal = "Set up the Drone Station" },
		{ name = "Industrial Giant", goal = "Build the DNA Lab" },
		{
			name = "Research & Space Export",
			goal = "Build the shuttle and save up for Rebirth",
		},
	},
}
