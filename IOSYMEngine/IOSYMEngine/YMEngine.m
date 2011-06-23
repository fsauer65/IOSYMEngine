//
//  YMEngine.m
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


#import "YMEngine.h"
#import "ASIHTTPRequest.h"
#import "JSONKit.h"

@interface NSString (UrlEncoding)
-(NSString *)urlEncoded;
@end

@implementation NSString (UrlEncoding)

-(NSString *)urlEncoded {
	return [(NSString *)CFURLCreateStringByAddingPercentEscapes(
                        NULL,
                        (CFStringRef)self,
                        (CFStringRef)@"%",
                        NULL,
                        kCFStringEncodingUTF8 ) autorelease];
}

@end

@interface NSURL (URLParams)

-(NSURL *)withParams: (NSDictionary *)params;
-(NSURL *)append: (NSString *)extra;
@end

@implementation NSURL (URLparams)

-(NSURL *)withParams: (NSDictionary *)params {
    NSMutableString *paramString = [NSMutableString stringWithString:@""];
    BOOL first = YES;
    for (NSString *key in [params allKeys]) {
        if (first) {
            [paramString appendString:@"?"];
            first = NO;
        } else {
            [paramString appendString:@"&"];
        }
        NSString *val = [params objectForKey:key];
        [paramString appendString:key];
        [paramString appendString:@"="];
        [paramString appendString:[val urlEncoded]];
    }
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self absoluteString], paramString]];
}

-(NSURL *)append: (NSString *)extra {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self absoluteString], extra]];
}

@end

@implementation YMEngine

#define URL_OAUTH_DIRECT @"https://login.yahoo.com/WSLogin/V1/get_auth_token"
#define URL_OAUTH_ACCESS_TOKEN @"https://api.login.yahoo.com/oauth/v2/get_token"
#define URL_YM_SESSION @"http://developer.messenger.yahooapis.com/v1/session"
#define URL_YM_CONTACT @"http://developer.messenger.yahooapis.com/v1/contacts"
#define URL_YM_MESSAGE @"http://developer.messenger.yahooapis.com/v1/message/yahoo/{{USER}}"

-(id)initWithConsumerKey: (NSString *)consumerKey secretKey: (NSString *)secretKey 
                userName: (NSString *)userName password: (NSString *)pwd {
    self = [super init];
    if (self) {
        _consumerKey = [consumerKey retain];
        _secretKey = [secretKey retain];
        _userName = [userName retain];
        _pwd = [pwd retain];
    }
    return self;
}

-(void)dealloc {
    [_consumerKey release];
    [_secretKey release];
    [_userName release];
    [_pwd release];
    [requestToken release];
    [oauthTokens release];
    [signon release];
    [super dealloc];
}

-(void)failWithCode: (NSInteger)code message: (NSString *)msg {
    if (_errorHandler) {
        NSError *err = [NSError errorWithDomain:@"Yahoo Messenger Engine" code:code userInfo:[NSDictionary dictionaryWithObject:msg forKey:@"localizedDescription"]];
        [self performSelectorOnMainThread:@selector(reportFailure:) withObject:err waitUntilDone:[NSThread isMainThread]];
    }
}

/*
 * error block is always invoked on MAIN THREAD
 */
-(void)reportFailure: (NSError *)error {
    _errorHandler(error);
}

-(NSString *)nonce {
    NSString *nonce = nil;
    CFUUIDRef generatedUUID = CFUUIDCreate(kCFAllocatorDefault);
    nonce = (NSString*)CFUUIDCreateString(kCFAllocatorDefault, generatedUUID);
    CFRelease(generatedUUID);
    
    return [nonce autorelease];
}

-(NSString *)timestamp {
    return [NSString stringWithFormat:@"%d", (long)[[NSDate date] timeIntervalSince1970]];
}

-(NSDictionary *)oauthParams {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            _consumerKey, @"oauth_consumer_key",
            [self nonce], @"oauth_nonce",
            [NSString stringWithFormat:@"%@%%26%@",
                _secretKey, 
                [oauthTokens objectForKey:@"oauth_token_secret"]], @"oauth_signature",
            @"PLAINTEXT", @"oauth_signature_method",
            [self timestamp], @"oauth_timestamp",
            [oauthTokens objectForKey:@"oauth_token"], @"oauth_token",
            @"1.0", @"oauth_version",
            nil];
}

-(BOOL)fetchRequestToken {
    NSURL *url = [[NSURL URLWithString:URL_OAUTH_DIRECT] 
                  withParams:[NSDictionary dictionaryWithObjectsAndKeys:
                              _userName, @"login",
                              _pwd, @"passwd",
                              _consumerKey, @"oauth_consumer_key",
                              nil]];
    ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
    req.useCookiePersistence = NO;
    NSLog(@"getting token from %@", url);
    [req startSynchronous];
    if (req.responseStatusCode == 200) {
        NSString *responseBody = [req responseString];
        if ([responseBody hasPrefix:@"RequestToken="]) {
            requestToken = [responseBody stringByReplacingOccurrencesOfString:@"RequestToken=" withString:@""];
            return true;
        } else {
            [self failWithCode:1 message:[NSString stringWithFormat:@"Error getting request token: %@", responseBody]];
            return false;
        }
    } else {
        [self failWithCode:1 message:[NSString stringWithFormat:@"Error getting request token: %d (%@)", req.responseStatusCode, [req responseString]]];
        return false;
    }
}

