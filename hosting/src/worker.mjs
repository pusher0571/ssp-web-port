const upstreamOrigin = 'https://cdn.rhythia.net';

export function allowedPath(path) {
  return path === '/index.json' || /^\/maps\/[a-zA-Z0-9_%.-]+\.sspm$/.test(path);
}

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
  'Access-Control-Allow-Headers': 'Range, If-Modified-Since',
  'Access-Control-Expose-Headers': 'Content-Length, Content-Range, Accept-Ranges',
};

export default {
  async fetch(request) {
    const url = new URL(request.url);
    if (!allowedPath(url.pathname) || url.search) return new Response('Not found', { status: 404, headers: cors });
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
    if (!['GET', 'HEAD'].includes(request.method)) return new Response('Method not allowed', { status: 405, headers: { ...cors, Allow: 'GET, HEAD, OPTIONS' } });
    const headers = new Headers({ 'User-Agent': 'SSP-Web-Port/1.0' });
    for (const name of ['Range', 'If-Modified-Since']) if (request.headers.has(name)) headers.set(name, request.headers.get(name));
    try {
      const result = await fetch(upstreamOrigin + url.pathname, {
        method: request.method, headers, redirect: 'manual',
        cf: { cacheTtl: 43200, cacheEverything: true },
      });
      // Never relay redirects to arbitrary hosts or become an open URL proxy.
      if (result.status >= 300 && result.status < 400 && result.status !== 304) return new Response('Unexpected upstream redirect', { status: 502, headers: cors });
      const responseHeaders = new Headers(cors);
      for (const name of ['Content-Type', 'Content-Length', 'Content-Range', 'Accept-Ranges', 'ETag', 'Last-Modified', 'Cache-Control']) {
        if (result.headers.has(name)) responseHeaders.set(name, result.headers.get(name));
      }
      responseHeaders.set('X-Content-Type-Options', 'nosniff');
      return new Response(result.body, { status: result.status, headers: responseHeaders });
    } catch {
      return new Response('Rhythia CDN is temporarily unavailable', { status: 502, headers: cors });
    }
  },
};
