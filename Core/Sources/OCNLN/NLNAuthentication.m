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

#import "NLNAuthentication.h"
#import "NLNLoader+Private.h"

@implementation NLNAuthentication

struct NLNAuthenticationXMLParserState {
    BOOL isError;
    BOOL ticketState;
    BOOL codeState;
    BOOL descriptionState;
};

static void toggleXMLParserState(NLNAuthenticationXMLParserState *state, NSString *element, BOOL value)
{
    if ([element isEqualToString:@"ticket"])
        state->ticketState = value;
    else if (state->isError && [element isEqualToString:@"code"])
        state->codeState = value;
    else if (state->isError && [element isEqualToString:@"description"])
        state->descriptionState = value;
}

- (id)init
{
    if ((state = calloc(1, sizeof(NLNAuthenticationXMLParserState))) == NULL)
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

- (void)authenticateWithEmail:(NSString *)email password:(NSString *)password delegate:(id)aDelegate didFinishSelector:(SEL)aSelector
{
    NSMutableString *param = [NSMutableString stringWithFormat:@"mail=%@&password=%@", email, password];
    [self releaseConnection];
    delegate = aDelegate;
    selector = aSelector;
    bytes = [[NSMutableData alloc] init];
    url = [[NSURL alloc] initWithString:@"https://secure.nicovideo.jp/secure/login?site=nicolive_antenna"];
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
    if ([elementName isEqualToString:@"nicovideo_user_response"]) {
        NSString *status = [attributeDict objectForKey:@"status"];
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
    if (state->ticketState) {
        entity = [string retain];
    }
    else if (state->codeState) {
        code = [string retain];
    }
    else if (state->descriptionState) {
        description = [string retain];
    }
}

@end
