// Рендер сцены из scenes.json (детали Roblox → three.js). Открывается tools/render/render.mjs в headless Chromium.
import * as THREE from "three";
import { EffectComposer } from "three/addons/postprocessing/EffectComposer.js";
import { RenderPass } from "three/addons/postprocessing/RenderPass.js";
import { UnrealBloomPass } from "three/addons/postprocessing/UnrealBloomPass.js";
import { OutputPass } from "three/addons/postprocessing/OutputPass.js";
import { RoomEnvironment } from "three/addons/environments/RoomEnvironment.js";

const params = new URLSearchParams(location.search);
const sceneId = params.get("scene");
const W = Number(params.get("w") || 1400);
const H = Number(params.get("h") || 900);
const all = await (await fetch("./scenes.json")).json();
const data = all[sceneId];
document.getElementById("title").textContent = data.title;

// ---------------------------------------------------------------------------
// Процедурные текстуры материалов Roblox (1 повтор = 4 стада)
// ---------------------------------------------------------------------------
function canvasTexture(draw, size = 256) {
  const c = document.createElement("canvas");
  c.width = c.height = size;
  const g = c.getContext("2d");
  g.fillStyle = "#fff";
  g.fillRect(0, 0, size, size);
  draw(g, size);
  const tex = new THREE.CanvasTexture(c);
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.anisotropy = 4;
  return tex;
}
let seed = 7;
const rand = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);
function noise(g, s, n, lo, hi, r = 1.5) {
  for (let i = 0; i < n; i++) {
    const v = Math.floor(255 * (lo + rand() * (hi - lo)));
    g.fillStyle = `rgb(${v},${v},${v})`;
    g.fillRect(rand() * s, rand() * s, r, r);
  }
}
const TEX = {
  WoodPlanks: canvasTexture((g, s) => {
    for (let i = 0; i < 4; i++) {
      const v = 215 + Math.floor(rand() * 35);
      g.fillStyle = `rgb(${v},${v},${v})`;
      g.fillRect(0, (i * s) / 4, s, s / 4);
      g.fillStyle = "rgba(0,0,0,0.35)";
      g.fillRect(0, (i * s) / 4, s, 2);
      g.fillRect(((i * 97) % s), (i * s) / 4, 2, s / 4);
    }
    g.globalAlpha = 0.08;
    for (let i = 0; i < 60; i++) {
      g.fillStyle = "#000";
      g.fillRect(0, rand() * s, s, 1);
    }
  }),
  Wood: canvasTexture((g, s) => {
    g.globalAlpha = 0.1;
    for (let i = 0; i < 70; i++) {
      g.fillStyle = "#000";
      g.fillRect(0, rand() * s, s, 1 + rand() * 2);
    }
  }),
  DiamondPlate: canvasTexture((g, s) => {
    g.fillStyle = "rgb(225,225,225)";
    g.fillRect(0, 0, s, s);
    for (let y = 0; y < 8; y++)
      for (let x = 0; x < 8; x++) {
        g.save();
        g.translate((x + (y % 2) * 0.5) * (s / 8), y * (s / 8) + s / 16);
        g.rotate(((x + y) % 2 ? 1 : -1) * 0.8);
        g.fillStyle = "rgb(255,255,255)";
        g.fillRect(-7, -2, 14, 4);
        g.fillStyle = "rgba(0,0,0,0.25)";
        g.fillRect(-7, 2, 14, 1.5);
        g.restore();
      }
  }),
  Grass: canvasTexture((g, s) => noise(g, s, 9000, 0.78, 1, 2)),
  Ground: canvasTexture((g, s) => noise(g, s, 7000, 0.7, 1, 2.5)),
  Concrete: canvasTexture((g, s) => noise(g, s, 6000, 0.86, 1, 1.5)),
  Asphalt: canvasTexture((g, s) => noise(g, s, 9000, 0.7, 1, 1.5)),
  Slate: canvasTexture((g, s) => {
    noise(g, s, 4000, 0.8, 1, 2);
    g.fillStyle = "rgba(0,0,0,0.12)";
    for (let i = 0; i < 6; i++) g.fillRect(0, rand() * s, s, 2);
  }),
  Pavement: canvasTexture((g, s) => {
    noise(g, s, 4000, 0.85, 1, 1.5);
    g.fillStyle = "rgba(0,0,0,0.25)";
    for (let i = 0; i < 4; i++) {
      g.fillRect(0, (i * s) / 4, s, 2);
      g.fillRect((i * s) / 4, 0, 2, s);
    }
  }),
  CeramicTiles: canvasTexture((g, s) => {
    g.fillStyle = "rgba(0,0,0,0.18)";
    for (let i = 0; i < 4; i++) {
      g.fillRect(0, (i * s) / 4, s, 3);
      g.fillRect((i * s) / 4, 0, 3, s);
    }
  }),
  Cobblestone: canvasTexture((g, s) => {
    for (let i = 0; i < 40; i++) {
      const v = 190 + Math.floor(rand() * 60);
      g.fillStyle = `rgb(${v},${v},${v})`;
      g.beginPath();
      g.ellipse(rand() * s, rand() * s, 18 + rand() * 10, 14 + rand() * 8, rand() * 3, 0, 7);
      g.fill();
    }
  }),
  Metal: canvasTexture((g, s) => {
    g.globalAlpha = 0.06;
    for (let i = 0; i < 120; i++) {
      g.fillStyle = rand() > 0.5 ? "#000" : "#fff";
      g.fillRect(0, rand() * s, s, 1);
    }
  }),
  CorrodedMetal: canvasTexture((g, s) => noise(g, s, 5000, 0.55, 1, 3)),
  Fabric: canvasTexture((g, s) => {
    g.fillStyle = "rgba(0,0,0,0.12)";
    for (let i = 0; i < s; i += 4) {
      g.fillRect(0, i, s, 1);
      g.fillRect(i, 0, 1, s);
    }
  }),
  Marble: canvasTexture((g, s) => {
    g.strokeStyle = "rgba(0,0,0,0.12)";
    for (let i = 0; i < 12; i++) {
      g.beginPath();
      g.moveTo(rand() * s, 0);
      g.bezierCurveTo(rand() * s, s / 3, rand() * s, (2 * s) / 3, rand() * s, s);
      g.stroke();
    }
  }),
};
TEX.Sand = TEX.Ground;
TEX.Granite = TEX.Slate;
TEX.Cardboard = TEX.Fabric;
TEX.Brick = TEX.Pavement;

