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

#import "NLNLoader.h"
#import "NLNLoader+Private.h"

NSString *const NLNWebAPIErrorDomain = @"NLNAPIErrorDomain";
NSString *const NLNUserAgentString = @"libnln-objective-c/1.0";

@implementation NLNLoader

- (id)init
{
    self = [super init];
    if (self != nil) {
        bytes = nil;
        delegate = nil;
        entity = nil;
        selector = nil;
        connection = nil;
        description = nil;
        code = nil;
    }
    return self;
}

- (void)dealloc
{
    [self releaseConnection];
    [super dealloc];
}

- (void)releaseConnection
{
    [entity release];
    [code release];
    [description release];
    [connection release];
    [bytes release];
    [request release];
    [url release];
    entity = nil;
    code = nil;
    description = nil;
    connection = nil;
    bytes = nil;
    request = nil;
    url = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [bytes setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [bytes appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [delegate performSelector:selector withObject:nil withObject:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:bytes];
    [parser setDelegate:self];
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
    [parser parse];
    NSError *error = [parser parserError];
    if (error) {
        [delegate performSelector:selector withObject:nil withObject:error];
    }
    [parser release];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    if (code != nil) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:NLNWebAPIErrorDomain code:0 userInfo:userInfo];
        [delegate performSelector:selector withObject:nil withObject:error];
    }
    else {
        [delegate performSelector:selector withObject:entity withObject:nil];
    }
    [entity release];
    entity = nil;
}

@end
