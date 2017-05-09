//
//  FWDebugJSPatch.m
//  FWDebug
//
//  Created by wuyong on 17/3/9.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWDebugJSPatch.h"
#import "JPEngine+FWDebug.h"

@interface FWDebugJSPatch ()

@property (nonatomic, strong) UITextView *textView;

@end

@implementation FWDebugJSPatch

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"JSPatch Editor";
    
    UIBarButtonItem *runItem = [[UIBarButtonItem alloc] initWithTitle:@"Run" style:UIBarButtonItemStylePlain target:self action:@selector(onRun)];
    UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(onSave)];
    self.navigationItem.rightBarButtonItems = @[runItem, saveItem];
    
    [self initView];
    
    [self onTest];
}

- (void)initView
{
    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.textView];
    
    NSString *scriptPath = [JPEngine fwDebugScriptPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {
        NSString *script = [[NSString alloc] initWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:NULL];
        self.textView.text = script;
    }

    if (self.textView.text.length < 1) {
        self.textView.text = @"\
require('UIAlertView');\n\
defineClass('FWDebugJSPatch', {\n\
    onTest: function() {\n\
        var alertView = UIAlertView.alloc().initWithTitle_message_delegate_cancelButtonTitle_otherButtonTitles(\"JSPatch\", \"onTest\", null, \"OK\", null);\n\
        alertView.show();\n\
    },\n\
});";
    }
}

- (void)onTest
{
    
}

#pragma mark - Action

- (void)onRun
{
    NSString *code = self.textView.text;
    if (code.length < 1) return;
    
    [JPEngine evaluateScript:code];
}

- (void)onSave
{
    NSString *code = self.textView.text;
    if (code.length < 1) return;
    
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:@"Input filename:"
                           message:nil
                           delegate:self
                           cancelButtonTitle:@"Cancel"
                           otherButtonTitles:@"Save", nil];
    dialog.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [dialog textFieldAtIndex:0];
    textField.text = @"main.js";
    [dialog show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        NSString *fileName = [alertView textFieldAtIndex:0].text;
        if (fileName.length < 1) return;
        
        // 创建脚本目录
        NSString *scriptFile = [[[JPEngine fwDebugScriptPath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
        NSString *scriptDir = [scriptFile stringByDeletingLastPathComponent];
        if (![[NSFileManager defaultManager] fileExistsAtPath:scriptDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:scriptDir withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        // 保存脚本文件
        [self.textView.text writeToFile:scriptFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
}

@end
