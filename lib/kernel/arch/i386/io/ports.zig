// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: ports.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub fn outb(port: u16, data: u8) void {
    asm volatile(
        \\ outb %[al], %[dx]

        :
        :[dx] "{dx}" (port),
         [al] "{al}" (data),
        : .{}
    );
}

pub fn outw(port: u16, data: u16) void {
    asm volatile(
        \\ outw %[ax], %[dx]
        :
        : [dx] "{dx}" (port),
          [ax] "{ax}" (data),
        : .{}
    );
}

pub fn outl(port: u16, data: u32) void {
    asm volatile(
        \\ outl %[eax], %[dx]

        :
        : [dx] "{dx}" (port),
          [eax] "{eax}" (data),
        : .{}
    );
}

pub fn inb(port: u16) u8 {
    return asm volatile(
        \\ inb %[dx], %[al] 

        :[al] "={al}" (-> u8)
        :[dx] "{dx}" (port),
        : .{}
    );
}

pub fn inw(port: u16) u16 {
    return asm volatile(
        \\ inw %[dx], %[ax]

        :[ax] "={ax}" (-> u16)
        :[dx] "{dx}" (port)
        : .{}
    );
}

pub fn inl(port: u16) u32 {
    return asm volatile(
        \\ inl %[dx], %[eax]

        :[eax] "={eax}" (-> u32)
        :[dx] "{dx}" (port)
        : .{}
    );
}
