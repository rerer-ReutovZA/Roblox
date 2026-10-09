"""Энергетика, часть 2: дизель-генераторы, биогаз, турбина, солнечный трекер, большой ветряк, геотермальная
станция, подстанция, аккумуляторы, Megapack, картофельный и термоядерный реакторы, офис, станция дронов,
ИИ-сортировщик, градирня, рубильник.

Точка Roblox (x, y, z) здесь пишется как (x, -z, y).
"""

import math

from mathutils import Vector

from .agro2 import solar_panel


def louvers(k, name, w, h, center, normal_y, key, parent, step=0.16, depth=0.08):
    """Жалюзи вентиляции на грани, смотрящей в ±Y."""
    n = max(2, int(h / step))
    for i in range(n):
        z = center[2] - h / 2 + (i + 0.5) * h / n
        k.box(f"{name}{i}", (w, depth, h / n * 0.45), (center[0], center[1] + normal_y * depth / 2, z), key,
              bevel=0.01, rot=(normal_y * 25, 0, 0), parent=parent)


def louvers_x(k, name, d, h, center, normal_x, key, parent, step=0.16, depth=0.08):
    """Жалюзи на грани, смотрящей в ±X."""
    n = max(2, int(h / step))
    for i in range(n):
        z = center[2] - h / 2 + (i + 0.5) * h / n
        k.box(f"{name}{i}", (depth, d, h / n * 0.45), (center[0] + normal_x * depth / 2, center[1], z), key,
              bevel=0.01, rot=(0, -normal_x * 25, 0), parent=parent)


def stack(k, name, x, y, z0, height, radius, parent, key="Steel"):
    """Выхлопная труба с дождевой крышкой."""
    k.lathe(name, [(radius * 1.25, 0), (radius * 1.25, 0.12), (radius, 0.2), (radius, height), (0.0, height)],
            (x, y, z0), key, segments=20, parent=parent)
    k.lathe(name + "Cap", [(0.0, 0.0), (radius * 1.6, 0.0), (radius * 1.4, 0.12), (0.0, 0.3)],
            (x, y, z0 + height + 0.18), "MetalDark", segments=20, parent=parent)
    for i in range(3):
        a = i / 3 * math.tau
        k.tube(f"{name}Rod{i}", [(x + math.cos(a) * radius * 0.9, y + math.sin(a) * radius * 0.9, z0 + height - 0.02),
                                 (x + math.cos(a) * radius * 1.2, y + math.sin(a) * radius * 1.2, z0 + height + 0.2)],
               0.02, "MetalDark", parent=parent, smooth_path=False)


def plate_text(k, name, text, w, h, loc, plate_key, text_key, parent, size=None):
    """Табличка с объёмной надписью, лицом в -Y."""
    k.box(name, (w, 0.06, h), loc, plate_key, bevel=0.02, parent=parent)
    k.text(name + "Text", text, size or h * 0.55, (loc[0], loc[1] - 0.05, loc[2]), text_key, extrude=0.015,
           parent=parent, max_width=w * 0.88)


# ----------------------------------------------------------------------
# Дизель-генераторы
# ----------------------------------------------------------------------
def gen_diesel25(k, root):
    k.box("Skid", (3.8, 3.6, 0.3), (0, 0, 0.15), "MetalDark", bevel=0.05, parent=root)
    for y in (-1.2, 1.2):
        k.box(f"SkidRail{y}", (3.9, 0.25, 0.32), (0, y, 0.16), "Black", bevel=0.04, parent=root)
    k.box("Canopy", (3.4, 3.2, 2.4), (0, 0, 1.5), "GreenDark", bevel=0.18, segments=3, parent=root)
    k.box("Roof", (3.5, 3.3, 0.12), (0, 0, 2.74), "GreenDark", bevel=0.05, parent=root)
    louvers(k, "FrontLouver", 2.4, 1.3, (0.2, -1.6, 1.35), -1, "Black", root)
    k.box("FrontFrame", (2.6, 0.04, 1.5), (0.2, -1.6, 1.35), "MetalDark", bevel=0.02, parent=root)
    louvers_x(k, "SideLouver", 2.2, 1.0, (1.7, 0, 1.6), 1, "Black", root)
    for y in (-0.8, 0.8):
        k.box(f"Door{y}", (0.04, 1.4, 1.8), (-1.71, y, 1.45), "GreenDark", bevel=0.02, parent=root)
        k.box(f"Handle{y}", (0.06, 0.08, 0.3), (-1.75, y + 0.5, 1.45), "Chrome", bevel=0.02, parent=root)
    k.box("Panel", (0.9, 0.06, 0.7), (-1.0, -1.62, 1.55), "Black", bevel=0.03, parent=root)
    k.box("Screen", (0.5, 0.03, 0.25), (-1.0, -1.66, 1.68), "NeonGreen", bevel=0.01, parent=root)
    led = k.lens("RunLed", 0.04, (-1.25, -1.66, 1.38), "NeonGreen", rot=(90, 0, 0), parent=root)
    k.tag(led, "pulse_2")
    k.lathe("EStop", [(0.07, 0), (0.07, 0.05), (0.11, 0.06), (0.1, 0.1), (0.0, 0.11)], (-0.72, -1.65, 1.38), "Red",
            rot=(90, 0, 0), parent=root)
    plate_text(k, "Label", "25 kW", 1.4, 0.42, (-0.85, -1.63, 2.35), "White", "Black", root)
    stack(k, "Stack", 1.1, 1.0, 2.8, 1.0, 0.18, root)
    for x in (-1.2, 1.2):
        k.torus(f"LiftEye{x}", 0.12, 0.03, (x, 0, 2.86), "MetalDark", rot=(90, 0, 0), parent=root)
    k.lathe("FuelCap", [(0.12, 0), (0.12, 0.08), (0.0, 0.1)], (-1.0, 1.0, 2.8), "Chrome", parent=root)


