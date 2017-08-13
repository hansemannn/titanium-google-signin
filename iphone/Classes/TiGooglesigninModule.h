/**
 * ti.googlesignin
 *
 * Created by Hans Knöchel
 * Copyright (c) 2017 Hans Knöchel. All rights reserved.
 */

#import "TiModule.h"
#import <GoogleSignIn/GoogleSignIn.h>

@interface TiGooglesigninModule : TiModule <GIDSignInDelegate, GIDSignInUIDelegate>

@end
