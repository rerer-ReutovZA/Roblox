-- Надписи на моделях из Blender: ключ модели → номер метки → текст и грань детали.
-- Исходный язык — английский; TextLabel с AutoLocalize переводит автоперевод Roblox.
-- Сгенерировано art/blender/build.py — правьте тексты в art/blender/assets/*.py.

export type Label = { text: string, face: string }

local ModelText: { [string]: { [number]: Label } } = {
	FenceWood = {
		[1] = { text = "FARM", face = "Back" },
	},
	Office = {
		[1] = { text = "OFFICE", face = "Back" },
		[2] = { text = "MARKET", face = "Back" },
	},
	SellStand = {
		[1] = { text = "POTATO BUYER", face = "Back" },
		[2] = { text = "$1 EACH", face = "Back" },
	},
	Washer = {
		[1] = { text = "WASHER x1.5", face = "Back" },
	},
}

return ModelText
