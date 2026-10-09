"""Агро-блок, часть 2: забор с аркой, авто-лейка, мешок XL, фитолампы, авто-грядки T2/T3,
неоновая вывеска, солнечная крыша, отпугиватель кротов, табло выработки, капельный полив.

Координаты совпадают с процедурными моделями (src/server/World/Models/*.luau):
точка Roblox (x, y, z) здесь пишется как (x, -z, y).
"""

import math
import random

from mathutils import Vector

from .agro import plants_and_tubers, soil_surface


# ----------------------------------------------------------------------
# Забор фермы (периметр агро-блока 80x26) с аркой над входом
# ----------------------------------------------------------------------
def fence_run(k, root, a, b, rnd, name):
    """Столбы через ~4 стада и две жерди между ними."""
    a, b = Vector(a), Vector(b)
    n = max(1, round((b - a).length / 4))
    posts = [a + (b - a) * (i / n) for i in range(n + 1)]
    along = (b - a).normalized()
    yaw = math.degrees(math.atan2(along.y, along.x))
    for i, p in enumerate(posts):
        h = 2.2 + rnd.uniform(-0.06, 0.06)
        k.box(f"{name}Post{i}", (0.4, 0.4, h), (p.x, p.y, h / 2), "WoodDark", bevel=0.06,
              rot=(0, 0, yaw + rnd.uniform(-2, 2)), parent=root)
        k.lathe(f"{name}Cap{i}", [(0.3, 0), (0.3, 0.05), (0.0, 0.22)], (p.x, p.y, h), "WoodDark", segments=4,
                rot=(0, 0, yaw + 45), parent=root, sharp=30)
    side = Vector((-along.y, along.x, 0)) * 0.27
    for i in range(n):
        p, q = posts[i], posts[i + 1]
        mid = (p + q) / 2
        length = (q - p).length + 0.3
        for j, z in enumerate((0.8, 1.6)):
            key = "WoodLight" if (i + j) % 2 else "Wood"
            k.box(f"{name}Rail{i}_{j}", (length, 0.16, 0.3), (mid.x + side.x, mid.y + side.y, z + rnd.uniform(-0.04, 0.04)),
                  key, bevel=0.05, rot=(rnd.uniform(-1.5, 1.5), 0, yaw + rnd.uniform(-0.5, 0.5)), parent=root)


def fence_wood(k, root):
    rnd = random.Random(41)
    front, back, half = -12.8, 13.0, 39.8
    fence_run(k, root, (-half, front, 0), (-3.6, front, 0), rnd, "FL")
    fence_run(k, root, (3.6, front, 0), (half, front, 0), rnd, "FR")
    fence_run(k, root, (-half, back, 0), (-half, front, 0), rnd, "SL")
    fence_run(k, root, (half, back, 0), (half, front, 0), rnd, "SR")
    # арка над входом с вывеской
    for x in (-3.6, 3.6):
        k.box(f"GatePost{x}", (0.62, 0.62, 4.6), (x, front, 2.3), "WoodDark", bevel=0.08, parent=root)
        k.lathe(f"GateCap{x}", [(0.45, 0), (0.45, 0.06), (0.0, 0.32)], (x, front, 4.6), "WoodDark", segments=4,
                rot=(0, 0, 45), parent=root, sharp=30)
        k.tube(f"GateBrace{x}", [(x, front, 3.1), (x - math.copysign(1.1, x), front, 4.05)], 0.1, "Wood", parent=root,
               smooth_path=False)
    k.box("GateBeam", (8.2, 0.4, 0.42), (0, front, 4.2), "Wood", bevel=0.07, parent=root)
    k.box("GateBeamTop", (8.6, 0.55, 0.16), (0, front, 4.48), "WoodDark", bevel=0.05, parent=root)
    sign = k.empty("GateSign", (0, front - 0.05, 3.35), root)
    k.box("SignBoard", (4.6, 0.14, 1.0), (0, 0, 0), "WoodLight", bevel=0.06, parent=sign)
    k.box("SignFrame", (4.8, 0.1, 1.2), (0, 0.04, 0), "WoodDark", bevel=0.05, parent=sign)
    k.text("SignText", "FARM", 0.62, (0.25, -0.09, 0), "WoodDark", extrude=0.04, parent=sign, max_width=3.2)
    k.potato("SignPotato", (-1.75, -0.12, 0), 0.62, parent=sign, seed=4, rot=(90, 20, 0))
    for x in (-1.9, 1.9):
        k.tube(f"SignChain{x}", [(x, 0, 0.5), (x, 0, 0.85)], 0.03, "MetalDark", parent=sign, smooth_path=False)
    k.tag(sign, k.swing(sign, "Y", degrees=2, cycles=1))


