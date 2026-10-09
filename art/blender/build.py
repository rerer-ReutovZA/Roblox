"""Сборка ассетов Potato Tycoon в Blender (запуск без интерфейса).

  blender -b --python art/blender/build.py -- [--only BedWood,Shuttle] [--no-render] [--frames]
          [--samples 96] [--save art/PotatoTycoon_Assets.blend]

Делает:
  * строит каждый ассет в своей коллекции (корень — пустышка с именем ключа модели из Config/Items);
  * art/export/fbx/<Ассет>.fbx — для импорта в Roblox Studio (детали склеены по материалам; анимации — в именах);
  * art/export/glb/<Ассет>.glb — каждый ассет с анимацией для просмотра в любом 3D-просмотрщике;
  * art/previews/<Ассет>.png — рендер Cycles; с --frames ещё кадры анимации в build/frames/<Ассет>/.
"""

import argparse
import json
import math
import os
import re
import sys
import time

import bmesh
import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)

import kit  # noqa: E402
import palette_luau  # noqa: E402
from assets import agro, agro2, agro3, energy, energy2, factory, factory2, misc, misc2, science  # noqa: E402

# ключ = Config/Items.model (или служебная модель игры), функция, вид камеры (yaw, pitch, zoom)
ASSETS = [
    ("BedWood", agro.bed_wood, (35, 30, 1.0)),
    ("BedStone", agro.bed_stone, (35, 30, 1.0)),
    ("BedMetal", agro.bed_metal, (35, 30, 1.0)),
    ("SellStand", agro.sell_stand, (28, 18, 1.0)),
    ("HarvestTower", agro.harvest_tower, (32, 14, 1.0)),
    ("AutoBedT1", agro.auto_bed_t1, (35, 30, 1.0)),
    ("Sprinkler", agro.sprinkler, (30, 20, 1.0)),
    ("FenceWood", agro2.fence_wood, (28, 14, 1.0, ("Gate", "Sign", "FLPost7", "FRPost1"))),
    ("WateringCan", agro2.watering_can, (35, 22, 1.0)),
    ("BigSack", agro2.big_sack, (30, 15, 1.0)),
    ("LampBasic", agro2.lamp_basic, (60, 15, 1.0)),
    ("LampLed", agro2.lamp_led, (60, 15, 1.0)),
    ("LampQuantum", agro2.lamp_quantum, (60, 15, 1.0)),
    ("AutoBedT2", agro2.auto_bed_t2, (35, 30, 1.0)),
    ("AutoBedT3", agro2.auto_bed_t3, (35, 30, 1.0)),
    ("NeonSign", agro2.neon_sign, (20, 10, 1.0)),
    ("SolarSmall", agro2.solar_small, (35, 25, 1.0)),
    ("MoleTrap", agro2.mole_trap, (30, 20, 1.0)),
    ("LedBoard", agro2.led_board, (25, 12, 1.0)),
    ("DripSystem", agro2.drip_system, (30, 30, 1.0, ("Tank", "Pump", "Lid", "Valve", "Outlet", "Dripper-1",
                                                     "Dripper1"))),
    ("HydroTray", agro3.hydro_tray_item, (35, 30, 1.0)),
    ("HydroRack2", agro3.hydro_rack2, (35, 22, 1.0)),
    ("HydroRack3", agro3.hydro_rack3, (35, 22, 1.0)),
    ("HydroTower", agro3.hydro_tower, (30, 15, 1.0)),
    ("Aeroponic", agro3.aeroponic, (25, 18, 1.0)),
    ("GreenhouseSmall", agro3.greenhouse_small, (35, 22, 1.0)),
    ("GreenhousePro", agro3.greenhouse_pro, (30, 22, 1.0)),
    ("Fertilizer", agro3.fertilizer, (35, 20, 1.0)),
    ("BiohumusTank", agro3.biohumus_tank, (40, 22, 1.0)),
    ("Fogger", agro3.fogger, (30, 18, 1.0)),
    ("SoilSensor", agro3.soil_sensor, (25, 15, 1.0)),
    ("Ionizer", agro3.ionizer, (30, 15, 1.0)),
    ("ForceDome", agro3.force_dome, (30, 15, 1.0)),
    ("Flagpole", agro3.flagpole, (55, 12, 1.0, ("Cloth", "Text", "Emblem", "Finial", "Clip"))),
    ("Mascot", agro3.mascot, (25, 12, 1.0)),
    ("GenPetrol", energy.gen_petrol, (35, 22, 1.0)),
    ("WindSmall", energy.wind_small, (30, 12, 1.0)),
    ("GenDiesel25", energy2.gen_diesel25, (35, 20, 1.0)),
    ("GenDiesel100", energy2.gen_diesel100, (35, 20, 1.0)),
    ("Biogas", energy2.biogas, (35, 20, 1.0)),
    ("BiogasTurbine", energy2.biogas_turbine, (35, 22, 1.0)),
    ("SolarMono", energy2.solar_mono, (30, 20, 1.0)),
    ("Wind50", energy2.wind50, (30, 10, 1.0)),
    ("Geothermal", energy2.geothermal, (35, 25, 1.0)),
    ("Substation", energy2.substation, (30, 25, 1.0)),
    ("Battery", energy2.battery, (35, 22, 1.0)),
    ("Megapack", energy2.megapack, (30, 18, 1.0)),
    ("PotatoReactor", energy2.potato_reactor, (30, 18, 1.0)),
    ("Fusion", energy2.fusion, (30, 25, 1.0)),
    ("Office", energy2.office, (30, 25, 1.0)),
    ("DroneStation", energy2.drone_station, (35, 25, 1.0)),
    ("AiSorter", energy2.ai_sorter, (30, 20, 1.0)),
    ("CoolingTower", energy2.cooling_tower, (30, 12, 1.0)),
    ("Breaker", energy2.breaker, (30, 15, 1.0)),
    ("FactoryHall", factory2.factory_hall, (25, 30, 1.0)),
    ("Washer", factory2.washer, (32, 22, 1.0)),
    ("Peeler", factory2.peeler, (32, 22, 1.0)),
    ("Slicer", factory.slicer, (32, 24, 1.0)),
    ("Fryer", factory2.fryer, (32, 22, 1.0)),
    ("SpiceDrum", factory2.spice_drum, (32, 22, 1.0)),
    ("PureeVat", factory2.puree_vat, (32, 22, 1.0)),
    ("Packer", factory2.packer, (32, 22, 1.0)),
    ("CryoTunnel", factory2.cryo_tunnel, (32, 22, 1.0)),
    ("Sublimator", factory2.sublimator, (32, 22, 1.0)),
    ("Autoclave", factory2.autoclave, (32, 22, 1.0)),
    ("StarchMill", factory2.starch_mill, (32, 22, 1.0)),
    ("Bioreactor", factory2.bioreactor, (32, 20, 1.0)),
    ("Extruder", factory2.extruder, (32, 22, 1.0)),
    ("QuantumConverter", factory2.quantum_converter, (30, 18, 1.0)),
    ("Lab", science.lab, (30, 28, 1.0)),
    ("Centrifuge", science.centrifuge, (30, 25, 1.0)),
    ("Mutagenesis", science.mutagenesis, (30, 20, 1.0)),
    ("Incubator", science.incubator, (30, 18, 1.0)),
    ("QuantumIrradiator", science.quantum_irradiator, (30, 15, 1.0)),
    ("HoloTerminal", science.holo_terminal, (30, 18, 1.0)),
    ("SeedVault", science.seed_vault, (30, 18, 1.0)),
    ("GodMonument", science.god_monument, (30, 15, 1.0)),
    ("LaunchTower", science.launch_tower, (35, 12, 1.0)),
    ("Beacon", science.beacon, (30, 10, 1.0)),
    ("Satellite", science.satellite, (30, 15, 1.0)),
    ("StarTerminal", science.star_terminal, (30, 15, 1.0)),
    ("Drone", misc.drone, (30, 25, 1.0)),
    ("Bug", misc.bug, (30, 30, 1.0)),
    ("Robot", misc2.robot, (30, 15, 1.0)),
    ("FounderStatue", misc2.founder_statue, (25, 12, 1.0)),
    ("HallOfFame", misc2.hall_of_fame, (25, 10, 1.0)),
    ("RebirthGate", misc2.rebirth_gate, (25, 10, 1.0)),
    ("GoldenPedestal", misc2.golden_pedestal, (30, 15, 1.0)),
    ("CryoCapsule", misc2.cryo_capsule, (40, 25, 1.0)),
    ("StreetLight", misc2.street_light, (60, 12, 1.0)),
    ("TrashBin", misc2.trash_bin, (30, 18, 1.0)),
    ("Bench", misc2.bench, (30, 15, 1.0)),
    ("Tree", misc2.tree, (30, 10, 1.0)),
    ("LaunchPad", misc.launch_pad, (30, 30, 1.0)),
    ("Shuttle", misc.shuttle, (28, 12, 1.0)),
]


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--only", default="")
    p.add_argument("--no-render", action="store_true")
    p.add_argument("--no-export", action="store_true")
    p.add_argument("--frames", action="store_true", help="вместо превью — кадры анимации в build/frames/")
    p.add_argument("--samples", type=int, default=96)
    p.add_argument("--res", default="1280x960")
    p.add_argument("--save", default="")
    p.add_argument("--out", default=os.path.join(ROOT, "art", "previews"))
    p.add_argument("--view", default="Khronos PBR Neutral", help="Khronos PBR Neutral | Standard | AgX")
    p.add_argument("--look", default="")
    return p.parse_args(argv)


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.fps = kit.FPS
    scene.frame_start = 1
    scene.frame_end = kit.LOOP
    scene.unit_settings.system = "NONE"
    return scene


