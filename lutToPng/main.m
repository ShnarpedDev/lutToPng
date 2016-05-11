//
//  main.m
//  lutToPng
//
//  Created by Morgan Jenkins on 2016-05-09.
//  Copyright © 2016 Morgan Jenkins. All rights reserved.
//

#import <Foundation/Foundation.h>

BOOL CGImageWriteToFile(CGImageRef image, NSString *path) {
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    if (!destination) {
        NSLog(@"Failed to create CGImageDestination for %@", path);
        return NO;
    }
    
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
        CFRelease(destination);
        return NO;
    }
    
    CFRelease(destination);
    return YES;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Check if there is a cached 'image' for this cube file already.
    
        char input[100];
        printf("Enter path to folder holding .cube, .Cube, or .CUBE files: ");
        scanf("%s", input);
        
        while (strcmp("q", input) != 0){
            NSString *inputFolder = [NSString stringWithCString:input encoding:NSUTF8StringEncoding];
            
            NSFileManager *fileManager=[[NSFileManager alloc] init];
            NSDirectoryEnumerator *dirEnum =
            [fileManager enumeratorAtPath:inputFolder];
            
            NSString *inputFile;
            while ((inputFile = [dirEnum nextObject])) {
                NSString *pathExtension = [inputFile pathExtension];
                if ([pathExtension isEqualToString: @"cube"] || [pathExtension isEqualToString: @"Cube"] || [pathExtension isEqualToString: @"CUBE"]) {
                    
                    NSString *inputFilePath = [inputFolder stringByAppendingPathComponent:inputFile];
                    
                    NSString *lutName = [inputFilePath stringByDeletingPathExtension];
                    
                    NSError *error;
                    NSString *content = [NSString stringWithContentsOfFile:inputFilePath encoding:NSUTF8StringEncoding error:&error];
                    
                    if (error) {
                        NSLog(@"Error loading %@ LUT: %@", inputFilePath, error.localizedDescription);
                        return 1;
                    }
                    
                    NSArray *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                    int lutSize = 0;
                    int index = 0;
                    unsigned char *rawData = nil;
                    for (int i = 0; i < lines.count; i++) {
                        NSString *line = lines[i];
                        NSArray *components = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        if (components && components.count > 0) {
                            if ([((NSString *)components.firstObject) hasPrefix:@"#"]) {
                                continue;
                            }
                            
                            if ([@"LUT_3D_SIZE" isEqualToString:components.firstObject]) {
                                lutSize = ((NSString *)components.lastObject).intValue;
                                // Create our image... dimensions = (LUT size * LUT size) x LUT size
                                if (lutSize > 0) {
                                    rawData = malloc(lutSize*lutSize*lutSize*4);
                                }
                            }
                            
                            if (components.count == 3 && rawData != nil) {
                                //                int z = i / (lutSize * lutSize);
                                //                int x = z + i % lutSize;
                                //                int y = i / lutSize;
                                
                                float r = ((NSString *)components[0]).floatValue;
                                float g = ((NSString *)components[1]).floatValue;
                                float b = ((NSString *)components[2]).floatValue;
                                
                                rawData[4*index] = r * 255;
                                rawData[4*index+1] = g * 255;
                                rawData[4*index+2] = b * 255;
                                rawData[4*index+3] = 255;
                                index++;
                            }
                        }
                    }
                    
                    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL,
                                                                              rawData,
                                                                              lutSize*lutSize*lutSize*4,
                                                                              NULL);
                    
                    int bitsPerComponent = 8;
                    int bitsPerPixel = 32;
                    int bytesPerRow = 4*lutSize*lutSize;
                    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
                    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
                    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
                    CGImageRef imageRef = CGImageCreate(lutSize*lutSize,
                                                        lutSize,
                                                        bitsPerComponent,
                                                        bitsPerPixel,
                                                        bytesPerRow,colorSpaceRef,
                                                        bitmapInfo,
                                                        provider,NULL,NO,renderingIntent);
                    
                    NSString *pngFile = [NSString stringWithFormat:@"%@.png", lutName];
                    
                    NSLog(@"Saving %@ LUT to: %@", lutName, pngFile);
                    CGImageWriteToFile(imageRef, pngFile);
                }
            }

        
            printf("Enter another folder path, or \"q\" to quit: ");
            scanf("%s", input);
        }
    }
    return 0;
}
