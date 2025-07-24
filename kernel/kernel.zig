// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: kernel.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const arch: type = @import("saturn/arch");
pub const core: type = @import("saturn/kernel/core");
pub const interfaces: type = @import("saturn/lib/interfaces");
pub const io: type = @import("saturn/lib/io");
pub const memory: type = @import("saturn/kernel/memory");
pub const supervisor: type = @import("saturn/supervisor");
pub const modules: type = @import("saturn/modules");
pub const debug: type = @import("saturn/debug");
pub const interrupt: type = @import("saturn/interrupt");

comptime {
    if(!@hasDecl(interrupt, "init")) {
        @compileError(
            "interruption of the kernel target cpu architecture does not have a declared function for init"
        );
    }
}

export fn init() void {
    @call(.never_inline, &arch.__SaturnEnabledArch__.init, .{});
    // Caso a arquitetura queira usar o supervisor, o saturn
    // precisa que a arquitetura tenha uma funçao para configurar
    // suas interrupçoes juntamente com o supervisor, caso contrario
    // o saturn nao pode garantir que as interrupçoes estao funcionando
    //
    // O uso do supervisor nao e obrigatorio, por exemplo, para microcontroladores
    // e desejavel ter maior controle sobre as interrupçoes
    switch(arch.__SaturnEnabledArchSupervisor__) {
        true => {
            if(@TypeOf(interrupt.init) != supervisor.initSupervisor_T) {
                @compileError(
                    "supervisor init function should be of the type '" ++ @typeName(supervisor.initSupervisor_T) ++ "'"
                );
            }
            if(!@hasDecl(interrupt, "__saturn_supervisor_table__")) {
                @compileError(
                    "__saturn_supervisor_table__ must be defined within the file"
                );
            }
            switch(@typeInfo(@TypeOf(interrupt.__saturn_supervisor_table__))) {
                // TODO: 
            }
            @call(.never_inline, &interrupt.init, .{
                comptime supervisor.init(
                    interrupt.__saturn_supervisor_table__,
                    [interrupt.__saturn_supervisor_table__.len]?*const fn() void
                )
            });
        },
        false => {
            @call(.never_inline, &interrupt.init, .{});
        },
    }
}

export fn main() void {
    @call(.always_inline, &init, .{});
    @call(.always_inline, &modules.callLinkableMods, .{});
}
