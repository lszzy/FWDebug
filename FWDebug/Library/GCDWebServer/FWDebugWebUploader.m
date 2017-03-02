//
//  FWDebugWebUploader.h
//  FWDebug
//
//  Created by wuyong on 16/6/23.
//  Copyright © 2016年 ocphp. All rights reserved.
//

#import "FWDebugWebUploader.h"
#import "FWDebugWebBundle.h"
#import <UIKit/UIKit.h>

#import "GCDWebServerDataRequest.h"
#import "GCDWebServerMultiPartFormRequest.h"
#import "GCDWebServerURLEncodedFormRequest.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerErrorResponse.h"
#import "GCDWebServerFileResponse.h"

@interface FWDebugWebUploader ()

@property (nonatomic, assign) BOOL allowHidden;
@property(nonatomic, copy) NSArray *allowedExtensions;

@end

@implementation FWDebugWebUploader

- (instancetype)initWithUploadDirectory:(NSString*)path {
    if ((self = [super init])) {
        [[FWDebugWebBundle sharedInstance] createBundle];
        NSBundle *siteBundle = [NSBundle bundleWithPath:[FWDebugWebBundle sharedInstance].bundlePath];
        if (siteBundle == nil) {
            return nil;
        }
        
        _allowHidden = YES;
        _allowedExtensions = nil;
        _uploadDirectory = [[path stringByStandardizingPath] copy];
        FWDebugWebUploader* __unsafe_unretained server = self;
        
        [self addGETHandlerForBasePath:@"/" directoryPath:[siteBundle resourcePath] indexFilename:nil cacheAge:3600 allowRangeRequests:NO];
        
        [self addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            NSString *device = [[UIDevice currentDevice] name];
            NSString *title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
            if (title == nil) {
                title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
            }
            NSString *header = title;
            NSString *prologue = @"<p>Drag &amp; drop files on this window or use the \"Upload Files&hellip;\" button to upload new files.</p>";
            NSString *epilogue = @"";
            NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
            NSString *footer = [NSString stringWithFormat:@"%@ %@", title, version];
            
            return [GCDWebServerDataResponse responseWithHTMLTemplate:[siteBundle pathForResource:@"index" ofType:@"html"]
                                                            variables:@{
                                                                        @"device": device,
                                                                        @"title": title,
                                                                        @"header": header,
                                                                        @"prologue": prologue,
                                                                        @"epilogue": epilogue,
                                                                        @"footer": footer
                                                                        }];
            
        }];
    
        [self addHandlerForMethod:@"GET" path:@"/list" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            return [server listDirectory:request];
        }];
    
        [self addHandlerForMethod:@"GET" path:@"/download" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            return [server downloadFile:request];
        }];
    
        [self addHandlerForMethod:@"POST" path:@"/upload" requestClass:[GCDWebServerMultiPartFormRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            return [server uploadFile:(GCDWebServerMultiPartFormRequest*)request];
        }];
    
        [self addHandlerForMethod:@"POST" path:@"/move" requestClass:[GCDWebServerURLEncodedFormRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            return [server moveItem:(GCDWebServerURLEncodedFormRequest*)request];
        }];
    
        [self addHandlerForMethod:@"POST" path:@"/delete" requestClass:[GCDWebServerURLEncodedFormRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            return [server deleteItem:(GCDWebServerURLEncodedFormRequest*)request];
        }];
    
        [self addHandlerForMethod:@"POST" path:@"/create" requestClass:[GCDWebServerURLEncodedFormRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            return [server createDirectory:(GCDWebServerURLEncodedFormRequest*)request];
        }];
    }
    return self;
}

- (BOOL)startWithPort:(NSUInteger)port bonjourName:(NSString *)name
{
    [[FWDebugWebBundle sharedInstance] createBundle];
    
    return [super startWithPort:port bonjourName:name];
}

- (void)stop
{
    [super stop];
    
    [[FWDebugWebBundle sharedInstance] deleteBundle];
}

- (BOOL)checkSandboxedPath:(NSString*)path {
    return [[path stringByStandardizingPath] hasPrefix:_uploadDirectory];
}

- (BOOL)checkFileExtension:(NSString*)fileName {
    if (_allowedExtensions && ![_allowedExtensions containsObject:[[fileName pathExtension] lowercaseString]]) {
        return NO;
    }
    return YES;
}