def build_assets(scene, only):
    built = []
    for key, fn, view in ASSETS:
        if only and key not in only:
            continue
        coll = bpy.data.collections.new(key)
        scene.collection.children.link(coll)
        k = kit.Kit(coll)
        root = k.empty(key)
        t = time.time()
        fn(k, root)
        meshes = [o for o in coll.objects if o.type == "MESH"]
        print(f"[build] {key:14s} {len(meshes):4d} деталей  {time.time() - t:.1f} с", flush=True)
        built.append((key, coll, root, view))
    return built


def apply_modifiers(coll):
    """Применяет модификаторы (фаски, толщина), чтобы экспортировалась итоговая геометрия."""
    dg = bpy.context.evaluated_depsgraph_get()
    for obj in coll.objects:
        if obj.type == "MESH" and obj.modifiers:
            mesh = bpy.data.meshes.new_from_object(obj.evaluated_get(dg))
            old = obj.data
            obj.modifiers.clear()
            obj.data = mesh
            if old.users == 0:
                bpy.data.meshes.remove(old)


# ----------------------------------------------------------------------
# Сцена для рендера
# ----------------------------------------------------------------------
BACKDROP = (0.63, 0.72, 0.55)  # цвет фона превью (линейный)


def setup_stage(scene, samples, res, view="Khronos PBR Neutral", look=""):
    w, h = (int(v) for v in res.split("x"))
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 6
    scene.render.resolution_x = w
    scene.render.resolution_y = h
    # пол — ловец теней, фон дорисовывает композитор: чистый ровный фон без линии горизонта
    scene.render.film_transparent = True
    scene.view_settings.view_transform = view
    for name in (f"{view} - {look}", look, "None"):
        try:
            scene.view_settings.look = name
            break
        except TypeError:
            continue
    scene.view_settings.exposure = -0.35 if view == "Standard" else 0.0
    scene.render.image_settings.color_mode = "RGB"
    scene.use_nodes = True
    ct = scene.node_tree
    ct.nodes.clear()
    layers = ct.nodes.new("CompositorNodeRLayers")
    over = ct.nodes.new("CompositorNodeAlphaOver")
    over.inputs[1].default_value = (*BACKDROP, 1)
    comp = ct.nodes.new("CompositorNodeComposite")
    ct.links.new(layers.outputs["Image"], over.inputs[2])
    ct.links.new(over.outputs["Image"], comp.inputs["Image"])

    world = bpy.data.worlds.new("Sky")
    scene.world = world
    world.use_nodes = True
    nt = world.node_tree
    nt.nodes.clear()
    sky = nt.nodes.new("ShaderNodeTexSky")
    sky.sky_type = "NISHITA"
    sky.sun_elevation = math.radians(38)
    sky.sun_rotation = math.radians(215)
    sky.sun_intensity = 0.35
    bg = nt.nodes.new("ShaderNodeBackground")
    bg.inputs["Strength"].default_value = 0.22
    out = nt.nodes.new("ShaderNodeOutputWorld")
    nt.links.new(sky.outputs["Color"], bg.inputs["Color"])
    nt.links.new(bg.outputs["Background"], out.inputs["Surface"])

    stage = bpy.data.collections.new("Stage")
    scene.collection.children.link(stage)
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 2.8
    sun.data.angle = math.radians(3)
    sun.data.color = (1.0, 0.95, 0.88)
    sun.rotation_euler = (math.radians(52), 0, math.radians(35))
    stage.objects.link(sun)
    fill = bpy.data.objects.new("Fill", bpy.data.lights.new("Fill", "SUN"))
    fill.data.energy = 0.6
    fill.data.color = (0.75, 0.85, 1.0)
    fill.data.use_shadow = False
    fill.rotation_euler = (math.radians(60), 0, math.radians(-140))
    stage.objects.link(fill)

    # пол: мягкая трава
    ground_mat = bpy.data.materials.new("StageGround")
    ground_mat.use_nodes = True
    gnt = ground_mat.node_tree
    bsdf = gnt.nodes["Principled BSDF"]
    noise_tex = gnt.nodes.new("ShaderNodeTexNoise")
    noise_tex.inputs["Scale"].default_value = 0.35
    noise_tex.inputs["Detail"].default_value = 8
    ramp = gnt.nodes.new("ShaderNodeValToRGB")
    # пол — ловец теней: его цвет виден только в отражениях, поэтому нейтральный
    ramp.color_ramp.elements[0].color = (0.32, 0.34, 0.3, 1)
    ramp.color_ramp.elements[1].color = (0.42, 0.44, 0.4, 1)
    gnt.links.new(noise_tex.outputs["Fac"], ramp.inputs["Fac"])
    gnt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.95
    mesh = bpy.data.meshes.new("Ground")
    s = 400
    mesh.from_pydata([(-s, -s, 0), (s, -s, 0), (s, s, 0), (-s, s, 0)], [], [(0, 1, 2, 3)])
    mesh.materials.append(ground_mat)
    ground = bpy.data.objects.new("Ground", mesh)
    ground.is_shadow_catcher = True
    stage.objects.link(ground)

    cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    cam.data.lens = 50
    stage.objects.link(cam)
    scene.camera = cam
    return cam


