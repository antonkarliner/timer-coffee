// web/middleware.js

import { geolocation } from '@vercel/functions';

const ENABLE_BANNER = true;

export async function middleware(req) {
  if (!ENABLE_BANNER) {
    return fetch(req);
  }

  // Use the geolocation helper to get visitor info.
  const geo = geolocation(req);
  console.log('Geolocation info:', geo);

  // For testing (or if the header is missing) default to "FR"
  let country = geo?.country;
  if (!country) {
    country = 'FR';
  }

  const targetCountry = 'FR';

  if (country !== targetCountry) {
    console.log(`Visitor country (${country}) does not match target (${targetCountry}).`);
    return fetch(req);
  }

  // Fetch and modify the HTML response.
  const response = await fetch(req);
  const contentType = response.headers.get('content-type') || '';
  if (!contentType.includes('text/html')) {
    return response;
  }

  let body = await response.text();
  const bannerHTML = `<div style="background: yellow; text-align: center; padding: 10px;">
                          Timer.Coffee stands with Palestine ☕️❤️🇵🇸
                       </div>`;
  body = body.replace('<body>', `<body>${bannerHTML}`);

  return new Response(body, {
    status: response.status,
    statusText: response.statusText,
    headers: response.headers,
  });
}

// Apply this middleware on the homepage (adjust the matcher as needed)
export const config = {
  matcher: ['/'],
};
