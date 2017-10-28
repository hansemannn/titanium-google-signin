/**
 * ti.googlesignin
 *
 * Created by Hans Knöchel
 * Copyright (c) 2017 Hans Knöchel. All rights reserved.
 */

#import "TiModule.h"
#import <GoogleSignIn/GoogleSignIn.h>

@interface TiGooglesigninModule : TiModule <GIDSignInDelegate, GIDSignInUIDelegate>

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