def gen_diesel100(k, root):
    k.box("Base", (6.0, 4.8, 0.4), (0, 0, 0.2), "MetalDark", bevel=0.06, parent=root)
    k.box("Housing", (5.6, 4.2, 3.0), (0, 0, 1.9), "Yellow", bevel=0.15, segments=3, parent=root)
    k.box("RoofTrim", (5.7, 4.3, 0.1), (0, 0, 3.42), "MetalDark", bevel=0.03, parent=root)
    # радиатор слева, жалюзи справа
    k.box("RadiatorFrame", (0.08, 3.0, 2.5), (-2.82, 0, 1.9), "MetalDark", bevel=0.03, parent=root)
    louvers_x(k, "Radiator", 2.8, 2.3, (-2.84, 0, 1.9), -1, "Black", root, step=0.14)
    louvers_x(k, "Exhaust", 3.2, 2.0, (2.82, 0, 1.9), 1, "MetalDark", root, step=0.18)
    for x in (-1.6, 0.0, 1.6):
        k.box(f"Door{x}", (1.5, 0.04, 2.5), (x, -2.12, 1.85), "Yellow", bevel=0.02, parent=root)
        k.box(f"DoorSeam{x}", (0.03, 0.05, 2.5), (x + 0.77, -2.12, 1.85), "MetalDark", bevel=0.0, parent=root)
        k.box(f"Latch{x}", (0.08, 0.08, 0.4), (x + 0.55, -2.17, 1.9), "Chrome", bevel=0.02, parent=root)
    k.box("Label", (2.4, 0.06, 0.7), (0, -2.13, 2.9), "Black", bevel=0.03, parent=root)
    k.text("LabelText", "100 kW", 0.42, (0, -2.18, 2.9), "Yellow", extrude=0.015, parent=root, max_width=2.1)
    for x in (-1.2, 1.2):
        stack(k, f"Stack{x}", x, 1.2, 3.4, 1.3, 0.24, root)
    for x in (-2.4, 2.4):
        for y in (-1.9, 1.9):
            k.torus(f"LiftEye{x}{y}", 0.14, 0.035, (x, y, 3.5), "MetalDark", rot=(90, 0, 0), parent=root)
    beacon = k.lathe("Beacon", [(0.12, 0), (0.14, 0.05), (0.12, 0.22), (0.0, 0.26)], (2.3, -1.6, 3.42), "NeonOrange",
                     parent=root)
    k.tag(beacon, "pulse_3")


# ----------------------------------------------------------------------
# Биогаз и когенерационная турбина
# ----------------------------------------------------------------------
def biogas(k, root):
    k.lathe("Digester", [(0.0, 0.0), (2.6, 0.0), (2.6, 3.3), (2.7, 3.35), (2.7, 3.45), (0.0, 3.45)], (0, 0, 0),
            "Concrete", segments=48, parent=root)
    for z in (1.1, 2.2):
        k.lathe(f"Seam{z}", [(2.605, 0), (2.62, 0.02), (2.62, 0.06), (2.605, 0.08)], (0, 0, z), "StoneDark",
                segments=48, parent=root)
    dome = [(2.55, 0.0)] + [(2.55 * math.cos(t), 1.6 * math.sin(t)) for t in [math.pi / 2 * i / 10 for i in
                                                                             range(1, 10)]] + [(0.0, 1.6)]
    k.lathe("Membrane", dome, (0, 0, 3.4), "GreenDark", segments=48, parent=root, sharp=80)
    k.lathe("DomeVent", [(0.25, 0), (0.25, 0.25), (0.0, 0.3)], (0, 0, 4.95), "MetalDark", parent=root)
    k.tube("GasPipe", [(2.3, 0.0, 1.0), (3.0, 0.0, 1.0), (3.0, -2.8, 1.0)], 0.2, "Yellow", parent=root,
           smooth_path=False)
    k.torus("Flange1", 0.24, 0.05, (3.0, -1.4, 1.0), "MetalDark", rot=(90, 0, 0), parent=root)
    k.torus("Valve", 0.22, 0.04, (3.0, -0.8, 1.35), "Red", parent=root)
    k.tube("ValveStem", [(3.0, -0.8, 1.15), (3.0, -0.8, 1.35)], 0.04, "Chrome", parent=root, smooth_path=False)
    # факел
    k.lathe("FlareBase", [(0.4, 0), (0.4, 0.2), (0.0, 0.2)], (-2.6, -2.6, 0), "Concrete", parent=root)
    k.lathe("Flare", [(0.18, 0.0), (0.16, 4.3), (0.25, 4.4), (0.25, 4.65), (0.0, 4.65)], (-2.6, -2.6, 0.2), "Steel",
            segments=16, parent=root)
    k.lathe("FlareTip", [(0.27, 0), (0.27, 0.12), (0.2, 0.15), (0.0, 0.15)], (-2.6, -2.6, 4.85), "Black", parent=root)
    flame = k.lathe("FlareFlame", [(0.0, 0.0), (0.18, 0.1), (0.2, 0.35), (0.1, 0.7), (0.0, 0.9)], (-2.6, -2.6, 5.0),
                    "NeonOrange", segments=12, parent=root)
    k.tag(flame, "pulse_4")
    # надпись на стенке и лестница
    plate_text(k, "Label", "BIOGAS", 2.4, 0.7, (0, -2.68, 1.7), "White", "GreenDark", root)
    for x in (-1.0, 1.0):
        k.box(f"LabelBracket{x}", (0.08, 0.2, 0.5), (x, -2.6, 1.7), "MetalDark", bevel=0.02, parent=root)
    for i in range(2):
        x = 2.0 - i * 0.6
        k.tube(f"LadderRail{i}", [(x, 1.75, 0), (x, 1.75, 3.4), (x * 0.9, 1.6, 3.9)], 0.04, "Chrome", parent=root,
               smooth_path=False)
    for r in range(7):
        k.tube(f"Rung{r}", [(2.0, 1.75, 0.35 + r * 0.45), (1.4, 1.75, 0.35 + r * 0.45)], 0.03, "Chrome", parent=root,
               smooth_path=False)
    k.lathe("Gauge", [(0.16, 0), (0.16, 0.06), (0.0, 0.06)], (-1.0, -2.6, 2.4), "White", rot=(90, 0, 0), parent=root)