# ----------------------------------------------------------------------
# Авто-лейка (2x2): ящик-подставка, лейка на шарнире наклоняется и поливает
# ----------------------------------------------------------------------
def watering_can(k, root):
    for i, z in enumerate((0.12, 0.36, 0.6)):
        for side in (-1, 1):
            k.box(f"CrateX{i}{side}", (1.6, 0.1, 0.2), (0, side * 0.75, z), "WoodLight" if i % 2 else "Wood",
                  bevel=0.03, parent=root)
            k.box(f"CrateY{i}{side}", (0.1, 1.4, 0.2), (side * 0.75, 0, z), "Wood" if i % 2 else "WoodLight",
                  bevel=0.03, parent=root)
    k.box("CrateTop", (1.6, 1.6, 0.1), (0, 0, 0.72), "WoodDark", bevel=0.03, parent=root)
    # шарнир и лейка
    k.box("Bracket", (0.5, 0.3, 0.3), (0.35, 0, 0.9), "MetalDark", bevel=0.05, parent=root)
    can = k.empty("Can", (0.35, 0, 0.95), root)
    body = [(0.0, 0.0), (0.38, 0.0), (0.44, 0.04), (0.46, 0.15), (0.44, 0.75), (0.4, 0.88), (0.43, 0.92),
            (0.42, 0.96), (0.36, 0.95), (0.0, 0.9)]
    k.lathe("CanBody", body, (-0.35, 0, 0.0), "Green", segments=32, parent=can, sharp=60)
    for z in (0.25, 0.55):
        k.lathe(f"CanRib{z}", [(0.452, 0), (0.468, 0.02), (0.468, 0.05), (0.452, 0.07)], (-0.35, 0, z), "GreenDark",
                segments=32, parent=can)
    k.tube("CanHandle", [(-0.45, 0, 0.94), (-0.62, 0, 1.22), (-0.88, 0, 1.12), (-0.83, 0, 0.6)], 0.05, "GreenDark",
           parent=can)
    k.tube("Spout", [(0.05, 0, 0.18), (0.45, 0, 0.55), (0.85, 0, 0.95)], 0.07, "Green", parent=can,
           radii=[1.2, 0.9, 0.75])
    k.lathe("Rose", [(0.06, 0), (0.17, 0.12), (0.17, 0.15), (0.0, 0.15)], (0.85, 0, 0.95), "Chrome", rot=(0, 55, 0),
            parent=can)
    # струйки воды из сита
    for i, dy in enumerate((-0.08, 0.0, 0.08)):
        pts = [(0.98, dy, 1.03)] + [(0.98 + t * 0.6, dy * (1 + t * 2), 1.03 + 0.25 * t - 2.2 * t * t) for t in
                                    (0.25, 0.5, 0.75, 1.0)]
        k.tube(f"Stream{i}", pts, 0.025, "Water", parent=can, radii=[1.0, 0.9, 0.8, 0.7, 0.5])
    k.tag(can, k.swing(can, "Y", degrees=10, cycles=1))
    # таймер полива
    k.box("Timer", (0.5, 0.2, 0.42), (-0.3, -0.82, 0.45), "White", bevel=0.06, parent=root)
    k.box("TimerScreen", (0.3, 0.04, 0.14), (-0.3, -0.93, 0.5), "Black", bevel=0.01, parent=root)
    led = k.lens("TimerLed", 0.04, (-0.15, -0.93, 0.33), "NeonCyan", rot=(90, 0, 0), parent=root)
    k.tag(led, "pulse_3")


