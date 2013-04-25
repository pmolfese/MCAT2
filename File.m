//
//  File.m
//  MCAT
//
//  Created by DNP on 9/13/05.
//  Copyright 2005 Peter J. Molfese. All rights reserved.
//

#import "File.h"


@implementation File

-init
{
	[super init];
	[self setFilename:@"Default Filename"];
	[self setPath:@"~/Default_Path"];
	return self;
}

-(void)dealloc
{
	[filename release];
	[path release];
	[data release];
	[super dealloc];
}

-initWithFilename:(NSString *)newFilename andPath:(NSString *)newPath
{
	[super init];
	[self setFilename:newFilename];
	[self setPath:newPath];
	return self;
}

-(NSString *)filename
{
	return filename;
}

-(void)setFilename:(NSString *)newName
{
	[newName retain];
	[filename release];
	filename = newName;
}

-(NSString *)path
{
	return path;
}

-(void)setPath:(NSString *)newPath
{
	[newPath retain];
	[path release];
	path = newPath;
}

-(NSArray *)data
{
	return data;
}

-(void)setData:(NSArray *)newData
{
	//Get NSArray of data from UI, put it into storage here
	[newData retain];
	[data release];
	data = newData;
}

-(void)setBaseline:(NSString *)base
{
	baseline = [base intValue];
}

-(void)processFile
{
	NSAutoreleasePool *filePool = [[NSAutoreleasePool alloc] init];
	int i, j;
	NSLock *processLock = [[NSLock alloc] init];
	[processLock lock];
	//eventually check type/creators to see if it's a RAW file
	//in the meantime, just assume it's a text file
	
	NSMutableArray *newData = [NSMutableArray arrayWithCapacity:(129*250)]; //initial size -- helps for RAM
	
	NSString *myFile = [NSString stringWithContentsOfFile:[self path]];	//whole file
	NSArray *mySamples = [NSArray arrayWithArray:[myFile componentsSeparatedByString:@"\r"]]; //one sample
	total_samples = [mySamples count];
	//NSArray *myChannels = [NSArray arrayWithArray:[[mySamples objectAtIndex:0] componentsSeparatedByString:@"\t"]]; //channels in that sample
	NSMutableArray *myChannels = [NSMutableArray arrayWithCapacity:2520];
	NSLog(@"Baseline: %i", baseline );
	total_electrodes = [[[mySamples objectAtIndex:0] componentsSeparatedByString:@"\t"] count];
	
	for( i=baseline; i<[mySamples count]; i++ )
	{
		[myChannels addObjectsFromArray:[[mySamples objectAtIndex:i] componentsSeparatedByString:@"\t"]];
		//myChannels = [myChannels arrayByAddingObjectsFromArray:[[mySamples objectAtIndex:i] componentsSeparatedByString:@"\t"]];
	}
	
	if( total_electrodes == 129 ) //it is a 128 file
	{
		for( i=0; i<129; i++ )
		{
			[newData addObject:@"\r"];
			for( j=0; j<([myChannels count] / 129); j++ )
			{
				[newData addObject:[NSNumber numberWithFloat:[[myChannels objectAtIndex:(i + (j*129))] floatValue]]];
			}
		}
	}
	else if( total_electrodes == 257 ) //if it's a 256 file
	{
		for( i=0; i<257; i++ )
		{
			[newData addObject:@"\r"];
			for( j=0; j<([myChannels count] / 257); j++ )
			{
				[newData addObject:[NSNumber numberWithFloat:[[myChannels objectAtIndex:(i + (j*257))] floatValue]]];
			}
		}
	}
	else
	{
		NSLog( @"total_electrodes = %d", total_electrodes );
		[[NSAlert alertWithMessageText:@"A file has the wrong number of electrodes" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"This means you should quit MCAT, examine your input files and make sure they have either 129 or 257 channels, if not export your files to text again"] runModal];
	}
	
	[self setData: newData];
	[processLock unlock];
	[filePool release];
}