-(BOOL)fetchAccessToken {
    NSURL *url = [[NSURL URLWithString:URL_OAUTH_ACCESS_TOKEN] 
                  withParams:[NSDictionary dictionaryWithObjectsAndKeys:
                              _consumerKey, @"oauth_consumer_key",
                              [self nonce], @"oauth_nonce",
                              [NSString stringWithFormat:@"%@%%26",_secretKey],@"oauth_signature",
                              @"PLAINTEXT", @"oauth_signature_method",
                              [self timestamp], @"oauth_timestamp",
                              requestToken, @"oauth_token",
                              @"1.0", @"oauth_version",
                              nil]];
    ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
    req.useCookiePersistence = NO;
    NSLog(@"getting token from %@", url);
    [req startSynchronous];
    if (req.responseStatusCode == 200) {
        NSString *responseBody = [req responseString];
        if ([responseBody rangeOfString:@"oauth_token"].location == NSNotFound) {
           [self failWithCode:2 message:[NSString stringWithFormat:@"No access token in: %@", responseBody]];
            return false;
        }
        // we have one, parse the response
        NSArray *parts = [responseBody componentsSeparatedByString:@"&"];
        NSMutableDictionary *oauth = [NSMutableDictionary dictionaryWithCapacity:[parts count]];
        for (NSString *p in parts) {
            NSArray *kv = [p componentsSeparatedByString:@"="];
            [oauth setObject:[kv objectAtIndex:1] forKey:[kv objectAtIndex:0]];
        }
        oauthTokens = [[NSDictionary dictionaryWithDictionary:oauth] retain];
        return true;
    } else {
        [self failWithCode:2 message:[NSString stringWithFormat:@"Error getting access token: %d (%@)", req.responseStatusCode, [req responseString]]];
        return false;
    }    
    return true;
}

-(BOOL)signon: (NSString *)status {
    NSURL *url = [[NSURL URLWithString:URL_YM_SESSION] withParams: [self oauthParams]];
    ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url]; 
    req.useCookiePersistence = NO;
    req.requestMethod = @"POST";
    [req addRequestHeader:@"Content-Type" value:@"application/json; charset=utf-8"];
    NSDictionary *json = [NSDictionary dictionaryWithObjectsAndKeys:
                          status, @"presenceMessage",
                          [NSNumber numberWithInt:0], @"presenceState",
                          nil];
    [req appendPostData:[json JSONData]];
    NSLog(@"Sending %@ to %@", json, url);
    [req startSynchronous];
    if (req.responseStatusCode == 200) {
        NSString *responseBody = [req responseString];
        if ([responseBody rangeOfString:@"sessionId"].location == NSNotFound) {
            [self failWithCode:3 message:[NSString stringWithFormat:@"No sessionId in: %@", responseBody]];
            return false;
        }
        signon = [[responseBody objectFromJSONString] retain];
        return true;
    } else {
        [self failWithCode:2 message:[NSString stringWithFormat:@"Error getting session: %d (%@)", req.responseStatusCode, [req responseString]]];
        return false;
    }  
}

-(NSMutableDictionary *)sessionParams {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self oauthParams]];
    [params setObject:[signon objectForKey:@"sessionId"] forKey:@"sid"];
    return params;
}

-(void)signoff {
    NSURL *url = [[NSURL URLWithString:URL_YM_SESSION] withParams: [self sessionParams]];
    ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url]; 
    req.requestMethod = @"DELETE";
    [req startSynchronous];
}

-(NSArray *)fetchContactList {
    NSURL *url = [[NSURL URLWithString:URL_YM_CONTACT] withParams: [self sessionParams]];
    url = [url append:@"&fields=%2Bpresence&fields=%2Bgroups"];
    ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url]; 
    [req addRequestHeader:@"Accept" value:@"application/json; charset=utf-8"];
    NSLog(@"getting contacts from %@", url);
    [req startSynchronous];
    if (req.responseStatusCode == 200) {
        NSDictionary *data = [[req responseData] objectFromJSONData];
        return [data objectForKey:@"contacts"];
    } else {
        NSLog(@"Error getting contacts: %d (%@)", req.responseStatusCode, [req responseString]);
        return nil;
    } 
}

-(BOOL)sendMessage: (NSString *)message to: (NSString *)user {
    NSString *withUser = [URL_YM_MESSAGE stringByReplacingOccurrencesOfString:@"{{USER}}" withString:user]; 
    NSURL *url = [[NSURL URLWithString:withUser] withParams: [self sessionParams]];
    ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
    [req addRequestHeader:@"Content-Type" value:@"application/json; charset=utf-8"];
    NSDictionary *content = [NSDictionary dictionaryWithObject:message forKey:@"message"];
    [req appendPostData:[content JSONData]];
    NSLog(@"Sending %@ to %@", message, url);
    [req startSynchronous];
    if (req.responseStatusCode == 200) {
        NSLog(@"Message sent");
        return true;
    } else {
        NSLog(@"Error sending message: %d (%@)", req.responseStatusCode, [req responseString]);
        return false;
    } 
}

-(void)onError: (YMErrorBlock)errorHandler {
    _errorHandler = errorHandler;
}

-(void)withSignOn: (NSString *)status signoffAfter: (BOOL)signoff 
               do: (void (^)(NSArray *))clientCode {
    if ([self fetchRequestToken]) {
        NSLog(@"Got request token");
        if ([self fetchAccessToken]) {
            NSLog(@"Got access token");
            if ([self signon:status]) {
                NSLog(@"Signed in!");
                clientCode([self fetchContactList]);
                if (signoff) [self signoff];
            }
        }
    }
    
}
@end
