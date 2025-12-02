// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: handler.zig     │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const kernel: type = @import("root").kernel;

pub var csi_isr =  r: {
    var isr: [32]*const fn() callconv(.naked) void = undefined;
    for(0..isr.len) |i| {
        isr[i] = &opaque {
            comptime {
                @export(&isr_handler, .{
                    .name = ".i386.csi.isr" ++ kernel.utils.fmt.intFromArray(10 + i),
                });
            }
            pub fn isr_handler() callconv(.naked) void {
                asm volatile(
                    \\ jmp .
                    \\ cli
                    \\ pushl %[int]
                    \\ calll .i386.csi.handler
                    :
                    :[int] "i" (i)
                );
            }
        }.isr_handler;
    }
    break :r isr;
};

pub fn csi_handler() callconv(.c) void {
    _ = asm volatile(
        \\ movl -12(%ebp), %eax
        \\ jmp .
        :[_] "={eax}" (-> u32)
    );
}
