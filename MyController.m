#import "MyController.h"

@implementation MyController

-(void)awakeFromNib
{
	NSAutoreleasePool *easy = [[NSAutoreleasePool alloc] init];
	
	NSFileManager *myFM = [NSFileManager defaultManager];
	NSString *temp = [NSString stringWithString:@"~/Library/Application Support/MCAT_Channels.txt"];
	if( [myFM fileExistsAtPath:[temp stringByExpandingTildeInPath]] == NO )
	{
		NSLog(@"Creating MCAT Channels file");
		[self restoreDefaultChannels:nil];
		[self startup_save_channels];
	}
	else
	{
		NSLog(@"Loading MCAT Channels file");
		[self startup_load_channels];
	}
	
	
	//[self restoreDefaultChannels:nil];
	NSDate *today = [NSDate date];
	[progressBar setUsesThreadedAnimation:YES];
	[debugBox insertText:@"MCAT Started "];
	[debugBox insertText:[today description]];
	[myTable registerForDraggedTypes: [NSArray arrayWithObject:NSFilenamesPboardType] ];
	[easy release];
}

-(void)dealloc
{
	[myTable unregisterDraggedTypes];
	[super dealloc];
}

- (IBAction)updateSoftware:(id)sender
{
	NSURL *myPage = [NSURL URLWithString:@"http://web.mac.com/pmolfese/iWeb/Site/Programming/Programming.html"];
	NSWorkspace *mySpace = [NSWorkspace sharedWorkspace];
	[mySpace openURL:myPage];
}

- (IBAction)addFiles:(id)sender
{
	NSAutoreleasePool *adder = [[NSAutoreleasePool alloc] init];
	int i=0;
	File *myFile;
	NSOpenPanel *opener = [NSOpenPanel openPanel];
	NSArray *files;
	NSArray *types = [NSArray arrayWithObject:@"txt"];
	[opener setAllowsMultipleSelection:YES];
	[opener setCanChooseDirectories:NO];
	if([opener runModalForTypes:types] == NSOKButton)
	{
		files = [[NSArray alloc] initWithArray:[opener filenames]];
		for( i=0; i<[files count]; i++ )
		{
			//Make File object
			myFile = [[File alloc] init];
			[myFile setFilename:[[files objectAtIndex:i] lastPathComponent]];
			[myFile setPath:[files objectAtIndex:i]];
			//insert File object into NSArrayController
			[DataFiles addObject:myFile];
			//[debugBox insertText:@"\rAdded File: "];
			//[debugBox insertText:[myFile filename]];
			[myFile release];
		}//for
	}//if
	[adder release];
}

