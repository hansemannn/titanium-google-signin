var Google = require('ti.googlesignin');

var win = Ti.UI.createWindow({
    backgroundColor: '#fff'
});

var btn = Ti.UI.createButton({
    height: 48,
    title: "Sign In with Google",
    width: 48
});

Google.initialize({
    // Change with your Google Client-ID from the Google API Console
    clientID: '123456789-xxxxxx.apps.googleusercontent.com' 
});

Google.addEventListener('login', function(e) {
    Ti.API.info('Logged in!');
    Ti.API.info(e.user);
});

Google.addEventListener('logout', function(e) {
    Ti.API.info('Logged out!');
    Ti.API.info(e.user);
});

Google.addEventListener('load', function(e) {
    Ti.API.info('Login UI loaded!');
});

Google.addEventListener('open', function(e) {
    Ti.API.info('Login UI opened!');
});

Google.addEventListener('close', function(e) {
    Ti.API.info('Login UI closed!');
});

btn.addEventListener('click', function() {
    Google.signIn();
});

win.add(btn);
win.open();
