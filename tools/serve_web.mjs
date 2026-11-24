// Serves the KursorQR Flutter web release build (default: app/build/web) on
// localhost with gzip and /r/* -> r.html rewrite for realistic local QA.
//
//   cd app && flutter build web --release && cd ..
//   node tools/fingerprint_web.mjs app/build/web
//   node tools/serve_web.mjs [app/build/web] [8787]
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join, normalize, resolve } from 'node:path';
import { gzipSync } from 'node:zlib';

const root = resolve(process.argv[2] ?? 'app/build/web');
const port = Number(process.argv[3] ?? process.env.PORT ?? 8787);

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.ico': 'image/x-icon',
  '.svg': 'image/svg+xml',
};
const compressible = new Set(['.html', '.js', '.mjs', '.json', '.wasm', '.ttf', '.otf', '.svg']);

createServer(async (req, res) => {
  const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  let file = pathname.startsWith('/r/')
    ? join(root, 'r.html')
    : normalize(join(root, pathname));
  if (!file.startsWith(root)) return res.writeHead(403).end();
  try {
    if ((await stat(file)).isDirectory()) file = join(file, 'index.html');
  } catch {
    file = join(root, 'index.html');
  }
  try {
    let body = await readFile(file);
    const ext = extname(file);
    const headers = {
      'Content-Type': types[ext] ?? 'application/octet-stream',
      'Cache-Control': 'no-cache',
    };
    if (compressible.has(ext) && /\bgzip\b/.test(req.headers['accept-encoding'] ?? '')) {
      body = gzipSync(body);
      headers['Content-Encoding'] = 'gzip';
    }
    res.writeHead(200, headers).end(body);
  } catch {
    res.writeHead(404).end();
  }
}).listen(port, 'localhost', () => console.log(`Serving ${root} on http://localhost:${port}`));