def bounds(coll):
    lo = Vector((1e9, 1e9, 1e9))
    hi = -lo
    for obj in coll.objects:
        if obj.type != "MESH":
            continue
        for corner in obj.bound_box:
            p = obj.matrix_world @ Vector(corner)
            lo = Vector(map(min, lo, p))
            hi = Vector(map(max, hi, p))
    return lo, hi


def frame_camera(cam, coll, view, aspect, margin=0.1):
    """Ставит камеру так, чтобы габариты всех деталей вписались в кадр с полями (с центровкой)."""
    yaw, pitch, zoom = view[:3]
    focus = view[3] if len(view) > 3 else None  # кадрировать только по деталям с этими префиксами имени
    meshes = [o for o in coll.objects if o.type == "MESH" and (not focus or o.get("base", "").startswith(focus))]
    pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
    lo, hi = bounds(coll)
    target = (lo + hi) / 2
    hfov = 2 * math.atan(cam.data.sensor_width / 2 / cam.data.lens)
    tx = math.tan(hfov / 2) * (1 - margin) * zoom
    ty = tx / aspect
    yaw_r, pitch_r = math.radians(yaw), math.radians(pitch)
    f = -Vector((math.sin(yaw_r) * math.cos(pitch_r), -math.cos(yaw_r) * math.cos(pitch_r), math.sin(pitch_r)))
    r = f.cross(Vector((0, 0, 1))).normalized()
    u = r.cross(f)
    def fit(target):
        rel = [p - target for p in pts]
        dist = max(max(abs(q.dot(r)) / tx, abs(q.dot(u)) / ty) - q.dot(f) for q in rel)
        return rel, dist

    for _ in range(6):
        rel, dist = fit(target)
        xs = [q.dot(r) / ((q.dot(f) + dist) * tx) for q in rel]
        ys = [q.dot(u) / ((q.dot(f) + dist) * ty) for q in rel]
        mx, my = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
        target = target + r * (mx * tx * dist) + u * (my * ty * dist)
    _, dist = fit(target)
    cam.location = target - f * dist
    cam.rotation_euler = f.to_track_quat("-Z", "Y").to_euler()
    cam.data.clip_end = dist * 10


