// middleware.js
export async function middleware(req) {
    // Read the geo-IP header injected by Vercel
    const country = req.headers.get('x-vercel-ip-country');
    const targetCountry = 'FR'; // change this to your desired country code
  
    // If the visitor is not from the target country, just pass the request through
    if (country !== targetCountry) {
      return fetch(req);
    }
  
    // Otherwise, fetch the original response
    const response = await fetch(req);
    const contentType = response.headers.get('content-type') || '';
  
    // Only modify HTML responses
    if (!contentType.includes('text/html')) {
      return response;
    }
  
    // Read the response body as text and inject the banner HTML
    let body = await response.text();
    const bannerHTML = `<div style="background: yellow; text-align: center; padding: 10px;">
                            Special Offer for ${country} users!
                         </div>`;
    // Insert the banner immediately after the opening <body> tag
    body = body.replace('<body>', `<body>${bannerHTML}`);
  
    // Return the modified response with the same status and headers
    return new Response(body, {
      status: response.status,
      statusText: response.statusText,
      headers: response.headers,
    });
  }
  
  // Only run this middleware on the homepage (adjust the matcher if needed)
  export const config = {
    matcher: ['/'],
  };
  