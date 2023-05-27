// insert-script.js
const fs = require('fs');
const cheerio = require('cheerio');

// Load the HTML file
const html = fs.readFileSync('web/index.html');
const $ = cheerio.load(html);

// Add the tracking script to the head
$('head').append(process.env.VERCEL_TRACKING_SCRIPT);

// Write the modified HTML back to the file
fs.writeFileSync('web/index.html', $.html());
