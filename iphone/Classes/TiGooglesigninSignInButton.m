/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2016 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiGooglesigninSignInButton.h"
#import "TiUtils.h"

@implementation TiGooglesigninSignInButton

-(GIDSignInButton *)loginButton
{
    if (button == nil) {
        button = [[GIDSignInButton alloc] initWithFrame:self.bounds];
        [self addSubview:button];
    }
    return button;
}

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
    [TiUtils setView:[self loginButton] positionRect:bounds];
}

#pragma mark Public APIs

- (void)setStyle:(id)value
{
    ENSURE_TYPE(value, NSNumber);
    [[self loginButton] setStyle:[TiUtils intValue:value def:kGIDSignInButtonStyleStandard]];
}

- (void)setColorScheme:(id)value
{
    ENSURE_TYPE(value, NSNumber);
    [[self loginButton] setColorScheme:[TiUtils intValue:value def:kGIDSignInButtonColorSchemeDark]];
}

@end