-(void)processHelper
{
	//Function looks at the array controller and sequentially tells each file
	//to process itself.  Then it writes each file's NSArray of data to disk
	//in the place where NSSavePanel is selected to put it!
	NSAutoreleasePool *myPool = [[NSAutoreleasePool alloc] init];
	NSLock *myLock = [[NSLock alloc] init];
	[myLock lock];
	int i;
	NSMutableArray *fileList = [NSArray arrayWithArray:[DataFiles arrangedObjects]];
	if( [fileList count] == 0 )
		return;
	NSString *saveFileName;
	NSMutableArray *outputPaths = [NSMutableArray arrayWithCapacity:0];
	//[debugBox insertText:@"\rBaseline: "];
	//[debugBox insertText:[baseline stringValue]];
	[progressBar setMaxValue:[fileList count]+1];
	[progressBar setMinValue:0];
	[progressBar setDoubleValue:0];
	
	
	if( [averageChannels state] == 0 )
	{
		for( i=0; i<[fileList count]; ++i )
		{
			[[fileList objectAtIndex:i] setBaseline:baseline];
			[[fileList objectAtIndex:i] processFile];
			//[debugBox insertText:@"\rRotated File: "];
			//[debugBox insertText:[[fileList objectAtIndex:i] filename]];
			saveFileName = [NSString stringWithString:[[fileList objectAtIndex:i] path]];
			saveFileName = [saveFileName stringByDeletingLastPathComponent];
			saveFileName = [saveFileName stringByAppendingString:@"/"];
			saveFileName = [saveFileName stringByAppendingString:[[fileList objectAtIndex:i] filename]];
			saveFileName = [saveFileName stringByDeletingPathExtension];
			saveFileName = [saveFileName stringByAppendingString:@"-processed.txt"];
			[outputPaths addObject:saveFileName];
			//[[fileList objectAtIndex:i] writeFile:saveFileName];
			[NSThread detachNewThreadSelector:@selector(writeFile:) toTarget:[fileList objectAtIndex:i] withObject:saveFileName];
			[progressBar incrementBy:1];
		}
	}
	else if( [averageChannels state] == 1 )
	{
		for( i=0; i<[fileList count]; ++i )
		{
			[[fileList objectAtIndex:i] setBaseline:baseline];
			[[fileList objectAtIndex:i] processAndAverageFile:[channelController arrangedObjects]];
			//[debugBox insertText:@"\rAveraged File: "];
			//[debugBox insertText:[[fileList objectAtIndex:i] filename]];
			saveFileName = [NSString stringWithString:[[fileList objectAtIndex:i] path]];
			saveFileName = [saveFileName stringByDeletingLastPathComponent];
			saveFileName = [saveFileName stringByAppendingString:@"/"];
			saveFileName = [saveFileName stringByAppendingString:[[fileList objectAtIndex:i] filename]];
			saveFileName = [saveFileName stringByDeletingPathExtension];
			saveFileName = [saveFileName stringByAppendingString:@"-averaged.txt"];
			[outputPaths addObject:saveFileName];
			//NSLog(@"File Save: %@", saveFileName);
			[[fileList objectAtIndex:i] writeAverageFile:saveFileName];
			//[NSThread detachNewThreadSelector:@selector(writeAverageFile:) toTarget:[fileList objectAtIndex:i] withObject:saveFileName];
			//at this point update the log for each file in the debugWindow
			[progressBar incrementBy:1];
		}
		//should now delete everything in list
	}
	if( [mergeFile state] == 1 )
	{
		//[debugBox insertText:@"\rCreating Merged File"];
		//saveFileName = [saveFileName stringByDeletingLastPathComponent];
		//saveFileName = [saveFileName stringByAppendingString:@"/"];
		//saveFileName = [saveFileName stringByAppendingString:@"merged.txt"];
		
		NSSavePanel *mySavePanel = [NSSavePanel savePanel];
		if( [mySavePanel runModal] == NSOKButton )
		{
			saveFileName = [mySavePanel filename];
			//saveFileName = [saveFileName stringByAppendingString:@".txt"];
		}
		else
		{
			saveFileName = [saveFileName stringByDeletingLastPathComponent];
			saveFileName = [saveFileName stringByAppendingString:@"/"];
			saveFileName = [saveFileName stringByAppendingString:@"merged.txt"];
		}
		
		NSMutableString *merger = [NSMutableString stringWithString:@""];
		NSString *temp;
		for( i=0; i<[outputPaths count]; ++i )
		{
			temp = [NSString stringWithContentsOfFile:[outputPaths objectAtIndex:i]];
			[merger appendString:temp];
			if( [tempCheck state] == 0 )
			{
				[[NSFileManager defaultManager] removeFileAtPath:[outputPaths objectAtIndex:i] handler:nil];
				NSLog(@"Order of Files: \r%@", [outputPaths objectAtIndex:i]);
			}
			
		}
		//write final file
		[merger writeToFile:saveFileName atomically:YES];
		[progressBar incrementBy:1];
	}
	else if( [mergeFile state] == 0 )
	{
		[progressBar incrementBy:1];
	}
	
	//empty file list
	
	NSArray *dataFilesArray = [DataFiles arrangedObjects];
	[DataFiles removeObjects:dataFilesArray];
	[progressBar stopAnimation:self];
	//[debugBox insertText:@"\rFreeing Memory"];
	[processButton setEnabled:YES];
	[myLock unlock];
	[myPool release];
}

- (IBAction)processFiles:(id)sender
{
	if( [[DataFiles arrangedObjects] count] == 0 )
		return;
	[processButton setEnabled:NO];
	[progressBar startAnimation:self];
	[NSThread detachNewThreadSelector:@selector(processHelper) toTarget:self withObject:nil];
}

- (IBAction)removeFiles:(id)sender
{
	//don't need to implement, carried out by Cocoa Bindings
}