// ---------------------------------------------------------------------------
// Материалы
// ---------------------------------------------------------------------------
const materials = new Map();
function material(m, c, t) {
  const key = `${m}|${c.join(",")}|${t}`;
  if (materials.has(key)) return materials.get(key);
  const color = new THREE.Color().setRGB(c[0], c[1], c[2], THREE.SRGBColorSpace);
  const opts = { color, roughness: 0.55, metalness: 0, map: TEX[m] || null };
  switch (m) {
    case "Neon":
      Object.assign(opts, { emissive: color, emissiveIntensity: 1.3, roughness: 0.4, map: null });
      break;
    case "Glass":
      Object.assign(opts, { roughness: 0.05, transparent: true, opacity: Math.max(0.22, (1 - t) * 0.7), envMapIntensity: 2 });
      break;
    case "Ice":
      Object.assign(opts, { roughness: 0.1, transparent: true, opacity: 0.85 });
      break;
    case "ForceField":
      Object.assign(opts, {
        transparent: true, opacity: 0.16, emissive: color, emissiveIntensity: 0.6, depthWrite: false, side: THREE.DoubleSide,
      });
      break;
    case "Metal": case "DiamondPlate":
      Object.assign(opts, { metalness: 0.7, roughness: 0.35 });
      break;
    case "CorrodedMetal":
      Object.assign(opts, { metalness: 0.5, roughness: 0.7 });
      break;
    case "Foil":
      Object.assign(opts, { metalness: 1, roughness: 0.18 });
      break;
    case "Marble":
      Object.assign(opts, { roughness: 0.25 });
      break;
    case "SmoothPlastic": case "Plastic":
      Object.assign(opts, { roughness: 0.42 });
      break;
    default:
      opts.roughness = 0.9;
  }
  if (t > 0 && !opts.transparent) Object.assign(opts, { transparent: true, opacity: 1 - t });
  const mat = new THREE.MeshStandardMaterial(opts);
  materials.set(key, mat);
  return mat;
}

