"""Завод: корпус цеха 78x19 и модули-множители 6x5 (мойка, пилер, фритюр, специи, пюре, упаковка, крио,
сублимация, автоклав, крахмал, биореактор, экструдер) и квантовый преобразователь.

Точка Roblox (x, y, z) здесь пишется как (x, -z, y).
"""

import math
import random

from mathutils import Vector

from .agro import auger_blade
from .energy2 import louvers, stack


# ----------------------------------------------------------------------
# Общая станина модуля 6x5: плита, ножки, корпус, пульт, табличка с множителем
# ----------------------------------------------------------------------
def machine(k, root, body_key, accent_key, h=1.2, label=None, label_key="NeonYellow", w=6.0, d=5.0):
    k.box("Plinth", (w, d, 0.4), (0, 0, 0.2), "Plate", bevel=0.06, parent=root)
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * (w / 2 - 0.5), sy * (d / 2 - 0.5)
            k.box(f"Leg{sx}{sy}", (0.36, 0.36, 1.0), (x, y, 0.9), "MetalDark", bevel=0.05, parent=root)
            k.lathe(f"LegFoot{sx}{sy}", [(0.26, 0), (0.26, 0.06), (0.18, 0.1), (0.0, 0.1)], (x, y, 0.4), "Rubber",
                    parent=root)
    k.box("Frame", (w - 0.4, d - 0.6, 0.22), (0, 0.1, 1.38), "MetalDark", bevel=0.05, parent=root)
    k.box("Body", (w - 0.6, d - 1.2, h), (0, 0.2, 1.48 + h / 2), body_key, bevel=0.14, segments=3, parent=root)
    k.box("TopRim", (w - 0.4, d - 1.0, 0.22), (0, 0.2, 1.48 + h + 0.1), accent_key, bevel=0.07, parent=root)
    front = 0.2 - (d - 1.2) / 2
    k.box("Hazard", (w - 0.8, 0.05, 0.26), (0, front - 0.02, 1.75), "Yellow", bevel=0.01, parent=root)
    for i in range(14):
        x = -(w - 1.0) / 2 + i * (w - 1.0) / 13
        k.box(f"Chevron{i}", (0.09, 0.06, 0.3), (x, front - 0.04, 1.75), "Black", bevel=0.0, rot=(0, 35, 0),
              parent=root)
    # пульт справа спереди
    px, py = w / 2 - 1.0, -(d / 2 - 0.45)
    k.box("ConsolePost", (0.2, 0.2, 1.4), (px, py + 0.1, 1.1), "MetalDark", bevel=0.04, parent=root)
    console = k.empty("Console", (px, py, 2.3), root, rot=(-20, 0, 0))
    k.box("ConsoleBox", (1.2, 0.3, 0.9), (0, 0, 0), "Black", bevel=0.08, parent=console)
    k.box("ConsoleScreen", (0.8, 0.04, 0.35), (0, -0.16, 0.15), "NeonGreen", bevel=0.01, parent=console)
    for i, key in enumerate(("NeonGreen", "NeonRed")):
        k.lens(f"Button{i}", 0.06, (-0.3 + i * 0.6, -0.15, -0.22), key, rot=(90, 0, 0), parent=console)
    k.lathe("EStop", [(0.06, 0), (0.06, 0.06), (0.11, 0.07), (0.1, 0.11), (0.0, 0.12)], (0, -0.15, -0.22), "Red",
            rot=(90, 0, 0), parent=console)
    if label:
        k.box("Sign", (3.2, 0.08, 0.6), (-0.8, front - 0.08, 2.6), "Black", bevel=0.03, parent=root)
        k.text("SignText", label, 0.3, (-0.8, front - 0.13, 2.6), label_key, extrude=0.015, parent=root,
               max_width=2.9)
    return 1.48 + h + 0.21


def drum_body(k, name, length, radius, loc, key, parent, ring_key=None, rings=3, segments=32):
    """Горизонтальный барабан вдоль X с закруглёнными торцами."""
    prof = [(0.0, -length / 2), (radius * 0.75, -length / 2), (radius * 0.97, -length / 2 + 0.1),
            (radius, -length / 2 + 0.25), (radius, length / 2 - 0.25), (radius * 0.97, length / 2 - 0.1),
            (radius * 0.75, length / 2), (0.0, length / 2)]
    k.lathe(name, prof, loc, key, segments=segments, rot=(0, 90, 0), parent=parent, sharp=50)
    if ring_key:
        for i in range(rings):
            x = -length / 2 + 0.5 + i * (length - 1.0) / max(rings - 1, 1)
            k.lathe(f"{name}Ring{i}", [(radius + 0.005, 0), (radius + 0.06, 0.04), (radius + 0.06, 0.16),
                                       (radius + 0.005, 0.2)], (loc[0] + x - 0.1, loc[1], loc[2]), ring_key,
                    segments=segments, rot=(0, 90, 0), parent=parent)


def cradle(k, name, x, y, z_top, radius, parent, key="MetalDark"):
    """Опора-ложемент под горизонтальный барабан."""
    k.box(name, (0.35, radius * 1.6, z_top - 1.6), (x, y, 1.6 + (z_top - 1.6) / 2), key, bevel=0.05, parent=parent)