- (NSString*)uniquePathForPath:(NSString*)path {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSString* directory = [path stringByDeletingLastPathComponent];
        NSString* file = [path lastPathComponent];
        NSString* base = [file stringByDeletingPathExtension];
        NSString* extension = [file pathExtension];
        int retries = 0;
        do {
            if (extension.length) {
                path = [directory stringByAppendingPathComponent:[[base stringByAppendingFormat:@" (%i)", ++retries] stringByAppendingPathExtension:extension]];
            } else {
                path = [directory stringByAppendingPathComponent:[base stringByAppendingFormat:@" (%i)", ++retries]];
            }
        } while ([[NSFileManager defaultManager] fileExistsAtPath:path]);
    }
    return path;
}

- (GCDWebServerResponse*)listDirectory:(GCDWebServerRequest*)request {
    NSString* relativePath = [[request query] objectForKey:@"path"];
    NSString* absolutePath = [_uploadDirectory stringByAppendingPathComponent:relativePath];
    BOOL isDirectory = NO;
    if (![self checkSandboxedPath:absolutePath] || ![[NSFileManager defaultManager] fileExistsAtPath:absolutePath isDirectory:&isDirectory]) {
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", relativePath];
    }
    if (!isDirectory) {
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_BadRequest message:@"\"%@\" is not a directory", relativePath];
    }
    
    NSString* directoryName = [absolutePath lastPathComponent];
    if (!_allowHidden && [directoryName hasPrefix:@"."]) {
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Listing directory name \"%@\" is not allowed", directoryName];
    }
    
    NSError* error = nil;
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:absolutePath error:&error];
    if (contents == nil) {
        return [GCDWebServerErrorResponse responseWithServerError:kGCDWebServerHTTPStatusCode_InternalServerError underlyingError:error message:@"Failed listing directory \"%@\"", relativePath];
    }
    
    NSMutableArray* array = [NSMutableArray array];
    for (NSString* item in [contents sortedArrayUsingSelector:@selector(localizedStandardCompare:)]) {
        if (_allowHidden || ![item hasPrefix:@"."]) {
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[absolutePath stringByAppendingPathComponent:item] error:NULL];
            NSString* type = [attributes objectForKey:NSFileType];
            if ([type isEqualToString:NSFileTypeRegular] && [self checkFileExtension:item]) {
                [array addObject:@{
                                   @"path": [relativePath stringByAppendingPathComponent:item],
                                   @"name": item,
                                   @"size": [attributes objectForKey:NSFileSize]
                                   }];
            } else if ([type isEqualToString:NSFileTypeDirectory]) {
                [array addObject:@{
                                   @"path": [[relativePath stringByAppendingPathComponent:item] stringByAppendingString:@"/"],
                                   @"name": item
                                   }];
            }
        }
    }
    return [GCDWebServerDataResponse responseWithJSONObject:array];
}

- (GCDWebServerResponse*)downloadFile:(GCDWebServerRequest*)request {
    NSString* relativePath = [[request query] objectForKey:@"path"];
    NSString* absolutePath = [_uploadDirectory stringByAppendingPathComponent:relativePath];
    BOOL isDirectory = NO;
    if (![self checkSandboxedPath:absolutePath] || ![[NSFileManager defaultManager] fileExistsAtPath:absolutePath isDirectory:&isDirectory]) {
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", relativePath];
    }
    if (isDirectory) {
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_BadRequest message:@"\"%@\" is a directory", relativePath];
    }
    
    NSString* fileName = [absolutePath lastPathComponent];
    if (([fileName hasPrefix:@"."] && !_allowHidden) || ![self checkFileExtension:fileName]) {
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Downlading file name \"%@\" is not allowed", fileName];
    }
    
    return [GCDWebServerFileResponse responseWithFile:absolutePath isAttachment:YES];
}

- (GCDWebServerResponse*)uploadFile:(GCDWebServerMultiPartFormRequest*)request {
    NSRange range = [[request.headers objectForKey:@"Accept"] rangeOfString:@"application/json" options:NSCaseInsensitiveSearch];
    NSString* contentType = (range.location != NSNotFound ? @"application/json" : @"text/plain; charset=utf-8");
    
    GCDWebServerMultiPartFile* file = [request firstFileForControlName:@"files[]"];
    if ((!_allowHidden && [file.fileName hasPrefix:@"."]) || ![self checkFileExtension:file.fileName]) {
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Uploaded file name \"%@\" is not allowed", file.fileName];
    }
    NSString* relativePath = [[request firstArgumentForControlName:@"path"] string];
    NSString* absolutePath = [self uniquePathForPath:[[_uploadDirectory stringByAppendingPathComponent:relativePath] stringByAppendingPathComponent:file.fileName]];
    if (![self checkSandboxedPath:absolutePath]) {
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", relativePath];
    }
    
    NSError* error = nil;
    if (![[NSFileManager defaultManager] moveItemAtPath:file.temporaryPath toPath:absolutePath error:&error]) {
        return [GCDWebServerErrorResponse responseWithServerError:kGCDWebServerHTTPStatusCode_InternalServerError underlyingError:error message:@"Failed moving uploaded file to \"%@\"", relativePath];
    }
    
    return [GCDWebServerDataResponse responseWithJSONObject:@{} contentType:contentType];
}

