//
//  Channel.h
//  MCAT
//
//  Created by DNP on 9/16/05.
//  Copyright 2005 Peter J. Molfese. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Channel : NSObject 
{
	NSString *name;
	NSString *channels;
	NSArray *data;
}
-(NSString *)name;
-(NSString *)channels;
-(NSArray *)channelsAsArray;
-initWithName:(NSString *)newName andChannels:(NSString *)newChannels;
-(void)setName:(NSString *)newName;
-(void)setChannels:(NSString *)newChannels;
-(void)setData:(NSArray *)newData;

@end
