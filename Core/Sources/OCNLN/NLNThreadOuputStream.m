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

#import "NLNThreadOuputStream.h"

@implementation NLNThreadOutputStream

- (id)initWithOutputStream:(NSOutputStream *)aStream
                  threadId:(NSString *)aThreadId
                  delegate:(id)aDelegate
         didFinishSelector:(SEL)aSelector
{
    self = [super init];
    if (self != nil) {
        delegate = aDelegate;
        selector = aSelector;
        isWritten = NO;
        threadId = [[NSString alloc] initWithString:aThreadId];
        output = [aStream retain];
        [output setDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    [self close];
    [output release];
    [threadId release];
    output = nil;
    threadId = nil;
    [super dealloc];
}

- (void)open
{
    [output scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [output open];
}

- (void)close
{
    [output removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [output close];
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    switch(eventCode) {
        case NSStreamEventHasSpaceAvailable: {
            if (!isWritten) {
                char buffer[128];
                NSUInteger len = snprintf(buffer, sizeof(buffer), "<thread thread=\"%s\" version=\"20061206\" res_from=\"-1\"/>\\0", [threadId UTF8String]);
                if (len >= 0) {
                    NSInteger written = [(NSOutputStream *)stream write:(const uint8_t *)buffer maxLength:len + 1];
                    if (written < 0) {
                        [delegate performSelector:selector withObject:nil withObject:[stream streamError]];
                    }
                }
                isWritten = YES;
                [self close];
            }
        }
            break;
        case NSStreamEventErrorOccurred: {
            if (!isWritten)
                [delegate performSelector:selector withObject:nil withObject:[stream streamError]];
            [self close];
        }
            break;
    }
}

@end