# ----------------------------------------------------------------------
# Заплечный мешок XL (2x2)
# ----------------------------------------------------------------------
def big_sack(k, root):
    rnd = random.Random(12)
    k.sack("Sack", (0, 0, 0), 2.35, parent=root, seed=3)
    for p in range(6):
        a = p / 6 * math.tau + rnd.uniform(-0.2, 0.2)
        k.potato(f"TopPotato{p}", (math.cos(a) * 0.22, math.sin(a) * 0.22, 2.45 + rnd.uniform(0, 0.12)), 0.42,
                 parent=root, seed=30 + p)
    # лямки рюкзака сзади (+Y)
    for x in (-0.38, 0.38):
        k.tube(f"Strap{x}", [(x, 0.66, 1.95), (x * 1.1, 0.93, 1.5), (x * 1.12, 0.97, 0.8), (x, 0.8, 0.35)], 0.055,
               "WoodDark", parent=root, radii=[0.8, 1.0, 1.0, 0.8])
        k.lens(f"StrapRivet{x}", 0.05, (x, 0.74, 1.95), "Gold", rot=(-60, 0, 0), parent=root)
    # кожаная нашивка «XL» спереди
    patch = k.empty("Patch", (0, -0.96, 1.05), root, rot=(-8, 0, 0))
    k.box("PatchLeather", (0.78, 0.06, 0.52), (0, 0, 0), "WoodDark", bevel=0.05, parent=patch)
    k.text("PatchText", "XL", 0.36, (0, -0.05, 0), "Red", extrude=0.03, parent=patch, max_width=0.6, logo=True)


# ----------------------------------------------------------------------
# Фитолампы: столб с консолью на две лампы над рядами грядок (Roblox z = ±5 → Blender y = ∓5)
# ----------------------------------------------------------------------
def lamp_post(k, root):
    k.lathe("PostBase", [(0.62, 0), (0.62, 0.1), (0.5, 0.16), (0.24, 0.24), (0.0, 0.24)], (0, 0, 0), "MetalDark",
            parent=root)
    for i in range(4):
        a = math.radians(45 + i * 90)
        k.lens(f"Bolt{i}", 0.05, (math.cos(a) * 0.45, math.sin(a) * 0.45, 0.12), "Chrome", parent=root)
    k.lathe("Pole", [(0.17, 0), (0.15, 3.0), (0.13, 6.2), (0.0, 6.2)], (0, 0, 0.2), "MetalDark", segments=16,
            parent=root)
    k.box("Arm", (0.24, 10.6, 0.26), (0, 0, 6.3), "MetalDark", bevel=0.05, parent=root)
    k.lathe("PoleCap", [(0.2, 0), (0.2, 0.08), (0.0, 0.2)], (0, 0, 6.43), "MetalDark", segments=16, parent=root)
    for s in (-1, 1):
        k.tube(f"Brace{s}", [(0, 0, 5.0), (0, s * 1.6, 6.2)], 0.06, "MetalDark", parent=root, smooth_path=False)
        k.lathe(f"ArmEnd{s}", [(0.0, 0), (0.15, 0.0), (0.15, 0.05), (0.0, 0.05)], (0, s * 5.3, 6.3), "MetalDark",
                rot=(-90 * s, 0, 0), parent=root)


def lamp_basic(k, root):
    lamp_post(k, root)
    for s in (-1, 1):
        y = s * 5
        k.tube(f"Rod{s}", [(0, y, 6.18), (0, y, 5.62)], 0.04, "Black", parent=root, smooth_path=False)
        shade = [(0.12, 0.0), (0.16, -0.05), (0.42, -0.32), (0.72, -0.56), (0.76, -0.6), (0.7, -0.6),
                 (0.38, -0.33), (0.1, -0.08)]
        k.lathe(f"Shade{s}", [(r, z) for r, z in shade], (0, y, 5.62), "GreenDark", segments=32, parent=root, sharp=60)
        k.lathe(f"Reflector{s}", [(0.15, -0.1), (0.41, -0.33), (0.69, -0.565), (0.67, -0.57), (0.39, -0.335),
                                  (0.13, -0.105)], (0, y, 5.62), "White", segments=32, parent=root, sharp=60)
        bulb = [(0.08, 0), (0.09, -0.08), (0.17, -0.18), (0.2, -0.3), (0.17, -0.42), (0.09, -0.48), (0.0, -0.5)]
        k.lathe(f"Socket{s}", [(0.09, 0), (0.09, -0.12), (0.0, -0.12)], (0, y, 5.52), "Chrome", segments=16,
                parent=root)
        k.lathe(f"Bulb{s}", bulb, (0, y, 5.42), "NeonYellow", segments=20, parent=root)