def render_asset(scene, cam, built, key, view, out_png, frames_dir=None):
    """Превью (PNG) или, с frames_dir, кадры анимации (каждый второй кадр цикла → 12 к/с)."""
    for k2, coll, _, _ in built:
        coll.hide_render = k2 != key
    coll = next(c for k2, c, _, _ in built if k2 == key)
    aspect = scene.render.resolution_x / scene.render.resolution_y
    scene.frame_set(1)
    frame_camera(cam, coll, view, aspect)
    t = time.time()
    if not frames_dir:
        scene.render.filepath = out_png
        bpy.ops.render.render(write_still=True)
        print(f"[render] {key} → {os.path.relpath(out_png, ROOT)} ({time.time() - t:.1f} с)", flush=True)
        return
    os.makedirs(frames_dir, exist_ok=True)
    for i, f in enumerate(range(1, kit.LOOP + 1, 2)):
        scene.frame_set(f)
        scene.render.filepath = os.path.join(frames_dir, f"{i:03d}.png")
        bpy.ops.render.render(write_still=True)
    print(f"[frames] {key}: {kit.LOOP // 2} кадров ({time.time() - t:.1f} с)", flush=True)


# ----------------------------------------------------------------------
# Экспорт
# ----------------------------------------------------------------------
# Группы, которые игра находит по имени (рост кустов, клубни, старт шаттла, пламя)
HOOKS = {"Bush", "Tubers", "Stack", "Flames"}
MAX_TRIS = 10000  # на одну MeshPart (лимит Roblox — 20k, берём с запасом)