def biogas_turbine(k, root):
    k.box("Skid", (7.0, 6.0, 0.4), (0, 0, 0.2), "MetalDark", bevel=0.06, parent=root)
    k.lathe("Casing", [(1.0, -2.0), (1.3, -1.8), (1.3, 1.6), (1.15, 2.0), (0.0, 2.0)][::1], (-1.0, 0, 2.0), "White",
            rot=(0, 90, 0), segments=40, parent=root)
    for x in (-2.4, -1.0, 0.4):
        k.lathe(f"Flange{x}", [(1.31, 0), (1.42, 0.04), (1.42, 0.16), (1.31, 0.2)], (x, 0, 2.0), "Steel",
                rot=(0, 90, 0), segments=40, parent=root)
    k.lathe("Coupling", [(0.6, 0), (0.6, 0.4), (0.0, 0.4)], (1.0, 0, 2.0), "Blue", rot=(0, 90, 0), parent=root)
    k.box("Generator", (2.2, 2.6, 2.6), (2.4, 0, 1.7), "Blue", bevel=0.14, segments=3, parent=root)
    louvers(k, "GenLouver", 1.6, 1.2, (2.4, -1.3, 1.5), -1, "BlueDark", root)
    k.lathe("Intake", [(0.0, 0.0), (0.7, 0.0), (0.75, 0.1), (0.75, 1.2), (0.0, 1.2)], (-4.2, 0, 2.0), "MetalDark",
            rot=(0, 90, 0), parent=root)
    for i in range(6):
        k.lathe(f"Filter{i}", [(0.76, 0), (0.8, 0.02), (0.8, 0.06), (0.76, 0.08)], (-4.1 + i * 0.18, 0, 2.0),
                "Steel", rot=(0, 90, 0), parent=root)
    for x in (-2.6, 0.6):
        for y in (-0.9, 0.9):
            k.box(f"Mount{x}{y}", (0.4, 0.4, 0.9), (x, y, 0.85), "MetalDark", bevel=0.05, parent=root)
    k.tube("Duct", [(-1.5, 0.9, 3.0), (-1.5, 1.8, 3.2), (-1.5, 1.8, 3.4)], 0.3, "Steel", parent=root)
    stack(k, "Stack", -1.5, 1.8, 3.3, 2.8, 0.32, root)
    k.box("Label", (2.0, 0.06, 0.6), (2.4, -1.33, 2.5), "White", bevel=0.02, parent=root)
    k.text("LabelText", "250 kW", 0.34, (2.4, -1.38, 2.5), "Blue", extrude=0.015, parent=root, max_width=1.8)
    for x in (-3.3, 3.3):
        k.box(f"Rail{x}", (0.08, 6.0, 0.08), (x, 0, 1.2), "Yellow", bevel=0.02, parent=root)
        for y in (-2.8, 0, 2.8):
            k.box(f"RailPost{x}{y}", (0.08, 0.08, 1.0), (x, y, 0.7), "Yellow", bevel=0.02, parent=root)


# ----------------------------------------------------------------------
# Солнечный трекер и большой ветряк
# ----------------------------------------------------------------------
def solar_mono(k, root):
    k.lathe("Footing", [(0.75, 0), (0.75, 0.4), (0.6, 0.45), (0.0, 0.45)], (0, 0, 0), "Concrete", parent=root)
    k.lathe("Mast", [(0.2, 0), (0.17, 2.0), (0.0, 2.0)], (0, 0, 0.45), "Steel", segments=16, parent=root)
    array = k.empty("Array", (0, 0, 2.5), root)
    k.lathe("Gearbox", [(0.28, -0.1), (0.3, 0.1), (0.0, 0.2)], (0, 0, -0.1), "MetalDark", parent=array)
    k.box("TorqueTube", (4.0, 0.16, 0.16), (0, 0, 0.12), "Steel", bevel=0.03, rot=(25, 0, 0), parent=array)
    for x in (-1.0, 1.0):
        for y in (-0.85, 0.85):
            solar_panel(k, f"Panel{x}{y}", 1.9, 1.6, (x, y * math.cos(math.radians(25)),
                                                       0.2 + y * math.sin(math.radians(25))), 25, array)
    k.tag(array, k.swing(array, "Z", degrees=20, cycles=1))


def wind50(k, root):
    k.lathe("Foundation", [(1.5, 0), (1.5, 0.4), (1.2, 0.5), (0.0, 0.5)], (0, 0, 0), "Concrete", segments=32,
            parent=root)
    k.lathe("Tower", [(0.48, 0), (0.42, 8.0), (0.32, 17.2), (0.0, 17.2)], (0, 0, 0.5), "White", segments=24,
            parent=root)
    k.box("DoorPanel", (0.5, 0.06, 1.0), (0, -0.46, 1.1), "Grey", bevel=0.03, parent=root)
    nacelle = [(0.0, 0.0), (0.35, 0.05), (0.6, 0.3), (0.7, 0.9), (0.7, 2.4), (0.62, 2.9), (0.0, 3.0)]
    k.lathe("Nacelle", nacelle, (0, 1.4, 17.9), "White", rot=(90, 0, 0), segments=28, parent=root, sharp=70)
    k.lathe("Yaw", [(0.45, 0), (0.45, 0.3), (0.0, 0.3)], (0, 0, 17.6), "MetalDark", parent=root)
    blink = k.lathe("Blink", [(0.12, 0), (0.12, 0.08), (0.09, 0.2), (0.0, 0.24)], (0, 0.9, 18.6), "NeonRed",
                    parent=root)
    k.tag(blink, "pulse_1")
    k.box("Anemometer", (0.04, 0.04, 0.5), (0, 1.1, 18.85), "Grey", bevel=0.0, parent=root)
    rotor = k.empty("Rotor", (0, -1.8, 17.9), root)
    k.lathe("Spinner", [(0.62, 0), (0.62, 0.1), (0.55, 0.45), (0.35, 0.85), (0.15, 1.05), (0.0, 1.1)], (0, 0.2, 0),
            "White", rot=(90, 0, 0), segments=28, parent=rotor, sharp=80)
    for i in range(3):
        k.airfoil(f"Blade{i}", 7.3, 1.1, 0.3, 18, "White", rotor, t0=0.0, t1=0.9, hub=0.5, thick=0.14, angle=i * 120,
                  sections=10)
        k.airfoil(f"BladeTip{i}", 7.3, 1.1, 0.3, 18, "Red", rotor, t0=0.9, t1=1.0, hub=0.5, thick=0.14,
                  angle=i * 120, sections=2)
    k.tag(rotor, k.spin(rotor, "Y", turns=0.39))


