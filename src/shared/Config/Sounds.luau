-- Звуки (ГДД, ассеты 196–204). Сейчас стоят встроенные звуки Roblox (rbxasset://) как заглушки.
-- Замените на звуки из Creator Store: "rbxassetid://<ID>". Пустая строка — звук не играет.

return {
	Dig = { id = "rbxasset://sounds/collide.wav", volume = 0.6, pitch = 0.7 }, -- 196 Dig Dirt
	Dump = { id = "rbxasset://sounds/swoosh.wav", volume = 0.5, pitch = 0.8 }, -- 197 Wood Dump
	Cash = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.5, pitch = 1.2 }, -- 198 Cha-ching
	Sizzle = { id = "", volume = 0.4, pitch = 1 }, -- 199 Sizzle (фритюр)
	Blade = { id = "", volume = 0.4, pitch = 1 }, -- 200 Whir Blade (слайсер)
	Hum = { id = "", volume = 0.3, pitch = 1 }, -- 201 Hum Electric (подстанция)
	Alarm = { id = "rbxasset://sounds/clickfast.wav", volume = 0.8, pitch = 0.5 }, -- 202 Klaxon Alarm
	Rocket = { id = "rbxasset://sounds/Launching rocket.wav", volume = 1, pitch = 1 }, -- 203 Rocket Blast
	BugBuzz = { id = "", volume = 0.4, pitch = 1 }, -- 204 Bug Buzz
	Squash = { id = "rbxasset://sounds/splat.wav", volume = 0.6, pitch = 1.2 },
	Click = { id = "rbxasset://sounds/button.wav", volume = 0.4, pitch = 1 },
	Error = { id = "rbxasset://sounds/clickfast.wav", volume = 0.4, pitch = 0.8 },
	Build = { id = "rbxasset://sounds/snap.wav", volume = 0.6, pitch = 0.9 },
	Golden = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.7, pitch = 1.6 },
}
