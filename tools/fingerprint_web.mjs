// Moves the app code and assets of a Flutter web build into a content-hashed
// folder (`app/<sha256-12>/`), so every release loads from fresh immutable URLs
// and never mixes stale JS chunks with new assets.
//
// Usage:
//   flutter build web --release
//   node tools/fingerprint_web.mjs [app/build/web]
import { createHash } from 'node:crypto';
import { mkdir, readdir, readFile, rename, rm, stat, writeFile } from 'node:fs/promises';
import { join, relative } from 'node:path';

const root = process.argv[2] ?? 'app/build/web';
const bootstrapPath = join(root, 'flutter_bootstrap.js');

const entries = await readdir(root);
const moved = [...entries.filter((f) => /^main\.dart\.js/.test(f)), 'assets'];
if (!entries.includes('main.dart.js') || !entries.includes('assets')) {
  throw new Error(`${root} is not a fresh Flutter web build (or was already fingerprinted)`);
}

async function listFiles(path) {
  if (!(await stat(path)).isDirectory()) return [path];
  const nested = await Promise.all((await readdir(path)).map((name) => listFiles(join(path, name))));
  return nested.flat();
}

const hash = createHash('sha256');
const all = (await Promise.all(moved.map((name) => listFiles(join(root, name))))).flat();
for (const file of all.map((f) => relative(root, f).replaceAll('\\', '/')).sort()) {
  hash.update(file);
  hash.update(await readFile(join(root, file)));
}
const dir = `app/${hash.digest('hex').slice(0, 12)}/`;

// Remove stale fingerprinted bundles from previous local builds so
// `firebase deploy` never uploads obsolete `app/<old-hash>/` directories.
await rm(join(root, 'app'), { recursive: true, force: true });
await mkdir(join(root, dir), { recursive: true });
for (const name of moved) {
  await rename(join(root, name), join(root, dir, name));
}

let bootstrap = await readFile(bootstrapPath, 'utf8');
const patches = [
  ['"mainJsPath":"main.dart.js"', `"mainJsPath":"${dir}main.dart.js"`],
  ['_flutter.loader.load({', `_flutter.loader.load({\n  config: { assetBase: "${dir}" },`],
];
for (const [from, to] of patches) {
  if (!bootstrap.includes(from)) {
    throw new Error(`flutter_bootstrap.js does not contain expected token: ${from}`);
  }
  bootstrap = bootstrap.replace(from, to);
}
await writeFile(bootstrapPath, bootstrap);
console.log(`Fingerprinted web bundle -> ${dir}`);
