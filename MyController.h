/* MyController */

#import <Cocoa/Cocoa.h>
#import "Channel.h"
#import "File.h"

@interface MyController : NSObject
{
    IBOutlet id adultInfantToggle;
    IBOutlet id averageChannels;
    IBOutlet id channelController;
    IBOutlet id channelWindow;
    IBOutlet id DataFiles;
    IBOutlet id debugBox;
    IBOutlet id debugWindow;
    IBOutlet id mainWindow;
    IBOutlet id mergeFile;
    IBOutlet id numberOfChannels;
	IBOutlet id baseline;
	IBOutlet id progressBar;
	IBOutlet id processButton;
	IBOutlet id myTable;
	IBOutlet id tempCheck;
}
- (IBAction)addFiles:(id)sender;
- (IBAction)changeChannels:(id)sender;
- (IBAction)loadChannels:(id)sender;
- (IBAction)openCloseLog:(id)sender;
- (IBAction)processFiles:(id)sender;
- (IBAction)removeFiles:(id)sender;
- (IBAction)restoreDefaultChannels:(id)sender;
- (IBAction)saveChannels:(id)sender;
- (IBAction)saveLog:(id)sender;
- (IBAction)updateSoftware:(id)sender;
- (IBAction)moveUp:(id)sender;
- (IBAction)moveDn:(id)sender;
- (IBAction)dismissChannels:(id)sender;
- (void)processHelper;
-(void)startup_load_channels;
-(void)startup_save_channels;
-(void)setDefault:(id)sender;
-(NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info 
				proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op;
- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info 
			  row:(int)row dropOperation:(NSTableViewDropOperation)operation;
@end