# ----------------------------------------------------------------------
# Геотермальная станция и подстанция
# ----------------------------------------------------------------------
def wellhead(k, name, x, y, key, parent):
    k.lathe(name + "Base", [(0.45, 0), (0.45, 0.2), (0.3, 0.3), (0.0, 0.3)], (x, y, 0.3), "MetalDark", parent=parent)
    k.lathe(name + "Body", [(0.2, 0), (0.2, 1.1), (0.0, 1.1)], (x, y, 0.55), "Steel", segments=16, parent=parent)
    for z in (0.75, 1.25):
        k.lathe(f"{name}Flange{z}", [(0.3, 0), (0.3, 0.1), (0.0, 0.1)], (x, y, z), "MetalDark", parent=parent)
        k.torus(f"{name}Wheel{z}", 0.22, 0.035, (x + 0.35, y, z + 0.05), key, rot=(0, 90, 0), parent=parent)


def geothermal(k, root):
    k.box("Pad", (5.6, 5.6, 0.3), (0, 0, 0.15), "Concrete", bevel=0.05, parent=root)
    k.box("House", (3.4, 3.0, 3.2), (-0.8, 0.8, 1.9), "White", bevel=0.1, parent=root)
    k.box("RoofBand", (3.6, 3.2, 0.3), (-0.8, 0.8, 3.65), "Red", bevel=0.06, parent=root)
    louvers(k, "HouseLouver", 1.6, 0.8, (-1.4, -0.7, 2.4), -1, "MetalDark", root)
    k.box("Door", (0.9, 0.05, 1.9), (0.2, -0.72, 1.25), "Grey", bevel=0.03, parent=root)
    plate_text(k, "Label", "GEOTHERMAL 300 kW", 2.6, 0.5, (-0.8, -0.73, 3.05), "White", "Red", root, size=0.26)
    for i, x in enumerate((1.4, 2.2)):
        key = "Red" if i == 0 else "Blue"
        wellhead(k, f"Well{i}", x, -1.8, key, root)
        k.tube(f"Pipe{i}", [(x, -1.8, 1.65), (x, -1.8, 2.6), (x, -0.3, 2.6), (0.9, 0.0, 2.6)], 0.2, key, parent=root,
               smooth_path=False)
        for t in (0.3, 0.7):
            k.torus(f"PipeBand{i}{t}", 0.21, 0.03, (x, -1.8 + 1.5 * t, 2.6), "MetalDark", rot=(90, 0, 0), parent=root)
    stack(k, "Vent", -1.8, 1.6, 3.8, 0.9, 0.35, root, key="Steel")


def insulator(k, name, loc, parent, sheds=4):
    prof = [(0.1, 0.0)]
    for i in range(sheds):
        z = 0.06 + i * 0.16
        prof += [(0.1, z), (0.22, z + 0.03), (0.2, z + 0.06), (0.1, z + 0.1)]
    prof += [(0.08, 0.06 + sheds * 0.16), (0.0, 0.08 + sheds * 0.16)]
    k.lathe(name, prof, loc, "White", segments=16, parent=parent, sharp=50)


def substation(k, root):
    k.box("Pad", (6.0, 5.0, 0.3), (0, 0, 0.15), "Concrete", bevel=0.05, parent=root)
    k.box("Gravel", (5.6, 4.6, 0.06), (0, 0, 0.32), "StoneDark", bevel=0.01, parent=root)
    for x in (-1.5, 1.5):
        k.box(f"Tank{x}", (2.0, 1.8, 2.2), (x, 0.5, 1.45), "MetalDark", bevel=0.08, parent=root)
        for f in range(7):
            k.box(f"Fin{x}{f}", (0.06, 0.5, 1.8), (x - 0.9 + f * 0.3, -0.62, 1.4), "Grey", bevel=0.02, parent=root)
        k.box(f"Lid{x}", (2.1, 1.9, 0.12), (x, 0.5, 2.6), "Grey", bevel=0.04, parent=root)
        for i, dx in enumerate((-0.6, 0.0, 0.6)):
            insulator(k, f"Bushing{x}{i}", (x + dx, 0.5, 2.66), root)
            k.lathe(f"Terminal{x}{i}", [(0.05, 0), (0.05, 0.15), (0.0, 0.15)], (x + dx, 0.5, 3.4), "Copper",
                    segments=8, parent=root)
        k.box(f"Plate{x}", (0.6, 0.04, 0.4), (x, -0.42, 1.9), "White", bevel=0.01, parent=root)
    k.tube("Busbar", [(-2.1, 0.5, 3.55), (2.1, 0.5, 3.55)], 0.05, "Copper", parent=root, smooth_path=False)
    for x in (-2.1, 2.1):
        k.lathe(f"BusPost{x}", [(0.12, 0), (0.1, 3.55), (0.0, 3.55)], (x, 0.5, 0.3), "Grey", segments=12, parent=root)
    # сетчатое ограждение по бокам и фасаду с калиткой
    def fence(name, a, b, height=2.0):
        a, b = Vector(a), Vector(b)
        n = max(1, round((b - a).length / 1.2))
        for i in range(n + 1):
            p = a + (b - a) * (i / n)
            k.box(f"{name}Post{i}", (0.08, 0.08, height), (p.x, p.y, 0.3 + height / 2), "Grey", bevel=0.02,
                  parent=root)
        d = (b - a)
        length = d.length
        mid = (a + b) / 2
        yaw = math.degrees(math.atan2(d.y, d.x))
        for z in (0.45, 1.3, 2.25):
            k.box(f"{name}Rail{z}", (length, 0.05, 0.05), (mid.x, mid.y, z), "Grey", bevel=0.01, rot=(0, 0, yaw),
                  parent=root)
        rows = int(height / 0.25)
        for r in range(rows):
            k.box(f"{name}Wire{r}", (length, 0.015, 0.015), (mid.x, mid.y, 0.4 + r * 0.25), "Steel", bevel=0.0,
                  rot=(0, 0, yaw), parent=root)
    fence("FenceL", (-2.9, 2.4, 0), (-2.9, -2.4, 0))
    fence("FenceR", (2.9, 2.4, 0), (2.9, -2.4, 0))
    fence("FenceF1", (-2.9, -2.4, 0), (-0.8, -2.4, 0))
    fence("FenceF2", (0.8, -2.4, 0), (2.9, -2.4, 0))
    sign = k.empty("Sign", (0, -2.42, 1.4), root)
    k.box("SignPlate", (1.4, 0.04, 1.0), (0, 0, 0), "Yellow", bevel=0.03, parent=sign)
    k.prism("Bolt", [(-0.1, 0.3), (0.12, 0.3), (0.0, 0.05), (0.15, 0.05), (-0.12, -0.32), (-0.02, -0.04),
                     (-0.16, -0.04)], 0.03, (-0.35, -0.03, 0.05), "Black", parent=sign, bevel=0.0)
    k.text("SignText", "DANGER", 0.22, (0.2, -0.03, -0.25), "Black", extrude=0.01, parent=sign, max_width=0.8)