def lamp_led(k, root):
    lamp_post(k, root)
    for s in (-1, 1):
        y = s * 5
        for x in (-1.2, 1.2):
            k.tube(f"Hanger{s}{x}", [(x, y, 6.2), (x, y, 5.6)], 0.025, "Chrome", parent=root, smooth_path=False)
        k.box(f"Frame{s}", (3.4, 4.8, 0.22), (0, y, 5.55), "MetalDark", bevel=0.06, parent=root)
        for f in range(9):
            k.box(f"Fin{s}{f}", (0.06, 4.4, 0.18), (-1.4 + f * 0.35, y, 5.74), "Grey", bevel=0.02, parent=root)
        for r in range(6):
            key = "NeonRed" if r % 2 else "NeonPurple"
            k.box(f"Strip{s}{r}", (3.0, 0.42, 0.06), (0, y - 2.1 + r * 0.84, 5.42), key, bevel=0.02, parent=root)


def lamp_quantum(k, root):
    lamp_post(k, root)
    for s in (-1, 1):
        y = s * 5
        k.tube(f"Rod{s}", [(0, y, 6.18), (0, y, 5.8)], 0.06, "Chrome", parent=root, smooth_path=False)
        k.box(f"Panel{s}", (3.4, 5.0, 0.24), (0, y, 5.52), "White", bevel=0.12, segments=3, parent=root)
        k.box(f"Glow{s}", (3.0, 4.6, 0.05), (0, y, 5.39), "NeonCyan", bevel=0.02, parent=root)
        ring = k.empty(f"Ring{s}", (0, y, 5.95), root)
        k.torus(f"RingTube{s}", 1.1, 0.06, (0, 0, 0), "NeonCyan", parent=ring, seg=48, ring=10)
        for o in range(3):
            a = o / 3 * math.tau
            k.lathe(f"Orb{s}{o}", [(0.0, -0.12), (0.09, -0.1), (0.12, 0.0), (0.09, 0.1), (0.0, 0.12)],
                    (math.cos(a) * 1.1, math.sin(a) * 1.1, 0), "NeonWhite", segments=12, parent=ring)
        k.tag(ring, k.spin(ring, "Z", turns=0.5))


# ----------------------------------------------------------------------
# Авто-грядки Tier 2 (вакуумный сборщик) и Tier 3 (лазерный портал)
# ----------------------------------------------------------------------
def auto_bed_base(k, root, frame_key, stripe_key, seed):
    w, d = 4.0, 6.0
    for side in (-1, 1):
        k.box(f"FrameL{side}", (0.36, d, 1.1), (side * (w / 2 - 0.18), 0, 0.55), frame_key, bevel=0.06, parent=root)
        k.box(f"FrameS{side}", (w - 0.72, 0.36, 1.1), (0, side * (d / 2 - 0.18), 0.55), frame_key, bevel=0.06,
              parent=root)
        k.box(f"Stripe{side}", (0.38, d - 0.5, 0.1), (side * (w / 2 - 0.18), 0, 0.86), stripe_key, bevel=0.02,
              parent=root)
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.box(f"Corner{sx}{sy}", (0.46, 0.46, 1.2), (sx * (w / 2 - 0.23), sy * (d / 2 - 0.23), 0.6), frame_key,
                  bevel=0.08, parent=root)
    soil_surface(k, root, w - 0.7, d - 0.7, 0.9, seed=seed)
    plants_and_tubers(k, root, d - 0.4, 0.98, seed=seed, scale=0.9)