// ---------------------------------------------------------------------------
// Геометрия деталей
// ---------------------------------------------------------------------------
// масштаб UV по реальному размеру граней, чтобы текстура была 4x4 стада везде
function boxGeometry(sx, sy, sz) {
  const geo = new THREE.BoxGeometry(sx, sy, sz);
  const uv = geo.attributes.uv;
  const faces = [[sz, sy], [sz, sy], [sx, sz], [sx, sz], [sx, sy], [sx, sy]];
  for (let f = 0; f < 6; f++)
    for (let v = 0; v < 4; v++) {
      const i = f * 4 + v;
      uv.setXY(i, (uv.getX(i) * faces[f][0]) / 4, (uv.getY(i) * faces[f][1]) / 4);
    }
  return geo;
}

// Клин Roblox: высокая сторона сзади (+Z), скат смотрит вперёд (-Z) и вверх
function wedgeGeometry(w, h, d) {
  const x0 = -w / 2, x1 = w / 2, y0 = -h / 2, y1 = h / 2, z0 = -d / 2, z1 = d / 2;
  const A = [z0, y0], B = [z1, y0], C = [z1, y1];
  const v = (x, p) => [x, p[1], p[0]];
  const tris = [
    [v(x0, A), v(x0, C), v(x0, B)],
    [v(x1, A), v(x1, B), v(x1, C)],
    [v(x0, A), v(x0, B), v(x1, B)], [v(x0, A), v(x1, B), v(x1, A)],
    [v(x0, B), v(x0, C), v(x1, C)], [v(x0, B), v(x1, C), v(x1, B)],
    [v(x0, A), v(x1, A), v(x1, C)], [v(x0, A), v(x1, C), v(x0, C)],
  ];
  const pos = new Float32Array(tris.flat(2));
  const geo = new THREE.BufferGeometry();
  geo.setAttribute("position", new THREE.BufferAttribute(pos, 3));
  const uvs = new Float32Array((pos.length / 3) * 2);
  for (let i = 0; i < pos.length / 3; i++) {
    uvs[i * 2] = (pos[i * 3] + pos[i * 3 + 2]) / 4;
    uvs[i * 2 + 1] = pos[i * 3 + 1] / 4;
  }
  geo.setAttribute("uv", new THREE.BufferAttribute(uvs, 2));
  geo.computeVertexNormals();
  return geo;
}

function partMatrix(p, r) {
  return new THREE.Matrix4().set(r[0], r[1], r[2], p[0], r[3], r[4], r[5], p[1], r[6], r[7], r[8], p[2], 0, 0, 0, 1);
}

const root = new THREE.Group();
for (const part of data.parts) {
  const [sx, sy, sz] = part.z;
  let geo;
  if (part.s === "cyl") {
    const r = Math.min(sy, sz) / 2;
    geo = new THREE.CylinderGeometry(r, r, sx, 28);
    geo.rotateZ(-Math.PI / 2);
  } else if (part.s === "ball") {
    geo = new THREE.SphereGeometry(Math.min(sx, sy, sz) / 2, 28, 18);
  } else if (part.s === "ell") {
    geo = new THREE.SphereGeometry(0.5, 28, 18);
    geo.scale(sx, sy, sz);
  } else if (part.s === "wedge") {
    geo = wedgeGeometry(sx, sy, sz);
  } else {
    geo = boxGeometry(sx, sy, sz);
  }
  const mesh = new THREE.Mesh(geo, material(part.m, part.c, part.t));
  mesh.matrixAutoUpdate = false;
  mesh.matrix.copy(partMatrix(part.p, part.r));
  const castsShadow = part.m !== "Neon" && part.m !== "ForceField" && part.t < 0.5;
  mesh.castShadow = castsShadow;
  mesh.receiveShadow = part.m !== "ForceField";
  root.add(mesh);
}

