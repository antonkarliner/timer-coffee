let deferredPrompt;
let promptVisible = false;
let prompt;

// Function to check if user agent is Android
function isAndroid() {
  var userAgent = navigator.userAgent || navigator.vendor;
  if (/android/i.test(userAgent)) {
    return true;
  }
  return false;
}

// Function to set a cookie
function setCookie(cname, cvalue, exdays) {
  const d = new Date();
  d.setTime(d.getTime() + (exdays*24*60*60*1000));
  let expires = "expires="+ d.toUTCString();
  document.cookie = cname + "=" + cvalue + ";" + expires + ";path=/";
}

// Function to get a cookie
function getCookie(cname) {
  let name = cname + "=";
  let decodedCookie = decodeURIComponent(document.cookie);
  let ca = decodedCookie.split(';');
  for(let i = 0; i <ca.length; i++) {
    let c = ca[i];
    while (c.charAt(0) === ' ') {
      c = c.substring(1);
    }
    if (c.indexOf(name) === 0) {
      return c.substring(name.length, c.length);
    }
  }
  return "";
}

window.addEventListener('beforeinstallprompt', (e) => {
  // Check if it's not Android
  if (!isAndroid()) {
    return;
  }

  // Check if the user dismissed the prompt before
  if (getCookie('appInstallPromptDismissed') === 'true') {
    return;
  }

  // Check if the user has not accepted the use of cookies
  if (getCookie('cookieConsent') !== 'true') {
    return;
  }

  // Prevent the mini-infobar from appearing on mobile
  e.preventDefault();
  
  // Stash the event so it can be triggered later
  deferredPrompt = e;
  
  // Show the install button
  if (!promptVisible) {
    showInstallPromotion();
  }
});

function showInstallPromotion() {
  // Create the "Add to Home screen" UI
  prompt = document.createElement('div');
  prompt.id = 'installContainer';
  prompt.innerHTML = `
    <button id='promptInstall'>Install our app</button>
    <button id='promptDismiss'>Not now</button>
  `;

  // Add the UI to the page
  document.body.appendChild(prompt);

  // Attach event listeners for the install and dismiss buttons
  document.getElementById('promptInstall').addEventListener('click', () => {
    // Hide our user interface that shows our A2HS button
    prompt.style.display = 'none';
    // Show the prompt
    deferredPrompt.prompt();
    // Wait for the user to respond to the prompt
    deferredPrompt.userChoice
      .then((choiceResult) => {
        if (choiceResult.outcome === 'accepted') {
          console.log('User accepted the A2HS prompt');
          // Set a cookie so the prompt won't show again
          setCookie('appInstallPromptDismissed', 'true', 365);
        } else {
          console.log('User dismissed the A2HS prompt');
        }
        deferredPrompt = null;
      });
  });

  document.getElementById('promptDismiss').addEventListener('click', () => {
    // Hide our user interface that shows our A2HS button
    prompt.style.display = 'none';
    // Set a cookie so the prompt won't show again
    setCookie('appInstallPromptDismissed', 'true', 365);
  });

  promptVisible = true;
}
