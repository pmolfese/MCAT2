//
//  File.h
//  MCAT
//
//  Created by DNP on 9/13/05.
//  Copyright 2005 Peter J. Molfese. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Channel.h"


@interface File : NSObject 
{
	NSString *filename;
	NSString *path;
	NSArray *data;
	int baseline;
	
	int total_electrodes;
	int total_samples;
}
-init;
-initWithFilename:(NSString *)filename andPath:(NSString *)path;
-(NSString *)filename;
-(void)setFilename:(NSString *)newName;
-(NSString *)path;
-(void)setPath:(NSString *)newPath;
-(NSArray *)data;
-(void)setBaseline:(NSString *)base;
-(void)setData:(NSArray *)newData;
-(void)processFile;
-(void)processAndAverageFile:(NSArray *)channels;
-(void)writeFile:(NSString *)pathToSave;
-(void)writeAverageFile:(NSString *)pathToSave;
-(NSArray *)averageArrays:(NSArray *)arrayOfArrays;


@end
