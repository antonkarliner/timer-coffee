// middleware.js

const ENABLE_BANNER = true;

export async function middleware(req) {
  if (!ENABLE_BANNER) {
    return fetch(req);
  }

  // Retrieve geo-IP header values directly.
  const countryHeader = req.headers.get('x-vercel-ip-country');
  const cityHeader = req.headers.get('x-vercel-ip-city');
  const regionHeader = req.headers.get('x-vercel-ip-country-region');
  
  console.log('x-vercel-ip-country:', countryHeader);
  console.log('x-vercel-ip-city:', cityHeader);
  console.log('x-vercel-ip-country-region:', regionHeader);

  // For testing or if the header is missing, default to "FR"
  let country = countryHeader || 'FR';
  const targetCountry = 'FR';

  if (country !== targetCountry) {
    console.log(`Visitor country (${country}) does not match target (${targetCountry}).`);
    return fetch(req);
  }

  // Fetch the original response
  const response = await fetch(req);
  const contentType = response.headers.get('content-type') || '';
  if (!contentType.includes('text/html')) {
    return response;
  }

  let body = await response.text();
  const bannerHTML = `<div style="background: yellow; text-align: center; padding: 10px;">
                          Timer.Coffee stands with Palestine ☕️❤️🇵🇸
                       </div>`;
  // Inject the banner immediately after the opening <body> tag.
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