// ---------------------------------------------------------------------------
// Надписи SurfaceGui
// ---------------------------------------------------------------------------
const FACES = {
  Front: { n: [0, 0, -1], right: [-1, 0, 0], up: [0, 1, 0], dims: [0, 1] },
  Back: { n: [0, 0, 1], right: [1, 0, 0], up: [0, 1, 0], dims: [0, 1] },
  Top: { n: [0, 1, 0], right: [1, 0, 0], up: [0, 0, -1], dims: [0, 2] },
  Bottom: { n: [0, -1, 0], right: [1, 0, 0], up: [0, 0, 1], dims: [0, 2] },
  Right: { n: [1, 0, 0], right: [0, 0, -1], up: [0, 1, 0], dims: [2, 1] },
  Left: { n: [-1, 0, 0], right: [0, 0, 1], up: [0, 1, 0], dims: [2, 1] },
};
const stripEmoji = (s) => s.replace(/[\u{1F000}-\u{1FFFF}\u{FE0F}\u{200D}]/gu, "").trim();

function labelTexture(label, wStuds, hStuds) {
  const scale = 96;
  const cw = Math.max(64, Math.round(wStuds * scale));
  const ch = Math.max(32, Math.round(hStuds * scale));
  const c = document.createElement("canvas");
  c.width = cw;
  c.height = ch;
  const g = c.getContext("2d");
  if (label.bg) {
    g.fillStyle = `rgb(${label.bg.map((v) => Math.round(v * 255)).join(",")})`;
    g.fillRect(0, 0, cw, ch);
  }
  const text = stripEmoji(label.text);
  const lines = text.split("\n");
  const family = label.font === "Arcade" ? "'DejaVu Sans Mono'" : "'DejaVu Sans'";
  const pad = 0.08;
  let size = ch;
  for (; size > 6; size -= 2) {
    g.font = `bold ${size}px ${family}`;
    const widest = Math.max(...lines.map((l) => g.measureText(l).width));
    if (widest <= cw * (1 - pad * 2) && size * lines.length * 1.15 <= ch * (1 - pad * 2)) break;
  }
  g.font = `bold ${size}px ${family}`;
  g.textAlign = "center";
  g.textBaseline = "middle";
  g.fillStyle = `rgb(${label.color.map((v) => Math.round(v * 255)).join(",")})`;
  lines.forEach((l, i) => g.fillText(l, cw / 2, ch / 2 + (i - (lines.length - 1) / 2) * size * 1.15));
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.anisotropy = 8;
  return tex;
}

for (const label of data.labels) {
  const face = FACES[label.face];
  if (!face) continue;
  const w = label.z[face.dims[0]];
  const h = label.z[face.dims[1]];
  const half = Math.abs(face.n[0]) * label.z[0] / 2 + Math.abs(face.n[1]) * label.z[1] / 2 + Math.abs(face.n[2]) * label.z[2] / 2;
  const plane = new THREE.Mesh(
    new THREE.PlaneGeometry(w, h),
    new THREE.MeshBasicMaterial({ map: labelTexture(label, w, h), transparent: !label.bg, toneMapped: false }),
  );
  const basis = new THREE.Matrix4().makeBasis(
    new THREE.Vector3(...face.right), new THREE.Vector3(...face.up), new THREE.Vector3(...face.n));
  basis.setPosition(new THREE.Vector3(...face.n).multiplyScalar(half + 0.02));
  plane.matrixAutoUpdate = false;
  plane.matrix.copy(partMatrix(label.p, label.r).multiply(basis));
  root.add(plane);
}

