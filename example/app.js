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

var scroll = Ti.UI.createScrollView({
    top: 40,
    layout: 'vertical'
});
win.add(scroll);

var btn = Ti.UI.createButton({
    title: loggedIn ? logOutMessage : logInMessage,
});

Google.addEventListener('login', function(e) {
    Ti.API.info('Logged in!');
    Ti.API.info(e.user);

    idLabel.text = 'id: ' + e.user.id;
    nameLabel.text = 'name: ' + e.user.profile.name;
    emailLabel.text = 'email: ' + e.user.profile.email;

    if (e.user.profile.hasImage) {
        profilePicture.visible = true;
        profilePicture.height = 100;
        profilePicture.setImage(Google.currentUserImageURLWithSize(200));
    }

    loggedIn = true;
    updateButtonState();
});

Google.addEventListener('disconnect', function(e) {
    Ti.API.info('Disconnected!'); // The Google SignIn API prefers "diconnect" over "logout"
    Ti.API.info(e.user);

    idLabel.text = '';
    nameLabel.text = '';
    emailLabel.text = '';
    profilePicture.visible = false;
    profilePicture.height = 0;

    loggedIn = false;
    updateButtonState();
});

Google.addEventListener('load', function(e) {
    Ti.API.info('Login UI loaded!');
});

Google.addEventListener('cancel', function(e) {
    Ti.API.info('Login UI cancelled: ' + e.message);
});

Google.addEventListener('error', function(e) {
    Ti.API.info('Login UI errored: ' + e.message);
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
    } else {
        Google.signIn();
    }
});

function updateButtonState() {
    btn.setTitle(loggedIn ? logOutMessage : logInMessage)
    btn.width = Ti.UI.SIZE;
}

scroll.add(btn);

var profilePicture = Ti.UI.createImageView({
    width: 100,
    height: 100,
    top: 20,
    borderRadius: 50
});
scroll.add(profilePicture);

var idLabel = Ti.UI.createLabel({
    color: 'black',
    font: {
        fontSize: 18
    },
    top: 20,
    left: 20,
    text: ''
});
scroll.add(idLabel);


var nameLabel = Ti.UI.createLabel({
    color: 'black',
    font: {
        fontSize: 18
    },
    top: 20,
    left: 20,
    text: ''
});
scroll.add(nameLabel);

var emailLabel = Ti.UI.createLabel({
    color: 'black',
    font: {
        fontSize: 18
    },
    top: 20,
    left: 20,
    text: ''
});
scroll.add(emailLabel);

win.open();
