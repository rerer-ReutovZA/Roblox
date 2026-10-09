-- Геймпассы (ГДД, раздел 6).
-- ВАЖНО: впишите сюда ID геймпассов, созданных на странице игры (Creator Hub → Monetization → Passes).
-- Пока id = 0, кнопка покупки показывает подсказку, а бонус не выдаётся.

return {
	List = {
		{
			key = "x2cash",
			id = 0,
			name = "x2 Cash Forever",
			desc = "Permanently doubles all income ($/sec)",
			icon = "💰",
		},
		{
			key = "infiniteEnergy",
			id = 0,
			name = "Infinite Energy",
			desc = "The power grid never drops below 100%",
			icon = "⚡",
		},
		{
			key = "magnateDrone",
			id = 0,
			name = "Tycoon's Auto-Drone",
			desc = "Golden tuber chance x3",
			icon = "🚁",
		},
		{
			key = "vip",
			id = 0,
			name = "VIP Farmer",
			desc = "Golden shovel, golden glow, [VIP] chat tag and +25% tick speed",
			icon = "👑",
		},
	},

	-- В Roblox Studio можно выдать себе все геймпассы для тестов
	GrantAllInStudio = false,
}
