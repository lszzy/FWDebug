//
//  FWDebugRuntimeBrowser.m
//  FWDebug
//
//  Created by wuyong on 17/2/22.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWDebugRuntimeBrowser.h"
#import "RTBRuntimeHeader.h"
#import "RTBProtocol.h"

@interface FWDebugRuntimeBrowser ()

@property (nonatomic, strong) NSString *className;

@property (nonatomic, strong) NSString *protocolName;

@property (nonatomic, strong) UITextView *textView;

@end

@implementation FWDebugRuntimeBrowser

#pragma mark - Lifecycle

- (instancetype)initWithClassName:(NSString *)className
{
    self = [super init];
    if (self) {
        _className = className;
    }
    return self;
}

- (instancetype)initWithProtocolName:(NSString *)protocolName
{
    self = [super init];
    if (self) {
        _protocolName = protocolName;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.className ? self.className : self.protocolName;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Copy" style:UIBarButtonItemStylePlain target:self action:@selector(copyButtonPressed:)];
    
    [self initView];
}

- (void)initView
{
    _textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    _textView.editable = NO;
    [self.view addSubview:_textView];
    
    NSString *headerText = [self headerString];
    if (headerText.length < 1) {
        _textView.text = @"";
        return;
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 4;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    NSDictionary *attributes = @{
                                 NSFontAttributeName: [UIFont systemFontOfSize:14],
                                 NSForegroundColorAttributeName: [UIColor blackColor],
                                 NSParagraphStyleAttributeName: paragraphStyle
                                 };
    _textView.attributedText = [[NSAttributedString alloc] initWithString:headerText attributes:attributes];
}

#pragma mark - Private

- (NSString *)headerString
{
    if (self.className) {
        Class targetClass = NSClassFromString(self.className);
        NSString *header = [RTBRuntimeHeader headerForClass:targetClass displayPropertiesDefaultValues:NO];
        return header;
    } else {
        RTBProtocol *p = [RTBProtocol protocolStubWithProtocolName:self.protocolName];
        NSString *header = [RTBRuntimeHeader headerForProtocol:p];
        return header;
    }
}

- (void)copyButtonPressed:(id)sender
{
    [[UIPasteboard generalPasteboard] setString:self.textView.text ? self.textView.text : @""];
}

@end
