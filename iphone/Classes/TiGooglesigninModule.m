/**
 * ti.googlesignin
 *
 * Created by Hans Knoechel
 * Copyright (c) 2017 Your Company. All rights reserved.
 */

#import "TiGooglesigninModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiApp.h"

#define ENSURE_LOGGED_IN \
if (![[GIDSignIn sharedInstance] hasAuthInKeychain]) { \
    NSLog(@"[WARN] No user infos found. Check with \"hasAuthInKeychain()\" before."); \
    return nil; \
} \

@implementation TiGooglesigninModule

#pragma mark Internal

- (id)moduleGUID
{
	return @"7fa817c2-5c36-402b-a442-f2cafd41da64";
}

- (NSString*)moduleId
{
	return @"ti.googlesignin";
}

#pragma mark Lifecycle

- (void)startup
{
	[super startup];

	NSLog(@"[DEBUG] %@ loaded",self);
}

- (void)handleOpenURL:(NSNotification *)notification
{
    NSDictionary *launchOptions = [[TiApp app] launchOptions];
    NSString *urlString = [launchOptions objectForKey:@"url"];
    NSString *sourceApplication = [launchOptions objectForKey:@"source"];
    id annotation = nil;
    
    if ([TiUtils isIOS9OrGreater]) {
#ifdef __IPHONE_9_0
        annotation = [launchOptions objectForKey:UIApplicationOpenURLOptionsAnnotationKey];
#endif
    }
    
    if (urlString != nil) {
        [[GIDSignIn sharedInstance] handleURL:[NSURL URLWithString:urlString]
                            sourceApplication:sourceApplication
                                   annotation:annotation];
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
                                                 name:@"TiApplicationLaunchedFromURL" object:nil];

    [[GIDSignIn sharedInstance] setDelegate:self];
    [[GIDSignIn sharedInstance] setUiDelegate:self];

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
    [[GIDSignIn sharedInstance] signInSilently];
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

- (id)hasAuthInKeychain:(id)unused
{
    return NUMBOOL([[GIDSignIn sharedInstance] hasAuthInKeychain]);
}

- (id)currentUser
{
    ENSURE_LOGGED_IN
    return [TiGooglesigninModule dictionaryFromUser:[[GIDSignIn sharedInstance] currentUser]];
}

- (id)currentUserImageURLWithSize:(id)size
{
    ENSURE_LOGGED_IN
    ENSURE_SINGLE_ARG(size, NSNumber);
    
    return [[[[[GIDSignIn sharedInstance] currentUser] profile] imageURLWithDimension:[TiUtils intValue:size]] absoluteString];
}

#pragma mark Delegates

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error
{
    if (error != nil) {
        if ([self _hasListeners:@"error"]) {
            [self fireEvent:@"error" withObject:@{
                @"message": [error localizedDescription],
                @"code": NUMINTEGER([error code])
            }];
        }
        
        return;
    }
    
    if ([self _hasListeners:@"login"]) {
        [self fireEvent:@"login" withObject:@{@"user": [TiGooglesigninModule dictionaryFromUser:user]}];
    }
}

- (void)signIn:(GIDSignIn *)signIn didDisconnectWithUser:(GIDGoogleUser *)user withError:(NSError *)error
{
    if ([self _hasListeners:@"disconnect"]) {
        [self fireEvent:@"disconnect" withObject:@{@"user": [TiGooglesigninModule dictionaryFromUser:user]}];
    }
}

- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController
{
    [[TiApp app] showModalController:viewController animated:YES];
    
    if ([self _hasListeners:@"open"]) {
        [self fireEvent:@"open"];
    }
}

- (void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController
{
    [[TiApp app] hideModalController:viewController animated:YES];

    if ([self _hasListeners:@"close"]) {
        [self fireEvent:@"close"];
    }
}

- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error
{
    if (error != nil) {
        if ([self _hasListeners:@"error"]) {
            [self fireEvent:@"error" withObject:@{
                @"message": [error localizedDescription],
                @"code": NUMINTEGER([error code])
            }];
        }
        
        return;
    }
    
    if ([self _hasListeners:@"load"]) {
        [self fireEvent:@"load"];
    }
}

#pragma mark Utilities

+ (NSDictionary *)dictionaryFromUser:(GIDGoogleUser *)user
{
    return @{
        @"id": user.userID,
        @"scopes": user.accessibleScopes,
        @"serverAuthCode": user.serverAuthCode ?: [NSNull null],
        @"hostedDomain": user.hostedDomain ?: [NSNull null],
        @"profile": @{
            @"name": user.profile.name,
            @"givenName": user.profile.givenName,
            @"familyName": user.profile.familyName,
            @"email": user.profile.email,
            @"hasImage": NUMBOOL(user.profile.hasImage),
        },
        @"authentication": @{
            @"clientID": user.authentication.clientID,
            @"accessToken": user.authentication.accessToken,
            @"clientID": user.authentication.clientID,
            @"accessTokenExpirationDate": user.authentication.accessTokenExpirationDate,
            @"refreshToken": user.authentication.refreshToken,
            @"idToken": user.authentication.idToken,
            @"idTokenExpirationDate": user.authentication.idTokenExpirationDate,
        }
    };
}

MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_STYLE_STANDARD, kGIDSignInButtonStyleStandard);
MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_STYLE_WIDE, kGIDSignInButtonStyleWide);
MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_STYLE_ICON_ONLY, kGIDSignInButtonStyleIconOnly);

MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_COLOR_SCHEME_DARK, kGIDSignInButtonColorSchemeDark);
MAKE_SYSTEM_PROP(SIGN_IN_BUTTON_COLOR_SCHEME_LIGHT, kGIDSignInButtonColorSchemeLight);

@end
