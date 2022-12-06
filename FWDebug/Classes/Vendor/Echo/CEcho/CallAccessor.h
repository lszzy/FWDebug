//
//  CallAccessor.h
//  Echo
//
//  Created by Alejandro Alonso
//  Copyright © 2021 Alejandro Alonso. All rights reserved.
//

#ifndef CALL_ACCESSOR_H
#define CALL_ACCESSOR_H

#include <stddef.h>

typedef struct CMetadataResponse {
  const void *Metadata;
  size_t State;
} CMetadataResponse;

const CMetadataResponse echo_callAccessor0(const void *ptr, size_t request);

const CMetadataResponse echo_callAccessor1(const void *ptr, size_t request,
                                          const void *arg0);

const CMetadataResponse echo_callAccessor2(const void *ptr, size_t request,
                                          const void *arg0, const void *arg1);

const CMetadataResponse echo_callAccessor3(const void *ptr, size_t request,
                                          const void *arg0, const void *arg1,
                                          const void *arg2);

// Where args is a list of pointers.
const CMetadataResponse echo_callAccessor(const void *ptr, size_t request,
                                         const void *args);

#endif /* CALL_ACCESSOR_H */
