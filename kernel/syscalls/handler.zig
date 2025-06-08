// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: handler.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Funçao handler para os syscalls
pub const syscall_handler: fn(syscallParam) u32 = @extern(fn(syscallParam) u32, .{
    .name = "syscall_handler"
});

const syscallParam: type = packed struct {
    @"eax": u32, // Syscall a ser executado
    // Parametros
    @"ecx": u32,
    @"edx": u32,
    @"ebx": u32,
    @"edi": u32,
    @"esi": u32,
};