def auto_bed_t2(k, root):
    auto_bed_base(k, root, "Steel", "Blue", seed=5)
    # рельсы по бортам и каретка-пылесос (едет вдоль грядки)
    for x in (-1.82, 1.82):
        k.box(f"Rail{x}", (0.12, 5.6, 0.1), (x, 0, 1.16), "Chrome", bevel=0.02, parent=root)
    cart = k.empty("Nozzle", (0, 0, 0), root)
    k.box("Bridge", (4.1, 0.5, 0.36), (0, 0, 2.55), "Blue", bevel=0.1, parent=cart)
    for x in (-1.82, 1.82):
        k.box(f"Leg{x}", (0.2, 0.4, 1.3), (x, 0, 1.85), "Blue", bevel=0.05, parent=cart)
        for y in (-0.16, 0.16):
            k.lathe(f"Wheel{x}{y}", [(0.1, 0), (0.1, 0.06), (0.0, 0.06)], (x - 0.1, y, 1.26), "Rubber",
                    rot=(0, 90, 0), parent=cart)
    k.lathe("Fan", [(0.42, 0), (0.42, 0.3), (0.36, 0.38), (0.0, 0.4)], (0, 0, 2.73), "BlueDark", parent=cart)
    k.lathe("FanGrille", [(0.3, 0), (0.3, 0.02), (0.0, 0.02)], (0, 0, 3.12), "Chrome", parent=cart)
    k.box("Mouth", (3.2, 0.42, 0.22), (0, 0, 2.2), "Black", bevel=0.08, parent=cart)
    k.box("MouthLip", (3.3, 0.5, 0.06), (0, 0, 2.07), "Rubber", bevel=0.02, parent=cart)
    k.tube("Duct", [(0, 0, 2.3), (0, 0, 2.75)], 0.16, "Black", parent=cart, smooth_path=False)
    k.tag(cart, k.slide(cart, "Y", distance=1.8, cycles=1))
    # док-станция с бункером спереди
    k.box("DockBase", (1.5, 1.0, 0.25), (0, -3.45, 0.12), "MetalDark", bevel=0.05, parent=root)
    k.lathe("Tank", [(0.0, 0.0), (0.5, 0.0), (0.58, 0.08), (0.6, 1.1), (0.52, 1.3), (0.2, 1.42), (0.0, 1.42)],
            (0, -3.45, 0.25), "Blue", segments=28, parent=root)
    k.lathe("TankBand", [(0.605, 0), (0.62, 0.03), (0.62, 0.12), (0.605, 0.15)], (0, -3.45, 0.85), "Chrome",
            segments=28, parent=root)
    k.lathe("TankWindow", [(0.12, 0), (0.12, 0.02), (0.0, 0.02)], (0, -4.04, 0.95), "Glass", rot=(90, 0, 0),
            parent=root)
    k.tube("DockHose", [(0, -3.4, 1.65), (0, -3.0, 2.2), (0, -2.6, 2.3)], 0.1, "Black", parent=root)


def auto_bed_t3(k, root):
    auto_bed_base(k, root, "MetalDark", "NeonRed", seed=6)
    # портал: 4 стойки и верхние направляющие
    for x in (-1.9, 1.9):
        for y in (-2.9, 2.9):
            k.box(f"Pillar{x}{y}", (0.26, 0.26, 3.0), (x, y, 1.5), "Black", bevel=0.05, parent=root)
        k.box(f"TopRail{x}", (0.22, 6.0, 0.22), (x, 0, 3.05), "Black", bevel=0.04, parent=root)
        k.box(f"RailGlow{x}", (0.06, 5.6, 0.05), (x - math.copysign(0.12, x), 0, 3.05), "NeonRed", bevel=0.01,
              parent=root)
    laser = k.empty("Laser", (0, 0, 0), root)
    k.box("Carriage", (4.2, 0.6, 0.36), (0, 0, 3.05), "White", bevel=0.12, segments=3, parent=laser)
    k.box("Emitter", (3.4, 0.24, 0.24), (0, 0, 2.78), "MetalDark", bevel=0.06, parent=laser)
    for i in range(5):
        k.lens(f"Lens{i}", 0.07, (-1.4 + i * 0.7, 0, 2.66), "NeonRed", rot=(180, 0, 0), parent=laser)
    for i in range(5):
        k.tube(f"Beam{i}", [(-1.4 + i * 0.7, 0, 2.62), (-1.4 + i * 0.7, 0, 1.15)], 0.022, "NeonRed", parent=laser,
               smooth_path=False)
    k.tag(laser, k.slide(laser, "Y", distance=2.3, cycles=1))
    k.box("ControlBox", (0.9, 0.5, 0.7), (1.3, -3.25, 0.45), "MetalDark", bevel=0.08, parent=root)
    warn = k.lens("WarnLamp", 0.09, (1.3, -3.25, 0.82), "NeonRed", parent=root)
    k.tag(warn, "pulse_4")


