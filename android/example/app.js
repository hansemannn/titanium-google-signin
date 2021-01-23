var Google = require('ti.googlesignin');
Google.initialize({
    clientID: "123456789123-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.apps.googleusercontent.com" //  Web application client ID, not androidID !!!!
});

var win = Ti.UI.createWindow({
    backgroundColor: '#fff'
});

var scroll = Ti.UI.createScrollView({
    top: 40,
    layout: 'vertical'
});
win.add(scroll);

var btn = Ti.UI.createButton({
    title: 'Sign In with Google'
});

Google.addEventListener('login', function(e) {
    Ti.API.info('Logged in!');
    Ti.API.info(' ***** RESULT: ' + JSON.stringify(e));

   //ANDROID RESULT:
   // {
   //     "familyName": "Family",
   //     "givenName": "Person",
   //     "fullName": "Person Name",
   //     "accountName": "user@domain.com",
   //     "token": "abc",
   //     "email": "user@domain.com",
   //     "displayName": "User Name",
   //     "photo": "https://lh5.googleusercontent.com/-F58Ul6-zinE/AAAAAAAAAAI/AAAAAAAAAAAA/123456789/abc-d/photo.jpg",
   // }
});

btn.addEventListener('click', function() {
	Google.signIn();
});

scroll.add(btn);
win.open();
