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

#import <Foundation/Foundation.h>
#import "NLNMessageServer.h"

@interface NLNUser : NSObject {
@private
    NSUInteger userId;
    NSString *hash;
    NSString *name;
    NSInteger prefecture;
    NSUInteger age;
    NSString *sex;
    BOOL isPremium;
    NSMutableArray *communities;
    NLNMessageServer *server;
}

@property(nonatomic, readonly) NSUInteger userId;
@property(nonatomic, readonly) NSString *hash;
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSInteger prefecture;
@property(nonatomic, readonly) NSUInteger age;
@property(nonatomic, readonly) NSString *sex;
@property(nonatomic, readonly) BOOL isPremium;
@property(nonatomic, readonly) NSArray *communities;
@property(nonatomic, readonly) NLNMessageServer *server;

- (BOOL)isMemberOfCommunityWithId:(NSString *)communityId;

@end
