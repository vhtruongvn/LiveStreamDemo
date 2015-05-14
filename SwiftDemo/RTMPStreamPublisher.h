//
//  RTMPStreamPublisher.h
//  SwiftDemo
//
//  Created by Truong Vo on 14/5/15.
//  Copyright (c) 2015 Truong Vo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RTMPStreamPublisher : UIViewController {
    IBOutlet UIView *previewView;
    IBOutlet UIBarButtonItem *btnConnect;
    IBOutlet UIBarButtonItem *btnToggle;
    IBOutlet UIBarButtonItem *btnPublish;
    IBOutlet UILabel *memoryLabel;
}

- (IBAction)connectControl:(id)sender;
- (IBAction)publishControl:(id)sender;
- (IBAction)camerasToggle:(id)sender;

@end
