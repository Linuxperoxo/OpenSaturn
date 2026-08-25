// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: handler.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Funçao handler para os syscalls
pub const syscallHandler: fn(SyscallParam) u32 = @extern(fn(SyscallParam) u32, .{
    .name = "syscall_handler"
});

const SyscallParam: type = packed struct {
    @"eax": u32, // Syscall a ser executado
    // Parametros
    @"ecx": u32,
    @"edx": u32,
    @"ebx": u32,
    @"edi": u32,
    @"esi": u32,
};
