// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: kernel.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const arch: type = @import("saturn/arch");
pub const core: type = @import("saturn/kernel/core");
pub const interfaces: type = @import("saturn/lib/interfaces");
pub const kernel: type = @import("saturn/lib/kernel");
pub const memory: type = @import("saturn/kernel/memory");
pub const supervisor: type = @import("saturn/supervisor");
pub const modules: type = @import("saturn/modules");
pub const debug: type = @import("saturn/debug");
pub const interrupts: type = @import("saturn/interrupts");

comptime {
    // Caso a arquitetura queira usar o supervisor, o saturn
    // precisa que a arquitetura tenha uma funçao para configurar
    // suas interrupçoes juntamente com o supervisor, caso contrario
    // o saturn nao pode garantir que as interrupçoes estao funcionando
    //
    // O uso do supervisor nao e obrigatorio, por exemplo, para microcontroladores
    // e desejavel ter maior controle sobre as interrupçoes
    if(!@hasDecl(interrupts, "init")) {
        @compileError(
            "interruption of the kernel target cpu architecture does not have a declared function for init"
        );
    }
    if(arch.__SaturnEnabledArchSupervisor__) {
        const supervisor_T: type = supervisor.supervisor_T;
        if(!@hasDecl(interrupts, "__saturn_supervisor_table__")) {
            @compileError(
                "__saturn_supervisor_table__ must be defined within the file"
            );
        }
        switch(@typeInfo(@TypeOf(interrupts.__saturn_supervisor_table__))) {
            .array => |A| {
                if(A.child != supervisor_T) {
                    @compileError(
                        "__saturn_supervisor_table__ must be an array of '" ++ @typeName(supervisor_T) ++ "'"
                    );
                }
                if(@TypeOf(interrupts.init) != fn([A.len]*const fn() callconv(.c) void) void) {
                    @compileError(
                        "supervisor interrupt init function must be an '" ++ @typeName(fn([A.len]*const fn() callconv(.c) void) void) ++ "'"
                    );
                }
            },
            else => {
                @compileError(
                    "__saturn_supervisor_table__ must be an array of '" ++ @typeName(supervisor_T) ++ "'"
                );
            },
        }
    }
}

export fn init() void {
    @call(.never_inline, &arch.__SaturnEnabledArch__.init, .{});
    switch(comptime arch.__SaturnEnabledArchSupervisor__) {
        true => @call(.never_inline, &interrupts.init, .{ supervisor.supervisorHandlerPerIsr }), // with supervisor
        false => @call(.never_inline, &interrupts.init, .{}), // without supervisor
    }
}

export fn main() void {
    @call(.always_inline, &init, .{});
    @call(.always_inline, &modules.callLinkableMods, .{});
}