# ----------------------------------------------------------------------
# Неоновая вывеска «POTATO TYCOON» (10x1)
# ----------------------------------------------------------------------
def neon_sign(k, root):
    for x in (-4.3, 4.3):
        k.box(f"BasePlate{x}", (1.2, 1.0, 0.12), (x, 0, 0.06), "MetalDark", bevel=0.03, parent=root)
        k.box(f"Post{x}", (0.5, 0.5, 9.9), (x, 0, 5.0), "Black", bevel=0.06, parent=root)
        for z in (2.5, 5.0):
            k.box(f"PostBand{x}{z}", (0.56, 0.56, 0.12), (x, 0, z), "MetalDark", bevel=0.03, parent=root)
    k.box("Board", (9.6, 0.4, 2.6), (0, 0, 9.0), "Black", bevel=0.12, segments=3, parent=root)
    k.box("BoardFrame", (9.8, 0.3, 2.8), (0, 0, 9.0), "MetalDark", bevel=0.1, parent=root)
    for side in (-1, 1):
        y = side * 0.21
        rot = (90, 0, 0) if side < 0 else (90, 0, 180)
        k.text(f"Title{side}", "POTATO TYCOON", 1.0, (0.45 * -side, y + side * 0.02, 8.95), "NeonYellow", rot=rot,
               extrude=0.05, parent=root, max_width=7.4, logo=True)
        k.potato(f"Logo{side}", (-4.0 * -side, y + side * 0.06, 9.0), 0.75, parent=root, key="Gold", seed=9,
                 rot=(90, 15, 0))
        for z in (7.8, 10.2):
            k.tube(f"Trim{side}{z}", [(-4.6, y + side * 0.03, z), (4.6, y + side * 0.03, z)], 0.06, "NeonPurple",
                   parent=root, smooth_path=False)
    for x in (-3.2, 3.2):
        k.tube(f"Lamp{x}", [(x, -0.25, 10.5), (x, -0.9, 10.7)], 0.05, "MetalDark", parent=root, smooth_path=False)
        k.lathe(f"Spot{x}", [(0.06, 0), (0.16, 0.1), (0.16, 0.22), (0.0, 0.22)], (x, -0.9, 10.7), "MetalDark",
                rot=(-130, 0, 0), parent=root)


# ----------------------------------------------------------------------
# Крышная солнечная батарея (4x4): сарай с двускатной крышей и панелями
# ----------------------------------------------------------------------
def solar_panel(k, name, w, h, loc, tilt, parent):
    """Панель w x h: рама, ячейки, лежит на скате с наклоном tilt (градусы вокруг X)."""
    g = k.empty(name, loc, parent, rot=(tilt, 0, 0))
    k.box("Frame", (w, h, 0.08), (0, 0, 0), "Chrome", bevel=0.03, parent=g)
    cols, rows = 6, 3
    cw, ch = (w - 0.16) / cols, (h - 0.16) / rows
    for c in range(cols):
        for r in range(rows):
            k.box(f"Cell{c}{r}", (cw - 0.04, ch - 0.04, 0.03), (-w / 2 + 0.08 + cw * (c + 0.5),
                                                               -h / 2 + 0.08 + ch * (r + 0.5), 0.045),
                  "SolarCell", bevel=0.005, parent=g)
    return g


