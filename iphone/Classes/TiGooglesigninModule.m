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

@implementation TiGooglesigninModule

#pragma mark Internal

-(id)moduleGUID
{
	return @"7fa817c2-5c36-402b-a442-f2cafd41da64";
}

-(NSString*)moduleId
{
	return @"ti.googlesignin";
}

#pragma mark Lifecycle

-(void)startup
{
	[super startup];

	NSLog(@"[DEBUG] %@ loaded",self);
}

#pragma Public APIs

-(void)initialize:(id)args
{
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    id scopes = [args objectForKey:@"scopes"];
    id clientID = [args objectForKey:@"clientID"];
    
    ENSURE_TYPE_OR_NIL(scopes, NSArray);
    ENSURE_TYPE(clientID, NSString);
    
    [[GIDSignIn sharedInstance] setScopes:scopes];
    [[GIDSignIn sharedInstance] setClientID:clientID];
    
    // TODO: Expose all other shared instance properties
    
    [[GIDSignIn sharedInstance] setDelegate:self];
}

-(void)signIn:(id)unused
{
    [[GIDSignIn sharedInstance] signIn];
}

-(void)signInSilently:(id)unused
{
    [[GIDSignIn sharedInstance] signInSilently];
}

-(void)signOut:(id)unused
{
    [[GIDSignIn sharedInstance] signOut];
}

-(void)disconnect:(id)unused
{
    [[GIDSignIn sharedInstance] disconnect];
}

#pragma mark Delegates

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error
{
    if ([self _hasListeners:@"login"]) {
        [self fireEvent:@"login" withObject:@{@"user": [TiGooglesigninModule dictionaryFromUser:user]}];
    }
}

- (void)signIn:(GIDSignIn *)signIn didDisconnectWithUser:(GIDGoogleUser *)user withError:(NSError *)error
{
    if ([self _hasListeners:@"logout"]) {
        [self fireEvent:@"logout" withObject:@{@"user": [TiGooglesigninModule dictionaryFromUser:user]}];
    }
}

- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController
{
    if ([self _hasListeners:@"open"]) {
        [self fireEvent:@"open"];
    }
}

- (void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController
{
    if ([self _hasListeners:@"close"]) {
        [self fireEvent:@"close"];
    }
}


- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error
{
    if ([self _hasListeners:@"load"]) {
        [self fireEvent:@"load"];
    }
}

#pragma mark Helper

+ (NSDictionary *)dictionaryFromUser:(GIDGoogleUser *)user
{
    // TODO: Expose all
    return @{
        @"id": user.userID,
        @"scopes": user.accessibleScopes,
        @"serverAuthCode": user.serverAuthCode
    };
}

@end
