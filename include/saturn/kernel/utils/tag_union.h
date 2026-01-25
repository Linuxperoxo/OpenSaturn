// ┌────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: tag_union.h    │
// │            Author: Linuxperoxo                 │
// └────────────────────────────────────────────────┘

#ifndef TAG_UNION_H
#define TAG_UNION_H

#include <saturn/kernel/utils/int.h>

#define CREATE_TAG_UNION(type_name, union_type) \
  typedef union { \
    usize tag; \
    union_type data; \
  } type_name; \

#endif // !TAG_UNION_H