# ----------------------------------------------------------------------
# Накопители энергии
# ----------------------------------------------------------------------
def battery(k, root):
    k.box("Pad", (4.0, 4.0, 0.3), (0, 0, 0.15), "Concrete", bevel=0.05, parent=root)
    for x in (-1, 1):
        k.box(f"Cabinet{x}", (1.6, 3.4, 2.6), (x, 0, 1.6), "White", bevel=0.12, segments=3, parent=root)
        k.box(f"Plinth{x}", (1.5, 3.3, 0.15), (x, 0, 0.36), "MetalDark", bevel=0.03, parent=root)
        for i, y in enumerate((-1.2, -0.6, 0.0, 0.6, 1.2)):
            led = k.box(f"Led{x}{i}", (0.05, 0.32, 0.12), (x * 1.81, y, 2.4), "NeonGreen", bevel=0.01, parent=root)
            k.tag(led, f"pulse_{1 + i * 0.4:g}")
            louvers_x(k, f"Vent{x}{i}", 0.4, 0.5, (x * 1.8, y, 1.2), x, "Grey", root, step=0.12, depth=0.05)
    k.box("CableTray", (2.4, 0.3, 0.1), (0, 1.3, 2.95), "Grey", bevel=0.02, parent=root)
    k.box("Sign", (1.8, 0.06, 0.5), (0, -1.73, 3.1), "White", bevel=0.02, parent=root)
    k.text("SignText", "50 kWh", 0.28, (0, -1.78, 3.1), "Green", extrude=0.015, parent=root, max_width=1.6)
    k.lathe("Bolt", [(0.18, 0), (0.18, 0.04), (0.0, 0.04)], (0, -1.74, 2.6), "Yellow", rot=(90, 0, 0), parent=root)


def megapack(k, root):
    k.box("Pad", (6.0, 3.8, 0.3), (0, 0, 0.15), "Concrete", bevel=0.05, parent=root)
    k.box("Body", (5.8, 3.2, 2.8), (0, 0, 1.7), "White", bevel=0.14, segments=3, parent=root)
    for i in range(6):
        x = -2.42 + i * 0.97
        k.box(f"Seam{i}", (0.03, 3.22, 2.5), (x + 0.485, 0, 1.7), "Grey", bevel=0.0, parent=root)
        k.box(f"Handle{i}", (0.05, 0.06, 0.3), (x + 0.75, -1.62, 1.6), "Grey", bevel=0.02, parent=root)
    k.text("Logo", "MEGAPACK", 0.42, (0, -1.63, 2.45), "Red", extrude=0.02, parent=root, max_width=3.2, logo=True)
    led = k.box("Strip", (5.0, 0.04, 0.08), (0, -1.62, 3.0), "NeonCyan", bevel=0.01, parent=root)
    k.tag(led, "pulse_0.7")
    for x in (-1.8, 0.0, 1.8):
        k.box(f"RoofUnit{x}", (1.2, 1.4, 0.35), (x, 0.3, 3.27), "Grey", bevel=0.08, parent=root)
        k.lathe(f"Fan{x}", [(0.45, 0), (0.45, 0.03), (0.0, 0.03)], (x, 0.3, 3.45), "MetalDark", parent=root)


# ----------------------------------------------------------------------
# Реакторы
# ----------------------------------------------------------------------
def potato_reactor(k, root):
    k.lathe("Base", [(2.2, 0), (2.2, 0.35), (2.0, 0.6), (0.0, 0.6)], (0, 0, 0), "MetalDark", segments=40, parent=root)
    k.lathe("Glass", [(1.8, 0.0), (1.8, 3.6), (1.7, 3.6), (1.7, 0.0)], (0, 0, 0.6), "Glass", segments=40, parent=root)
    k.lathe("Fluid", [(0.0, 0.0), (1.68, 0.0), (1.68, 0.5), (0.0, 0.5)], (0, 0, 0.62), "NeonGreen", segments=40,
            parent=root)
    tuber = k.empty("Tuber", (0, 0, 2.4), root)
    k.potato("Potato", (0, 0, 0), 2.6, parent=tuber, seed=33, rot=(0, 20, 30))
    k.tag(tuber, k.bob(tuber, amplitude=0.3, cycles=1))
    for i in range(6):
        a = i / 6 * math.tau
        bubble = k.lathe(f"Bubble{i}", [(0.0, -0.1), (0.09, -0.06), (0.1, 0.0), (0.07, 0.07), (0.0, 0.1)],
                         (math.cos(a) * 1.3, math.sin(a) * 1.3, 1.3 + (i % 3) * 0.6), "NeonGreen", segments=10,
                         parent=root)
        k.tag(bubble, f"pulse_{1 + (i % 3) * 0.5:g}")
    k.lathe("Cap", [(2.1, 0), (2.1, 0.3), (1.6, 0.5), (0.5, 0.6), (0.0, 0.6)], (0, 0, 4.2), "MetalDark", segments=40,
            parent=root)
    for x in (-0.9, 0.9):
        k.lathe(f"Electrode{x}", [(0.12, 0), (0.12, 2.0), (0.0, 2.1)], (x, 0, 2.2), "Copper", rot=(180, 0, 0),
                segments=12, parent=root)
        k.tube(f"Cable{x}", [(x, 0, 4.8), (x * 1.3, 0, 5.3), (x * 1.9, 0.8, 4.6), (x * 2.2, 1.0, 0.5)], 0.06,
               "Black", parent=root)
    for i in range(4):
        a = i / 4 * math.tau + math.pi / 4
        k.lathe(f"Rib{i}", [(0.1, 0), (0.1, 3.6), (0.0, 3.6)], (math.cos(a) * 1.86, math.sin(a) * 1.86, 0.6),
                "MetalDark", segments=8, parent=root)


