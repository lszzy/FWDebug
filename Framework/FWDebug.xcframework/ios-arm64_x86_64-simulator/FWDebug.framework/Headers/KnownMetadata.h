//
//  KnownMetadata.h
//  Echo
//
//  Created by Alejandro Alonso
//  Copyright © 2019 - 2020 Alejandro Alonso. All rights reserved.
//

#ifndef KNOWN_METADATA_H
#define KNOWN_METADATA_H

// The mangling scheme for builtin metadata is:
// $s SYMBOL N
// $s = Swift mangling prefix
// SYMBOL = The builtin type mangling
// N = Metadata
// Example: Builtin.NativeObject Metadata is $sBoN
//
// Reference the runtime defined metadata variable for builtin types.
extern void $sBi1_N;
extern void $sBi7_N;
extern void $sBi8_N;
extern void $sBi16_N;
extern void $sBi32_N;
extern void $sBi64_N;
extern void $sBi128_N;
extern void $sBi256_N;
extern void $sBi512_N;
extern void $sBwN;
extern void $sBf16_N;
extern void $sBf32_N;
extern void $sBf64_N;
extern void $sBf80_N;
extern void $sBf128_N;
extern void $sBoN;
extern void $sBbN;
extern void $sBpN;
extern void $sBBN;
extern void $sBON;

// Define this utility function because you can't see variables that start with
// $ in Swift.
void *getBuiltinInt1Metadata(void);
void *getBuiltinInt7Metadata(void);
void *getBuiltinInt8Metadata(void);
void *getBuiltinInt16Metadata(void);
void *getBuiltinInt32Metadata(void);
void *getBuiltinInt64Metadata(void);
void *getBuiltinInt128Metadata(void);
void *getBuiltinInt256Metadata(void);
void *getBuiltinInt512Metadata(void);
void *getBuiltinWordMetadata(void);
void *getBuiltinFPIEE16Metadata(void);
void *getBuiltinFPIEE32Metadata(void);
void *getBuiltinFPIEE64Metadata(void);
void *getBuiltinFPIEE80Metadata(void);
void *getBuiltinFPIEE128Metadata(void);
void *getBuiltinNativeObjectMetadata(void);
void *getBuiltinBridgeObjectMetadata(void);
void *getBuiltinRawPointerMetadata(void);
void *getBuiltinUnsafeValueBufferMetadata(void);
void *getBuiltinUnknownObjectMetadata(void);

#endif /* KNOWN_METADATA_H */