def select_only(objects):
    bpy.context.view_layer.update()
    for o in bpy.context.view_layer.objects:
        if o is not None:
            o.select_set(False)
    for o in objects:
        if o is not None:
            o.select_set(True)


def num(v):
    return f"{v:.3f}".rstrip("0").rstrip(".") if abs(v) >= 0.0005 else "0"


def roblox(v):
    """Точка Blender → координаты модели Roblox: (x, y, z) → (x, z, -y)."""
    return f"{num(v.x)},{num(v.z)},{num(-v.y)}"


def scope_of(obj, root):
    """Путь групп (хуки и анимируемые пустышки) и ближайшая анимируемая пустышка."""
    path, anim_scope = [], None
    node = obj.parent
    while node and node != root:
        if "anim" in node:
            anim_scope = anim_scope or node
            path.append(node["base"])
        elif node.get("base") in HOOKS:
            path.append(node["base"])
        node = node.parent
    path.reverse()
    return path, anim_scope


def join(objs, name):
    """Склеивает объекты в один (через bpy.ops, чтобы сохранить нормали фасок)."""
    for o in objs:
        mw = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = mw
    if len(objs) > 1:
        with bpy.context.temp_override(active_object=objs[0], object=objs[0], selected_objects=objs,
                                       selected_editable_objects=objs):
            bpy.ops.object.join()
    obj = objs[0]
    obj.name = name
    obj.data.name = name
    return obj


