/**
 * titanium-googlesignin
 *
 * Created by Hans Knöchel
 * Copyright (c) 2017-present Hans Knöchel. All rights reserved.
 */

#import <GoogleSignIn/GoogleSignIn.h>
#import <TitaniumKit/TitaniumKit.h>

@interface TiGooglesigninModule : TiModule <GIDSignInDelegate>

- (void)initialize:(id)args;

- (void)signIn:(id)unused;

- (void)signInSilently:(id)unused;

- (void)signOut:(id)unused;

- (void)disconnect:(id)unused;

- (id)hasAuthInKeychain:(id)unused;

- (id)currentUser;

- (id)currentUserImageURLWithSize:(id)size;

- (NSNumber *)loggedIn;

@end
