
# Titanium Google SignIn Demo

This app is an example of using the Google SignIn iOS SDK in Axway Titanium

## Getting started

1. Replace the `GoogleService-Info.plist` in `Resources/` with the file [obtained by Google](https://developers.google.com/identity/sign-in/ios/start).
2. Change the `CFBundleURLSchemes` key in the `<ios>` section of your `tiapp.xml` to the `REVERSED_CLIENT_ID` value inside your `GoogleService-Info.plist`.
3. Extract the `ti.googlesignin` module to the `modules/` directory
4. Run the app!
