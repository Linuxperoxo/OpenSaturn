// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: slice.h     │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

#ifndef SLICE_H
#define SLICE_H

#include <saturn/kernel/utils/int.h>

#define CREATE_SLICE(field_type, type_name) \
  typedef struct { \
    field_type ptr; \
    usize len; \
  } type_name; \

typedef struct {
  void* ptr;
  usize len;
} slice_T;

#endif // SLICE_H
