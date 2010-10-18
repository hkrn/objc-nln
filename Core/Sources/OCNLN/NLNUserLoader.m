/*
 Copyright (c) 2010, hkrn
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the <organization> nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDER BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NLNUserLoader.h"
#import "NLNLoader+Private.h"

@interface NLNMessageServer (Private)

- (void)setAddress:(NSString *)value;
- (void)setPort:(NSInteger)value;
- (void)setThreadId:(NSString *)value;

@end

@implementation NLNMessageServer (Private)

- (void)setAddress:(NSString *)value
{
    address = [value retain];
}

- (void)setPort:(NSInteger)value
{
    port = value;
}

- (void)setThreadId:(NSString *)value
{
    threadId = [value retain];
}

@end

@interface NLNUser (Private)

- (void)setUserId:(NSUInteger)value;
- (void)setUserName:(NSString *)value;
- (void)setHash:(NSString *)value;
- (void)setAge:(NSUInteger)value;
- (void)setPrefecture:(NSInteger)value;
- (void)setPremium:(BOOL)value;
- (void)addCommunity:(NSString *)value;

@end

@implementation NLNUser (Private)

- (void)setUserId:(NSUInteger)value
{
    userId = value;
}

- (void)setUserName:(NSString *)value
{
    name = [value retain];
}

- (void)setHash:(NSString *)value
{
    hash = [value retain];
}

- (void)setAge:(NSUInteger)value
{
    age = value;
}

- (void)setPrefecture:(NSInteger)value
{
    prefecture = value;
}

- (void)setPremium:(BOOL)value
{
    isPremium = value;
}

- (void)addCommunity:(NSString *)value
{
    [communities addObject:value];
}

@end

@implementation NLNUserLoader

struct NLNUserXMLParserState {
    BOOL isError;
    BOOL userIdState;
    BOOL userHashState;
    BOOL userNameState;
    BOOL userPrefectureState;
    BOOL userAgeState;
    BOOL userSexState;
    BOOL isPremiumState;
    BOOL communitiesState;
    BOOL messageServerAddrState;
    BOOL messageServerPortState;
    BOOL messageServerThreadState;
    BOOL codeState;
    BOOL descriptionState;
};

static void toggleXMLParserState(NLNUserXMLParserState *state, NSString *element, BOOL value)
{
    if ([element isEqualToString:@"user_id"]) {
        state->userIdState = value;
    }
    else if ([element isEqualToString:@"user_hash"]) {
        state->userHashState = value;
    }
    else if ([element isEqualToString:@"user_name"]) {
        state->userNameState = value;
    }
    else if ([element isEqualToString:@"user_prefecture"]) {
        state->userPrefectureState = value;
    }
    else if ([element isEqualToString:@"user_age"]) {
        state->userAgeState = value;
    }
    else if ([element isEqualToString:@"user_sex"]) {
        state->userSexState = value;
    }
    else if ([element isEqualToString:@"is_premium"]) {
        state->isPremiumState = value;
    }
    else if ([element isEqualToString:@"communities"]) {
        state->communitiesState = value;
    }
    else if ([element isEqualToString:@"addr"]) {
        state->messageServerAddrState = value;
    }
    else if ([element isEqualToString:@"port"]) {
        state->messageServerPortState = value;
    }
    else if ([element isEqualToString:@"thread"]) {
        state->messageServerThreadState = value;
    }
    else if (state->isError && [element isEqualToString:@"code"]) {
        state->codeState = value;
    }
    else if (state->isError && [element isEqualToString:@"description"]) {
        state->descriptionState = value;
    }
}

- (id)init
{
    state = calloc(1, sizeof(NLNUserXMLParserState));
    if (state == NULL)
        return nil;
    return [super init];
}

- (void)dealloc
{
    if (state != NULL) {
        free(state);
        state = NULL;
    }
    [super dealloc];
}

- (void)loadUserWithDelegate:(id)aDelegate didFinishSelector:(SEL)aSelector
{
    [self releaseConnection];
    delegate = aDelegate;
    selector = aSelector;
    bytes = [[NSMutableData alloc] init];
    url = [[NSURL alloc] initWithString:@"http://live.nicovideo.jp/api/getalertinfo"];
    request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:NLNUserAgentString forHTTPHeaderField:@"User-Agent"];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)loadUserWithTicket:(NSString *)ticket delegate:(id)aDelegate didFinishSelector:(SEL)aSelector
{
    NSMutableString *param = [NSMutableString stringWithFormat:@"ticket=%@", ticket];
    [self releaseConnection];
    delegate = aDelegate;
    selector = aSelector;
    bytes = [[NSMutableData alloc] init];
    url = [[NSURL alloc] initWithString:@"http://live.nicovideo.jp/api/getalertstatus"];
    request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:NLNUserAgentString forHTTPHeaderField:@"User-Agent"];
    [request setHTTPBody:[param dataUsingEncoding:NSUTF8StringEncoding]];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (qName)
        elementName = qName;
    if ([elementName isEqualToString:@"getalertstatus"]) {
        NSString *status = [attributeDict objectForKey:@"status"];
        entity = [[NLNUser alloc] init];
        state->isError = [status isEqualToString:@"ok"] == NO;
    }
    else {
        toggleXMLParserState(state, elementName, YES);
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if (qName)
        elementName = qName;
    toggleXMLParserState(state, elementName, NO);
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    NLNUser *user = (NLNUser *)entity;
    if (state->communitiesState) {
        [user addCommunity:string];
    }
    else if (state->userIdState) {
        [user setUserId:[string integerValue]];
    }
    else if (state->userNameState) {
        [user setUserName:string];
    }
    else if (state->userHashState) {
        [user setHash:string];
    }
    else if (state->userPrefectureState) {
        [user setPrefecture:[string integerValue]];
    }
    else if (state->userAgeState) {
        [user setAge:[string integerValue]];
    }
    else if (state->isPremiumState) {
        [user setPremium:[string integerValue] > 0];
    }
    else if (state->messageServerAddrState) {
        [user.server setAddress:string];
    }
    else if (state->messageServerPortState) {
        [user.server setPort:[string integerValue]];
    }
    else if (state->messageServerThreadState) {
        [user.server setThreadId:string];
    }
    else if (state->codeState) {
        code = [string retain];
    }
    else if (state->descriptionState) {
        description = [string retain];
    }
}

@end
