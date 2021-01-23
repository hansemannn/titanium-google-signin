# Ti.GoogleSignIn (Android)

## Description

Ti.GoogleSignIn is an open-source project to support the Google SignIn Android-SDK in Appcelerator's Titanium Mobile.
The iOS version with API-parity is available at [@hansemannn/Ti.GoogleSignIn](https://github.com/hansemannn/titanium-google-signin).

## Setup

Unpack the module and place it inside the `modules/android/` folder of your project.
Edit the modules section of your `tiapp.xml` file to include this module:
```xml
<modules>
    <module platform="android">ti.googlesignin</module>
</modules>
```

## Usage

Initialize the module by setting the Google SignIn API key you can get from the Google API Console.   
Note that you will need to use the Web ClientID from Google instead of a Android one.   

```js
var Google = require('ti.googlesignin');
Google.initialize({
    clientID: '<client-id>' //  Web application client ID, not androidID !!!!
});
```

## Author

Rainer Schleevoigt ([AppWerft](https://github.com/AppWerft)

## License

Apache 2.0

## Contributing

Code contributions are greatly appreciated, please submit a new [pull request](https://github.com/AppWerft/Ti.GoogleSignIn/pull/new/master)!