- (IBAction)restoreDefaultChannels:(id)sender
{
	//clear current channels if any
	while( [[channelController arrangedObjects] count] )
	{
		[channelController removeObjectAtArrangedObjectIndex:0];
	}
	
	//create static strings
	NSString *FL = @"18 19 20 22 23 24 25 26 27 28 33 34 39 128";
	NSString *FR = @"1 2 3 4 8 9 10 14 15 121 122 123 124 125";
	NSString *CL = @"7 12 13 21 29 30 31 32 35 36 37 38 41 42 43 46 47 48 51";
	NSString *CR = @"5 81 88 94 98 99 103 104 105 106 107 109 110 111 112 113 117 118 119";
	NSString *PL = @"54 61 67 53 60 52 59 58 64 63";
	NSString *PR = @"78 79 80 87 86 93 92 97 96 100";
	NSString *OL = @"65 66 69 70 71 72 74 75";
	NSString *OR = @"77 83 84 85 89 90 91 95";
	NSString *TL = @"40 44 45 49 50 56 57";
	NSString *TR = @"101 102 108 114 115 116 120";
	
	//put those into Channel objects
	Channel *one = [[Channel alloc] initWithName:@"FL" andChannels:FL];
	Channel *two = [[Channel alloc] initWithName:@"FR" andChannels:FR];
	Channel *three = [[Channel alloc] initWithName:@"CL" andChannels:CL];
	Channel *four = [[Channel alloc] initWithName:@"CR" andChannels:CR];
	Channel *five = [[Channel alloc] initWithName:@"PL" andChannels:PL];
	Channel *six = [[Channel alloc] initWithName:@"PR" andChannels:PR];
	Channel *seven = [[Channel alloc] initWithName:@"OL" andChannels:OL];
	Channel *eight = [[Channel alloc] initWithName:@"OR" andChannels:OR];
	Channel *nine = [[Channel alloc] initWithName:@"TL" andChannels:TL];
	Channel *ten = [[Channel alloc] initWithName:@"TR" andChannels:TR];
	
	//add objects UI controller
	[channelController addObject: one];
	[channelController addObject: two];
	[channelController addObject: three];
	[channelController addObject: four];
	[channelController addObject: five];
	[channelController addObject: six];
	[channelController addObject: seven];
	[channelController addObject: eight];
	[channelController addObject: nine];
	[channelController addObject: ten];
	
	//free memory from Channels now in array
	[one release];
	[two release];
	[three release];
	[four release];
	[five release];
	[six release];
	[seven release];
	[eight release];
	[nine release];
	[ten release];
}

- (IBAction)saveChannels:(id)sender
{
	NSAutoreleasePool *saveChPool = [[NSAutoreleasePool alloc] init];
	//saves channel listing to file
	[debugBox insertText:@"\rChannels Saved..."];
	NSString *channelWrite = [NSString stringWithString:@""]; //give me an empty string
	NSArray *channelArray = [NSArray arrayWithArray:[channelController arrangedObjects]];
	NSString *fileToSave;
	int i;
	NSSavePanel *mySavePanel = [NSSavePanel savePanel];
	if( [mySavePanel runModal] == NSOKButton )
	{
		//they've selected where to save the file, now get the values
		//from channelController and put them into the file using NSString
		for( i = 0; i< [channelArray count]; i++ )
		{
			channelWrite = [channelWrite stringByAppendingString:[[channelArray objectAtIndex:i] name]];
			channelWrite = [channelWrite stringByAppendingString:@" "];
			channelWrite = [channelWrite stringByAppendingString:[[channelArray objectAtIndex:i] channels]];
			channelWrite = [channelWrite stringByAppendingString:@"\r"];
			//NSLog(@"STRING_TO_FILE: %@", channelWrite);
		}
		fileToSave = [NSString stringWithString:[mySavePanel filename]];
		fileToSave = [fileToSave stringByAppendingString:@".txt"];
		[channelWrite writeToFile:fileToSave atomically:YES];
	}
	[saveChPool release];
}