def tri_count(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def face_of(normal):
    """Нормаль в Blender → грань детали в Roblox (Enum.NormalId)."""
    r = (normal.x, normal.z, -normal.y)
    axis = max(range(3), key=lambda i: abs(r[i]))
    return (("Right", "Left"), ("Top", "Bottom"), ("Back", "Front"))[axis][0 if r[axis] > 0 else 1]


def label_markers(key, coll, root):
    """Надписи → плоские метки «…__Ключ!номер»: игра рисует на них текст Roblox (его переводит автоперевод)."""
    labels = {}
    for obj in [o for o in coll.objects if o.type == "MESH" and "label" in o]:
        mw = obj.matrix_world
        pts = [mw @ v.co for v in obj.data.vertices]
        if not pts:
            bpy.data.objects.remove(obj)
            continue
        lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
        hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
        normal = (mw.to_3x3() @ Vector((0, 0, 1))).normalized()
        size = Vector([max(h - l, 0.02) for h, l in zip(hi, lo)])
        # небольшие поля, чтобы перевод (часто длиннее) поместился
        for i in range(3):
            if abs(normal[i]) < 0.7:
                size[i] *= 1.12
        n = len(labels) + 1
        labels[n] = {"text": obj["label"], "face": face_of(normal)}
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1)
        bmesh.ops.scale(bm, vec=size, verts=bm.verts)
        mesh = bpy.data.meshes.new(f"Label{n}")
        bm.to_mesh(mesh)
        bm.free()
        marker = bpy.data.objects.new(f"Label{n}", mesh)
        coll.objects.link(marker)
        marker.parent = obj.parent
        marker.matrix_world = Matrix.Translation((lo + hi) / 2)
        marker["base"], marker["key"], marker["label_id"] = f"Label{n}", obj["key"], n
        bpy.data.objects.remove(obj)
    return labels


MAX_NAME = 50  # 3D Importer Roblox обрезает более длинные имена посередине
SERIAL = [0]


def hold_name(obj, name):
    """Имя детали в игре хранится в свойстве rbx_name, а в Blender — уникальное «0001|имя»:
    одинаковые имена в разных ассетах иначе получили бы суффиксы .001, .002… и попали бы в FBX."""
    SERIAL[0] += 1
    obj["rbx_name"] = name
    obj.name = obj.data.name = f"{SERIAL[0]:04d}|{name}"


