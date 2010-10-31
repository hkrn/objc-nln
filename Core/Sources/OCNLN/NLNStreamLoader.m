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

#import "NLNStreamLoader.h"
#import "NLNLoader+Private.h"

@interface NLNCommunity (Private)

- (void)setName:(NSString *)value;
- (void)setThumbnailURL:(NSString *)value;

@end

@implementation NLNCommunity (Private)

- (void)setName:(NSString *)value
{
    name = [value retain];
}

- (void)setThumbnailURL:(NSString *)value
{
    NSURL *url = [[NSURL alloc] initWithString:value];
    thumbnailURL = url;
}

@end

@interface NLNStream (Private)

- (void)setStreamId:(NSString *)value;
- (void)setTitle:(NSString *)value;
- (void)setDescription:(NSString *)value;
- (void)setProviderType:(NSString *)value;
- (void)setDefaultCommunityId:(NSString *)value;

@end

@implementation NLNStream (Private)

- (void)setStreamId:(NSString *)value
{
    streamId = [value retain];
}

- (void)setTitle:(NSString *)value
{
    title = [value retain];
}

- (void)setDescription:(NSString *)value
{
    description = [value retain];
}

- (void)setProviderType:(NSString *)value
{
    providerType = [value retain];
}

- (void)setDefaultCommunityId:(NSString *)value
{
    defaultCommunityId = [value retain];
}

@end

@implementation NLNStreamLoader

struct NLNStreamXMLParserState {
    BOOL isError;
    BOOL isStreamInfoTag;
    BOOL isCommunityInfoTag;
    BOOL requestIdState;
    BOOL streamTitleState;
    BOOL streamDescriptionState;
    BOOL providerTypeState;
    BOOL defaultCommunityState;
    BOOL communityNameState;
    BOOL communityThumbnailState;
    BOOL codeState;
    BOOL descriptionState;
};

static void toggleXMLParserState(NLNStreamXMLParserState *state, NSString *element, BOOL value)
{
    if ([element isEqualToString:@"request_id"])
        state->requestIdState = value;
    else if ([element isEqualToString:@"streaminfo"])
        state->isStreamInfoTag = value;
    else if ([element isEqualToString:@"communityinfo"])
        state->isCommunityInfoTag = value;
    else if (state->isStreamInfoTag && [element isEqualToString:@"title"])
        state->streamTitleState = value;
    else if (state->isStreamInfoTag && [element isEqualToString:@"description"])
        state->streamDescriptionState = value;
    else if (state->isStreamInfoTag && [element isEqualToString:@"provider_type"])
        state->providerTypeState = value;
    else if (state->isStreamInfoTag && [element isEqualToString:@"default_community"])
        state->defaultCommunityState = value;
    else if (state->isCommunityInfoTag && [element isEqualToString:@"name"])
        state->communityNameState = value;
    else if (state->isCommunityInfoTag && [element isEqualToString:@"thumbnail"])
        state->communityThumbnailState = value;
    else if (state->isError && [element isEqualToString:@"code"])
        state->codeState = value;
    else if (state->isError && [element isEqualToString:@"description"])
        state->descriptionState = value;
}

- (id)init
{
    if ((state = calloc(1, sizeof(NLNStreamXMLParserState))) == NULL)
        return nil;
    self = [super init];
    if (self != nil) {
        delegate = nil;
        selector = nil;
    }
    return self;
}

- (void)dealloc
{
    if (state != NULL) {
        free(state);
        state = NULL;
    }
    [super dealloc];
}

- (void)loadStreamWithId:(NSString *)streamId delegate:(id)aDelegate didFinishSelector:(SEL)aSelector
{
    NLNStream *stream = [[NLNStream alloc] init];
    NSMutableString *urlString = [NSString stringWithFormat:@"http://live.nicovideo.jp/api/getstreaminfo/%@", streamId];
    [self releaseConnection];
    [stream setStreamId:streamId];
    entity = stream;
    delegate = aDelegate;
    selector = aSelector;
    bytes = [[NSMutableData alloc] init];
    url = [[NSURL alloc] initWithString:urlString];
    request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:NLNUserAgentString forHTTPHeaderField:@"User-Agent"];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (qName)
        elementName = qName;
    if ([elementName isEqualToString:@"getstreaminfo"]) {
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
    NLNStream *stream = (NLNStream *)entity;
    if (state->streamTitleState) {
        [stream setTitle:string];
    }
    else if (state->streamDescriptionState) {
        [stream setDescription:string];
    }
    else if (state->providerTypeState) {
        [stream setProviderType:string];
    }
    else if (state->defaultCommunityState) {
        [stream setDefaultCommunityId:string];
    }
    else if (state->communityNameState) {
        [stream.community setName:string];
    }
    else if (state->communityThumbnailState) {
        [stream.community setThumbnailURL:string];
    }
    else if (state->codeState) {
        code = [[NSString alloc] initWithString:string];
    }
    else if (state->descriptionState) {
        description = [[NSString alloc] initWithString:string];
    }
}

@end