- (GCDWebServerResponse*)moveItem:(GCDWebServerURLEncodedFormRequest*)request {
    NSString* oldRelativePath = [request.arguments objectForKey:@"oldPath"];
    NSString* oldAbsolutePath = [_uploadDirectory stringByAppendingPathComponent:oldRelativePath];
    BOOL isDirectory = NO;
    if (![self checkSandboxedPath:oldAbsolutePath] || ![[NSFileManager defaultManager] fileExistsAtPath:oldAbsolutePath isDirectory:&isDirectory]) {
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", oldRelativePath];
    }
    
    NSString* newRelativePath = [request.arguments objectForKey:@"newPath"];
    NSString* newAbsolutePath = [self uniquePathForPath:[_uploadDirectory stringByAppendingPathComponent:newRelativePath]];
    if (![self checkSandboxedPath:newAbsolutePath]) {
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", newRelativePath];
    }
    
    NSString* itemName = [newAbsolutePath lastPathComponent];
    if ((!_allowHidden && [itemName hasPrefix:@"."]) || (!isDirectory && ![self checkFileExtension:itemName])) {
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Moving to item name \"%@\" is not allowed", itemName];
    }
    
    NSError* error = nil;
    if (![[NSFileManager defaultManager] moveItemAtPath:oldAbsolutePath toPath:newAbsolutePath error:&error]) {
        return [GCDWebServerErrorResponse responseWithServerError:kGCDWebServerHTTPStatusCode_InternalServerError underlyingError:error message:@"Failed moving \"%@\" to \"%@\"", oldRelativePath, newRelativePath];
    }
    
    return [GCDWebServerDataResponse responseWithJSONObject:@{}];
}

- (GCDWebServerResponse*)deleteItem:(GCDWebServerURLEncodedFormRequest*)request {
    NSString* relativePath = [request.arguments objectForKey:@"path"];
    NSString* absolutePath = [_uploadDirectory stringByAppendingPathComponent:relativePath];
    BOOL isDirectory = NO;
    if (![self checkSandboxedPath:absolutePath] || ![[NSFileManager defaultManager] fileExistsAtPath:absolutePath isDirectory:&isDirectory]) {
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", relativePath];
    }
    
    NSString* itemName = [absolutePath lastPathComponent];
    if (([itemName hasPrefix:@"."] && !_allowHidden) || (!isDirectory && ![self checkFileExtension:itemName])) {
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Deleting item name \"%@\" is not allowed", itemName];
    }
    
    NSError* error = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:absolutePath error:&error]) {
        return [GCDWebServerErrorResponse responseWithServerError:kGCDWebServerHTTPStatusCode_InternalServerError underlyingError:error message:@"Failed deleting \"%@\"", relativePath];
    }
    
    return [GCDWebServerDataResponse responseWithJSONObject:@{}];
}

- (GCDWebServerResponse*)createDirectory:(GCDWebServerURLEncodedFormRequest*)request {
    NSString* relativePath = [request.arguments objectForKey:@"path"];
    NSString* absolutePath = [self uniquePathForPath:[_uploadDirectory stringByAppendingPathComponent:relativePath]];
    if (![self checkSandboxedPath:absolutePath]) {
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", relativePath];
    }
    
    NSString* directoryName = [absolutePath lastPathComponent];
    if (!_allowHidden && [directoryName hasPrefix:@"."]) {
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Creating directory name \"%@\" is not allowed", directoryName];
    }
    
    NSError* error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:absolutePath withIntermediateDirectories:NO attributes:nil error:&error]) {
        return [GCDWebServerErrorResponse responseWithServerError:kGCDWebServerHTTPStatusCode_InternalServerError underlyingError:error message:@"Failed creating directory \"%@\"", relativePath];
    }
    
    return [GCDWebServerDataResponse responseWithJSONObject:@{}];
}

@end
