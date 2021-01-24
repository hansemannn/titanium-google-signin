/**
 * titanium-googlesignin
 *
 * Created by Hans Knöchel
 * Copyright (c) 2017-present Hans Knöchel. All rights reserved.
 */

#import "TiGooglesigninModule.h"

#define ENSURE_LOGGED_IN                                                              \
  if (![[GIDSignIn sharedInstance] hasPreviousSignIn]) {                              \
    NSLog(@"[WARN] No user infos found. Check with \"hasAuthInKeychain()\" before."); \
    return nil;                                                                       \
  }

@implementation TiGooglesigninModule

#pragma mark Internal

- (id)moduleGUID
{
  return @"7fa817c2-5c36-402b-a442-f2cafd41da64";
}

- (NSString *)moduleId
{
  return @"ti.googlesignin";
}

- (void)handleOpenURL:(NSNotification *)notification
{
  NSDictionary *launchOptions = [[TiApp app] launchOptions];
  NSString *url = [launchOptions objectForKey:@"url"];

  if (url != nil) {
    [[GIDSignIn sharedInstance] handleURL:[NSURL URLWithString:url]];
  }
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"TiApplicationLaunchedFromURL"
                                                object:nil];
}

#pragma Public APIs

- (void)initialize:(id)args
{
  ENSURE_SINGLE_ARG(args, NSDictionary);

  id clientID = [args objectForKey:@"clientID"];
  id scopes = [args objectForKey:@"scopes"];
  id language = [args objectForKey:@"language"];
  id loginHint = [args objectForKey:@"loginHint"];
  id hostedDomain = [args objectForKey:@"hostedDomain"];
  id serverClientID = [args objectForKey:@"serverClientID"];
  id shouldFetchBasicProfile = [args objectForKey:@"shouldFetchBasicProfile"];
  id openIDRealm = [args objectForKey:@"openIDRealm"];

  if (!clientID) {
    NSLog(@"[ERROR] The \"clientID\" property is required when initializing Google Sign In.");
    return;
  }

  ENSURE_TYPE(clientID, NSString);
  ENSURE_TYPE_OR_NIL(scopes, NSArray);
  ENSURE_TYPE_OR_NIL(language, NSString);
  ENSURE_TYPE_OR_NIL(loginHint, NSString);
  ENSURE_TYPE_OR_NIL(hostedDomain, NSString);
  ENSURE_TYPE_OR_NIL(serverClientID, NSString);
  ENSURE_TYPE_OR_NIL(shouldFetchBasicProfile, NSNumber);
  ENSURE_TYPE_OR_NIL(openIDRealm, NSString);

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleOpenURL:)
                                               name:@"TiApplicationLaunchedFromURL"
                                             object:nil];

  [[GIDSignIn sharedInstance] setDelegate:self];
  [[GIDSignIn sharedInstance] setPresentingViewController:TiApp.app.controller.topPresentedController];

  [[GIDSignIn sharedInstance] setClientID:clientID];

  if (scopes != nil) {
    [[GIDSignIn sharedInstance] setScopes:scopes];
  }

  if (language != nil) {
    [[GIDSignIn sharedInstance] setLanguage:language];
  }

  if (loginHint != nil) {
    [[GIDSignIn sharedInstance] setLoginHint:loginHint];
  }

  if (hostedDomain != nil) {
    [[GIDSignIn sharedInstance] setHostedDomain:hostedDomain];
  }

  if (shouldFetchBasicProfile != nil) {
    [[GIDSignIn sharedInstance] setShouldFetchBasicProfile:[TiUtils boolValue:shouldFetchBasicProfile def:YES]];
  }

  if (serverClientID != nil) {
    [[GIDSignIn sharedInstance] setServerClientID:serverClientID];
  }

  if (openIDRealm != nil) {
    [[GIDSignIn sharedInstance] setOpenIDRealm:openIDRealm];
  }
}

- (void)signIn:(id)unused
{
  ENSURE_UI_THREAD(signIn, unused);
  [[GIDSignIn sharedInstance] signIn];
}

