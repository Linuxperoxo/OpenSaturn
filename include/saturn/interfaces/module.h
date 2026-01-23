// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: module.h    │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

#ifndef MODULE_H
#define MODULE_H

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
  int anon: 1;

  struct {
    int init: 1;
    int after: 1;
    int exit: 1;
    int remove: 1;

    struct {
      int install: 1;
      int remove: 1;
    }__attribute__((packed)) handler;

  }__attribute__((packed)) call;

}__attribute__((packed)) ModControlFlags_T;

// EO control struct fields

// internal struct fields

typedef struct {
  int installed: 1;
  int removed: 1;

  struct {
    int name: 1;
    int pointer: 1;
  }__attribute__((packed)) collision;

  struct {
    int init: 1;
    int after: 1;
    int exit: 1;

    struct {
      int install: 1;
      int remove: 1;
    }__attribute__((packed)) handler;

  }__attribute__((packed)) call;

  struct {
    int remove: 1;

    struct {
      int init: 1;
      int after: 1;
      int exit: 1;

      struct {
        int install: 1;
        int remove: 1;
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
  int license;
  int type;
  const char** deps;
  int (*init)();
  void (*exit)();
  void* private;
  ModFlags_T flags;
} Mod_T;

extern int inmod(Mod_T*);
extern int rmmod(Mod_T*);
extern Mod_T* srchmod(char*, int);

#endif // !MODULE_H
