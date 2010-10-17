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

#import "NLNThreadInputStream.h"

@implementation NLNThreadInputStream

#define NLN_THREAD_INPUT_STREAM_BUFFER_SIZE 256

- (id)initWithInputStream:(NSInputStream *)aStream delegate:(id)aDelegate selector:(SEL)aSelector streamFilter:(SEL)aFilter
{
    self = [super init];
    if (self != nil) {
        delegate = aDelegate;
        selector = aSelector;
        byteBuffer = [[NSMutableData alloc] initWithCapacity:NLN_THREAD_INPUT_STREAM_BUFFER_SIZE];
        streamFilter = aFilter;
        streamLoader = [[NLNStreamLoader alloc] init];
        isChat = NO;
        input = [aStream retain];
        [input setDelegate:self];
        [input scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [input open];
    }
    return self;
}

- (void)dealloc
{
    [input close];
    [input release];
    input = nil;
    [super dealloc];
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    switch(eventCode) {
        case NSStreamEventHasBytesAvailable: {
            uint8_t buffer[NLN_THREAD_INPUT_STREAM_BUFFER_SIZE];
            uint8_t fragment[NLN_THREAD_INPUT_STREAM_BUFFER_SIZE];
            int readBytes = [(NSInputStream *)stream read:buffer maxLength:sizeof(buffer)];
            if (readBytes > 0) {
                [byteBuffer appendBytes:buffer length:readBytes];
                const char *s = [byteBuffer bytes];
                char *ptr = NULL;
                int loc = 0;
                while ((ptr = memchr(s + loc, '\0', readBytes - loc)) != NULL) {
                    int len = ptr - (s + loc);
                    memset(fragment, 0, NLN_THREAD_INPUT_STREAM_BUFFER_SIZE);
                    [byteBuffer getBytes:fragment range:NSMakeRange(loc, len)];
                    NSData *bytes = [[NSData alloc] initWithBytes:fragment length:len];
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
                    [bytes release];
                    loc += len + 1;
                }
                [byteBuffer replaceBytesInRange:NSMakeRange(0, loc) withBytes:NULL length:0];
            }
        }
            break;
        case NSStreamEventErrorOccurred: {
            [delegate performSelector:selector withObject:nil withObject:[stream streamError]];
        }
            break;
    }
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (qName)
        elementName = qName;
    if ([elementName isEqualToString:@"chat"])
        isChat = YES;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    isChat = NO;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (isChat) {
        NSArray *streamInfo = [string componentsSeparatedByString:@","];
        NSString *streamID = [streamInfo objectAtIndex:0];
        NSString *communityID = [streamInfo objectAtIndex:1];
        if ([[delegate performSelector:streamFilter withObject:streamID withObject:communityID] boolValue]) {
            NSString *streamName = [[NSString alloc] initWithFormat:@"lv%@", streamID];
            [streamLoader loadWithStreamId:streamName delegate:delegate selector:selector];
            [streamName release];
        }
    }
}

#undef NLN_THREAD_INPUT_STREAM_BUFFER_SIZE

@end