def merge_asset(key, coll, root):
    """Детали одного материала в одной группе → одна MeshPart с именем «Путь/Группы__КлючПалитры[~n][!надпись]».
    Анимация и точка вращения группы (в координатах Roblox) — в groups: игра берёт их из Config/AssetMeta.luau."""
    labels = label_markers(key, coll, root)
    groups = {}
    for obj in [o for o in coll.objects if o.type == "MESH"]:
        path, scope = scope_of(obj, root)
        if "label_id" in obj:  # метка надписи: всегда отдельная деталь
            pivot = roblox(scope.matrix_world.translation) if scope is not None else None
            gid = ("/".join(path) or "Body", obj["key"], scope["anim"] if scope is not None else None, pivot,
                   f"!{obj['label_id']}")
        elif "anim" in obj:  # собственная анимация детали (например, мигающая лампа) — отдельная деталь
            gid = ("/".join(path + [obj["base"]]), obj["key"], obj["anim"], None)
        elif obj.get("solo"):  # стены, сквозь проёмы которых ходят игроки: своя деталь — своя коллизия
            gid = ("/".join(path) or "Body", obj["key"], None, None, obj.name)
        elif scope is not None:
            gid = ("/".join(path), obj["key"], scope["anim"], roblox(scope.matrix_world.translation))
        else:
            gid = ("/".join(path) or "Body", obj["key"], None, None)
        groups.setdefault(gid, []).append(obj)
    parts, meta, used = [], {}, {}
    for (path, pkey, anim, pivot, *extra), objs in sorted(groups.items(), key=lambda kv: kv[0][:2]):
        # в именах групп — только буквы, цифры, «_», «-» и «/» (Flame1.6 → Flame1_6)
        path = re.sub(r"[^A-Za-z0-9_\-/]", "_", path)
        if anim:
            old = meta.get(path)
            if old and old != {"anim": anim, "pivot": pivot}:
                raise RuntimeError(f"{key}: у группы {path} две разные анимации: {old} и {anim} {pivot}")
            meta[path] = {"anim": anim, "pivot": pivot}
        base = f"{path}__{pkey}"
        label = extra[0] if extra and str(extra[0]).startswith("!") else ""
        chunks, chunk, tris = [], [], 0
        for o in objs:
            t = tri_count(o)
            if chunk and tris + t > MAX_TRIS:
                chunks.append(chunk)
                chunk, tris = [], 0
            chunk.append(o)
            tris += t
        chunks.append(chunk)
        for c in chunks:
            # одинаковые имена внутри ассета (куски большой группы, отдельные стены) различает «~n»
            n = used[base + label] = used.get(base + label, 0) + 1
            name = base + (f"~{n}" if n > 1 else "") + label
            if len(name) > MAX_NAME:
                raise RuntimeError(f"{key}: имя детали длиннее {MAX_NAME} символов: {name}")
            merged = join(c, name)
            hold_name(merged, name)
            merged.parent = root
            parts.append((name, tri_count(merged)))
    # пустышки больше не нужны: группы — в именах, анимации и точки вращения — в meta
    for o in [o for o in coll.objects if o.type == "EMPTY" and o != root]:
        bpy.data.objects.remove(o)
    # калибровочный куб 1x1x1 в начале координат ассета: по нему игра находит origin и масштаб импорта
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1)
    mesh = bpy.data.meshes.new("Origin__Pivot")
    bm.to_mesh(mesh)
    bm.free()
    marker = bpy.data.objects.new("Origin__Pivot", mesh)
    coll.objects.link(marker)
    hold_name(marker, "Origin__Pivot")
    marker.parent = root
    # две точки осей Roblox (+X и +Z на расстоянии 1 стад): по ним игра находит поворот импорта —
    # симметричный куб не выдал бы, если 3D Importer развернёт модель
    for name, pos in (("Origin__AxisX", (1, 0, 0)), ("Origin__AxisZ", (0, -1, 0))):
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=0.2)
        mesh = bpy.data.meshes.new(name)
        bm.to_mesh(mesh)
        bm.free()
        axis = bpy.data.objects.new(name, mesh)
        coll.objects.link(axis)
        hold_name(axis, name)
        axis.parent = root
        axis.location = pos
    total = sum(t for _, t in parts)
    print(f"[merge] {key:14s} {len(parts):3d} MeshPart, {total:6d} треугольников", flush=True)
    return {"parts": [{"name": n, "tris": t} for n, t in parts], "tris": total,
            "labels": {str(i): v for i, v in labels.items()},
            "groups": {p: meta[p] for p in sorted(meta)}}


def export_glb(built, out_dir):
    os.makedirs(os.path.join(out_dir, "glb"), exist_ok=True)
    for key, coll, _, _ in built:
        select_only(list(coll.objects))
        bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, "glb", f"{key}.glb"), export_format="GLB",
                                  use_selection=True, export_animations=True, export_apply=True,
                                  export_yup=True)


def export_fbx(built, out_dir):
    os.makedirs(os.path.join(out_dir, "fbx"), exist_ok=True)
    # «FBX Units Scale» при системе единиц None — как советует руководство Roblox по Blender:
    # 1 единица Blender = 1 стад, у объектов масштаб 1 (масштаб импорта игра всё равно проверяет по Origin__Pivot)
    opts = dict(use_selection=True, object_types={"EMPTY", "MESH"}, apply_unit_scale=True,
                apply_scale_options="FBX_SCALE_UNITS", axis_forward="-Z", axis_up="Y", bake_anim=False,
                mesh_smooth_type="OFF", add_leaf_bones=False, use_mesh_modifiers=True)
    manifest = {}
    for key, coll, root, _ in built:
        manifest[key] = merge_asset(key, coll, root)
    for key, coll, root, _ in built:
        objs = [o for o in coll.objects if "rbx_name" in o]
        held = {o: o.name for o in objs}
        # на время экспорта — точные имена (в других ассетах сейчас у всех имена «0001|…», конфликтов нет)
        for o in objs:
            o.name = o.data.name = o["rbx_name"]
            assert o.name == o["rbx_name"], f"{key}: Blender переименовал {o['rbx_name']} в {o.name}"
        select_only(list(coll.objects))
        bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, "fbx", f"{key}.fbx"), **opts)
        for o, name in held.items():
            o.name = o.data.name = name
    path = os.path.join(out_dir, "manifest.json")
    old = json.load(open(path, encoding="utf-8")) if os.path.exists(path) else {}
    old.update(manifest)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(old, f, ensure_ascii=False, indent=1, sort_keys=True)
    write_model_text(old)
    write_asset_meta(old)
    print(f"[export] {len(built)} ассетов → art/export/fbx/*.fbx, glb/, manifest.json", flush=True)