def solar_small(k, root):
    w = 3.6
    for i in range(6):
        z = 0.1 + i * 0.2
        for side in (-1, 1):
            k.box(f"PlankF{i}{side}", (w, 0.1, 0.2), (0, side * (w / 2 - 0.05), z), "Wood" if i % 2 else "WoodLight",
                  bevel=0.03, parent=root)
            k.box(f"PlankS{i}{side}", (0.1, w - 0.2, 0.2), (side * (w / 2 - 0.05), 0, z), "WoodLight" if i % 2 else
                  "Wood", bevel=0.03, parent=root)
    k.box("Floor", (w - 0.2, w - 0.2, 0.1), (0, 0, 0.05), "WoodDark", bevel=0.02, parent=root)
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.box(f"Corner{sx}{sy}", (0.2, 0.2, 1.25), (sx * (w / 2 - 0.08), sy * (w / 2 - 0.08), 0.62), "WoodDark",
                  bevel=0.04, parent=root)
    k.box("Door", (0.8, 0.06, 1.0), (-0.9, -w / 2 - 0.02, 0.55), "WoodDark", bevel=0.03, parent=root)
    k.lens("DoorKnob", 0.05, (-0.62, -w / 2 - 0.06, 0.55), "Gold", rot=(90, 0, 0), parent=root)
    # фронтоны и скаты крыши (конёк вдоль X)
    ridge = 2.3
    k.prism("Gable", [(-w / 2, 1.2), (w / 2, 1.2), (0, ridge)], w - 0.02, (0, 0, 0), "Wood", parent=root,
            rot=(0, 0, 90), bevel=0.02)
    slope = math.degrees(math.atan2(ridge - 1.2, w / 2))
    run = math.hypot(w / 2, ridge - 1.2) + 0.3
    for side in (-1, 1):
        cy = side * (w / 4 + 0.05)
        cz = (1.2 + ridge) / 2 + 0.08
        k.box(f"Roof{side}", (w + 0.4, run, 0.14), (0, cy, cz), "Red", bevel=0.04, rot=(-side * slope, 0, 0),
              parent=root)
        solar_panel(k, f"Panel{side}", w - 0.2, run - 0.55, (0, cy * 1.02, cz + 0.12), -side * slope, root)
    k.box("RidgeCap", (w + 0.5, 0.3, 0.12), (0, 0, ridge + 0.1), "RedMetal", bevel=0.04, parent=root)
    # инвертор на стене
    k.box("Inverter", (0.6, 0.18, 0.5), (1.0, -w / 2 - 0.09, 0.75), "White", bevel=0.05, parent=root)
    led = k.lens("InverterLed", 0.04, (1.18, -w / 2 - 0.19, 0.88), "NeonGreen", rot=(90, 0, 0), parent=root)
    k.tag(led, "pulse_1")
    k.tube("Cable", [(1.0, -w / 2 - 0.1, 1.0), (1.2, -w / 2 - 0.1, 1.15), (1.3, -w / 2 + 0.2, 1.5)], 0.03, "Black",
           parent=root)


# ----------------------------------------------------------------------
# Ультразвуковая ловушка для кротов (2x2)
# ----------------------------------------------------------------------
def mole_trap(k, root):
    k.blob("Mound", (1.7, 1.5, 0.5), (0, 0, 0.0), "Soil", parent=root, jitter=0.12, seed=3, squash_bottom=0.0)
    k.lathe("Stake", [(0.12, 0.0), (0.12, 1.2), (0.0, 1.2)], (0, 0, 0.0), "Green", segments=16, parent=root)
    k.lathe("Housing", [(0.0, 0.0), (0.3, 0.0), (0.42, 0.12), (0.45, 0.45), (0.4, 0.58), (0.0, 0.6)],
            (0, 0, 1.1), "Green", segments=32, parent=root)
    for i, z in enumerate((0.18, 0.28, 0.38)):
        k.lathe(f"Grille{i}", [(0.455, 0), (0.47, 0.015), (0.47, 0.04), (0.455, 0.055)], (0, 0, 1.1 + z),
                "GreenDark", segments=32, parent=root)
    solar_panel(k, "Solar", 0.62, 0.5, (0, 0.05, 1.74), -25, root)
    k.tube("Antenna", [(0.25, 0.2, 1.65), (0.3, 0.25, 2.2)], 0.015, "Black", parent=root, smooth_path=False)
    tip = k.lens("AntennaTip", 0.04, (0.3, 0.25, 2.2), "NeonRed", parent=root, height=0.9)
    k.tag(tip, "pulse_2")
    for i, r in enumerate((0.75, 0.95)):
        ring = k.torus(f"Wave{i}", r, 0.035, (0, 0, 0.12 + i * 0.01), "NeonCyan", parent=root, seg=48, ring=8)
        k.tag(ring, f"pulse_{2 + i}")