def fusion(k, root):
    k.box("Base", (6.0, 6.0, 0.4), (0, 0, 0.2), "MetalDark", bevel=0.08, parent=root)
    k.lathe("Pedestal", [(1.0, 0), (1.0, 0.3), (0.8, 2.0), (0.0, 2.0)], (0, 0, 0.4), "Steel", segments=32,
            parent=root)
    k.torus("Vessel", 2.2, 0.7, (0, 0, 3.2), "Chrome", parent=root, seg=48, ring=20)
    ring = k.empty("Torus", (0, 0, 3.2), root)
    for i in range(12):
        a = i / 12 * math.tau
        coil = k.box(f"Coil{i}", (0.5, 1.9, 1.9), (math.cos(a) * 2.2, math.sin(a) * 2.2, 0), "Copper", bevel=0.2,
                     segments=3, rot=(0, 0, math.degrees(a)), parent=ring)
        del coil
    for i in range(8):
        a = (i + 0.5) / 8 * math.tau
        k.box(f"Glow{i}", (0.25, 0.25, 1.0), (math.cos(a) * 2.95, math.sin(a) * 2.95, 0), "NeonOrange", bevel=0.05,
              rot=(0, 0, math.degrees(a)), parent=ring)
    k.tag(ring, k.spin(ring, "Z", turns=0.22))
    plasma = k.lathe("Plasma", [(0.0, -0.75), (0.5, -0.6), (0.75, 0.0), (0.5, 0.6), (0.0, 0.75)], (0, 0, 3.2),
                     "NeonPurple", segments=24, parent=root)
    k.tag(plasma, "pulse_3")
    for i in range(4):
        a = i / 4 * math.tau + math.pi / 4
        k.box(f"Leg{i}", (0.4, 0.4, 2.6), (math.cos(a) * 2.2, math.sin(a) * 2.2, 1.5), "MetalDark", bevel=0.06,
              parent=root)


# ----------------------------------------------------------------------
# Офис менеджера и станция дронов (сюда игроки заходят — стены отдельными деталями)
# ----------------------------------------------------------------------
def office(k, root):
    k.box("Floor", (7.0, 6.0, 0.3), (0, 0, 0.15), "Concrete", bevel=0.04, parent=root)
    k.box("FloorTiles", (6.4, 5.4, 0.04), (0, 0, 0.31), "StoneLight", bevel=0.0, parent=root)
    walls = [
        ("WallBack", (7.0, 0.3, 4.0), (0, 2.85, 2.15)),
        ("WallLeft", (0.3, 6.0, 4.0), (-3.35, 0, 2.15)),
        ("WallRight", (0.3, 6.0, 4.0), (3.35, 0, 2.15)),
        ("WallFrontL", (2.5, 0.3, 4.0), (-2.25, -2.85, 2.15)),
        ("WallFrontR1", (2.6, 0.3, 1.2), (2.2, -2.85, 0.75)),
        ("WallFrontR2", (2.6, 0.3, 1.2), (2.2, -2.85, 3.55)),
        ("WallOverDoor", (2.0, 0.3, 1.0), (-0.1, -2.85, 3.65)),
    ]
    for name, size, loc in walls:
        k.solo(k.box(name, size, loc, "White", bevel=0.04, parent=root))
    k.box("Window", (2.6, 0.1, 1.6), (2.2, -2.85, 2.15), "Glass", bevel=0.0, parent=root)
    for x in (1.3, 2.2, 3.1):
        k.box(f"Mullion{x}", (0.06, 0.16, 1.6), (x, -2.85, 2.15), "MetalDark", bevel=0.01, parent=root)
    k.box("DoorFrame", (2.1, 0.36, 0.12), (-0.1, -2.85, 3.1), "MetalDark", bevel=0.02, parent=root)
    k.solo(k.box("Roof", (7.4, 6.4, 0.3), (0, 0, 4.3), "MetalDark", bevel=0.06, parent=root))
    k.box("Canopy", (2.6, 1.2, 0.12), (-0.1, -3.5, 3.4), "Blue", bevel=0.04, rot=(-6, 0, 0), parent=root)
    sign = k.empty("Sign", (0, -3.0, 4.85), root)
    k.box("SignBox", (3.0, 0.2, 0.8), (0, 0, 0), "Blue", bevel=0.06, parent=sign)
    k.text("SignText", "OFFICE", 0.5, (0, -0.12, 0), "White", extrude=0.03, parent=sign, max_width=2.6)
    # интерьер
    k.box("Desk", (2.6, 1.2, 0.12), (0.6, 1.6, 1.1), "WoodDark", bevel=0.03, parent=root)
    for x in (-0.6, 1.8):
        k.box(f"DeskLeg{x}", (0.12, 1.1, 0.95), (x, 1.6, 0.6), "WoodDark", bevel=0.02, parent=root)
    k.box("Monitor", (1.4, 0.08, 0.8), (0.6, 2.05, 1.65), "Black", bevel=0.03, parent=root)
    k.box("MonitorScreen", (1.3, 0.02, 0.7), (0.6, 2.0, 1.65), "NeonGreen", bevel=0.0, parent=root)
    k.text("MonitorText", "MARKET", 0.2, (0.6, 1.98, 1.65), "Black", extrude=0.005, parent=root, max_width=1.0)
    k.box("ChairSeat", (0.8, 0.8, 0.14), (0.6, 0.5, 0.75), "Black", bevel=0.06, parent=root)
    k.box("ChairBack", (0.8, 0.14, 0.9), (0.6, 0.12, 1.25), "Black", bevel=0.06, parent=root)
    k.lathe("ChairStem", [(0.06, 0), (0.06, 0.4), (0.0, 0.4)], (0.6, 0.5, 0.3), "Chrome", parent=root)
    k.lathe("CoolerBase", [(0.3, 0), (0.3, 1.25), (0.0, 1.25)], (-2.6, 2.2, 0.32), "White", parent=root)
    k.lathe("CoolerBottle", [(0.0, 0.0), (0.26, 0.05), (0.27, 0.5), (0.12, 0.65), (0.0, 0.65)], (-2.6, 2.2, 1.57),
            "Water", parent=root)
    k.box("Cabinet", (1.0, 0.7, 2.4), (2.6, 2.3, 1.5), "Grey", bevel=0.05, parent=root)
    k.lathe("Plant", [(0.2, 0), (0.25, 0.4), (0.0, 0.4)], (-2.7, -2.2, 0.32), "Red", parent=root)


