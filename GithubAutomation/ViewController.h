//
//  ViewController.h
//  GithubAutomation
//
//  Created by hoang pham on 4/12/16.
//  Copyright © 2016 Jeppesen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController
@property BOOL isRun;
@property (strong) IBOutlet NSTextView *txtVOutput;
@property (strong) IBOutlet NSTextField *tfImagePath;
@property (strong) IBOutlet NSButton *btnStart;

- (IBAction)startBtnPressed:(id)sender;

@end

