// ┌────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: str.zig    │
// │            Author: Linuxperoxo             │
// └────────────────────────────────────────────┘

pub fn movsb(dest: *anyerror, src: *anyerror, len: u32) void {
    asm volatile(
        \\ rep movsb
        :
        :[_] "{edi}" (dest),
         [_] "{esi}" (src),
         [_] "{ecx}" (len)
        : .{
            .memory = true,
        }
    );
}

pub fn movsw(dest: *anyerror, src: *anyerror, len: u32) void {
    asm volatile(
        \\ rep movsw
        :
        :[_] "{edi}" (dest),
         [_] "{esi}" (src),
         [_] "{ecx}" (len)
        : .{
            .memory = true,
        }
    );
}

pub fn movsl(dest: *anyerror, src: *anyerror, len: u32) void {
    asm volatile(
        \\ rep movsl
        :
        :[_] "{edi}" (dest),
         [_] "{esi}" (src),
         [_] "{ecx}" (len)
        : .{
            .memory = true,
        }
    );
}