def drone_station(k, root):
    k.box("Pad", (8.0, 6.0, 0.3), (0, 0, 0.15), "MetalDark", bevel=0.05, parent=root)
    k.box("Asphalt", (7.6, 5.6, 0.04), (0, 0, 0.31), "Black", bevel=0.0, parent=root)
    # арочный ангар вдоль Y
    hx, hy = -1.6, 0.8
    # оболочка строится вокруг локальной Z, поворот (90, 0, 0) кладёт её вдоль Y: локальная z = -y мира
    k.solo(k.shell("Hangar", 2.5, -(hy + 2.0), -(hy - 2.0), 0, 180, (hx, 0, 0.3), "Grey", parent=root,
                   thickness=0.08, rows=1, cols=24, rot=(90, 0, 0)))
    for i in range(5):
        y = hy - 2.0 + i
        k.shell(f"Rib{i}", 2.58, -y - 0.06, -y + 0.06, 0, 180, (hx, 0, 0.3), "MetalDark", parent=root,
                thickness=0.06, rows=1, cols=24, rot=(90, 0, 0))
    verts = [(0, 0, 0)] + [(2.5 * math.cos(math.pi * i / 16), 0, 2.5 * math.sin(math.pi * i / 16)) for i in range(17)]
    faces = [[0, i + 2, i + 1] for i in range(16)]
    back = k.mesh_from("HangarBack", verts, faces, (hx, hy + 2.0, 0.3), "Grey", parent=root)
    back.modifiers.new("Solid", "SOLIDIFY").thickness = 0.06
    k.box("Doorway", (3.0, 0.06, 2.2), (hx, hy - 2.02, 1.4), "Black", bevel=0.02, parent=root)
    sign = k.empty("Sign", (hx, -1.25, 3.2), root)
    k.box("SignBox", (3.2, 0.12, 0.7), (0, 0, 0), "White", bevel=0.05, parent=sign)
    k.text("SignText", "DRONES", 0.42, (0, -0.08, 0), "Blue", extrude=0.02, parent=sign, max_width=2.8)
    for x in (-1.0, 1.0):
        k.tube(f"SignPole{x}", [(hx + x, -1.25, 2.4), (hx + x, -1.25, 2.85)], 0.04, "MetalDark", parent=root,
               smooth_path=False)
    # посадочные площадки
    for i, y in enumerate((1.6, -1.4)):
        k.lathe(f"Landing{i}", [(1.2, 0), (1.2, 0.12), (0.0, 0.12)], (2.6, y, 0.3), "Yellow", segments=32,
                parent=root)
        k.text(f"H{i}", "H", 0.9, (2.6, y, 0.43), "Black", rot=(0, 0, 0), extrude=0.01, parent=root, logo=True)
        ring = k.torus(f"Ring{i}", 1.3, 0.04, (2.6, y, 0.33), "NeonCyan", parent=root, seg=48, ring=8)
        k.tag(ring, f"pulse_{1 + i * 0.5:g}")
    # ветроуказатель
    k.lathe("WindsockPole", [(0.05, 0), (0.04, 2.6), (0.0, 2.6)], (3.6, 2.7, 0.3), "Grey", segments=8, parent=root)
    sock = k.empty("Windsock", (3.6, 2.7, 2.8), root)
    k.lathe("Sock", [(0.18, 0), (0.14, 0.5), (0.1, 1.0), (0.07, 1.3)], (0, 0, 0), "Orange", rot=(0, 80, 0),
            segments=16, parent=sock)
    k.tag(sock, k.swing(sock, "Z", degrees=15, cycles=1))
    k.box("Antenna", (0.06, 0.06, 1.2), (hx + 1.6, hy + 1.2, 3.0), "Grey", bevel=0.0, parent=root)
    tip = k.lens("AntennaTip", 0.06, (hx + 1.6, hy + 1.2, 3.6), "NeonRed", parent=root)
    k.tag(tip, "pulse_1")