# ----------------------------------------------------------------------
# Табло суточной выработки (5x1.5). Сам экран — процедурная деталь «Board» с живым текстом,
# здесь — рама вокруг неё (экран 5 x 2.4 на высоте 3.9).
# ----------------------------------------------------------------------
def led_board(k, root):
    for x in (-2.2, 2.2):
        k.box(f"Foot{x}", (0.7, 0.9, 0.12), (x, 0, 0.06), "MetalDark", bevel=0.03, parent=root)
        k.box(f"Post{x}", (0.28, 0.28, 2.75), (x, 0, 1.4), "MetalDark", bevel=0.05, parent=root)
    cz, bw, bh = 3.9, 5.0, 2.4
    t = 0.18
    k.box("FrameTop", (bw + 2 * t, 0.5, t), (0, 0, cz + bh / 2 + t / 2), "Black", bevel=0.05, parent=root)
    k.box("FrameBottom", (bw + 2 * t, 0.5, t), (0, 0, cz - bh / 2 - t / 2), "Black", bevel=0.05, parent=root)
    for x in (-1, 1):
        k.box(f"FrameSide{x}", (t, 0.5, bh), (x * (bw / 2 + t / 2), 0, cz), "Black", bevel=0.05, parent=root)
    k.box("Back", (bw, 0.08, bh), (0, 0.19, cz), "MetalDark", bevel=0.02, parent=root)
    k.box("Hood", (bw + 0.6, 0.75, 0.1), (0, -0.12, cz + bh / 2 + t + 0.06), "MetalDark", bevel=0.04,
          rot=(-8, 0, 0), parent=root)
    for x in (-1.6, 0, 1.6):
        k.lens(f"Bolt{x}", 0.05, (x, -0.26, cz - bh / 2 - t / 2), "Chrome", rot=(90, 0, 0), parent=root)
    k.potato("Mascot", (bw / 2 + 0.45, -0.1, cz + bh / 2 + 0.3), 0.7, parent=root, key="Potato", seed=21,
             rot=(80, 0, 20))


# ----------------------------------------------------------------------
# Капельная система подземного орошения (3x3) с длинным шлангом вдоль грядок
# ----------------------------------------------------------------------
def drip_system(k, root):
    tank = [(0.0, 0.0), (1.0, 0.0), (1.08, 0.08), (1.1, 2.0), (1.0, 2.15), (0.0, 2.18)]
    k.lathe("Tank", tank, (0, 0.2, 0), "Blue", segments=40, parent=root)
    for z in (0.5, 1.0, 1.5):
        k.lathe(f"TankRib{z}", [(1.105, 0), (1.13, 0.03), (1.13, 0.1), (1.105, 0.13)], (0, 0.2, z), "BlueDark",
                segments=40, parent=root)
    k.lathe("Lid", [(0.42, 0), (0.42, 0.12), (0.36, 0.16), (0.0, 0.16)], (0, 0.2, 2.17), "White", parent=root)
    k.lathe("Gauge", [(0.08, 0), (0.08, 1.6), (0.0, 1.6)], (0.8, -0.55, 0.25), "Glass", segments=12, parent=root)
    # насос и кран
    k.box("PumpBase", (0.9, 0.7, 0.12), (0.8, -1.1, 0.06), "MetalDark", bevel=0.03, parent=root)
    k.motor("Pump", (0.8, -1.1, 0.45), parent=root, key="Black", radius=0.22, height=0.45, rot=(-90, 0, 0))
    k.box("PumpBody", (0.5, 0.42, 0.5), (0.8, -1.25, 0.42), "MetalDark", bevel=0.06, parent=root)
    k.torus("Valve", 0.14, 0.03, (0.8, -1.25, 0.88), "Red", parent=root)
    k.lathe("ValveStem", [(0.03, 0), (0.03, 0.2), (0.0, 0.2)], (0.8, -1.25, 0.68), "Chrome", parent=root)
    k.tube("Feed", [(0.6, 0.0, 0.3), (0.65, -0.7, 0.25), (0.8, -1.05, 0.3)], 0.07, "Black", parent=root)
    k.tube("Outlet", [(0.8, -1.45, 0.3), (0.8, -2.4, 0.2), (0.8, -3.2, 0.15)], 0.09, "Black", parent=root)
    # магистраль вдоль грядок с капельницами
    k.tube("Line", [(-10, -3.2, 0.15), (10, -3.2, 0.15)], 0.09, "Black", parent=root, smooth_path=False)
    for i in range(-9, 10, 2):
        k.lathe(f"Dripper{i}", [(0.06, 0), (0.06, 0.08), (0.03, 0.14), (0.0, 0.14)], (i + 0.5, -3.2, 0.2), "Green",
                segments=10, parent=root)
        drop = k.lathe(f"Drop{i}", [(0.0, 0.0), (0.04, 0.03), (0.035, 0.06), (0.0, 0.1)], (i + 0.5, -3.32, 0.04),
                       "Water", segments=10, parent=root)
        k.tag(drop, "pulse_2")
