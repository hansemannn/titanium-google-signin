var Google = require('ti.googlesignin');

Google.initialize({
   clientID: '123456789-xxxxxx.apps.googleusercontent.com' 
});

var loggedIn = Google.hasAuthInKeychain();
var logOutMessage = 'Sign Out';
var logInMessage = 'Sign In with Google';

var win = Ti.UI.createWindow({
    backgroundColor: '#fff'
});

var btn = Ti.UI.createButton({
    title: loggedIn ? logOutMessage : logInMessage,
});

Google.addEventListener('login', function(e) {
    Ti.API.info('Logged in!');
    Ti.API.info(e.user);
    
    loggedIn = true;
    updateButtonState();
});

Google.addEventListener('logout', function(e) {
    Ti.API.info('Logged out!');
    Ti.API.info(e.user);
      
    loggedIn = false;
    updateButtonState();
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
    if (loggedIn) {
        Google.disconnect();
    } else {
        Google.signIn();
    }
});

function updateButtonState() {
    btn.setTitle(loggedIn ? logOutMessage : logInMessage)
}

win.add(btn);
win.open();
