//
//  ViewController.m
//  GithubAutomation
//
//  Created by hoang pham on 4/12/16.
//  Copyright © 2016 Jeppesen. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
}

- (void)run {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
            ^{
                  while (self.isRun) {
                        [NSThread sleepForTimeInterval:5.0];
                        [self checkIsUpdateAvailable];
                        [NSThread sleepForTimeInterval:5.0];
                  }
            });
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)writeOutput:(NSString *)input {
    NSDate *date  = [NSDate new];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *newDate = [dateFormatter stringFromDate:date];
    
    NSString *preOuput = self.txtVOutput.string;
    NSString *outPut = [preOuput stringByAppendingString:[NSString stringWithFormat:@"\n%@: %@", newDate, input]];
    self.txtVOutput.string = outPut;
}

- (NSString *)runCommand:(NSString *)commandToRun
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    
    NSArray *arguments = [NSArray arrayWithObjects:
                          @"-c" ,
                          [NSString stringWithFormat:@"%@", commandToRun],
                          nil];
    NSLog(@"run command:%@", commandToRun);
    [task setArguments:arguments];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
    
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return output;
}

- (BOOL)updateImages {
    NSString *output =  [self runCommand:[NSString stringWithFormat:@"cd %@ && git fetch --all && git reset --hard origin/master", self.tfImagePath.stringValue]];
    if ([output containsString:@"HEAD is now at"]) {
        [self writeOutput:output];
        return YES;
    } else {
        return NO;
    }
}

- (void)updateThenRestartServer {
    NSDictionary* errorDict;
    NSAppleEventDescriptor* returnDescriptor = NULL;
    //git fetch --all
    //git reset --hard origin/master
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
                                   @"\
                                   tell application \"Terminal\" \n \
                                   activate \n \
                                   delay 1 \n \
                                   tell application \"System Events\" \n \
                                   keystroke \"git fetch --all\" \n \
                                   keystroke return \n \
                                   delay 5 \n \
                                   keystroke \"git reset --hard origin/master\" \n \
                                   keystroke return \n \
                                   end tell"];
    
    returnDescriptor = [scriptObject executeAndReturnError: &errorDict];

    if (returnDescriptor != NULL)
    {
        // successful execution
        if (kAENullEvent != [returnDescriptor descriptorType])
        {
            // script returned an AppleScript result
            if (cAEList == [returnDescriptor descriptorType])
            {
                // result is a list of other descriptors
            }
            else
            {
                // coerce the result to the appropriate ObjC type
            }
        } 
    }
    else
    {
        // no script result, handle error here
    }
}

- (void)checkIsUpdateAvailable {
    @autoreleasepool {
        NSURL *url = [NSURL URLWithString:@"https://github-automation.firebaseio.com/isUpdated.json"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSError *e = nil;
        NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:jsonData options: NSJSONReadingMutableContainers error: &e];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger numberOfUpdate = [self loadUserDefault];
            if (numberOfUpdate != JSON.count) {
                if(self.tfImagePath.stringValue.length > 3) {
                    [self writeOutput:@"Update available. Update images..."];
                     BOOL isValid = [self updateImages];
                    if (isValid) {
                        [self saveUserDefault:JSON.count];
                    } else {
                        self.isRun = NO;
                        self.btnStart.title = @"Start";
                        NSAlert *alert = [[NSAlert alloc] init];
                        [alert setAlertStyle:NSInformationalAlertStyle];
                        [alert setMessageText:@"Invalid Path"];
                        [alert setInformativeText:@"Input path to folder contains ios and windows folder"];
                        [alert runModal];
                        [self.tfImagePath selectText:self];
                        [[self.tfImagePath currentEditor] setSelectedRange:NSMakeRange(0, [[self.tfImagePath stringValue] length])];
                        return;
                    }
                    
                }
            }
        });
    }
}

- (void)saveUserDefault:(NSInteger) numberOfUpdate {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:numberOfUpdate forKey:@"numberOfUpdate"];
    [defaults synchronize];
}

- (NSInteger)loadUserDefault {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger r = [defaults integerForKey:@"numberOfUpdate"];
    NSLog(@"r %ld", r);
    return r;
}
- (IBAction)startBtnPressed:(id)sender {
    if ([self.btnStart.title isEqualToString:@"Start"]) {
        if(self.tfImagePath.stringValue.length < 3) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setAlertStyle:NSInformationalAlertStyle];
            [alert setMessageText:@"Invalid Path"];
            [alert setInformativeText:@"Input path to folder contains ios and windows folder"];
            [alert runModal];
            return;
        }
        [self.tfImagePath.window makeFirstResponder:nil];
        self.isRun = YES;
        [self run];
        self.btnStart.title = @"Stop";
        
    } else {
        self.isRun = NO;
        self.btnStart.title = @"Start";
    }
    
}
@end
