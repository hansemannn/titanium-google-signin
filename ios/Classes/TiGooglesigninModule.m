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
}

- (void)signIn:(id)unused
{
  ENSURE_UI_THREAD(signIn, unused);
    
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
    ENSURE_TYPE_OR_NIL(loginHint, NSString);
    ENSURE_TYPE_OR_NIL(hostedDomain, NSString);
    ENSURE_TYPE_OR_NIL(serverClientID, NSString);
    ENSURE_TYPE_OR_NIL(openIDRealm, NSString);

    GIDConfiguration *config = [[GIDConfiguration alloc] initWithClientID:clientID
                                                           serverClientID:serverClientID
                                                             hostedDomain:hostedDomain
                                                              openIDRealm:openIDRealm];

  [[GIDSignIn sharedInstance] signInWithPresentingViewController:TiApp.app.controller.topPresentedController
                                                            hint:loginHint
                                                additionalScopes:scopes
                                                      completion:^(GIDSignInResult * _Nullable signInResult, NSError * _Nullable error) {
    [self fireLoginEventWithUser:signInResult.user andServerAuthCode:signInResult.serverAuthCode error:error];
  }];
}

- (void)signInSilently:(id)unused
{
  ENSURE_UI_THREAD(signInSilently, unused);
  [[GIDSignIn sharedInstance] restorePreviousSignInWithCompletion:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
    [self fireLoginEventWithUser:user andServerAuthCode:nil error:error];
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
  return [TiGooglesigninModule dictionaryFromUser:[[GIDSignIn sharedInstance] currentUser] andServerAuthCode:nil];
}

- (NSString *)currentUserImageURLWithSize:(id)size
{
  ENSURE_LOGGED_IN
  ENSURE_SINGLE_ARG(size, NSNumber);

  return [[[[[GIDSignIn sharedInstance] currentUser] profile] imageURLWithDimension:[TiUtils intValue:size]] absoluteString];
}

#pragma mark Utilities

- (void)fireLoginEventWithUser:(GIDGoogleUser *)user andServerAuthCode:(NSString *)serverAuthCode error:(NSError *)error
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

      [self fireEvent:@"login" withObject:@{
        @"success": @(YES),
        @"cancelled": @(NO),
        @"user" : [TiGooglesigninModule dictionaryFromUser:user andServerAuthCode:serverAuthCode]
      }];
    }
}

+ (NSDictionary *)dictionaryFromUser:(GIDGoogleUser *)user andServerAuthCode:(NSString *)serverAuthCode
{
  return @{
    @"id" : user.userID,
    @"scopes" : NULL_IF_NIL(user.grantedScopes),
    @"serverAuthCode": NULL_IF_NIL(serverAuthCode),
    @"hostedDomain" : NULL_IF_NIL(user.configuration.hostedDomain),
    @"profile" : @{
      @"name" : NULL_IF_NIL(user.profile.name),
      @"givenName" : NULL_IF_NIL(user.profile.givenName),
      @"familyName" : NULL_IF_NIL(user.profile.familyName),
      @"email" : NULL_IF_NIL(user.profile.email),
      @"hasImage" : @(user.profile.hasImage),
    },
    @"authentication" : @{
      @"clientID" : NULL_IF_NIL(user.configuration.clientID),
      @"serverClientID" : NULL_IF_NIL(user.configuration.serverClientID),
      @"accessToken" : NULL_IF_NIL(user.accessToken),
      @"refreshToken" : NULL_IF_NIL(user.refreshToken),
      @"idToken" : NULL_IF_NIL(user.idToken),
      @"openIDRealm": NULL_IF_NIL(user.configuration.openIDRealm)
    }
  };
}

MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_STYLE_STANDARD, kGIDSignInButtonStyleStandard);
MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_STYLE_WIDE, kGIDSignInButtonStyleWide);
MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_STYLE_ICON_ONLY, kGIDSignInButtonStyleIconOnly);

MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_COLOR_SCHEME_DARK, kGIDSignInButtonColorSchemeDark);
MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_COLOR_SCHEME_LIGHT, kGIDSignInButtonColorSchemeLight);

@end
