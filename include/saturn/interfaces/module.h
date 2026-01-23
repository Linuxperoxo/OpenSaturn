// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: module.h    │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

#ifndef MODULE_H
#define MODULE_H

#include <saturn/kernel/utils/int.h>

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

// control struct fields

typedef struct {
  u8 anon: 1;

  struct {
    u8 init: 1;
    u8 after: 1;
    u8 exit: 1;
    u8 remove: 1;

    struct {
      u8 install: 1;
      u8 remove: 1;
    }__attribute__((packed)) handler;

  }__attribute__((packed)) call;

}__attribute__((packed)) ModControlFlags_T;

// EO control struct fields

// internal struct fields

typedef struct {
  u8 installed: 1;
  u8 removed: 1;

  struct {
    u8 name: 1;
    u8 pointer: 1;
  }__attribute__((packed)) collision;

  struct {
    u8 init: 1;
    u8 after: 1;
    u8 exit: 1;

    struct {
      u8 install: 1;
      u8 remove: 1;
    }__attribute__((packed)) handler;

  }__attribute__((packed)) call;

  struct {
    u8 remove: 1;

    struct {
      u8 init: 1;
      u8 after: 1;
      u8 exit: 1;

      struct {
        u8 install: 1;
        u8 remove: 1;
      }__attribute__((packed)) handler;

    }__attribute__((packed)) call;

  }__attribute__((packed)) fault;

}__attribute__((packed)) ModInternalFlags_T;

// EO internal struct fields

typedef struct {
  ModControlFlags_T control;
  ModInternalFlags_T internal;
}__attribute__((packed)) ModFlags_T;

typedef struct {
  const char* name;
  const char* desc;
  const char* version;
  const char* author;
  u16 license;
  u8 type;
  const char** deps;
  usize (*init)();
  void (*exit)();
  void* private;
  ModFlags_T flags;
} Mod_T;

extern i8 inmod(Mod_T*);
extern i8 rmmod(Mod_T*);
extern Mod_T* srchmod(char*, int);

#endif // !MODULE_H
