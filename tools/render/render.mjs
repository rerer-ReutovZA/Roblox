// Рендер сцен из scenes.json в JPEG через headless Chromium.
//
//   lune run tools/render/export.luau build/PotatoTycoon.rbxlx build/render/scenes.json
//   cd tools/render && npm install && node render.mjs ../../build/render/scenes.json ../../docs/renders
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const here = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
const scenesPath = path.resolve(process.argv[2] || path.join(here, "../../build/render/scenes.json"));
const outDir = path.resolve(process.argv[3] || path.join(here, "../../docs/renders"));
const only = process.argv[4] ? process.argv[4].split(",") : null;
const threeDir = path.resolve(path.dirname(require.resolve("three")), "..");
const W = 1600;
const H = 1000;

const MIME = { ".html": "text/html", ".js": "text/javascript", ".json": "application/json" };
const server = http.createServer((req, res) => {
  const url = decodeURIComponent(new URL(req.url, "http://x").pathname);
  let file;
  if (url === "/scenes.json") file = scenesPath;
  else if (url.startsWith("/three/")) file = path.join(threeDir, url.slice("/three/".length));
  else file = path.join(here, url);
  fs.readFile(file, (err, body) => {
    if (err) {
      res.writeHead(404).end();
      return;
    }
    res.writeHead(200, { "Content-Type": MIME[path.extname(file)] || "application/octet-stream" }).end(body);
  });
});
await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const port = server.address().port;

const scenes = Object.keys(JSON.parse(fs.readFileSync(scenesPath, "utf8"))).filter((id) => !only || only.includes(id));
fs.mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch({
  args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"],
});
const page = await browser.newPage({ viewport: { width: W, height: H } });
page.on("console", (msg) => {
  if (msg.type() === "error") console.error("  [browser]", msg.text());
});
page.on("pageerror", (err) => console.error("  [page]", err.message));
for (const id of scenes) {
  const started = Date.now();
  await page.goto(`http://127.0.0.1:${port}/viewer.html?scene=${id}&w=${W}&h=${H}`);
  await page.waitForFunction("window.__done === true", null, { timeout: 300000 });
  const file = path.join(outDir, `${id}.jpg`);
  await page.screenshot({ path: file, type: "jpeg", quality: 90 });
  console.log(`✓ ${id} → ${path.relative(process.cwd(), file)} (${((Date.now() - started) / 1000).toFixed(1)} с)`);
}
await browser.close();
server.close();
