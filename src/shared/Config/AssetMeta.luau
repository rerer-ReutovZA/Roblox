-- Анимированные группы моделей из Blender: ключ модели → путь группы → анимация и точка вращения
-- (координаты модели Roblox, стады). Формат анимации — в src/shared/AssetName.luau.
-- Сгенерировано art/blender/build.py.

export type Group = { anim: string, pivot: { number }? }

local AssetMeta: { [string]: { [string]: Group } } = {
	Aeroponic = {
		["PanelLed"] = { anim = "pulse_2" },
	},
	AiSorter = {
		["Arm"] = { anim = "sway_y_50_3.14", pivot = { 1.2, 2.1, -0.2 } },
		["Lens"] = { anim = "pulse_2" },
	},
	AutoBedT1 = {
		["Auger"] = { anim = "spin_z_-360", pivot = { 1.38, 0.66, 0 } },
		["Bush/Plant0"] = { anim = "sway_x_2.5_3.14_0.15", pivot = { -0.503, 0.97, 1.9 } },
		["Bush/Plant1"] = { anim = "sway_x_2.5_3.14_0.45", pivot = { -0.397, 0.97, 0 } },
		["Bush/Plant2"] = { anim = "sway_x_2.5_3.14_0.75", pivot = { -0.384, 0.97, -1.9 } },
	},
	AutoBedT2 = {
		["Bush/Plant0"] = { anim = "sway_x_2.5_3.14_0.15", pivot = { 0.025, 1.03, 1.867 } },
		["Bush/Plant1"] = { anim = "sway_x_2.5_3.14_0.45", pivot = { 0.089, 1.03, 0 } },
		["Bush/Plant2"] = { anim = "sway_x_2.5_3.14_0.75", pivot = { -0.097, 1.03, -1.867 } },
		["Nozzle"] = { anim = "slide_z_-1.8_3.14", pivot = { 0, 0, 0 } },
	},
	AutoBedT3 = {
		["Bush/Plant0"] = { anim = "sway_x_2.5_3.14_0.15", pivot = { 0.059, 1.03, 1.867 } },
		["Bush/Plant1"] = { anim = "sway_x_2.5_3.14_0.45", pivot = { -0.025, 1.03, 0 } },
		["Bush/Plant2"] = { anim = "sway_x_2.5_3.14_0.75", pivot = { -0.061, 1.03, -1.867 } },
		["Laser"] = { anim = "slide_z_-2.3_3.14", pivot = { 0, 0, 0 } },
		["WarnLamp"] = { anim = "pulse_4" },
	},
	Battery = {
		["Led-10"] = { anim = "pulse_1" },
		["Led-11"] = { anim = "pulse_1.4" },
		["Led-12"] = { anim = "pulse_1.8" },
		["Led-13"] = { anim = "pulse_2.2" },
		["Led-14"] = { anim = "pulse_2.6" },
		["Led10"] = { anim = "pulse_1" },
		["Led11"] = { anim = "pulse_1.4" },
		["Led12"] = { anim = "pulse_1.8" },
		["Led13"] = { anim = "pulse_2.2" },
		["Led14"] = { anim = "pulse_2.6" },
	},
	Beacon = {
		["Lamp"] = { anim = "pulse_1.2" },
	},
	BedMetal = {
		["Bush/Plant0"] = { anim = "sway_x_2.5_3.14_0.15", pivot = { -0.052, 1.13, 2 } },
		["Bush/Plant1"] = { anim = "sway_x_2.5_3.14_0.45", pivot = { -0.048, 1.13, 0 } },
		["Bush/Plant2"] = { anim = "sway_x_2.5_3.14_0.75", pivot = { 0.027, 1.13, -2 } },
		["HeatLamp"] = { anim = "pulse_2" },
	},
	BedStone = {
		["Bush/Plant0"] = { anim = "sway_x_2.5_3.14_0.15", pivot = { 0.091, 1.01, 1.867 } },
		["Bush/Plant1"] = { anim = "sway_x_2.5_3.14_0.45", pivot = { 0.021, 1.01, 0 } },
		["Bush/Plant2"] = { anim = "sway_x_2.5_3.14_0.75", pivot = { 0.09, 1.01, -1.867 } },
	},
	BedWood = {
		["Bush/Plant0"] = { anim = "sway_x_2.5_3.14_0.15", pivot = { -0.073, 0.85, 2 } },
		["Bush/Plant1"] = { anim = "sway_x_2.5_3.14_0.45", pivot = { -0.081, 0.85, 0 } },
		["Bush/Plant2"] = { anim = "sway_x_2.5_3.14_0.75", pivot = { -0.054, 0.85, -2 } },
	},
	Biogas = {
		["FlareFlame"] = { anim = "pulse_4" },
	},
	Breaker = {
		["Led0"] = { anim = "pulse_1" },
		["Led1"] = { anim = "pulse_2" },
		["Led2"] = { anim = "pulse_3" },
	},
	Bug = {
		["BugBody"] = { anim = "bob_0.03_25.13", pivot = { 0, 0, 0 } },
		["BugBody/HeadGroup"] = { anim = "sway_y_8_6.28", pivot = { 0, 0.4, 1.28 } },
		["BugBody/Hip0-1"] = { anim = "sway_y_14_12.57_0.5", pivot = { -0.5, 0.32, 0.72 } },
		["BugBody/Hip01"] = { anim = "sway_y_14_12.57_0", pivot = { 0.5, 0.32, 0.72 } },
		["BugBody/Hip1-1"] = { anim = "sway_y_14_12.57_0", pivot = { -0.5, 0.32, 0.25 } },
		["BugBody/Hip11"] = { anim = "sway_y_14_12.57_0.5", pivot = { 0.5, 0.32, 0.25 } },
		["BugBody/Hip2-1"] = { anim = "sway_y_14_12.57_0.5", pivot = { -0.5, 0.32, -0.25 } },
		["BugBody/Hip21"] = { anim = "sway_y_14_12.57_0", pivot = { 0.5, 0.32, -0.25 } },
	},
	Centrifuge = {
		["PanelLed"] = { anim = "pulse_2" },
		["Rotor"] = { anim = "spin_y_720", pivot = { 0, 1.4, 0 } },
	},
	CryoCapsule = {
		["Led"] = { anim = "pulse_0.8" },
	},
	DripSystem = {
		["Drop-1"] = { anim = "pulse_2" },
		["Drop-3"] = { anim = "pulse_2" },
		["Drop-5"] = { anim = "pulse_2" },
		["Drop-7"] = { anim = "pulse_2" },
		["Drop-9"] = { anim = "pulse_2" },
		["Drop1"] = { anim = "pulse_2" },
		["Drop3"] = { anim = "pulse_2" },
		["Drop5"] = { anim = "pulse_2" },
		["Drop7"] = { anim = "pulse_2" },
		["Drop9"] = { anim = "pulse_2" },
	},
	Drone = {
		["DroneBody"] = { anim = "bob_0.12_3.14", pivot = { 0, 1.6, 0 } },
		["DroneBody/Claw"] = { anim = "sway_x_6_3.14_0.25", pivot = { 0, 0.94, -0.12 } },
		["DroneBody/Prop0"] = { anim = "spin_y_1440", pivot = { -0.98, 1.86, 0.98 } },
		["DroneBody/Prop1"] = { anim = "spin_y_-1440", pivot = { 0.98, 1.86, 0.98 } },
		["DroneBody/Prop2"] = { anim = "spin_y_1440", pivot = { 0.98, 1.86, -0.98 } },
		["DroneBody/Prop3"] = { anim = "spin_y_-1440", pivot = { -0.98, 1.86, -0.98 } },
	},
	DroneStation = {
		["AntennaTip"] = { anim = "pulse_1" },
		["Ring0"] = { anim = "pulse_1" },
		["Ring1"] = { anim = "pulse_1.5" },
		["Windsock"] = { anim = "sway_y_15_3.14", pivot = { 3.6, 2.8, -2.7 } },
	},
	Extruder = {
		["Screw"] = { anim = "spin_x_239", pivot = { -0.2, 3.19, -0.3 } },
	},
	FenceWood = {
		["GateSign"] = { anim = "sway_z_-2_3.14", pivot = { 0, 3.35, 12.85 } },
	},
	Fertilizer = {
		["DoserLed"] = { anim = "pulse_4" },
	},
	Flagpole = {
		["Flag"] = { anim = "sway_y_12_3.14", pivot = { 0, 11, 0 } },
	},
	Fogger = {
		["Strip"] = { anim = "pulse_1" },
	},
	ForceDome = {
		["Orb"] = { anim = "pulse_1.5" },
	},
	Fusion = {
		["Plasma"] = { anim = "pulse_3" },
		["Torus"] = { anim = "spin_y_40", pivot = { 0, 3.2, 0 } },
	},
	GenDiesel100 = {
		["Beacon"] = { anim = "pulse_3" },
	},
	GenDiesel25 = {
		["RunLed"] = { anim = "pulse_2" },
	},
	GenPetrol = {
		["Motor"] = { anim = "slide_x_0.012_37.70", pivot = { 0, 0, 0 } },
	},
	GodMonument = {
		["Flame-1_6"] = { anim = "pulse_3" },
		["Flame1_6"] = { anim = "pulse_3" },
		["Idol"] = { anim = "bob_0.3_3.14", pivot = { 0, 2.35, 0 } },
	},
	GoldenPedestal = {
		["Tuber"] = { anim = "bob_0.3_3.14", pivot = { 0, 3.6, 0 } },
	},
	HallOfFame = {
		["TrophyStar"] = { anim = "pulse_1.5" },
	},
	HarvestTower = {
		["Beacon"] = { anim = "pulse_3" },
		["Radar"] = { anim = "spin_y_90", pivot = { 0, 13.55, -0.15 } },
	},
	HoloTerminal = {
		["Holo"] = { anim = "spin_y_40", pivot = { 0, 1.4, 0 } },
		["Projector"] = { anim = "pulse_1" },
	},
	HydroTower = {
		["Tower"] = { anim = "spin_y_12", pivot = { 0, 1, 0 } },
	},
	Ionizer = {
		["Orb"] = { anim = "pulse_2" },
		["Rings"] = { anim = "spin_y_45", pivot = { 0, 2, 0 } },
	},
	Lab = {
		["Helix"] = { anim = "spin_y_45", pivot = { -0.5, 0.3, -1 } },
		["Laser"] = { anim = "pulse_6" },
		["ScanPad"] = { anim = "pulse_2" },
		["ServerLed0"] = { anim = "pulse_1" },
		["ServerLed1"] = { anim = "pulse_1.3" },
		["ServerLed2"] = { anim = "pulse_1.6" },
		["ServerLed3"] = { anim = "pulse_1.9" },
		["ServerLed4"] = { anim = "pulse_2.2" },
		["ServerLed5"] = { anim = "pulse_2.5" },
		["ServerLed6"] = { anim = "pulse_2.8" },
	},
	LampQuantum = {
		["Ring-1"] = { anim = "spin_y_90", pivot = { 0, 5.95, 5 } },
		["Ring1"] = { anim = "spin_y_90", pivot = { 0, 5.95, -5 } },
	},
	LaunchPad = {
		["Lamp-1-1"] = { anim = "pulse_1.5" },
		["Lamp-11"] = { anim = "pulse_1.5" },
		["Lamp1-1"] = { anim = "pulse_1.5" },
		["Lamp11"] = { anim = "pulse_1.5" },
	},
	LaunchTower = {
		["TopBeacon"] = { anim = "pulse_1" },
	},
	Mascot = {
		["Plush"] = { anim = "bob_0.25_3.14", pivot = { 0, 0, 0 } },
	},
	Megapack = {
		["Strip"] = { anim = "pulse_0.7" },
	},
	MoleTrap = {
		["AntennaTip"] = { anim = "pulse_2" },
		["Wave0"] = { anim = "pulse_2" },
		["Wave1"] = { anim = "pulse_3" },
	},
	Mutagenesis = {
		["Warning"] = { anim = "pulse_2" },
	},
	PotatoReactor = {
		["Bubble0"] = { anim = "pulse_1" },
		["Bubble1"] = { anim = "pulse_1.5" },
		["Bubble2"] = { anim = "pulse_2" },
		["Bubble3"] = { anim = "pulse_1" },
		["Bubble4"] = { anim = "pulse_1.5" },
		["Bubble5"] = { anim = "pulse_2" },
		["Tuber"] = { anim = "bob_0.3_3.14", pivot = { 0, 2.4, 0 } },
	},
	PureeVat = {
		["Mixer"] = { anim = "spin_y_70", pivot = { -0.4, 4.19, -0.3 } },
	},
	QuantumConverter = {
		["Core"] = { anim = "bob_0.35_3.14", pivot = { 0, 4.3, 0 } },
		["Ring"] = { anim = "spin_z_50", pivot = { 0, 4.3, 0 } },
	},
	QuantumIrradiator = {
		["Rings"] = { anim = "bob_0.4_3.14", pivot = { 0, 2.8, 0 } },
	},
	RebirthGate = {
		["Rune-3_80"] = { anim = "pulse_1" },
		["Rune-3_81"] = { anim = "pulse_1.3" },
		["Rune-3_82"] = { anim = "pulse_1.6" },
		["Rune-3_83"] = { anim = "pulse_1.9" },
		["Rune3_80"] = { anim = "pulse_1" },
		["Rune3_81"] = { anim = "pulse_1.3" },
		["Rune3_82"] = { anim = "pulse_1.6" },
		["Rune3_83"] = { anim = "pulse_1.9" },
		["Swirl"] = { anim = "spin_z_59", pivot = { 0, 4.7, 0 } },
	},
	Robot = {
		["ChestLed0"] = { anim = "pulse_1" },
		["ChestLed1"] = { anim = "pulse_2" },
		["ChestLed2"] = { anim = "pulse_3" },
		["Head"] = { anim = "sway_y_20_3.14", pivot = { 0, 1.6, 0 } },
		["Head/Visor"] = { anim = "pulse_2" },
	},
	Satellite = {
		["Dish"] = { anim = "spin_y_15", pivot = { 0, 3.4, 0 } },
	},
	SellStand = {
		["ScalePan"] = { anim = "bob_0.03_6.28", pivot = { -2.3, 2.22, 2.3 } },
	},
	Slicer = {
		["BladeDisc"] = { anim = "spin_y_720", pivot = { 0.1, 2.89, -0.35 } },
		["Chips"] = { anim = "slide_x_0.19_6.28", pivot = { 0, 0, 0 } },
	},
	SolarMono = {
		["Array"] = { anim = "sway_y_20_3.14", pivot = { 0, 2.5, 0 } },
	},
	SolarSmall = {
		["InverterLed"] = { anim = "pulse_1" },
	},
	SpiceDrum = {
		["Drum"] = { anim = "spin_x_59", pivot = { 0, 4.09, -0.2 } },
	},
	Sprinkler = {
		["Head"] = { anim = "spin_y_180", pivot = { 0, 2.2, 0 } },
	},
	StarTerminal = {
		["Star"] = { anim = "bob_0.3_3.14", pivot = { 0, 3.45, -0.3 } },
	},
	StarchMill = {
		["Stones"] = { anim = "spin_y_50", pivot = { -0.8, 2.39, -0.3 } },
	},
	Washer = {
		["Drum"] = { anim = "spin_x_90", pivot = { -0.3, 4.39, -0.2 } },
	},
	WateringCan = {
		["Can"] = { anim = "sway_z_-10_3.14", pivot = { 0.35, 0.95, 0 } },
		["TimerLed"] = { anim = "pulse_3" },
	},
	Wind50 = {
		["Blink"] = { anim = "pulse_1" },
		["Rotor"] = { anim = "spin_z_-70", pivot = { 0, 17.9, 1.8 } },
	},
	WindSmall = {
		["Head"] = { anim = "sway_y_6_3.14", pivot = { 0, 8.75, 0 } },
		["Head/Rotor"] = { anim = "spin_z_-180", pivot = { 0, 9.3, 0.64 } },
	},
}

return AssetMeta