- (IBAction)loadChannels:(id)sender
{
	NSAutoreleasePool *loadChPool = [[NSAutoreleasePool alloc] init];
	int i, j;
	NSArray *types = [NSArray arrayWithObject:@"txt"];
	[debugBox insertText:@"\rChannels Loaded..."];
	NSOpenPanel *opener = [NSOpenPanel openPanel];
	[opener setAllowsMultipleSelection:NO];
	[opener setCanChooseDirectories:NO];
	if([opener runModalForTypes:types] == NSOKButton)
	{
		NSString *myFile = [NSString stringWithContentsOfFile:[[opener filenames] objectAtIndex:0]];
		NSArray *myArr = [NSArray arrayWithArray:[myFile componentsSeparatedByString:@"\r"]];
		if( [myArr count] == 1 )
		{
			//[myArr release];
			myArr = [NSArray arrayWithArray:[myFile componentsSeparatedByString:@"\n"]];
		}
		if( [myArr count] == 1 )
		{
			myArr = [NSArray arrayWithArray:[myFile componentsSeparatedByString:@"\r"]];
		}
		NSLog(@"WHICH_FILE: %@", [[opener filenames] objectAtIndex:0]);
		//NSLog(@"LOAD_ARRAY_SIZE: %i", [myArr count]);
		for( i=0; i<[myArr count]-1; i++ )
		{
			NSArray *row = [NSArray arrayWithArray:[[myArr objectAtIndex:i] componentsSeparatedByString:@" "]];
			NSMutableString *chList = [NSMutableString stringWithString:@""];
			Channel *myChannel = [[Channel alloc] init];
			//[myChannel release];
			[myChannel autorelease];
			for( j=1; j<[row count]; j++ )
			{
				//chList = [chList stringByAppendingString:[row objectAtIndex:j]];
				[chList appendString:[row objectAtIndex:j]];
				//chList = [chList stringByAppendingString:@" "];
				[chList appendString:@" "];
			}
			//delete extra space at end
			NSRange lenVar; 
			lenVar.length = 1;
			lenVar.location = [chList length]-1;
			[chList deleteCharactersInRange:lenVar];
			[myChannel setName: [row objectAtIndex:0]];
			[myChannel setChannels:chList];
			[channelController addObject: myChannel];
		}
	}
	[loadChPool release];
}

-(void)setDefault:(id)sender
{
	NSAutoreleasePool *saveChPool = [[NSAutoreleasePool alloc] init];
	//saves channel listing to file
	[debugBox insertText:@"\rChannels Saved..."];
	NSString *channelWrite = [NSString stringWithString:@""]; //give me an empty string
	NSArray *channelArray = [NSArray arrayWithArray:[channelController arrangedObjects]];
	NSString *fileToSave = @"~/Library/Application Support/MCAT_Channels.txt";
	int i;
	for( i = 0; i< [channelArray count]; i++ )
	{
		channelWrite = [channelWrite stringByAppendingString:[[channelArray objectAtIndex:i] name]];
		channelWrite = [channelWrite stringByAppendingString:@" "];
		channelWrite = [channelWrite stringByAppendingString:[[channelArray objectAtIndex:i] channels]];
		channelWrite = [channelWrite stringByAppendingString:@"\r"];
		//NSLog(@"STRING_TO_FILE: %@", channelWrite);
	}
	[channelWrite writeToFile:[fileToSave stringByExpandingTildeInPath] atomically:YES];
	[saveChPool release];
}

-(void)startup_load_channels
{
	NSString *temp = @"~/Library/Application Support/MCAT_Channels.txt";
	NSString *myFile = [NSString stringWithContentsOfFile:[temp stringByExpandingTildeInPath]];
	NSArray *myArr = [NSArray arrayWithArray:[myFile componentsSeparatedByString:@"\r"]];
	//NSLog(@"LOAD_ARRAY_SIZE: %i", [myArr count]);
	int i, j;
	for( i=0; i<[myArr count]-1; i++ )
		{
			NSArray *row = [NSArray arrayWithArray:[[myArr objectAtIndex:i] componentsSeparatedByString:@" "]];
			NSMutableString *chList = [NSMutableString stringWithString:@""];
			Channel *myChannel = [[Channel alloc] init];
			[myChannel autorelease];
			for( j=1; j<[row count]; j++ )
			{
				[chList appendString:[row objectAtIndex:j]];
				[chList appendString:@" "];
			}
			//delete extra space at end
			NSRange lenVar; 
			lenVar.length = 1;
			lenVar.location = [chList length]-1;
			[chList deleteCharactersInRange:lenVar];
			[myChannel setName: [row objectAtIndex:0]];
			[myChannel setChannels:chList];
			[channelController addObject: myChannel];
		}
}