-(NSArray *)averageArrays:(NSArray *)arrayOfArrays
{
	NSAutoreleasePool *extraPool = [[NSAutoreleasePool alloc] init];
	NSLock *avgArrLock = [[NSLock alloc] init];;
	[avgArrLock lock];
	NSMutableArray *aveArray = [NSMutableArray arrayWithCapacity:250];
	int i, j;
	int div = [arrayOfArrays count];
	float x=0;
	NSArray *tempArr = [arrayOfArrays objectAtIndex:0];
	int size = [tempArr count];
	for( i=0; i<size; ++i )
	{
		x = 0;
		for( j=0; j<div; ++j )
		{
			x += [[[arrayOfArrays objectAtIndex: j] objectAtIndex: i] floatValue]; //mmm, yummy nested messages
		}
		x = x/div;
		[aveArray addObject:[NSNumber numberWithFloat:x]];
	}
	[aveArray retain];
	[avgArrLock unlock];
	[extraPool release];
	return aveArray;
}

-(void)processAndAverageFile:(NSArray *)channels
{
	NSAutoreleasePool *processPool = [[NSAutoreleasePool alloc] init];
	int i, j;
	[self processFile];
	NSLock *mcatLock = [[NSLock alloc] init];
	[mcatLock lock];
	NSMutableArray *myAveragedData = [NSMutableArray arrayWithArray:[self data]];
	NSMutableArray *finalData = [NSMutableArray arrayWithCapacity:0];
	[myAveragedData removeObject:@" "];
	[myAveragedData removeObject:@"\r"];
	//NSLog(@"There are %i items in the dataset" , [myAveragedData count] );	//32,250 in a standard file
	
	for( j=0; j < [channels count] ; ++j )
	{
		Channel *myChannel = [[Channel alloc] init];
		[myChannel setName: [[channels objectAtIndex:j] name]];
		[myChannel setChannels: [[channels objectAtIndex:j] channels]];
		[finalData addObject:@"\r"];
		[finalData addObject:[myChannel name]];
		NSArray *channelSet = [NSArray arrayWithArray:[myChannel channelsAsArray]];
		[myChannel release];
		
		
		NSMutableArray *averageSet = [NSMutableArray arrayWithCapacity:[channelSet count]];
		NSRange averageSetRange;
		//NSLog(@"Channel Set Count: %d" , [channelSet count] );
		for( i=0; i<[channelSet count]; ++i )
		{
			//averageSetRange.length = 250;
			//averageSetRange.length = ([myAveragedData count]/129) ;
			averageSetRange.length = ([myAveragedData count]/total_electrodes) ;
			//averageSetRange.location = (([[channelSet objectAtIndex:i] intValue]-1) * 250);
			//averageSetRange.location = (([[channelSet objectAtIndex:i] intValue]-1) * ([myAveragedData count]/129));
			averageSetRange.location = (([[channelSet objectAtIndex:i] intValue]-1) * ([myAveragedData count]/total_electrodes));
			NSArray *tempArr = [myAveragedData subarrayWithRange:averageSetRange];
			[averageSet addObject:tempArr];
		}
		//now send averageSet to helper function
		NSLog(@"Sending %d Channels to Average Helper" , [averageSet count]);
		NSArray *getReadyArray = [self averageArrays:averageSet];
		//[finalData addObjectsFromArray: [self averageArrays: averageSet]];
		[finalData addObjectsFromArray: getReadyArray];
		[getReadyArray release];
		//[finalData addObject:@"\r"];
	}
	
	NSLog(@"Final Data Count: %d" , [finalData count] );	//remember you have /r characters and channel names!
	[self setData: finalData];								//meaning you have roughly 2520 items in an array
	[mcatLock unlock];
	[processPool release];
}

-(void)writeAverageFile:(NSString *)pathToSave
{
	NSAutoreleasePool *easy = [[NSAutoreleasePool alloc] init];
	NSString *output = [[self data] componentsJoinedByString:@" "];
	NSString *fileToSave = [NSString stringWithString:pathToSave];
	[output writeToFile:fileToSave atomically:YES];
	[easy release];
}

-(void)writeFile:(NSString *)pathToSave
{
	NSAutoreleasePool *easy = [[NSAutoreleasePool alloc] init];
	NSString *output = [[self data] componentsJoinedByString:@" "];
	NSString *fileToSave = [NSString stringWithString:pathToSave];
	[output writeToFile:fileToSave atomically:YES];
	[easy release];
}

@end