- (void)signInSilently:(id)unused
{
  ENSURE_UI_THREAD(signInSilently, unused);
  [[GIDSignIn sharedInstance] restorePreviousSignIn];
}

- (void)signOut:(id)unused
{
  ENSURE_UI_THREAD(signOut, unused);
  [[GIDSignIn sharedInstance] signOut];
}

- (void)disconnect:(id)unused
{
  ENSURE_UI_THREAD(disconnect, unused);
  [[GIDSignIn sharedInstance] disconnect];
}

- (NSNumber *)hasAuthInKeychain:(id)unused
{
  return @([[GIDSignIn sharedInstance] hasPreviousSignIn]);
}

- (NSDictionary *)currentUser
{
  ENSURE_LOGGED_IN
  return [TiGooglesigninModule dictionaryFromUser:[[GIDSignIn sharedInstance] currentUser]];
}

- (NSString *)currentUserImageURLWithSize:(id)size
{
  ENSURE_LOGGED_IN
  ENSURE_SINGLE_ARG(size, NSNumber);

  return [[[[[GIDSignIn sharedInstance] currentUser] profile] imageURLWithDimension:[TiUtils intValue:size]] absoluteString];
}

- (void)setLanguage:(NSString *)language
{
  [[GIDSignIn sharedInstance] setLanguage:language];
}

- (NSString *)language
{
  return [[GIDSignIn sharedInstance] language];
}

#pragma mark Delegates

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error
{
  if ([self _hasListeners:@"login"]) {
    if (error != nil) {
      if (error.code == -5) {
        [self fireEvent:@"login" withObject:@{ @"success": @(NO), @"cancelled": @(YES) }];
      } else if ([self _hasListeners:@"error"]) {
        [self fireEvent:@"login" withObject:@{
          @"success": @(NO),
          @"error" : [error localizedDescription],
          @"code" : @([error code])
        }];
      }
      
      return;
    }

    [self fireEvent:@"login" withObject:@{ @"success": @(YES), @"cancelled": @(NO), @"user" : [TiGooglesigninModule dictionaryFromUser:user] }];
  }
}

- (void)signIn:(GIDSignIn *)signIn didDisconnectWithUser:(GIDGoogleUser *)user withError:(NSError *)error
{
  if ([self _hasListeners:@"logout"]) {
    [self fireEvent:@"logout"];
  }
}

#pragma mark Utilities

+ (NSDictionary *)dictionaryFromUser:(GIDGoogleUser *)user
{
  return @{
    @"id" : user.userID,
    @"scopes" : NULL_IF_NIL(user.grantedScopes),
    @"serverAuthCode" : NULL_IF_NIL(user.serverAuthCode),
    @"hostedDomain" : NULL_IF_NIL(user.hostedDomain),
    @"profile" : @{
      @"name" : NULL_IF_NIL(user.profile.name),
      @"givenName" : NULL_IF_NIL(user.profile.givenName),
      @"familyName" : NULL_IF_NIL(user.profile.familyName),
      @"email" : NULL_IF_NIL(user.profile.email),
      @"hasImage" : @(user.profile.hasImage)
    },
    @"authentication" : @{
      @"clientID" : NULL_IF_NIL(user.authentication.clientID),
      @"accessToken" : NULL_IF_NIL(user.authentication.accessToken),
      @"accessTokenExpirationDate" : NULL_IF_NIL(user.authentication.accessTokenExpirationDate),
      @"refreshToken" : NULL_IF_NIL(user.authentication.refreshToken),
      @"idToken" : NULL_IF_NIL(user.authentication.idToken),
      @"idTokenExpirationDate" : NULL_IF_NIL(user.authentication.idTokenExpirationDate)
    }
  };
}

MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_STYLE_STANDARD, kGIDSignInButtonStyleStandard);
MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_STYLE_WIDE, kGIDSignInButtonStyleWide);
MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_STYLE_ICON_ONLY, kGIDSignInButtonStyleIconOnly);

MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_COLOR_SCHEME_DARK, kGIDSignInButtonColorSchemeDark);
MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_COLOR_SCHEME_LIGHT, kGIDSignInButtonColorSchemeLight);

@end
