-- Надписи на моделях из Blender: ключ модели → номер метки → текст и грань детали.
-- Исходный язык — английский; TextLabel с AutoLocalize переводит автоперевод Roblox.
-- Сгенерировано art/blender/build.py — правьте тексты в art/blender/assets/*.py.

export type Label = { text: string, face: string }

local ModelText: { [string]: { [number]: Label } } = {
	AiSorter = {
		[1] = { text = "AI QC", face = "Back" },
	},
	Autoclave = {
		[1] = { text = "AUTOCLAVE +1.5", face = "Back" },
	},
	Battery = {
		[1] = { text = "50 kWh", face = "Back" },
	},
	Biogas = {
		[1] = { text = "BIOGAS", face = "Back" },
	},
	BiogasTurbine = {
		[1] = { text = "250 kW", face = "Back" },
	},
	Bioreactor = {
		[1] = { text = "BIOREACTOR x35", face = "Back" },
	},
	Breaker = {
		[1] = { text = "380 V", face = "Back" },
	},
	CryoTunnel = {
		[1] = { text = "CRYO x10", face = "Back" },
	},
	DroneStation = {
		[1] = { text = "DRONES", face = "Back" },
	},
	Extruder = {
		[1] = { text = "STICKS +1", face = "Back" },
	},
	FactoryHall = {
		[1] = { text = "PROCESSING PLANT", face = "Back" },
		[2] = { text = "CHIPS", face = "Back" },
		[3] = { text = "CHIPS", face = "Back" },
		[4] = { text = "CHIPS", face = "Back" },
	},
	FenceWood = {
		[1] = { text = "FARM", face = "Back" },
	},
	FounderStatue = {
		[1] = { text = "FOUNDER OF THE POTATO EMPIRE", face = "Back" },
	},
	Fryer = {
		[1] = { text = "FRYER x4", face = "Back" },
	},
	GenDiesel100 = {
		[1] = { text = "100 kW", face = "Back" },
	},
	GenDiesel25 = {
		[1] = { text = "25 kW", face = "Back" },
	},
	Geothermal = {
		[1] = { text = "GEOTHERMAL 300 kW", face = "Back" },
	},
	GodMonument = {
		[1] = { text = "POTATO GOD", face = "Back" },
	},
	HarvestTower = {
		[1] = { text = "AUTO-SELL", face = "Back" },
	},
	Lab = {
		[1] = { text = "DNA LAB", face = "Back" },
		[2] = { text = "VARIETIES", face = "Back" },
	},
	Office = {
		[1] = { text = "OFFICE", face = "Back" },
		[2] = { text = "MARKET", face = "Back" },
	},
	Packer = {
		[1] = { text = "PACKING +0.5", face = "Back" },
	},
	Peeler = {
		[1] = { text = "PEELER +0.5", face = "Back" },
	},
	PureeVat = {
		[1] = { text = "PUREE +1", face = "Back" },
	},
	QuantumConverter = {
		[1] = { text = "QUANTUM x100", face = "Back" },
	},
	SeedVault = {
		[1] = { text = "SEED VAULT", face = "Back" },
	},
	SellStand = {
		[1] = { text = "POTATO BUYER", face = "Back" },
		[2] = { text = "$1 EACH", face = "Back" },
	},
	Slicer = {
		[1] = { text = "CHIPS x2.5", face = "Back" },
	},
	SpiceDrum = {
		[1] = { text = "SPICES x6", face = "Back" },
	},
	StarTerminal = {
		[1] = { text = "STARS", face = "Back" },
	},
	StarchMill = {
		[1] = { text = "STARCH +2", face = "Back" },
	},
	Sublimator = {
		[1] = { text = "FREEZE-DRY x18", face = "Back" },
	},
	Substation = {
		[1] = { text = "DANGER", face = "Back" },
	},
	Washer = {
		[1] = { text = "WASHER x1.5", face = "Back" },
	},
}

return ModelText