# ----------------------------------------------------------------------
# ИИ-сортировщик, градирня, рубильник
# ----------------------------------------------------------------------
def ai_sorter(k, root):
    k.box("Base", (4.0, 4.0, 0.3), (0, 0, 0.15), "MetalDark", bevel=0.05, parent=root)
    k.box("Housing", (2.8, 2.0, 1.8), (0, 0.6, 1.2), "White", bevel=0.2, segments=3, parent=root)
    k.box("Belt", (3.6, 0.8, 0.12), (0, -0.85, 0.75), "Rubber", bevel=0.03, parent=root)
    k.box("BeltFrame", (3.7, 0.9, 0.2), (0, -0.85, 0.64), "Steel", bevel=0.03, parent=root)
    for x in (-1.6, 1.6):
        k.box(f"BeltLeg{x}", (0.12, 0.6, 0.5), (x, -0.85, 0.4), "Steel", bevel=0.02, parent=root)
    for i in range(4):
        k.potato(f"OnBelt{i}", (-1.2 + i * 0.75, -0.85, 0.92), 0.4, parent=root, seed=60 + i, low=True)
    # «глаз» камеры
    k.lathe("EyeMount", [(0.5, 0), (0.5, 0.15), (0.0, 0.15)], (0, -0.4, 2.1), "MetalDark", rot=(90, 0, 0),
            parent=root)
    k.lathe("Eye", [(0.0, 0.0), (0.42, 0.0), (0.45, 0.15), (0.36, 0.35), (0.0, 0.42)], (0, -0.5, 2.1), "Black",
            rot=(90, 0, 0), parent=root)
    lens = k.lens("Lens", 0.18, (0, -0.9, 2.1), "NeonRed", rot=(90, 0, 0), parent=root, height=0.6)
    k.tag(lens, "pulse_2")
    k.text("Label", "AI QC", 0.3, (0, -0.42, 1.0), "NeonCyan", extrude=0.015, parent=root, max_width=1.6)
    # манипулятор
    arm = k.empty("Arm", (1.2, 0.2, 2.1), root)
    k.lathe("ArmBase", [(0.3, 0), (0.3, 0.25), (0.0, 0.25)], (0, 0, 0), "MetalDark", parent=arm)
    k.box("ArmUpper", (0.26, 0.26, 1.2), (0, 0, 0.8), "Orange", bevel=0.08, parent=arm)
    k.lathe("Elbow", [(0.0, -0.18), (0.16, -0.16), (0.2, 0.0), (0.16, 0.16), (0.0, 0.18)], (0, 0, 1.45),
            "MetalDark", rot=(90, 0, 0), parent=arm)
    k.box("ArmFore", (1.2, 0.22, 0.22), (-0.55, 0, 1.45), "Orange", bevel=0.07, parent=arm)
    for y in (-0.1, 0.1):
        k.box(f"Finger{y}", (0.06, 0.05, 0.35), (-1.15, y, 1.25), "Chrome", bevel=0.02, parent=arm)
    k.tag(arm, k.swing(arm, "Z", degrees=50, cycles=1))
    # контейнеры: годные / отходы
    for i, key in enumerate(("Green", "WoodDark")):
        x = -0.7 + i * 1.3
        k.lathe(f"Bin{i}", [(0.0, 0.0), (0.45, 0.0), (0.55, 0.8), (0.58, 0.85), (0.5, 0.85), (0.42, 0.08),
                            (0.0, 0.08)], (x, -1.75, 0.3), key, segments=4, rot=(0, 0, 45), parent=root, sharp=30)


def cooling_tower(k, root):
    def radius(t):
        # гиперболоид: широкое основание, «талия» на 72% высоты, лёгкий раструб наверху
        if t <= 0.72:
            return 1.5 + 0.85 * ((0.72 - t) / 0.72) ** 2
        return 1.5 + 0.25 * ((t - 0.72) / 0.28) ** 2

    h0, h = 0.6, 6.4
    prof = [(radius(i / 16), h0 + h * i / 16) for i in range(17)]
    inner = [(r - 0.12, z) for r, z in reversed(prof)]
    k.lathe("Shell", prof + inner, (0, 0, 0), "Concrete", segments=48, parent=root, sharp=40)
    rt = radius(1.0)
    k.lathe("Band", [(radius(0.92) + 0.015, 0), (radius(0.96) + 0.02, 0.25), (rt + 0.02, 0.5)],
            (0, 0, h0 + h * 0.92), "Red", segments=48, parent=root)
    for i in range(16):
        a = i / 16 * math.tau
        b = a + math.tau / 16
        r0 = 2.3
        k.tube(f"Column{i}", [(math.cos(a) * r0, math.sin(a) * r0, 0.0), (math.cos(b) * r0, math.sin(b) * r0, 0.65)],
               0.07, "Concrete", parent=root, smooth_path=False)
    k.lathe("Basin", [(2.45, 0), (2.45, 0.25), (2.3, 0.25), (2.3, 0.1), (0.0, 0.1)], (0, 0, 0), "StoneDark",
            segments=48, parent=root)
    k.lathe("Water", [(2.28, 0), (2.28, 0.02), (0.0, 0.02)], (0, 0, 0.18), "Water", segments=48, parent=root)


def breaker(k, root):
    k.box("Pad", (3.0, 2.0, 0.12), (0, 0, 0.06), "Concrete", bevel=0.03, parent=root)
    k.box("SwitchBox", (1.6, 0.8, 2.6), (-0.6, 0.4, 1.4), "Grey", bevel=0.08, parent=root)
    k.box("SwitchDoor", (1.4, 0.04, 2.3), (-0.6, -0.01, 1.4), "Steel", bevel=0.03, parent=root)
    k.box("Warning", (1.2, 0.02, 0.3), (-0.6, -0.04, 2.25), "Yellow", bevel=0.01, parent=root)
    k.text("WarningText", "380 V", 0.16, (-0.6, -0.06, 2.25), "Black", extrude=0.005, parent=root, max_width=1.0)
    lever = k.empty("Lever", (-0.6, -0.1, 1.45), root)
    k.lathe("Pivot", [(0.12, 0), (0.12, 0.15), (0.0, 0.15)], (0, 0, 0), "MetalDark", rot=(90, 0, 0), parent=lever)
    k.box("Arm", (0.12, 0.12, 0.8), (0, -0.12, 0.35), "MetalDark", bevel=0.03, rot=(-15, 0, 0), parent=lever)
    k.lathe("Grip", [(0.0, -0.25), (0.1, -0.22), (0.11, 0.22), (0.0, 0.25)], (0, -0.24, 0.78), "Red",
            rot=(0, 90, 0), parent=lever)
    k.box("Cabinet", (1.0, 0.6, 1.8), (0.8, 0.5, 1.02), "BlueDark", bevel=0.06, parent=root)
    k.box("CabinetDoor", (0.84, 0.03, 1.6), (0.8, 0.19, 1.02), "Blue", bevel=0.02, parent=root)
    for i in range(3):
        led = k.lens(f"Led{i}", 0.05, (0.55 + i * 0.25, 0.16, 1.55), "NeonRed" if i == 2 else "NeonGreen",
                     rot=(90, 0, 0), parent=root)
        k.tag(led, f"pulse_{1 + i}")
    for x in (-0.9, -0.3, 0.6, 1.0):
        k.tube(f"Conduit{x}", [(x, 0.6, 0.0), (x, 0.6, 0.2 if x > 0 else 0.15)], 0.06, "Grey", parent=root,
               smooth_path=False)
