// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: module.h    │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

#ifndef MODULE_H
#define MODULE_H

#include <saturn/kernel/utils/int.h>
#include <saturn/kernel/utils/slice.h>
#include <saturn/kernel/utils/tag_union.h>

#ifndef NULL
#define NULL (void*)0
#endif

#define GPL2_ONLY 0
#define GPL2_OR_LATER 1
#define GPL3_ONLY 2
#define GPL3_OR_LATER 3
#define BSD_2_CLAUSE 4
#define BSD_3_CLAUSE 5
#define MIT 6
#define APACHE_2_0 7
#define PROPRIETARY 8

#define DRIVER 0
#define SYSCALL 1
#define IRQ 2
#define FILESYSTEM 3

typedef struct {
  u8 control;
  u16 internal;
}__attribute__((packed)) ModFlags;

typedef union {
  void* filesystem;
} ModPrivateUnion;

CREATE_TAG_UNION(ModPrivate, ModPrivateUnion)

typedef struct {
  Slice name;
  Slice desc;
  Slice version;
  Slice author;
  Slice deps;
  u8 license;
  u8 type;
  i8 (*init)();
  i8 (*exit)();
  ModPrivate private;
  ModFlags flags;
} Mod;

extern i8 inmod(Mod*);
extern i8 rmmod(Mod*);
extern Mod* srchmod(char*, int);

#endif // !MODULE_H
