//
//  YMEngine.h
//
//  Created by FRANK SAUER on 6/22/11.
//  Copyright 2011 Volantec.biz. All rights reserved.
//
//  Based on PHP code by Yahoo! Inc. from https://github.com/yahoo/messenger-sdk-php
//
//  All rights reserved.
//
//  Redistribution and use of this software in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above
//  copyright notice, this list of conditions and the
//  following disclaimer.
//
//  Redistributions in binary form must reproduce the above
//  copyright notice, this list of conditions and the
//  following disclaimer in the documentation and/or other
//  materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import <Foundation/Foundation.h>

typedef void (^YMErrorBlock)(NSError *error);
typedef void (^SignedOnBlock)(NSArray *contacts);

@interface YMEngine : NSObject {
    NSString *_consumerKey;
    NSString *_secretKey;
    NSString *_userName;
    NSString *_pwd;
    
    NSDictionary *oauthTokens;
    NSDictionary *signon;
    NSString *requestToken;
    
    YMErrorBlock _errorHandler;
}

-(id)initWithConsumerKey: (NSString *)consumerKey secretKey: (NSString *)secretKey 
                userName: (NSString *)userName password: (NSString *)pwd;

-(BOOL)fetchRequestToken;
-(BOOL)fetchAccessToken;
-(BOOL)signon: (NSString *)status;
-(void)signoff;
-(NSArray *)fetchContactList;
-(BOOL)sendMessage: (NSString *)message to: (NSString *)user;

-(void)withSignOn: (NSString *)status signoffAfter: (BOOL)signoff 
               do: (SignedOnBlock)clientCode;

-(void)onError: (YMErrorBlock)errorHandler;

@end
