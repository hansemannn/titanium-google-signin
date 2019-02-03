var Google = require('ti.googlesignin');

/**
 * Use the "CLIENT_ID" from the GoogleService-Info.plist file
 */
Google.initialize({
  clientID: 'xxxxxxxx-xxxxxxxx.apps.googleusercontent.com'
});

var loggedIn = Google.hasAuthInKeychain();

var logOutMessage = 'Sign Out';
var logInMessage = 'Sign In with Google';

var win = Ti.UI.createWindow({
  backgroundColor: '#fff'
});

win.addEventListener('open', function() {
  if (loggedIn === true) {
    Google.signInSilently();
  }
});

var payloadTextArea = Ti.UI.createTextArea({
  editable: false,
  top: 50,
  width: Ti.UI.FILL,
  height: Ti.UI.FILL,
  font: {
    fontFamily: 'Menlo',
    fontSize: 12
  },
  backgroundColor: '#eee'
});

var btn = Ti.UI.createButton({
  top: 20,
  title: logInMessage
});

Google.addEventListener('login', function(e) {
  if (!e.success) {
    Ti.API.error('Cannot log in:' + e.error);
    return;
  }

  Ti.API.info('Logged in!');
  Ti.API.info(e.user);

  loggedIn = true;
  payloadTextArea.value = e.user;
  updateButtonState();
});

Google.addEventListener('logout', function(e) {
  Ti.API.info('Logged out!');

  loggedIn = false;
  payloadTextArea.value = '';
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
    Ti.API.info('Logging out ...');
    Google.signOut();
    Google.disconnect();
  } else  {
    Ti.API.info('Logging in ...');
    Google.signIn();
  }
});

function updateButtonState() {
  btn.setTitle(loggedIn ? logOutMessage : logInMessage)
}

win.add(btn);
win.add(payloadTextArea);
win.open();
