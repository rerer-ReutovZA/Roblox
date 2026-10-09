"""Библиотека моделинга ассетов Potato Tycoon для Blender 4.2 (bpy).

Соглашения:
  * 1 единица Blender = 1 стад Roblox, Z вверх, пол на z = 0.
  * «Лицо» ассета смотрит в -Y (в игре это +Z — к входу на базу).
  * Имя объекта: «Имя__КлючПалитры[@анимация]», например «Rotor__White@spin_z_160».
    Ключ палитры задаёт цвет и материал Roblox (art/palette.json), а суффикс @… —
    анимацию, которую игра проигрывает сама (без загрузки анимаций в Roblox).
  * Один объект = один материал: так каждая деталь станет отдельной MeshPart.
"""

import json
import math
import os
import random

import bmesh
import bpy
from mathutils import Matrix, Vector, noise

FPS = 24
LOOP = 48  # кадров в цикле анимации превью (2 секунды)

HERE = os.path.dirname(os.path.abspath(__file__))
PALETTE = json.load(open(os.path.join(HERE, "..", "palette.json"), encoding="utf-8"))

# Ось Blender → (ось Roblox, знак) для имён анимаций: (x, y, z) Blender = (x, -z, y) Roblox,
# т.е. «лицо» -Y в Blender смотрит в +Z в игре.
ROBLOX_AXIS = {"X": ("x", 1), "Y": ("z", -1), "Z": ("y", 1)}


def srgb_to_linear(c):
    c = c / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


MATERIALS = {}