# ----------------------------------------------------------------------
# Модули
# ----------------------------------------------------------------------
def washer(k, root):
    top = machine(k, root, "Blue", "NeonCyan", h=1.4, label="WASHER x1.5", label_key="NeonCyan")
    y = 0.2
    for x in (-2.0, 1.4):
        cradle(k, f"Cradle{x}", x, y, top + 0.5, 1.1, root)
    drum = k.empty("Drum", (-0.3, y, top + 1.3), root)
    drum_body(k, "DrumShell", 4.6, 1.1, (0, 0, 0), "Steel", drum, ring_key="Blue", rings=4)
    for i in range(8):
        a = i / 8 * math.tau
        k.box(f"Paddle{i}", (4.0, 0.06, 0.16), (0, math.cos(a) * 1.12, math.sin(a) * 1.12), "BlueDark", bevel=0.02,
              rot=(math.degrees(a), 0, 0), parent=drum)
    k.tag(drum, k.spin(drum, "X", turns=0.5))
    k.tube("SprayBar", [(-2.4, y - 0.2, top + 2.65), (1.8, y - 0.2, top + 2.65)], 0.07, "Chrome", parent=root,
           smooth_path=False)
    for i in range(6):
        x = -2.1 + i * 0.75
        k.lathe(f"Nozzle{i}", [(0.05, 0), (0.08, -0.12), (0.0, -0.13)], (x, y - 0.2, top + 2.6), "MetalDark",
                segments=8, parent=root)
    for x in (-2.4, 1.8):
        k.tube(f"SprayPost{x}", [(x, y - 0.2, top), (x, y - 0.2, top + 2.65)], 0.06, "Chrome", parent=root,
               smooth_path=False)
    k.lathe("Hopper", [(0.25, 0), (0.3, 0.1), (0.75, 0.8), (0.78, 0.9), (0.7, 0.9), (0.25, 0.15), (0.0, 0.15)],
            (-2.6, y, top + 2.0), "Steel", segments=4, rot=(0, 0, 45), parent=root, sharp=30)
    k.box("Chute", (0.6, 0.8, 0.12), (2.4, y - 0.6, top + 0.6), "Steel", bevel=0.03, rot=(0, -25, 0), parent=root)


def peeler(k, root):
    top = machine(k, root, "Steel", "Orange", h=0.9, label="PEELER +0.5", label_key="NeonOrange")
    x, y = -0.6, 0.4
    vessel = [(0.0, 0.0), (0.6, 0.02), (1.1, 0.2), (1.3, 0.55), (1.3, 2.4), (1.1, 2.8), (0.6, 3.05), (0.4, 3.1),
              (0.4, 3.4), (0.48, 3.45), (0.48, 3.55), (0.0, 3.55)]
    k.lathe("Vessel", vessel, (x, y, top + 0.3), "Chrome", segments=40, parent=root, sharp=50)
    for z in (0.9, 1.9):
        k.lathe(f"Band{z}", [(1.305, 0), (1.34, 0.03), (1.34, 0.14), (1.305, 0.17)], (x, y, top + 0.3 + z), "Orange",
                segments=40, parent=root)
    for i in range(3):
        a = i / 3 * math.tau + 0.5
        k.box(f"VesselLeg{i}", (0.18, 0.18, 0.7), (x + math.cos(a) * 0.9, y + math.sin(a) * 0.9, top + 0.3),
              "MetalDark", bevel=0.04, parent=root)
    k.lathe("Valve", [(0.22, 0), (0.22, 0.4), (0.3, 0.45), (0.3, 0.55), (0.0, 0.6)], (x, y, top + 3.85), "Red",
            parent=root)
    k.torus("ValveWheel", 0.28, 0.04, (x, y, top + 4.3), "Red", parent=root)
    k.lathe("GaugeDial", [(0.2, 0), (0.2, 0.06), (0.0, 0.08)], (x + 0.45, y - 1.22, top + 1.9), "White",
            rot=(90, 0, 15), parent=root)
    k.torus("GaugeRim", 0.21, 0.03, (x + 0.45, y - 1.26, top + 1.9), "Chrome", rot=(90, 0, 15), parent=root)
    k.tube("SteamPipe", [(x + 1.3, y, top + 2.4), (2.0, y, top + 2.4), (2.0, y, top - 0.1)], 0.1, "Copper",
           parent=root, smooth_path=False)
    k.lathe("Discharge", [(0.25, 0), (0.25, 0.4), (0.0, 0.4)], (x, y - 0.95, top + 0.75), "Chrome", rot=(70, 0, 0),
            parent=root)