-(void)startup_save_channels
{
	//they've selected where to save the file, now get the values
	//from channelController and put them into the file using NSString
	int i;
	NSString *channelWrite = [NSString stringWithString:@""];
	NSArray *channelArray = [NSArray arrayWithArray:[channelController arrangedObjects]];
	for( i = 0; i< [channelArray count]; i++ )
	{
		channelWrite = [channelWrite stringByAppendingString:[[channelArray objectAtIndex:i] name]];
		channelWrite = [channelWrite stringByAppendingString:@" "];
		channelWrite = [channelWrite stringByAppendingString:[[channelArray objectAtIndex:i] channels]];
		channelWrite = [channelWrite stringByAppendingString:@"\r"];
	}
	//NSLog(@"STRING_TO_FILE: %@", channelWrite);
	//have to create file to write to first
	NSString *fileToSave = [NSString stringWithString:@"~/Library/Application Support/MCAT_Channels.txt"];
	//NSString won't write if there's a ~ in it, so expand that
	[channelWrite writeToFile:[fileToSave stringByExpandingTildeInPath] atomically:NO];
	
}

- (IBAction)saveLog:(id)sender
{
	//not sure how to do this yet...  see NSTextView class
}

- (IBAction)openCloseLog:(id)sender
{
	[debugWindow orderFront:(id)sender];
	[debugWindow makeKeyWindow];
}

- (IBAction)changeChannels:(id)sender
{
	//opens channel changing window or sheet
	//[channelWindow orderFront:(id)sender];
	//[channelWindow makeKeyWindow];
	[NSApp beginSheet:channelWindow modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(dismissChannels:) contextInfo:nil];
}

- (IBAction)dismissChannels:(id)sender
{
	[NSApp endSheet:channelWindow];
	[channelWindow orderOut:self];
}

- (IBAction)moveUp:(id)sender
{
	NSAutoreleasePool *myPool = [[NSAutoreleasePool alloc] init];
	int i = [DataFiles selectionIndex];
	NSArray *myArr = [DataFiles arrangedObjects];
	if( i > 0 )
	{
		NSLog(@"Selection index: %d", i);
		NSLog(@"Array total: %d", [myArr count]);
		//ERPFile *myFile = [[ERPFile alloc] initWithERPFile:[myArr objectAtIndex:i]];
		File *myFile = [[File alloc] initWithFilename:[[myArr objectAtIndex:i] filename] andPath:[[myArr objectAtIndex:i] path]];
		[DataFiles removeObjectAtArrangedObjectIndex:i];
		//insertObject:atArrangedObjectIndex:
		[DataFiles insertObject:myFile atArrangedObjectIndex:(i-1)];
		[myFile release];
	}
	else
		NSLog(@"Trying to move out of bounds!");
	[myPool release];
}

- (IBAction)moveDn:(id)sender
{
	NSAutoreleasePool *myPool = [[NSAutoreleasePool alloc] init];
	int i = [DataFiles selectionIndex];
	NSArray *myArr = [DataFiles arrangedObjects];
	if( i < ([myArr count] - 1) )
	{
		NSLog(@"Selection index: %d", i);
		NSLog(@"Array total: %d", [myArr count]);
		File *myFile = [[File alloc] initWithFilename:[[myArr objectAtIndex:i] filename] andPath:[[myArr objectAtIndex:i] path]];
		[DataFiles removeObjectAtArrangedObjectIndex:i];
		//insertObject:atArrangedObjectIndex:
		[DataFiles insertObject:myFile atArrangedObjectIndex:(i+1)];
		[myFile release];
	}
	else
		NSLog(@"Trying to move out of bounds!");
	[myPool release];
}

//drag and drop stuff

-(NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op 
{
    // Add code here to validate the drop
    NSLog(@"validate Drop");
	[tv setDropRow: -1 dropOperation: NSTableViewDropOn];
    return NSDragOperationCopy;    
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info 
			  row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	int i;
	int compareStr;

	
    NSPasteboard* pboard = [info draggingPasteboard];
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) 
	{
        NSArray *theFiles = [[pboard propertyListForType:NSFilenamesPboardType] retain];
        // Perform operation using the list of files
		NSArray *sortedFiles = [NSArray arrayWithArray:[theFiles sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
		
		
		for( i=0; i<[theFiles count]; ++i )
		{
			NSString *myStr = [NSString stringWithString: [sortedFiles objectAtIndex:i]];
			compareStr = [[myStr pathExtension] caseInsensitiveCompare:@"TXT"];
			if( compareStr == 0 )
			{
				NSLog(@"Adding to table");
				File *newFile = [[File alloc] init];
				[newFile setFilename:[myStr lastPathComponent]];
				[newFile setPath:myStr];
				[DataFiles addObject:newFile];
				[newFile release];
			}
			else
			{
				NSLog(@"Wrong File Type");
			}
		}
    }
	
	return YES;
}



@end
