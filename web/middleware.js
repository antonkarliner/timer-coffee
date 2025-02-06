// web/middleware.js

// Toggle banner injection here (set to false to disable)
const ENABLE_BANNER = true;

export async function middleware(req) {
  if (!ENABLE_BANNER) {
    return fetch(req);
  }

  // Read the geo-IP header injected by Vercel
  let country = req.headers.get('x-vercel-ip-country');
  console.log('x-vercel-ip-country header:', country);

  const targetCountry = 'FR'; // Target country code

  // If the header is missing, you could uncomment the next line for testing:
  // if (!country) country = targetCountry;

  // If the visitor is not from the target country, return the original response
  if (country !== targetCountry) {
    console.log(`Country (${country}) does not match target (${targetCountry}).`);
    return fetch(req);
  }

  // Fetch the original response
  const response = await fetch(req);
  const contentType = response.headers.get('content-type') || '';

  // Only modify HTML responses
  if (!contentType.includes('text/html')) {
    return response;
  }

  // Read the response body as text and inject the banner HTML
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

// Run this middleware on the homepage (adjust the matcher as needed)
export const config = {
  matcher: ['/'],
};