def fryer(k, root):
    top = machine(k, root, "Steel", "Orange", h=0.9, label="FRYER x4", label_key="NeonOrange")
    y = 0.2
    k.box("Tank", (5.0, 3.2, 1.0), (0, y, top + 0.5), "Chrome", bevel=0.1, parent=root)
    k.box("Oil", (4.6, 2.8, 0.06), (0, y, top + 0.98), "NeonOrange", bevel=0.02, parent=root)
    for i in range(4):
        k.box(f"Basket{i}", (1.0, 1.0, 0.5), (-1.8 + i * 1.2, y - 0.3, top + 1.0), "Chrome", bevel=0.05,
              parent=root)
        for j in range(5):
            k.box(f"Fries{i}{j}", (0.08, 0.6, 0.08), (-2.1 + i * 1.2 + j * 0.15, y - 0.3, top + 1.28), "Yellow",
                  bevel=0.02, rot=(10 * (j % 3 - 1), 0, 20 * (j % 2)), parent=root)
    k.prism("Hood", [(-2.5, 0.0), (2.5, 0.0), (2.5, 1.2), (-2.5, 1.2)], 1.6, (0, y + 1.1, top + 1.6), "Steel",
            parent=root, rot=(25, 0, 0))
    k.box("HoodLip", (5.1, 1.7, 0.12), (0, y + 1.0, top + 1.6), "MetalDark", bevel=0.04, parent=root)
    stack(k, "Chimney", 0.0, 1.2, top + 2.6, 1.0, 0.3, root)
    k.lathe("Thermo", [(0.15, 0), (0.15, 0.05), (0.0, 0.06)], (2.0, y - 1.62, top + 0.5), "White", rot=(90, 0, 0),
            parent=root)


def spice_drum(k, root):
    top = machine(k, root, "RedMetal", "Yellow", h=0.9, label="SPICES x6", label_key="NeonYellow")
    y = 0.2
    for x in (-1.7, 1.7):
        cradle(k, f"Cradle{x}", x, y, top + 0.6 - x * 0.07, 1.2, root)
    holder = k.empty("Tilt", (0, y, top + 1.5), root, rot=(0, 8, 0))
    drum = k.empty("Drum", (0, 0, 0), holder)
    drum_body(k, "DrumShell", 4.4, 1.2, (0, 0, 0), "Orange", drum, ring_key="Red", rings=2)
    for i in range(6):
        a = i / 6 * math.tau
        k.lathe(f"Bolt{i}", [(0.06, 0), (0.06, 0.04), (0.0, 0.05)], (2.2, math.cos(a) * 0.8, math.sin(a) * 0.8),
                "Chrome", rot=(0, 90, 0), parent=drum)
    k.tag(drum, k.spin(drum, "X", turns=0.33))
    k.lathe("Hopper", [(0.2, 0), (0.25, 0.1), (0.7, 0.9), (0.72, 1.0), (0.64, 1.0), (0.2, 0.15), (0.0, 0.15)],
            (-1.6, y, top + 2.8), "Red", segments=4, rot=(0, 0, 45), parent=root, sharp=30)
    for i in range(5):
        k.blob(f"Spice{i}", (0.35, 0.35, 0.2), (-1.6 + (i - 2) * 0.18, y + (i % 2) * 0.15, top + 3.72), "Orange",
               parent=root, jitter=0.2, seed=i, segments=6, rings=4, levels=1)
    for i, key in enumerate(("Red", "Green", "Yellow")):
        k.lathe(f"Jar{i}", [(0.0, 0.0), (0.22, 0.0), (0.24, 0.5), (0.16, 0.6), (0.16, 0.7), (0.0, 0.7)],
                (1.4 + i * 0.5, y + 1.2, top), key, segments=16, parent=root)


def puree_vat(k, root):
    top = machine(k, root, "Steel", "Yellow", h=0.5, label="PUREE +1", label_key="NeonYellow")
    x, y = -0.4, 0.3
    k.lathe("Vat", [(0.0, 0.0), (1.6, 0.0), (1.8, 0.2), (1.8, 2.5), (1.9, 2.6), (1.9, 2.7), (1.7, 2.7), (1.7, 0.3),
                    (0.0, 0.3)], (x, y, top), "Chrome", segments=48, parent=root, sharp=60)
    k.lathe("Puree", [(1.7, 0), (1.7, 0.02), (0.0, 0.02)], (x, y, top + 2.3), "Straw", segments=48, parent=root)
    k.box("Bridge", (3.9, 0.4, 0.3), (x, y, top + 2.9), "Blue", bevel=0.06, parent=root)
    k.motor("MixerMotor", (x, y, top + 3.05), parent=root, key="Blue", radius=0.3, height=0.9)
    mixer = k.empty("Mixer", (x, y, top + 2.0), root)
    k.lathe("Shaft", [(0.08, -1.6), (0.08, 1.0), (0.0, 1.0)], (0, 0, 0), "Chrome", segments=12, parent=mixer)
    for i in range(2):
        k.box(f"Blade{i}", (2.6, 0.14, 0.3), (0, 0, -1.2 + i * 0.7), "Chrome", bevel=0.04, rot=(20, 0, i * 90),
              parent=mixer)
    k.tag(mixer, k.spin(mixer, "Z", turns=0.39))
    k.tube("Outlet", [(x + 1.6, y, top + 0.3), (2.3, y - 0.6, top + 0.2), (2.4, y - 1.4, top - 0.2)], 0.12, "Chrome",
           parent=root)


