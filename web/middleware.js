// middleware.js

// Toggle banner injection here (set to false to disable)
const ENABLE_BANNER = true;

export async function middleware(req) {
  if (!ENABLE_BANNER) {
    return fetch(req);
  }

  // Read the geo-IP header injected by Vercel
  const country = req.headers.get('x-vercel-ip-country');
  const targetCountry = 'FR'; // Change to your desired country code

  // If the visitor is not from the target country, return the response unmodified
  if (country !== targetCountry) {
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

// Run this middleware on the homepage; adjust matcher as needed.
export const config = {
  matcher: ['/'],
};