def luau_str(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def write_model_text(manifest):
    """Тексты надписей моделей → src/shared/Config/ModelText.luau (исходный язык — английский)."""
    lines = [
        "-- Надписи на моделях из Blender: ключ модели → номер метки → текст и грань детали.",
        "-- Исходный язык — английский; TextLabel с AutoLocalize переводит автоперевод Roblox.",
        "-- Сгенерировано art/blender/build.py — правьте тексты в art/blender/assets/*.py.",
        "",
        "export type Label = { text: string, face: string }",
        "",
        "local ModelText: { [string]: { [number]: Label } } = {",
    ]
    for key in sorted(manifest):
        labels = manifest[key].get("labels") or {}
        if not labels:
            continue
        lines.append(f"\t{key} = {{")
        for i in sorted(labels, key=int):
            v = labels[i]
            lines.append(f"\t\t[{int(i)}] = {{ text = {luau_str(v['text'])}, face = {luau_str(v['face'])} }},")
        lines.append("\t},")
    lines += ["}", "", "return ModelText", ""]
    with open(os.path.join(ROOT, "src", "shared", "Config", "ModelText.luau"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def write_asset_meta(manifest):
    """Анимации групп → src/shared/Config/AssetMeta.luau (имена деталей в FBX короткие и без них)."""
    lines = [
        "-- Анимированные группы моделей из Blender: ключ модели → путь группы → анимация и точка вращения",
        "-- (координаты модели Roblox, стады). Формат анимации — в src/shared/AssetName.luau.",
        "-- Сгенерировано art/blender/build.py.",
        "",
        "export type Group = { anim: string, pivot: { number }? }",
        "",
        "local AssetMeta: { [string]: { [string]: Group } } = {",
    ]
    for key in sorted(manifest):
        groups = manifest[key].get("groups") or {}
        if not groups:
            continue
        lines.append(f"\t{key} = {{")
        for path in sorted(groups):
            g = groups[path]
            pivot = f", pivot = {{ {', '.join(g['pivot'].split(','))} }}" if g.get("pivot") else ""
            lines.append(f"\t\t[{luau_str(path)}] = {{ anim = {luau_str(g['anim'])}{pivot} }},")
        lines.append("\t},")
    lines += ["}", "", "return AssetMeta", ""]
    with open(os.path.join(ROOT, "src", "shared", "Config", "AssetMeta.luau"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def main():
    args = parse_args()
    only = {s for s in args.only.split(",") if s}
    scene = reset_scene()
    built = build_assets(scene, only)
    for _, coll, _, _ in built:
        apply_modifiers(coll)
    if not args.no_render:
        cam = setup_stage(scene, args.samples, args.res, args.view, args.look)
        for key, _, _, view in built:
            frames = os.path.join(ROOT, "build", "frames", key) if args.frames else None
            render_asset(scene, cam, built, key, view, os.path.join(args.out, f"{key}.png"), frames)
    if args.save:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, args.save))
        print(f"[save] {args.save}", flush=True)
    if not args.no_export:
        palette_luau.write(ROOT)
        out = os.path.join(ROOT, "art", "export")
        export_glb(built, out)
        export_fbx(built, out)


main()