def packer(k, root):
    top = machine(k, root, "White", "Blue", h=2.2, label="PACKING +0.5", label_key="NeonCyan")
    y = 0.2
    k.box("FeedBox", (1.4, 1.4, 1.6), (-1.5, y + 0.6, top + 0.8), "Steel", bevel=0.1, parent=root)
    k.lathe("FilmRoll", [(0.42, -0.6), (0.42, 0.6), (0.1, 0.6), (0.1, -0.6)], (-1.5, y - 0.4, top + 0.4), "Chrome",
            rot=(0, 90, 0), parent=root)
    k.box("Belt", (3.4, 1.0, 0.12), (1.0, y - 0.3, top + 0.08), "Rubber", bevel=0.03, parent=root)
    keys = ("Red", "Yellow", "Blue", "Green")
    rnd = random.Random(8)
    for i in range(6):
        k.box(f"Pack{i}", (0.6, 0.3, 0.85), (0.1 + (i % 3) * 0.75, y - 0.3 + (i // 3) * 0.35, top + 0.6),
              keys[i % 4], bevel=0.12, segments=3, rot=(rnd.uniform(-5, 5), 0, rnd.uniform(-8, 8)), parent=root)
    k.box("Sealer", (0.6, 1.2, 0.5), (-0.6, y - 0.3, top + 1.2), "Blue", bevel=0.08, parent=root)
    k.box("SealerBar", (0.5, 1.1, 0.08), (-0.6, y - 0.3, top + 0.9), "NeonRed", bevel=0.02, parent=root)


def cryo_tunnel(k, root):
    top = machine(k, root, "White", "NeonCyan", h=0.9, label="CRYO x10", label_key="NeonCyan")
    y = 0.2
    k.box("Tunnel", (5.4, 3.0, 2.2), (0, y, top + 1.1), "White", bevel=0.25, segments=3, parent=root)
    k.box("Frost", (5.6, 3.2, 0.3), (0, y, top + 2.2), "Ice", bevel=0.12, parent=root)
    k.box("Window", (1.6, 0.06, 1.2), (0, y - 1.5, top + 1.1), "NeonCyan", bevel=0.04, parent=root)
    k.box("WindowFrame", (1.8, 0.05, 1.4), (0, y - 1.48, top + 1.1), "Steel", bevel=0.04, parent=root)
    for x in (-2.7, 2.7):
        k.box(f"Curtain{x}", (0.06, 1.6, 1.2), (x, y, top + 0.75), "Ice", bevel=0.02, parent=root)
    for x in (-2.2, -1.5):
        k.lathe(f"Dewar{x}", [(0.0, 0.0), (0.28, 0.0), (0.3, 0.1), (0.3, 2.3), (0.2, 2.5), (0.08, 2.55),
                              (0.08, 2.7), (0.0, 2.7)], (x, 1.2, top + 2.35), "Blue", segments=20, parent=root)
    k.tube("LN2Line", [(-1.85, 1.2, top + 4.9), (-1.85, 0.6, top + 5.0), (0.6, 0.6, top + 2.4)], 0.06, "Chrome",
           parent=root)
    for i in range(5):
        k.lens(f"Icicle{i}", 0.06, (-2.0 + i, y - 1.62, top + 2.1), "Ice", rot=(180, 0, 0), parent=root, height=2.0)


def sublimator(k, root):
    top = machine(k, root, "Steel", "NeonPurple", h=0.5, label="FREEZE-DRY x18", label_key="NeonPurple")
    y = 0.3
    for x in (-1.6, 1.4):
        cradle(k, f"Cradle{x}", x, y, top + 0.4, 1.4, root)
    drum_body(k, "Chamber", 4.6, 1.4, (0, y, top + 1.6), "Chrome", root, ring_key="MetalDark", rings=3)
    k.lathe("Hatch", [(1.15, 0), (1.15, 0.3), (1.0, 0.36), (0.0, 0.36)], (2.3, y, top + 1.6), "MetalDark",
            rot=(0, 90, 0), parent=root)
    k.torus("HatchGlow", 0.6, 0.06, (2.68, y, top + 1.6), "NeonPurple", rot=(0, 90, 0), parent=root)
    k.lathe("HatchGlass", [(0.55, 0), (0.55, 0.02), (0.0, 0.02)], (2.67, y, top + 1.6), "Glass", rot=(0, 90, 0),
            parent=root)
    k.box("Condenser", (1.2, 1.2, 1.2), (-1.8, y, top + 3.4), "NeonPurple", bevel=0.04, parent=root)
    k.box("CondenserShell", (1.3, 1.3, 1.0), (-1.8, y, top + 3.4), "MetalDark", bevel=0.1, parent=root)
    k.tube("VacLine", [(-1.8, y, top + 2.9), (-1.8, y, top + 3.0)], 0.15, "Black", parent=root, smooth_path=False)
    k.motor("Pump", (1.6, -1.2, top), parent=root, key="MetalDark", radius=0.25, height=0.6)


def autoclave(k, root):
    top = machine(k, root, "Steel", "Red", h=0.5, label="AUTOCLAVE +1.5", label_key="NeonRed")
    y = 0.3
    for x in (-1.8, 1.2):
        cradle(k, f"Cradle{x}", x, y, top + 0.4, 1.4, root)
    drum_body(k, "Vessel", 4.4, 1.4, (-0.3, y, top + 1.6), "StoneLight", root, ring_key="MetalDark", rings=3)
    door = k.empty("Door", (1.95, y, top + 1.6), root)
    k.lathe("DoorPlate", [(1.45, 0), (1.45, 0.3), (1.3, 0.4), (0.0, 0.42)], (0, 0, 0), "Red", rot=(0, 90, 0),
            parent=door)
    k.torus("Wheel", 0.45, 0.06, (0.55, 0, 0), "Yellow", rot=(0, 90, 0), parent=door)
    for i in range(3):
        a = i / 3 * math.pi
        k.box(f"Spoke{i}", (0.06, 0.9, 0.06), (0.55, 0, 0), "Yellow", bevel=0.02, rot=(math.degrees(a), 0, 0),
              parent=door)
    for i in range(8):
        a = i / 8 * math.tau
        k.lathe(f"Clamp{i}", [(0.1, 0), (0.1, 0.2), (0.0, 0.2)], (0.3, math.cos(a) * 1.35, math.sin(a) * 1.35),
                "MetalDark", rot=(0, 90, 0), parent=door)
    stack(k, "Vent", -1.2, y, top + 2.95, 0.5, 0.18, root, key="Chrome")
    k.lathe("Gauge", [(0.22, 0), (0.22, 0.06), (0.0, 0.08)], (-0.3, y - 1.43, top + 2.2), "White", rot=(90, 0, 0),
            parent=root)


def starch_mill(k, root):
    top = machine(k, root, "Steel", "White", h=0.5, label="STARCH +2", label_key="NeonWhite")
    x, y = -0.8, 0.3
    k.lathe("MillBed", [(1.6, 0), (1.6, 0.5), (1.45, 0.5), (1.45, 0.2), (0.0, 0.2)], (x, y, top), "MetalDark",
            segments=40, parent=root)
    stones = k.empty("Stones", (x, y, top + 0.2), root)
    k.lathe("StoneLow", [(1.4, 0), (1.4, 0.6), (1.3, 0.7), (0.0, 0.72)], (0, 0, 0), "StoneDark", segments=32,
            parent=stones)
    k.lathe("StoneTop", [(1.35, 0), (1.35, 0.6), (1.2, 0.72), (0.3, 0.75), (0.3, 0.9), (0.0, 0.9)], (0, 0, 0.75),
            "Stone", segments=32, parent=stones)
    k.tag(stones, k.spin(stones, "Z", turns=0.28))
    k.lathe("Hopper", [(0.25, 0), (0.3, 0.1), (0.7, 0.8), (0.72, 0.9), (0.64, 0.9), (0.25, 0.15), (0.0, 0.15)],
            (x, y, top + 2.3), "Chrome", segments=24, parent=root, sharp=40)
    k.tube("HopperStem", [(x, y, top + 1.9), (x, y, top + 2.35)], 0.12, "Chrome", parent=root, smooth_path=False)
    for i in range(3):
        a = i / 3 * math.tau
        k.tube(f"HopperStrut{i}", [(x + math.cos(a) * 1.55, y + math.sin(a) * 1.55, top + 0.5),
                                   (x + math.cos(a) * 0.65, y + math.sin(a) * 0.65, top + 2.9)], 0.05, "MetalDark",
               parent=root, smooth_path=False)
    k.box("Press", (1.8, 1.8, 2.6), (1.6, y, top + 1.3), "Steel", bevel=0.12, parent=root)
    k.box("PressHead", (1.2, 1.2, 0.3), (1.6, y, top + 2.75), "MetalDark", bevel=0.06, parent=root)
    k.blob("Starch", (1.6, 1.2, 0.7), (1.6, y - 1.35, top - 0.02), "White", parent=root, jitter=0.1, seed=3,
           squash_bottom=0.0)
    k.sack("StarchSack", (-2.4, -1.6, top), 1.0, parent=root, seed=5, key="FabricWhite")


def bioreactor(k, root):
    k.box("Base", (8.0, 5.0, 0.4), (0, 0, 0.2), "Plate", bevel=0.06, parent=root)
    for i, x in enumerate((-2.6, 0.0)):
        tank = [(0.0, 0.0), (1.1, 0.0), (1.2, 0.15), (1.2, 4.6), (1.0, 5.1), (0.6, 5.4), (0.2, 5.5), (0.0, 5.5)]
        k.lathe(f"Fermenter{i}", tank, (x, 0.6, 0.4), "Chrome", segments=36, parent=root, sharp=50)
        for z in (1.2, 2.4, 3.6):
            k.lathe(f"Jacket{i}{z}", [(1.205, 0), (1.24, 0.03), (1.24, 0.13), (1.205, 0.16)], (x, 0.6, 0.4 + z),
                    "Steel", segments=36, parent=root)
        k.box(f"SightGlass{i}", (0.7, 0.08, 2.6), (x, 0.6 - 1.2, 2.9), "NeonGreen", bevel=0.04, parent=root)
        k.box(f"SightFrame{i}", (0.85, 0.06, 2.75), (x, 0.6 - 1.18, 2.9), "MetalDark", bevel=0.04, parent=root)
        k.motor(f"Agitator{i}", (x, 0.6, 5.85), parent=root, key="Blue", radius=0.25, height=0.6)
    k.lathe("Column", [(0.5, 0), (0.45, 0.2), (0.45, 7.2), (0.35, 7.5), (0.1, 7.6), (0.0, 7.6)], (2.8, 1.0, 0.4),
            "Chrome", segments=24, parent=root)
    for i in range(7):
        k.lathe(f"Tray{i}", [(0.455, 0), (0.6, 0.03), (0.6, 0.12), (0.455, 0.15)], (2.8, 1.0, 1.2 + i),
                "Yellow", segments=24, parent=root)
    k.tube("Vapor", [(0.0, 0.6, 5.7), (1.4, 0.8, 6.8), (2.8, 1.0, 6.5)], 0.13, "Chrome", parent=root)
    k.tube("Transfer", [(-1.4, 0.6, 1.0), (-1.2, 0.6, 1.0)], 0.12, "Chrome", parent=root, smooth_path=False)
    k.tube("Bridge", [(-2.6 + 1.2, 0.6, 1.0), (-1.2, 0.6, 1.0)], 0.12, "Chrome", parent=root, smooth_path=False)
    k.box("Sign", (3.2, 0.08, 0.6), (-1.3, -2.45, 1.6), "Black", bevel=0.03, parent=root)
    k.text("SignText", "BIOREACTOR x35", 0.26, (-1.3, -2.5, 1.6), "NeonGreen", extrude=0.015, parent=root,
           max_width=2.9)
    for x in (-2.0, -0.6):
        k.box(f"SignLeg{x}", (0.08, 0.08, 1.3), (x, -2.42, 0.85), "MetalDark", bevel=0.02, parent=root)


def extruder(k, root):
    top = machine(k, root, "Steel", "Yellow", h=0.5, label="STICKS +1", label_key="NeonYellow")
    y = 0.3
    for x in (-1.8, 1.6):
        cradle(k, f"Cradle{x}", x, y, top + 0.5, 0.7, root)
    zc = top + 1.0
    k.shell("Barrel", 0.62, -2.4, 2.4, 0, 360, (-0.2, y, zc), "Glass", parent=root, thickness=0.03, rows=1, cols=24,
            rot=(0, 90, 0))
    for x in (-2.3, -0.2, 1.9):
        k.lathe(f"Flange{x}", [(0.63, 0), (0.75, 0.03), (0.75, 0.18), (0.63, 0.21)], (x - 0.1, y, zc), "Yellow",
                rot=(0, 90, 0), parent=root)
    screw = k.empty("Screw", (-0.2, y, zc), root)
    blade_holder = k.empty("ScrewAxis", (0, 0, 0), screw, rot=(0, 0, 90))
    k.cylinder("ScrewShaft", 0.12, 4.6, (0, 0, 0), "Chrome", rot=(0, 90, 0), verts=12, bevel=0.0, parent=screw)
    auger_blade(k, "ScrewBlade", 4.4, 0.12, 0.52, 0.6, "Orange", blade_holder)
    k.tag(screw, k.spin(screw, "X", turns=1.33))
    k.lathe("Hopper", [(0.2, 0), (0.25, 0.1), (0.75, 1.0), (0.78, 1.1), (0.7, 1.1), (0.2, 0.15), (0.0, 0.15)],
            (-2.2, y, zc + 0.55), "Yellow", segments=4, rot=(0, 0, 45), parent=root, sharp=30)
    k.lathe("Die", [(0.5, 0), (0.5, 0.25), (0.3, 0.35), (0.0, 0.35)], (2.3, y, zc), "MetalDark", rot=(0, 90, 0),
            parent=root)
    k.box("Tray", (1.4, 1.2, 0.1), (2.85, y - 0.2, top + 0.1), "Chrome", bevel=0.03, parent=root)
    rnd = random.Random(14)
    for i in range(9):
        k.box(f"Stick{i}", (1.1, 0.09, 0.09), (2.85 + rnd.uniform(-0.1, 0.1), y - 0.6 + i * 0.1, top + 0.2 +
                                                (i % 2) * 0.08), "Potato", bevel=0.03,
              rot=(0, 0, rnd.uniform(-10, 10)), parent=root)
    k.motor("Drive", (-2.9, y, zc), parent=root, key="Yellow", radius=0.35, height=0.6, rot=(0, -90, 0))


def quantum_converter(k, root):
    k.lathe("Platform", [(4.7, 0), (4.7, 0.4), (4.5, 0.6), (0.0, 0.6)], (0, 0, 0), "MetalDark", segments=64,
            parent=root)
    k.lathe("Inlay", [(4.0, 0), (4.0, 0.02), (3.8, 0.02), (3.8, 0.0)], (0, 0, 0.6), "NeonPurple", segments=64,
            parent=root)
    k.lathe("Dais", [(2.2, 0), (2.2, 0.25), (1.8, 0.4), (0.0, 0.4)], (0, 0, 0.6), "Plate", segments=48, parent=root)
    for x in (-3.8, 3.8):
        k.box(f"Pylon{x}", (0.8, 1.4, 4.6), (x, 0, 3.0), "Black", bevel=0.2, segments=3, parent=root)
        k.box(f"PylonGlow{x}", (0.1, 1.0, 3.8), (x - math.copysign(0.42, x), 0, 3.0), "NeonCyan", bevel=0.03,
              parent=root)
        k.tube(f"Arm{x}", [(x, 0, 4.3), (x * 0.95, 0, 4.3)], 0.25, "Chrome", parent=root, smooth_path=False)
    ring = k.empty("Ring", (0, 0, 4.3), root)
    k.torus("RingCore", 3.4, 0.22, (0, 0, 0), "MetalDark", rot=(90, 0, 0), parent=ring, seg=64, ring=12)
    for i in range(20):
        a = i / 20 * math.tau
        k.box(f"Segment{i}", (0.7, 0.7, 0.7), (math.cos(a) * 3.4, 0, math.sin(a) * 3.4),
              "NeonPurple" if i % 2 == 0 else "NeonCyan", bevel=0.12, rot=(0, -math.degrees(a), 0), parent=ring)
    k.tag(ring, k.spin(ring, "Y", turns=-0.28))
    core = k.empty("Core", (0, 0, 4.3), root)
    k.potato("CorePotato", (0, 0, 0), 2.0, parent=core, key="Gold", seed=19, rot=(0, 15, 30))
    k.tag(core, k.bob(core, amplitude=0.35, cycles=1))
    k.box("Sign", (4.0, 0.1, 0.7), (0, -4.3, 1.3), "Black", bevel=0.04, parent=root)
    k.text("SignText", "QUANTUM x100", 0.4, (0, -4.36, 1.3), "NeonPurple", extrude=0.02, parent=root, max_width=3.6)
    for x in (-1.5, 1.5):
        k.box(f"SignLeg{x}", (0.1, 0.1, 0.8), (x, -4.3, 0.75), "MetalDark", bevel=0.02, parent=root)


# ----------------------------------------------------------------------
# Корпус цеха 78x19x9 (игроки ходят внутри: стены — отдельные детали)
# ----------------------------------------------------------------------
def factory_hall(k, root):
    W, D, H = 78.0, 19.0, 9.0
    hw, hd = W / 2, D / 2
    k.box("Floor", (W, D, 0.2), (0, 0, 0.1), "Concrete", bevel=0.02, parent=root)
    for x in (-hw, hw):
        k.solo(k.box(f"EndWall{x}", (0.5, D, H), (x, 0, H / 2), "Grey", bevel=0.05, parent=root))
    for y in (-hd, hd):  # фасад (-Y) и северная стена (+Y), ворота на дорожке |x| < 4
        for sx in (-1, 1):
            length = hw - 4
            cx = sx * (4 + length / 2)
            k.solo(k.box(f"WallLow{y}{sx}", (length, 0.5, 3.0), (cx, y, 1.5), "Grey", bevel=0.05, parent=root))
            k.box(f"Glazing{y}{sx}", (length, 0.2, 2.6), (cx, y, 4.3), "Glass", bevel=0.0, parent=root)
            k.solo(k.box(f"WallHigh{y}{sx}", (length, 0.5, H - 5.6), (cx, y, 5.6 + (H - 5.6) / 2), "Grey",
                         bevel=0.05, parent=root))
            for i in range(int(length / 3.0)):
                mx = sx * (4 + 1.5 + i * 3.0)
                k.box(f"Mullion{y}{sx}{i}", (0.12, 0.3, 2.6), (mx, y, 4.3), "MetalDark", bevel=0.02, parent=root)
            k.box(f"Plinth{y}{sx}", (length, 0.6, 0.4), (cx, y, 0.2), "StoneDark", bevel=0.04, parent=root)
        k.solo(k.box(f"OverGate{y}", (8.0, 0.5, H - 6), (0, y, 6 + (H - 6) / 2), "Grey", bevel=0.05, parent=root))
        for x in (-4.1, 4.1):
            k.box(f"GatePost{y}{x}", (0.6, 0.7, 6.0), (x, y, 3.0), "Yellow", bevel=0.08, parent=root)
        k.box(f"GateBeam{y}", (8.8, 0.7, 0.6), (0, y, 6.0), "Yellow", bevel=0.08, parent=root)
        for i in range(8):
            k.box(f"GateStripe{y}{i}", (0.3, 0.72, 0.5), (-3.5 + i, y, 6.0), "Black", bevel=0.0, rot=(0, 40, 0),
                  parent=root)
        k.box(f"RollerBox{y}", (8.2, 0.9, 0.6), (0, y + math.copysign(0.3, y), 6.7), "MetalDark", bevel=0.1,
              parent=root)
    k.box("Cornice", (W + 0.6, D + 0.6, 0.4), (0, 0, H + 0.2), "MetalDark", bevel=0.08, parent=root)
    # стеклянная крыша с фермами
    k.box("RoofGlass", (W - 0.6, D - 0.6, 0.12), (0, 0, H + 0.1), "Glass", bevel=0.0, parent=root)
    x = -hw + 2
    i = 0
    while x <= hw - 2 + 1e-6:
        k.box(f"Truss{i}", (0.4, D - 0.4, 0.5), (x, 0, H + 0.25), "MetalDark", bevel=0.05, parent=root)
        for y in (hd - 0.6, -hd + 0.6):
            k.box(f"Column{i}{y}", (0.5, 0.5, H), (x, y, H / 2), "MetalDark", bevel=0.05, parent=root)
            k.box(f"ColumnFlange{i}{y}", (0.7, 0.15, H), (x, y, H / 2), "MetalDark", bevel=0.03, parent=root)
        lamp_x = x + 3.2
        if lamp_x < hw - 1:
            k.box(f"LampHousing{i}", (0.6, 3.2, 0.2), (lamp_x, 0, H - 0.3), "Grey", bevel=0.05, parent=root)
            k.box(f"Lamp{i}", (0.4, 3.0, 0.08), (lamp_x, 0, H - 0.42), "NeonWhite", bevel=0.02, parent=root)
            k.tube(f"LampWire{i}", [(lamp_x, 0, H - 0.2), (lamp_x, 0, H)], 0.03, "Black", parent=root,
                   smooth_path=False)
        x += 6.5
        i += 1
    # мостик инспектора вдоль северной стены и лестница
    yb = hd - 1.2
    k.box("Catwalk", (W - 2, 1.4, 0.25), (0, yb, 6.4), "Plate", bevel=0.04, parent=root)
    k.box("Handrail", (W - 2, 0.1, 0.1), (0, yb - 0.65, 7.4), "Yellow", bevel=0.02, parent=root)
    k.box("MidRail", (W - 2, 0.06, 0.06), (0, yb - 0.65, 6.9), "Yellow", bevel=0.01, parent=root)
    for j in range(int((W - 2) / 3) + 1):
        k.box(f"RailPost{j}", (0.08, 0.08, 1.0), (-hw + 1 + j * 3, yb - 0.65, 6.9), "Yellow", bevel=0.02,
              parent=root)
    for j in range(9):
        k.box(f"Step{j}", (1.2, 0.7, 0.2), (-hw + 1.6, hd - 2.4 - (8 - j) * 0.55, 0.7 * j + 0.3), "Plate",
              bevel=0.03, parent=root)
    k.tube("StairRail", [(-hw + 2.2, hd - 2.4 - 8 * 0.55, 1.2), (-hw + 2.2, hd - 2.4, 6.9)], 0.05, "Yellow",
           parent=root, smooth_path=False)
    # пожарный щит, аптечка
    k.box("FireBoard", (0.15, 1.6, 2.0), (-hw + 0.35, -3.0, 2.2), "Red", bevel=0.04, parent=root)
    k.lathe("Extinguisher", [(0.0, 0.0), (0.16, 0.0), (0.17, 0.6), (0.1, 0.72), (0.04, 0.8), (0.0, 0.8)],
            (-hw + 0.55, -3.0, 1.5), "Red", segments=16, parent=root)
    k.box("FirstAid", (0.2, 0.9, 0.9), (hw - 0.4, -3.0, 2.4), "White", bevel=0.05, parent=root)
    for r in ((0.6, 0.18), (0.18, 0.6)):
        k.box(f"Cross{r}", (0.06, r[0], r[1]), (hw - 0.52, -3.0, 2.4), "Red", bevel=0.0, parent=root)
    # отбойники у ворот
    for x in (-5.5, 5.5):
        k.box(f"Barrier{x}", (1.5, 0.6, 0.9), (x, -hd - 1.0, 0.45), "Yellow", bevel=0.1, parent=root)
        for dx in (-0.4, 0.4):
            k.box(f"BarrierStripe{x}{dx}", (0.3, 0.62, 0.92), (x + dx, -hd - 1.0, 0.45), "Black", bevel=0.05,
                  parent=root)
    # вывеска
    k.box("Sign", (12.0, 0.3, 1.4), (0, -hd - 0.4, H - 1.1), "Blue", bevel=0.1, parent=root)
    k.text("SignText", "PROCESSING PLANT", 0.8, (0, -hd - 0.58, H - 1.1), "White", extrude=0.04, parent=root,
           max_width=11.0)
    # декор: коробки чипсов и мешки
    for j in range(3):
        k.box(f"ChipsBox{j}", (1.2, 0.9, 0.9), (hw - 1.4, hd - 3.2, 0.65 + j * 0.9), "Yellow", bevel=0.05,
              parent=root)
        k.text(f"ChipsText{j}", "CHIPS", 0.25, (hw - 1.4, hd - 3.66, 0.65 + j * 0.9), "Red", extrude=0.01,
               parent=root, max_width=1.0)
    for j in range(2):
        k.sack(f"Sack{j}", (-hw + 1.2 + j * 1.3, -hd + 2.5, 0.2), 1.5, parent=root, seed=j)
