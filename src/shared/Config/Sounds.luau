-- Звуки игры. Все из официальных библиотек каталога Roblox (Pro Sound Effects, APM Music, Roblox) —
-- бесплатные и разрешены в любом опыте. Подбор и громкость — docs/SOUNDS.md.
-- id — rbxassetid; volume — громкость; pitch — скорость воспроизведения;
-- start/length — фрагмент файла в секундах (пропустить тишину, обрезать хвост; 0 — до конца);
-- variants — другие дубли для разнообразия; loop — фоновая петля на постройке; range — слышимость, стады.

return {
	-- Interface
	-- кнопки интерфейса, клик по незрелой грядке: «Roblox_UI_Bright_Click» (Roblox)
	Click = { id = "rbxassetid://15675059323", volume = 0.16, pitch = 1 },
	-- открытие окна: «Roblox_UI_Whoosh_04» (Roblox)
	Open = { id = "rbxassetid://15675012262", volume = 0.23, pitch = 1, start = 0.01 },
	-- ошибка / не хватает денег: «Roblox GUI - Negative» (Roblox)
	Error = { id = "rbxassetid://17208353912", volume = 0.25, pitch = 1 },
	-- Economy
	-- продажа, покупка, офлайн-доход: «Roblox GUI - Purchase» (Roblox)
	Cash = { id = "rbxassetid://17208380755", volume = 0.9, pitch = 1 },
	-- золотая картошка: «Magical Meetup - Hit2» (APMOfficial)
	Golden = { id = "rbxassetid://9048764475", volume = 0.95, pitch = 1 },
	-- картошка высыпается в ящик скупщика: «Crate Of Rocks 10» (ProSoundEffects)
	Dump = { id = "rbxassetid://9113967337", volume = 0.86, pitch = 1.1, start = 0.92 },
	-- новый этап, Rebirth, победа в событии: «Glamour Fanfare 4» (APMOfficial)
	Fanfare = { id = "rbxassetid://1844584807", volume = 0.33, pitch = 1, start = 0.25 },
	-- Farm
	-- копание лопатой: «Dirt Scoops 4» (ProSoundEffects)
	Dig = {
		id = "rbxassetid://9114116006",
		volume = 0.7,
		pitch = 1,
		start = 0.12,
		length = 0.5,
		variants = {
			{ id = "rbxassetid://9114115952", start = 0.07, volume = 0.55 },
			{ id = "rbxassetid://9114115823", start = 0.17, volume = 0.38 },
		},
	},
	-- раздавить жука: «Fruit Vegetable Impacts 6» (ProSoundEffects)
	Squash = { id = "rbxassetid://9114540148", volume = 0.94, pitch = 1.1, start = 0.04, length = 0.4 },
	-- начало нашествия жуков: «Bee Various Buzzing Actions 10» (ProSoundEffects)
	BugBuzz = { id = "rbxassetid://9113414621", volume = 1.17, pitch = 0.9, start = 0.11 },
	-- постройка куплена: «Hammer Nail Into Wood 25» (ProSoundEffects)
	Build = { id = "rbxassetid://9114756916", volume = 1.12, pitch = 1, start = 0.15, length = 0.63 },
	-- Events
	-- перегрузка сети: «Sci- Fi Siren Constant Varied Alarms 1» (ProSoundEffects)
	Alarm = { id = "rbxassetid://9118781307", volume = 0.32, pitch = 1, start = 0.1, length = 2.75 },
	-- искры при перегрузке: «Arc Zaps Phasey Short Bursts 1» (ProSoundEffects)
	Zap = { id = "rbxassetid://9113149296", volume = 0.32, pitch = 1, length = 0.8 },
	-- старт шаттла: «Tubular Whoosh Explosion Long Constant Roar» (ProSoundEffects)
	Rocket = { id = "rbxassetid://9126142721", volume = 0.46, pitch = 1, length = 5 },
	-- Ambient loops (3D, on buildings)
	-- фритюр (петля): «Fry Or Sizzle 2» (ProSoundEffects)
	Sizzle = { id = "rbxassetid://9114542880", volume = 0.51, pitch = 1, start = 3, length = 8, loop = true },
	-- слайсер (петля): «Conveyor Belt 3» (ProSoundEffects)
	Blade = { id = "rbxassetid://9113910518", volume = 0.26, pitch = 1, start = 1, length = 12, loop = true },
	-- подстанция (петля): «Transformer Hum 1» (ProSoundEffects)
	Hum = { id = "rbxassetid://9112889082", volume = 4.5, pitch = 1, start = 1, length = 29, loop = true },
	-- генераторы (петля): «Lawn Mower Motor 1» (ProSoundEffects)
	Engine = { id = "rbxassetid://9116244745", volume = 0.11, pitch = 0.9, start = 2, length = 15, loop = true },
	-- спринклер (петля): «Water Fountain 1» (ProSoundEffects)
	Water = { id = "rbxassetid://9120557629", volume = 0.74, pitch = 1, start = 11.5, length = 20, loop = true },
	-- Music (playlist)
	-- фоновая музыка: «Playful Things (a)» (APMOfficial)
	Music1 = { id = "rbxassetid://1842106837", volume = 0.1, pitch = 1 },
	-- фоновая музыка: «Wild West Uke» (APMOfficial)
	Music2 = { id = "rbxassetid://1843265603", volume = 0.09, pitch = 1 },
	-- фоновая музыка: «Happy Ways» (APMOfficial)
	Music3 = { id = "rbxassetid://1843278593", volume = 0.1, pitch = 1 },
}
