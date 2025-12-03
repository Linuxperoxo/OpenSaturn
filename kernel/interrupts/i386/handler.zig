// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: handler.zig     │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const kernel: type = @import("root").kernel;
const events: type = @import("root").core.events;
const csi: type = @import("csi.zig");

pub var csi_isr =  r: {
    var isr: [32]*const fn() callconv(.naked) void = undefined;
    for(0..isr.len) |i| {
        isr[i] = &opaque {
            comptime {
                // apenas para facilitar a busca no assembly
                @export(&isr_handler, .{
                    .name = ".i386.csi.isr" ++ kernel.utils.fmt.intFromArray(i),
                });
            }
            pub fn isr_handler() callconv(.naked) void {
                // nao precisamos de cli e sti ja que
                // usando o gate type 0xE aqui
                asm volatile(
                    \\ pushl %[int]
                    \\ calll .i386.csi.handler
                    \\ leal 4(%esp), %esp
                    \\ iret
                    :
                    :[int] "i" (i)
                );
            }
        }.isr_handler;
    }
    break :r isr;
};

pub fn csi_handler() callconv(.c) void {
    events.send_event(&csi.csi_event, .{
        .data = 0,
        // pegar o csi dessa maneira e muito mais legal
        // que apenas adicionar o parametro na funcao e
        // deixar o compilador fazer o servico
        .event = asm volatile(
            \\ movl 8(%ebp), %eax
            :[_] "={al}" (-> u8)
        ),
        .flags = .{
            .d = 0,
            .e = 1,
        },
    }) catch {
        // KLOG: this is a kernel panic!
    };
}
