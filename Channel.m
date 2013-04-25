//
//  Channel.m
//  MCAT
//
//  Created by DNP on 9/16/05.
//  Copyright 2005 Peter J. Molfese. All rights reserved.
//

#import "Channel.h"


@implementation Channel

-init
{
	[super init];
	[self setName:@""];
	[self setChannels:@""];
	return self;
}

-initWithName:(NSString *)newName andChannels:(NSString *)newChannels
{
	[super init];
	[self setName:newName];
	[self setChannels:newChannels];
	return self;
}

-(void)dealloc
{
	[name release];
	[channels release];
	[data release];
	[super dealloc];
}

-(NSString *)name
{
	return name;
}

-(NSString *)channels
{
	return channels;
}

-(void)setName:(NSString *)newName
{
	[newName retain];
	[name release];
	name = newName;
}

-(void)setChannels:(NSString *)newChannels
{
	[newChannels retain];
	[channels release];
	channels = newChannels;
}

-(void)setData:(NSArray *)newData
{
	[newData retain];
	[data release];
	data = newData;
}

-(NSArray *)channelsAsArray
{
	NSArray *temp = [channels componentsSeparatedByString:@" "];
	return temp;
}



@end
