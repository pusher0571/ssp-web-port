import assert from 'node:assert/strict';
import test from 'node:test';
import worker, { allowedPath } from '../src/worker.mjs';

test('proxy only accepts the catalog and single map files', () => {
  assert.equal(allowedPath('/index.json'), true);
  assert.equal(allowedPath('/maps/ss_archive_song-name.sspm'), true);
  for (const path of ['/https://example.com', '/maps/../secret.sspm', '/maps/a/b.sspm', '/maps/a.zip', '/admin']) assert.equal(allowedPath(path), false);
});
test('rejects writes and arbitrary query URLs', async () => {
  assert.equal((await worker.fetch(new Request('https://proxy.test/maps/example.sspm', { method: 'POST' }))).status, 405);
  assert.equal((await worker.fetch(new Request('https://proxy.test/index.json?url=https://example.com'))).status, 404);
  assert.equal((await worker.fetch(new Request('https://proxy.test/index.json', { method: 'OPTIONS' }))).headers.get('Access-Control-Allow-Origin'), '*');
});
test('streams map bytes and preserves range and CORS headers', async () => {
  const realFetch = globalThis.fetch;
  globalThis.fetch = async (url, options) => {
    assert.equal(url, 'https://cdn.rhythia.net/maps/example.sspm');
    assert.equal(options.headers.get('Range'), 'bytes=0-3');
    return new Response(new Uint8Array([83, 83, 43, 109]), { status: 206, headers: { 'Content-Range': 'bytes 0-3/100' } });
  };
  try {
    const response = await worker.fetch(new Request('https://proxy.test/maps/example.sspm', { headers: { Range: 'bytes=0-3' } }));
    assert.equal(response.status, 206);
    assert.equal(response.headers.get('Content-Range'), 'bytes 0-3/100');
    assert.equal(response.headers.get('Access-Control-Allow-Origin'), '*');
    assert.deepEqual(new Uint8Array(await response.arrayBuffer()), new Uint8Array([83, 83, 43, 109]));
  } finally { globalThis.fetch = realFetch; }
});