class Kit:
    def __init__(self, collection):
        self.collection = collection
        self.materials = MATERIALS
        self.rng = random.Random(1)

    # ------------------------------------------------------------------
    # Материалы (превью в Cycles; в игре — Color + Enum.Material)
    # ------------------------------------------------------------------
    def material(self, key):
        if key in self.materials:
            return self.materials[key]
        spec = PALETTE[key]
        rgb = [srgb_to_linear(v) for v in spec["color"]]
        kind = spec["roblox"]
        mat = bpy.data.materials.get(key) or bpy.data.materials.new(key)
        mat.use_nodes = True
        nt = mat.node_tree
        nt.nodes.clear()
        out = nt.nodes.new("ShaderNodeOutputMaterial")
        bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
        nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
        bsdf.inputs["Base Color"].default_value = (*rgb, 1)
        rough, metal = 0.45, 0.0
        if kind in ("Wood", "WoodPlanks"):
            rough = 0.72
            self._wood(nt, bsdf, rgb, planks=kind == "WoodPlanks")
        elif kind in ("Metal", "DiamondPlate"):
            rough, metal = 0.32, 0.85
            self._grain(nt, bsdf, rgb, scale=40, amount=0.06, bump=0.05)
        elif kind == "Foil":
            rough, metal = 0.18, 1.0
        elif kind in ("Ground", "Slate", "Concrete"):
            rough = 0.95
            self._grain(nt, bsdf, rgb, scale=9, amount=0.18, bump=0.35)
        elif kind == "Grass":
            rough = 0.75
            bsdf.inputs["Subsurface Weight"].default_value = 0.15
            bsdf.inputs["Subsurface Radius"].default_value = (0.3, 0.6, 0.2)
        elif kind == "Fabric":
            rough = 0.9
            bsdf.inputs["Sheen Weight"].default_value = 0.4
            self._grain(nt, bsdf, rgb, scale=60, amount=0.07, bump=0.1)
        elif kind == "Rubber":
            rough = 0.85
        elif kind == "Glass":
            rough = 0.04
            bsdf.inputs["Transmission Weight"].default_value = 0.92
            bsdf.inputs["IOR"].default_value = 1.4
        elif kind == "Neon":
            bsdf.inputs["Emission Color"].default_value = (*rgb, 1)
            bsdf.inputs["Emission Strength"].default_value = 6.0
            rough = 0.4
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal
        self.materials[key] = mat
        return mat

    def _grain(self, nt, bsdf, rgb, scale, amount, bump):
        """Лёгкая вариация цвета и рельеф шумом."""
        coord = nt.nodes.new("ShaderNodeTexCoord")
        tex = nt.nodes.new("ShaderNodeTexNoise")
        tex.inputs["Scale"].default_value = scale
        tex.inputs["Detail"].default_value = 6
        nt.links.new(coord.outputs["Object"], tex.inputs["Vector"])
        mix = nt.nodes.new("ShaderNodeMixRGB")
        mix.blend_type = "MULTIPLY"
        mix.inputs["Fac"].default_value = amount * 2
        mix.inputs["Color1"].default_value = (*rgb, 1)
        nt.links.new(tex.outputs["Fac"], mix.inputs["Color2"])
        nt.links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
        bmp = nt.nodes.new("ShaderNodeBump")
        bmp.inputs["Strength"].default_value = bump
        bmp.inputs["Distance"].default_value = 0.02
        nt.links.new(tex.outputs["Fac"], bmp.inputs["Height"])
        nt.links.new(bmp.outputs["Normal"], bsdf.inputs["Normal"])

    def _wood(self, nt, bsdf, rgb, planks):
        coord = nt.nodes.new("ShaderNodeTexCoord")
        mapping = nt.nodes.new("ShaderNodeMapping")
        mapping.inputs["Scale"].default_value = (1, 1, 6)
        nt.links.new(coord.outputs["Object"], mapping.inputs["Vector"])
        wave = nt.nodes.new("ShaderNodeTexWave")
        wave.wave_type = "RINGS"
        wave.inputs["Scale"].default_value = 3.5
        wave.inputs["Distortion"].default_value = 6
        wave.inputs["Detail"].default_value = 3
        nt.links.new(mapping.outputs["Vector"], wave.inputs["Vector"])
        ramp = nt.nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.elements[0].color = (*[c * 0.72 for c in rgb], 1)
        ramp.color_ramp.elements[1].color = (*rgb, 1)
        nt.links.new(wave.outputs["Fac"], ramp.inputs["Fac"])
        nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
        bmp = nt.nodes.new("ShaderNodeBump")
        bmp.inputs["Strength"].default_value = 0.15
        nt.links.new(wave.outputs["Fac"], bmp.inputs["Height"])
        nt.links.new(bmp.outputs["Normal"], bsdf.inputs["Normal"])

    # ------------------------------------------------------------------
    # Объекты
    # ------------------------------------------------------------------
    def _object(self, name, mesh, key, parent, loc, rot, anim=None):
        full = f"{name}__{key}" + (f"@{anim}" if anim else "")
        obj = bpy.data.objects.new(full, mesh)
        # метаданные для экспорта (имена Blender могут получить суффикс .001)
        obj["base"], obj["key"] = name, key
        if anim:
            obj["anim"] = anim
        self.collection.objects.link(obj)
        mesh.materials.append(self.material(key))
        obj.location = loc
        obj.rotation_euler = [math.radians(a) for a in rot]
        if parent:
            obj.parent = parent
        return obj

    def empty(self, name, loc=(0, 0, 0), parent=None, rot=(0, 0, 0)):
        obj = bpy.data.objects.new(name, None)
        obj["base"] = name
        obj.empty_display_type = "PLAIN_AXES"
        obj.empty_display_size = 0.5
        self.collection.objects.link(obj)
        obj.location = loc
        obj.rotation_euler = [math.radians(a) for a in rot]
        if parent:
            obj.parent = parent
        return obj

    def _finish(self, obj, bevel=0.0, segments=2, angle=30, smooth=True, subsurf=0):
        if bevel > 0:
            mod = obj.modifiers.new("Bevel", "BEVEL")
            mod.width = bevel
            mod.segments = segments
            mod.limit_method = "ANGLE"
            mod.angle_limit = math.radians(angle)
            mod.harden_normals = True
            mod.use_clamp_overlap = True
        if subsurf:
            mod = obj.modifiers.new("Subsurf", "SUBSURF")
            mod.levels = subsurf
            mod.render_levels = subsurf
        if smooth:
            for poly in obj.data.polygons:
                poly.use_smooth = True
        return obj

    def box(self, name, size, loc, key, bevel=0.06, segments=2, rot=(0, 0, 0), parent=None, anim=None):
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1)
        bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
        mesh = bpy.data.meshes.new(name)
        bm.to_mesh(mesh)
        bm.free()
        obj = self._object(name, mesh, key, parent, loc, rot, anim)
        return self._finish(obj, bevel=min(bevel, min(size) * 0.45), segments=segments)

    def cylinder(self, name, radius, depth, loc, key, verts=24, radius2=None, bevel=0.04, rot=(0, 0, 0),
                 parent=None, anim=None, segments=2):
        """Цилиндр (или усечённый конус) вдоль локальной оси Z, центр в loc."""
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=verts, radius1=radius,
                              radius2=radius if radius2 is None else radius2, depth=depth)
        mesh = bpy.data.meshes.new(name)
        bm.to_mesh(mesh)
        bm.free()
        obj = self._object(name, mesh, key, parent, loc, rot, anim)
        return self._finish(obj, bevel=min(bevel, depth * 0.4, radius * 0.4), segments=segments, angle=40)

    def sphere(self, name, radius, loc, key, scale=(1, 1, 1), rot=(0, 0, 0), parent=None, anim=None,
               subdiv=3, wobble=0.0, seed=0, freq=1.6, flatten_bottom=None):
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=radius)
        if wobble:
            off = Vector((seed * 7.31, seed * 3.17, seed * 5.53))
            for v in bm.verts:
                n = v.co.normalized()
                v.co += n * noise.noise(v.co * freq / max(radius, 0.01) + off) * wobble * radius
        for v in bm.verts:
            v.co = Vector((v.co.x * scale[0], v.co.y * scale[1], v.co.z * scale[2]))
            if flatten_bottom is not None and v.co.z < flatten_bottom:
                v.co.z = flatten_bottom
        mesh = bpy.data.meshes.new(name)
        bm.to_mesh(mesh)
        bm.free()
        obj = self._object(name, mesh, key, parent, loc, rot, anim)
        return self._finish(obj, smooth=True)

    def torus(self, name, major, minor, loc, key, rot=(0, 0, 0), parent=None, anim=None, seg=32, ring=12):
        bm = bmesh.new()
        rings = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            ring_verts = []
            for j in range(ring):
                b = 2 * math.pi * j / ring
                r = major + minor * math.cos(b)
                ring_verts.append(bm.verts.new((r * math.cos(a), r * math.sin(a), minor * math.sin(b))))
            rings.append(ring_verts)
        for i in range(seg):
            for j in range(ring):
                a, b = rings[i], rings[(i + 1) % seg]
                bm.faces.new((a[j], b[j], b[(j + 1) % ring], a[(j + 1) % ring]))
        mesh = bpy.data.meshes.new(name)
        bm.to_mesh(mesh)
        bm.free()
        obj = self._object(name, mesh, key, parent, loc, rot, anim)
        return self._finish(obj, smooth=True)

    def tube(self, name, points, radius, key, parent=None, anim=None, resolution=4, smooth_path=True, radii=None,
             steps=10):
        """Труба по точкам (кривая с фаской → меш); radii — множители толщины в точках (сужение)."""
        curve = bpy.data.curves.new(name + "_curve", "CURVE")
        curve.dimensions = "3D"
        curve.bevel_depth = radius
        curve.bevel_resolution = resolution
        curve.use_fill_caps = True
        if smooth_path and len(points) > 2:
            spline = curve.splines.new("BEZIER")
            spline.bezier_points.add(len(points) - 1)
            for i, (bp, p) in enumerate(zip(spline.bezier_points, points)):
                bp.co = p
                bp.handle_left_type = bp.handle_right_type = "AUTO"
                bp.radius = radii[i] if radii else 1.0
        else:
            spline = curve.splines.new("POLY")
            spline.points.add(len(points) - 1)
            for i, (sp, p) in enumerate(zip(spline.points, points)):
                sp.co = (*p, 1)
                sp.radius = radii[i] if radii else 1.0
        spline.resolution_u = steps
        tmp = bpy.data.objects.new(name + "_tmp", curve)
        self.collection.objects.link(tmp)
        dg = bpy.context.evaluated_depsgraph_get()
        mesh = bpy.data.meshes.new_from_object(tmp.evaluated_get(dg))
        bpy.data.objects.remove(tmp)
        bpy.data.curves.remove(curve)
        obj = self._object(name, mesh, key, parent, (0, 0, 0), (0, 0, 0), anim)
        return self._finish(obj, smooth=True)

    def mesh_from(self, name, verts, faces, loc, key, parent=None, anim=None, bevel=0.0, rot=(0, 0, 0), smooth=False,
                  recalc=False):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata([Vector(v) for v in verts], [], faces)
        mesh.validate()
        if recalc:
            bm = bmesh.new()
            bm.from_mesh(mesh)
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
            bm.to_mesh(mesh)
            bm.free()
        obj = self._object(name, mesh, key, parent, loc, rot, anim)
        return self._finish(obj, bevel=bevel, smooth=smooth or bevel > 0)

    def prism(self, name, profile, depth, loc, key, parent=None, anim=None, bevel=0.04, rot=(0, 0, 0)):
        """Призма: профиль (список (x, z)) выдавливается вдоль Y на depth."""
        n = len(profile)
        verts = [(x, -depth / 2, z) for x, z in profile] + [(x, depth / 2, z) for x, z in profile]
        faces = [list(range(n))[::-1], list(range(n, 2 * n))]
        for i in range(n):
            j = (i + 1) % n
            faces.append([i, j, n + j, n + i])
        return self.mesh_from(name, verts, faces, loc, key, parent, anim, bevel=bevel, rot=rot, recalc=True)

    def airfoil(self, name, length, root_chord, tip_chord, twist, key, parent=None, t0=0.0, t1=1.0, hub=0.25,
                thick=0.06, angle=0.0, sections=8):
        """Лопасть (ветряк, пропеллер): профиль-капля, сужение и закрутка вдоль локальной Z.
        t0..t1 — участок длины (так кончик лопасти можно сделать другим цветом без шва)."""
        verts = []
        rows = []
        for s in range(sections + 1):
            t = t0 + (t1 - t0) * s / sections
            r = hub + length * t
            chord = root_chord + (tip_chord - root_chord) * t
            tw = math.radians(twist * (1 - t))
            th = thick * (1 - 0.6 * t)
            ring = []
            for cx, cz in ((-chord * 0.35, 0), (-chord * 0.2, th * 0.8), (0.0, th), (chord * 0.35, th * 0.55),
                           (chord * 0.65, 0), (chord * 0.35, -th * 0.35), (0.0, -th * 0.6), (-chord * 0.2, -th * 0.5)):
                x = cx * math.cos(tw) - cz * math.sin(tw)
                y = cx * math.sin(tw) + cz * math.cos(tw)
                verts.append((x, y, r))
                ring.append(len(verts) - 1)
            rows.append(ring)
        faces = []
        m = len(rows[0])
        for a, b in zip(rows, rows[1:]):
            for i in range(m):
                j = (i + 1) % m
                faces.append([a[i], a[j], b[j], b[i]])
        faces.append(rows[0][::-1])
        faces.append(rows[-1])
        obj = self.mesh_from(name, verts, faces, (0, 0, 0), key, parent=parent, smooth=True, recalc=True)
        obj.data.set_sharp_from_angle(angle=math.radians(60))
        obj.rotation_euler = (0, math.radians(angle), 0)
        return obj

    def shell(self, name, radius, z0, z1, a0, a1, loc, key, parent=None, thickness=0.03, rot=(0, 0, 0), rows=8,
              cols=12, profile=None):
        """Сектор цилиндрической обшивки (углы a0..a1 в градусах, 0° = +X); profile(t) — множитель радиуса."""
        verts, faces = [], []
        for r in range(rows + 1):
            t = r / rows
            z = z0 + (z1 - z0) * t
            rr = radius * (profile(t) if profile else 1.0)
            for c in range(cols + 1):
                a = math.radians(a0 + (a1 - a0) * c / cols)
                verts.append((rr * math.cos(a), rr * math.sin(a), z))
        for r in range(rows):
            for c in range(cols):
                i = r * (cols + 1) + c
                faces.append([i, i + 1, i + cols + 2, i + cols + 1])
        obj = self.mesh_from(name, verts, faces, loc, key, parent=parent, smooth=True, rot=rot)
        mod = obj.modifiers.new("Solid", "SOLIDIFY")
        mod.thickness = thickness
        mod.offset = 1
        return obj

    # ------------------------------------------------------------------
    # Профильные поверхности, сглаженные каркасы, текст
    # ------------------------------------------------------------------
    def lathe(self, name, profile, loc, key, segments=32, parent=None, anim=None, rot=(0, 0, 0), sharp=50,
              scale=(1, 1, 1)):
        """Тело вращения вокруг локальной Z по профилю [(радиус, z), ...] снизу вверх."""
        verts, faces = [], []
        rings = []
        for r, z in profile:
            ring = []
            if r <= 1e-6:
                verts.append((0, 0, z * scale[2]))
                ring = [len(verts) - 1] * segments
            else:
                for i in range(segments):
                    a = math.tau * i / segments
                    verts.append((r * math.cos(a) * scale[0], r * math.sin(a) * scale[1], z * scale[2]))
                    ring.append(len(verts) - 1)
            rings.append(ring)
        for a, b in zip(rings, rings[1:]):
            for i in range(segments):
                j = (i + 1) % segments
                quad = [a[i], a[j], b[j], b[i]]
                uniq = list(dict.fromkeys(quad))
                if len(uniq) >= 3:
                    faces.append(uniq)
        if profile[0][0] > 1e-6:
            faces.append(rings[0][::-1])
        if profile[-1][0] > 1e-6:
            faces.append(rings[-1])
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata([Vector(v) for v in verts], [], faces)
        mesh.validate()
        obj = self._object(name, mesh, key, parent, loc, rot, anim)
        for poly in mesh.polygons:
            poly.use_smooth = True
        mesh.set_sharp_from_angle(angle=math.radians(sharp))
        return obj

    def lens(self, name, radius, loc, key, rot=(0, 0, 0), parent=None, anim=None, height=0.6):
        """Купол-линза: лампы, светодиоды, заклёпки."""
        prof = [(radius, 0), (radius, radius * 0.15)]
        for i in range(1, 6):
            a = i / 5 * math.pi / 2
            prof.append((radius * math.cos(a), radius * 0.15 + radius * height * math.sin(a)))
        prof[-1] = (0.0, prof[-1][1])
        return self.lathe(name, prof, loc, key, segments=16, parent=parent, anim=anim, rot=rot, sharp=70)

    def cage(self, name, verts, faces, loc, key, levels=2, parent=None, anim=None, rot=(0, 0, 0)):
        """Каркас низкой детализации + Subdivision Surface = гладкая органическая форма."""
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata([Vector(v) for v in verts], [], faces)
        mesh.validate()
        obj = self._object(name, mesh, key, parent, loc, rot, anim)
        return self._finish(obj, subsurf=levels, smooth=True)

    def blob(self, name, size, loc, key, parent=None, rot=(0, 0, 0), jitter=0.08, seed=0, segments=8, rings=6,
             levels=2, anim=None, squash_bottom=None):
        """Гладкая неровная капля (клубень, камень, мешок): низкополигональная сфера + шум + subdivision."""
        rnd = random.Random(seed)
        verts, faces = [], []
        verts.append((0, 0, -1))
        for r in range(1, rings):
            phi = math.pi * r / rings
            for i in range(segments):
                th = math.tau * i / segments
                j = 1 + rnd.uniform(-jitter, jitter)
                verts.append((math.sin(phi) * math.cos(th) * j, math.sin(phi) * math.sin(th) * j, -math.cos(phi) * j))
        verts.append((0, 0, 1))
        top = len(verts) - 1
        for i in range(segments):
            faces.append([0, 1 + (i + 1) % segments, 1 + i])
        for r in range(rings - 2):
            for i in range(segments):
                a = 1 + r * segments
                b = a + segments
                faces.append([a + i, a + (i + 1) % segments, b + (i + 1) % segments, b + i])
        last = 1 + (rings - 2) * segments
        for i in range(segments):
            faces.append([last + i, last + (i + 1) % segments, top])
        sx, sy, sz = size[0] / 2, size[1] / 2, size[2] / 2
        out = []
        for x, y, z in verts:
            z = z * sz
            if squash_bottom is not None:
                z = max(z, -squash_bottom)
            out.append((x * sx, y * sy, z))
        return self.cage(name, out, faces, loc, key, levels=levels, parent=parent, rot=rot, anim=anim)

    def text(self, name, body, size, loc, key, rot=(90, 0, 0), extrude=0.04, parent=None, align="CENTER",
             max_width=None, logo=False):
        """Надпись (по умолчанию лицом к -Y), всегда на английском.

        В превью — объёмный текст. При экспорте обычная надпись заменяется плоской меткой, на которой игра
        рисует текст Roblox (SurfaceGui): его переводит автоперевод Roblox. logo=True — логотип или символ
        («POTATO TYCOON», «H», «XL»): остаётся объёмной геометрией и не переводится."""
        cu = bpy.data.curves.new(name + "_font", "FONT")
        cu.body = body
        cu.size = size
        cu.extrude = extrude
        cu.align_x = align
        cu.align_y = "CENTER"
        cu.bevel_depth = extrude * 0.25
        cu.bevel_resolution = 0
        cu.resolution_u = 3
        tmp = bpy.data.objects.new(name + "_tmp", cu)
        self.collection.objects.link(tmp)
        dg = bpy.context.evaluated_depsgraph_get()
        mesh = bpy.data.meshes.new_from_object(tmp.evaluated_get(dg))
        if max_width:
            xs = [v.co.x for v in mesh.vertices]
            width = (max(xs) - min(xs)) if xs else 1
            if width > max_width:
                f = max_width / width
                for v in mesh.vertices:
                    v.co *= f
        bpy.data.objects.remove(tmp)
        bpy.data.curves.remove(cu)
        obj = self._object(name, mesh, key, parent, loc, rot)
        if not logo:
            obj["label"] = body
        return obj

    # ------------------------------------------------------------------
    # Растения и клубни
    # ------------------------------------------------------------------
    @staticmethod
    def _frame(origin, direction, up_hint=Vector((0, 0, 1))):
        d = direction.normalized()
        side = d.cross(up_hint)
        if side.length < 1e-4:
            side = d.cross(Vector((1, 0, 0)))
        side.normalize()
        normal = side.cross(d).normalized()
        m = Matrix((side, d, normal)).transposed().to_4x4()
        m.translation = origin
        return m

    def leaf_mesh(self, length, width, fold=0.25, droop=0.15, nu=7, nv=2, tip=1.0):
        """Вершины/грани листа в локальных осях: длина по +Y, ширина по X, нормаль +Z."""
        verts, faces = [], []
        cols = nv * 2 + 1
        for iu in range(nu + 1):
            u = iu / nu
            w = width * math.sin(math.pi * min(1.0, u ** 0.75)) ** 0.85 * (1 - 0.25 * u)
            if iu == nu:
                w = 0.0
            for iv in range(cols):
                v = -1 + 2 * iv / (cols - 1)
                x = v * w / 2
                z = -fold * abs(v) * w * 0.35 - droop * u * u * length
                verts.append((x, u * length * tip, z))
        for iu in range(nu):
            for iv in range(cols - 1):
                a = iu * cols + iv
                faces.append([a, a + 1, a + cols + 1, a + cols])
        return verts, faces

    def leaf(self, name, length, width, matrix, key, parent=None, fold=0.25, droop=0.15, thickness=0.012, nu=5, nv=1):
        verts, faces = self.leaf_mesh(length, width, fold, droop, nu=nu, nv=nv)
        verts = [matrix @ Vector(v) for v in verts]
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(verts, [], faces)
        mesh.validate()
        obj = self._object(name, mesh, key, parent, (0, 0, 0), (0, 0, 0))
        mod = obj.modifiers.new("Thick", "SOLIDIFY")
        mod.thickness = thickness
        mod.offset = 0
        mod.use_rim = False  # торец листа не виден, а треугольников экономит треть
        for poly in mesh.polygons:
            poly.use_smooth = True
        return obj

    def compound_leaf(self, prefix, base, yaw, reach, rise, parent, rnd, key="Leaf", scale=1.0):
        """Сложный лист картофеля: черешок + 2 пары листочков + верхушечный листочек."""
        d = Vector((math.cos(yaw), math.sin(yaw), 0))
        p0 = base
        p1 = base + d * reach * 0.3 + Vector((0, 0, rise))
        p2 = base + d * reach * 0.75 + Vector((0, 0, rise * 1.15))
        p3 = base + d * reach + Vector((0, 0, rise * 0.85))
        pts = [p0, p1, p2, p3]
        self.tube(prefix + "Petiole", [tuple(p) for p in pts], 0.035 * scale, "Stem", parent=parent, resolution=1,
                  steps=4)

        def at(t):
            # кусочно-линейная интерполяция по точкам черешка
            seg = min(int(t * 3), 2)
            local = t * 3 - seg
            a, b = pts[seg], pts[seg + 1]
            return a + (b - a) * local, (b - a)

        pairs = (0.5, 0.78)
        for i, t in enumerate(pairs):
            pos, tangent = at(t)
            size = (0.82 + 0.28 * i) * scale
            for side in (-1, 1):
                frame = self._frame(pos, tangent)
                side_vec = Vector((frame[0][0], frame[1][0], frame[2][0]))
                tangent_n = tangent.normalized()
                direction = (tangent_n * 0.55 + side_vec * side * 0.85 + Vector((0, 0, 0.12))).normalized()
                m = self._frame(pos, direction)
                m = m @ Matrix.Rotation(rnd.uniform(-0.25, 0.25) + side * 0.2, 4, "Y")
                self.leaf(f"{prefix}Leaflet{i}{side}", size * 0.62, size * 0.36, m, key, parent=parent,
                          droop=0.12 + rnd.uniform(0, 0.1))
        tip_dir = (p3 - p2).normalized() + Vector((0, 0, 0.1))
        self.leaf(prefix + "LeafTip", 0.66 * scale, 0.42 * scale, self._frame(p3, tip_dir), key, parent=parent,
                  droop=0.18)

    def flower(self, prefix, pos, parent, rnd, petal_key="Flower", scale=1.0):
        """Цветок картофеля: 5 заострённых лепестков и жёлтый конус тычинок."""
        for p in range(5):
            a = p / 5 * math.tau + rnd.uniform(-0.1, 0.1)
            direction = Vector((math.cos(a), math.sin(a), 0.35))
            self.leaf(f"{prefix}Petal{p}", 0.17 * scale, 0.13 * scale, self._frame(Vector(pos), direction), petal_key,
                      parent=parent, fold=0.1, droop=-0.2, thickness=0.008)
        self.lathe(f"{prefix}Cone", [(0.045 * scale, 0), (0.035 * scale, 0.06 * scale), (0.0, 0.12 * scale)],
                   Vector(pos) + Vector((0, 0, 0.01)), "FlowerCore", segments=10, parent=parent, sharp=80)

    def seedling(self, name, loc, parent, rnd, scale=1.0, leaves=5, key="Leaf", cup="White"):
        """Рассада в сетчатом стаканчике: розетка из нескольких простых листьев (лёгкая, для гидропоники)."""
        g = self.empty(name, loc, parent)
        self.lathe("Cup", [(0.0, -0.12), (0.1, -0.12), (0.13, 0.0), (0.15, 0.02), (0.0, 0.02)], (0, 0, 0), cup,
                   segments=10, parent=g, sharp=60)
        base = rnd.uniform(0, math.tau)
        for i in range(leaves):
            a = base + i / leaves * math.tau + rnd.uniform(-0.2, 0.2)
            up = 0.55 + rnd.uniform(-0.15, 0.2)
            direction = Vector((math.cos(a), math.sin(a), up))
            self.leaf(f"Leaf{i}", 0.42 * scale * rnd.uniform(0.85, 1.1), 0.26 * scale, self._frame(Vector((0, 0, 0.02)),
                      direction), key if i % 2 else "LeafDark", parent=g, droop=0.25, nu=4, nv=1)
        return g

    def potato(self, name, loc, size, parent=None, key="Potato", seed=0, rot=None, low=False):
        """Клубень; low=True — облегчённый (для куч в ящиках и бункерах)."""
        rnd = random.Random(seed)
        rot = rot or (rnd.uniform(-15, 15), rnd.uniform(-15, 15), rnd.uniform(0, 360))
        return self.blob(name, (size, size * 0.72, size * 0.6), loc, key, parent=parent, rot=rot, jitter=0.1,
                         seed=seed, segments=6 if low else 8, rings=4 if low else 5, levels=1)

    def potato_plant(self, name, loc, parent, seed=0, scale=1.0, flowers=True):
        """Куст картофеля: розетка из 7 сложных листьев, стебли и соцветия."""
        rnd = random.Random(seed)
        plant = self.empty(name, loc, parent)
        n = 8
        for i in range(n):
            yaw = i / n * math.tau + rnd.uniform(-0.2, 0.2)
            inner = i % 3 == 1
            reach = (0.7 if inner else 1.05) * scale * rnd.uniform(0.9, 1.1)
            rise = (0.85 if inner else 0.55) * scale * rnd.uniform(0.9, 1.15)
            base = Vector((math.cos(yaw) * 0.08, math.sin(yaw) * 0.08, 0.0))
            self.compound_leaf(f"L{i}", base, yaw, reach, rise, plant, rnd,
                               key="LeafDark" if i % 3 == 0 else "Leaf", scale=scale * (0.85 if inner else 1.0))
        if flowers:
            for f in range(3):
                a = rnd.uniform(0, math.tau)
                top = Vector((math.cos(a) * 0.18, math.sin(a) * 0.18, 1.15 * scale))
                self.tube(f"FlowerStalk{f}", [(0, 0, 0.0), (top.x * 0.5, top.y * 0.5, top.z * 0.6), tuple(top)],
                          0.025 * scale, "Stem", parent=plant, resolution=1, steps=4)
                self.flower(f"F{f}", top, plant, rnd, scale=scale)
        return plant

    def sack(self, name, loc, height, parent=None, seed=0, key="Burlap"):
        """Мешок из мешковины: осевшее дно, стянутая верёвкой горловина и раскрытый край."""
        rnd = random.Random(seed)
        f = height * 0.6
        prof = [(0.0, 0.0), (0.5, 0.01), (0.64, 0.1), (0.68, 0.32), (0.62, 0.58), (0.46, 0.76), (0.26, 0.86),
                (0.2, 0.9), (0.27, 0.98), (0.36, 1.06), (0.33, 1.08), (0.0, 1.0)]
        obj = self.lathe(name, [(r * f, z * height) for r, z in prof], loc, key, segments=16, parent=parent,
                         sharp=80)
        for v in obj.data.vertices:
            v.co += Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-0.3, 0.3))) * 0.03 * height
        mod = obj.modifiers.new("Subsurf", "SUBSURF")
        mod.levels = mod.render_levels = 1
        self.torus(name + "Tie", 0.21 * f, 0.025 * height, Vector(loc) + Vector((0, 0, 0.9 * height)), "Straw",
                   parent=parent, seg=24, ring=8)
        return obj

    def motor(self, name, loc, parent=None, key="Green", radius=0.24, height=0.6, rot=(0, 0, 0)):
        """Электромотор: оребрённый корпус и крышка вентилятора (одно тело вращения вдоль Z)."""
        prof = [(radius * 0.9, 0.0), (radius, 0.03)]
        ribs = 6
        for i in range(ribs):
            z = 0.08 + (height - 0.2) * i / (ribs - 1)
            prof += [(radius, z - 0.02), (radius * 1.12, z), (radius * 1.12, z + 0.025), (radius, z + 0.045)]
        prof += [(radius, height - 0.08), (radius * 0.92, height - 0.04), (radius * 0.6, height), (0.0, height)]
        return self.lathe(name, prof, loc, key, segments=28, parent=parent, rot=rot, sharp=50)

    # ------------------------------------------------------------------
    # Анимации (ключи для превью/GLB; суффикс имени — для игры)
    # ------------------------------------------------------------------
    @staticmethod
    def _linear(obj):
        if obj.animation_data and obj.animation_data.action:
            for fc in obj.animation_data.action.fcurves:
                for kp in fc.keyframe_points:
                    kp.interpolation = "LINEAR"

    def spin(self, obj, axis="Z", turns=1.0):
        idx = "XYZ".index(axis)
        base = obj.rotation_euler[idx]
        obj.keyframe_insert("rotation_euler", index=idx, frame=1)
        obj.rotation_euler[idx] = base + math.tau * turns
        obj.keyframe_insert("rotation_euler", index=idx, frame=LOOP + 1)
        obj.rotation_euler[idx] = base
        self._linear(obj)
        ax, sign = ROBLOX_AXIS[axis]
        deg_per_sec = 360 * turns / (LOOP / FPS) * sign
        return f"spin_{ax}_{round(deg_per_sec)}"

    def wave(self, obj, prop, index, amplitude, cycles=1, phase=0.0, steps=16):
        """Синусоида свойства (location/rotation_euler/scale) за цикл LOOP."""
        base = getattr(obj, prop)[index]
        for s in range(steps + 1):
            t = s / steps
            getattr(obj, prop)[index] = base + amplitude * math.sin(math.tau * (cycles * t + phase))
            obj.keyframe_insert(prop, index=index, frame=1 + t * LOOP)
        getattr(obj, prop)[index] = base
        self._linear(obj)

    # Синусоидальные анимации: суффикс «_<фаза>» (доля цикла) — только если фаза задана; без неё игра
    # берёт случайную фазу. Фазы нужны там, где детали движутся согласованно (лапы жука).
    @staticmethod
    def _phase(phase):
        return "" if phase is None else f"_{phase:g}"

    def bob(self, obj, amplitude=0.2, cycles=1, phase=None):
        self.wave(obj, "location", 2, amplitude, cycles, phase or 0.0)
        speed = cycles / (LOOP / FPS) * math.tau
        return f"bob_{amplitude:g}_{speed:.2f}" + self._phase(phase)

    def swing(self, obj, axis="Z", degrees=15, cycles=1, phase=None):
        self.wave(obj, "rotation_euler", "XYZ".index(axis), math.radians(degrees), cycles, phase or 0.0)
        speed = cycles / (LOOP / FPS) * math.tau
        ax, sign = ROBLOX_AXIS[axis]
        return f"sway_{ax}_{degrees * sign:g}_{speed:.2f}" + self._phase(phase)

    def slide(self, obj, axis="X", distance=1.0, cycles=1, phase=None):
        self.wave(obj, "location", "XYZ".index(axis), distance, cycles, phase or 0.0)
        speed = cycles / (LOOP / FPS) * math.tau
        ax, sign = ROBLOX_AXIS[axis]
        return f"slide_{ax}_{distance * sign:g}_{speed:.2f}" + self._phase(phase)

    @staticmethod
    def solo(obj):
        """Не склеивать с другими деталями при экспорте (стены с проёмами: точная коллизия в Roblox)."""
        obj["solo"] = True
        return obj

    @staticmethod
    def tag(obj, anim):
        """Дописать суффикс анимации к имени объекта (для игры)."""
        if anim and "anim" not in obj:
            obj["anim"] = anim
            obj.name = f"{obj.name}@{anim}"
        return obj
