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

    [self run];
    
    // Do any additional setup after loading the view.
}

- (void)run {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
            ^{
                  while (true) {
                        [NSThread sleepForTimeInterval:15.0];
                        [self checkIsUpdateAvailable];
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
                                   tell application \"System Events\" to keystroke \"c\" using control down \n \
                                   delay 1 \n \
                                   tell application \"System Events\" \n \
                                   keystroke \"git fetch --all\" \n \
                                   keystroke return \n \
                                   delay 5 \n \
                                   keystroke \"git reset --hard origin/master\" \n \
                                   keystroke return \n \
                                   delay 1 \n \
                                   keystroke \"python Main.py\" \n \
                                   keystroke return \n \
                                   end tell \n \
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
    NSURL *url = [NSURL URLWithString:@"https://github-automation.firebaseio.com/isUpdated.json"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *e = nil;
    NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:jsonData options: NSJSONReadingMutableContainers error: &e];
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSInteger numberOfUpdate = [self loadUserDefault];
        if (numberOfUpdate != JSON.count) {
            [self writeOutput:@"Update available. Update then restart server..."];
            [self updateThenRestartServer];
            [self saveUserDefault:JSON.count];
        }
    });
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
@end