// ---------------------------------------------------------------------------
// Сцена, свет, камера
// ---------------------------------------------------------------------------
root.updateMatrixWorld(true);
const box = new THREE.Box3().setFromObject(root);
const sphere = box.getBoundingSphere(new THREE.Sphere());
const center = sphere.center;
const R = Math.max(sphere.radius, 4);

const renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true });
renderer.setSize(W, H);
renderer.setPixelRatio(1);
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.05;
document.body.appendChild(renderer.domElement);

const scene = new THREE.Scene();
const sky = document.createElement("canvas");
sky.width = 2;
sky.height = 256;
const sg = sky.getContext("2d");
const grad = sg.createLinearGradient(0, 0, 0, 256);
grad.addColorStop(0, "#6fa8e8");
grad.addColorStop(0.65, "#bcd9f2");
grad.addColorStop(1, "#e8f1f8");
sg.fillStyle = grad;
sg.fillRect(0, 0, 2, 256);
const skyTex = new THREE.CanvasTexture(sky);
skyTex.colorSpace = THREE.SRGBColorSpace;
scene.background = skyTex;
const pmrem = new THREE.PMREMGenerator(renderer);
scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;
scene.add(root);

const GROUNDS = {
  grass: { c: [0.38, 0.6, 0.29], m: "Grass" },
  concrete: { c: [0.62, 0.62, 0.6], m: "Concrete" },
  tiles: { c: [0.66, 0.7, 0.76], m: "CeramicTiles" },
  asphalt: { c: [0.3, 0.31, 0.33], m: "Asphalt" },
};
const gdef = GROUNDS[data.ground] || GROUNDS.grass;
const gsize = Math.max(R * 8, 200);
const ground = new THREE.Mesh(boxGeometry(gsize, 0.2, gsize), material(gdef.m, gdef.c, 0));
ground.position.set(center.x, box.min.y - 0.1, center.z);
ground.receiveShadow = true;
scene.add(ground);

scene.add(new THREE.HemisphereLight(0xdcecff, 0x6f7f52, 0.9));
const sun = new THREE.DirectionalLight(0xfff1dc, 2.8);
sun.position.copy(center).add(new THREE.Vector3(-0.55, 1, 0.6).normalize().multiplyScalar(R * 3));
sun.target.position.copy(center);
sun.castShadow = true;
sun.shadow.mapSize.set(4096, 4096);
const sc = sun.shadow.camera;
sc.left = sc.bottom = -R * 1.4;
sc.right = sc.top = R * 1.4;
sc.near = 0.5;
sc.far = R * 7;
sun.shadow.bias = -0.0004;
sun.shadow.normalBias = 0.02;
scene.add(sun, sun.target);

const view = data.view || {};
const yaw = THREE.MathUtils.degToRad(view.yaw ?? 35);
const pitch = THREE.MathUtils.degToRad(view.pitch ?? 22);
const fov = 32;
const camera = new THREE.PerspectiveCamera(fov, W / H, 0.1, R * 20);
const dist = (R / Math.sin(THREE.MathUtils.degToRad(fov / 2))) * 0.92 / (view.zoom ?? 1);
camera.position.copy(center).add(
  new THREE.Vector3(Math.sin(yaw) * Math.cos(pitch), Math.sin(pitch), Math.cos(yaw) * Math.cos(pitch)).multiplyScalar(dist),
);
camera.lookAt(center.x, center.y - R * 0.08, center.z);
// дымка только у горизонта, сам объект не выцветает
scene.fog = new THREE.Fog(0xd6e6f3, dist * 1.8, dist * 6);

const target = new THREE.WebGLRenderTarget(W, H, { samples: 4, type: THREE.HalfFloatType });
const composer = new EffectComposer(renderer, target);
composer.addPass(new RenderPass(scene, camera));
composer.addPass(new UnrealBloomPass(new THREE.Vector2(W, H), 0.45, 0.45, 1.6));
composer.addPass(new OutputPass());
composer.render();
window.__done = true;
