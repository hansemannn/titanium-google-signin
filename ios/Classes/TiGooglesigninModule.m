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

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleOpenURL:)
                                               name:@"TiApplicationLaunchedFromURL"
                                             object:nil];

  // These are actually used in "signIn()" now, but we keep it here for backwards compatibility with Android
  signInConfig = args;

  // Restoring a previous sign-in also needs the configuration
  id clientID = [signInConfig objectForKey:@"clientID"];
  if ([clientID isKindOfClass:[NSString class]]) {
    [[GIDSignIn sharedInstance] setConfiguration:[[GIDConfiguration alloc] initWithClientID:clientID
                                                                             serverClientID:[signInConfig objectForKey:@"serverClientID"]
                                                                               hostedDomain:[signInConfig objectForKey:@"hostedDomain"]
                                                                                openIDRealm:[signInConfig objectForKey:@"openIDRealm"]]];
  }
}

- (void)signIn:(id)args
{
  ENSURE_UI_THREAD(signIn, args);

    NSDictionary *params = nil;
    ENSURE_ARG_OR_NIL_AT_INDEX(params, args, 0, NSDictionary);
    id nonce = [params objectForKey:@"nonce"];
    ENSURE_TYPE_OR_NIL(nonce, NSString);
    
    id clientID = [signInConfig objectForKey:@"clientID"];
    id scopes = [signInConfig objectForKey:@"scopes"];
    id language = [signInConfig objectForKey:@"language"];
    id loginHint = [signInConfig objectForKey:@"loginHint"];
    id hostedDomain = [signInConfig objectForKey:@"hostedDomain"];
    id serverClientID = [signInConfig objectForKey:@"serverClientID"];
    id shouldFetchBasicProfile = [signInConfig objectForKey:@"shouldFetchBasicProfile"];
    id openIDRealm = [signInConfig objectForKey:@"openIDRealm"];

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

    GIDConfiguration *config = [[GIDConfiguration alloc] initWithClientID:clientID
                                                           serverClientID:serverClientID
                                                             hostedDomain:hostedDomain
                                                              openIDRealm:openIDRealm];

    if (language != nil) {
        DEPRECATED_REMOVED(@"GoogleSignIn.language (removed by Google)", @"5.0.0", @"5.0.0");
    }

    if (shouldFetchBasicProfile != nil) {
        DEPRECATED_REMOVED(@"GoogleSignIn.shouldFetchBasicProfile (removed by Google)", @"5.0.0", @"5.0.0");
    }

    [[GIDSignIn sharedInstance] setConfiguration:config];
    [[GIDSignIn sharedInstance] signInWithPresentingViewController:TiApp.app.controller.topPresentedController
                                                              hint:loginHint
                                                  additionalScopes:scopes
                                                             nonce:nonce
                                                        completion:^(GIDSignInResult * _Nullable signInResult, NSError * _Nullable error) {
        [self fireLoginEventWithUser:signInResult.user serverAuthCode:signInResult.serverAuthCode andError:error];
    }];
}

- (void)signInSilently:(id)unused
{
  ENSURE_UI_THREAD(signInSilently, unused);
    [[GIDSignIn sharedInstance] restorePreviousSignInWithCompletion:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
        [self fireLoginEventWithUser:user serverAuthCode:nil andError:error];
    }];
}

- (void)signOut:(id)unused
{
  ENSURE_UI_THREAD(signOut, unused);
  [[GIDSignIn sharedInstance] signOut];
}

- (void)disconnect:(id)unused
{
    ENSURE_UI_THREAD(disconnect, unused);
    [[GIDSignIn sharedInstance] disconnectWithCompletion:^(NSError * _Nullable error) {
        if ([self _hasListeners:@"logout"]) {
            [self fireEvent:@"logout" withObject:@{ @"success": @(error == nil), @"error": NULL_IF_NIL(error.localizedDescription) }];
        }
    }];
}

- (NSNumber *)hasAuthInKeychain:(id)unused
{
  return @([[GIDSignIn sharedInstance] hasPreviousSignIn]);
}

- (NSDictionary *)currentUser
{
  ENSURE_LOGGED_IN
  return [TiGooglesigninModule dictionaryFromUser:[[GIDSignIn sharedInstance] currentUser] serverAuthCode:nil];
}

- (NSString *)currentUserImageURLWithSize:(id)size
{
  ENSURE_LOGGED_IN
  ENSURE_SINGLE_ARG(size, NSNumber);

  return [[[[[GIDSignIn sharedInstance] currentUser] profile] imageURLWithDimension:[TiUtils intValue:size]] absoluteString];
}

- (void)setLanguage:(NSString *)language
{
    DEPRECATED_REMOVED(@"GoogleSignIn.language (removed by Google)", @"5.0.0", @"5.0.0");
}

- (NSString *)language
{
    DEPRECATED_REMOVED(@"GoogleSignIn.language (removed by Google)", @"5.0.0", @"5.0.0");
    return nil;
}

#pragma mark Utilities

- (void)fireLoginEventWithUser:(GIDGoogleUser *)user serverAuthCode:(NSString *)serverAuthCode andError:(NSError *)error
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

      [self fireEvent:@"login" withObject:@{ @"success": @(YES), @"cancelled": @(NO), @"user" : [TiGooglesigninModule dictionaryFromUser:user serverAuthCode:serverAuthCode] }];
    }
}

+ (NSDictionary *)dictionaryFromUser:(GIDGoogleUser *)user serverAuthCode:(NSString *)serverAuthCode
{
  return @{
    @"id" : user.userID,
    @"scopes" : NULL_IF_NIL(user.grantedScopes),
    @"serverAuthCode" : NULL_IF_NIL(serverAuthCode),
    @"hostedDomain" : NULL_IF_NIL(user.configuration.hostedDomain),
    @"profile" : @{
      @"name" : NULL_IF_NIL(user.profile.name),
      @"givenName" : NULL_IF_NIL(user.profile.givenName),
      @"familyName" : NULL_IF_NIL(user.profile.familyName),
      @"email" : NULL_IF_NIL(user.profile.email),
      @"hasImage" : @(user.profile.hasImage)
    },
    @"authentication" : @{
      @"clientID" : NULL_IF_NIL(user.configuration.clientID),
      @"accessToken" : NULL_IF_NIL(user.accessToken.tokenString),
      @"accessTokenExpirationDate" : NULL_IF_NIL(user.accessToken.expirationDate),
      @"refreshToken" : NULL_IF_NIL(user.refreshToken.tokenString),
      @"idToken" : NULL_IF_NIL(user.idToken.tokenString),
      @"idTokenExpirationDate" : NULL_IF_NIL(user.idToken.expirationDate)
    }
  };
}

MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_STYLE_STANDARD, kGIDSignInButtonStyleStandard);
MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_STYLE_WIDE, kGIDSignInButtonStyleWide);
MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_STYLE_ICON_ONLY, kGIDSignInButtonStyleIconOnly);

MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_COLOR_SCHEME_DARK, kGIDSignInButtonColorSchemeDark);
MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_COLOR_SCHEME_LIGHT, kGIDSignInButtonColorSchemeLight);

@end
