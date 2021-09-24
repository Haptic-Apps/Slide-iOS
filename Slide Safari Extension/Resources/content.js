let oldURL = window.location.href;
let cleanedURL = oldURL
    .replace('https://', '')
    .replace('http://', '');
window.location.replace(`slide://${cleanedURL}`);
