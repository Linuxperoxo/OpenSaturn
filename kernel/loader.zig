// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: loader.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Esse arquivo e responsavel por 2 coisas, carregar
// recursos do kernel, e fazer verificacoes, se alguma
// coisa caiu em um @compileError, pode ter certeza que
// foi nesse arquivo

const arch: type = @import("root").arch;
const config: type = @import("root").config;
const modules: type = @import("root").modules;
const supervisor: type = @import("root").supervisor;
const interrupts: type = @import("root").interrupts;

pub fn loadInterrupts() void {
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
    switch(comptime arch.__SaturnEnabledArchSupervisor__) {
        true => @call(.never_inline, &interrupts.init, .{ supervisor.supervisorHandlerPerIsr }), // with supervisor
        false => @call(.never_inline, &interrupts.init, .{}), // without supervisor
    }
}

pub fn loadModules() void {
    comptime {
        for(modules.__SaturnAllMods__) |M| {
            if(!@hasDecl(M, "__SaturnModuleDescription__")) {
                @compileError(
                    "__SaturnModuleDescription__ is not defined in the module file" ++ @typeName(M)
                );
            }
        }
    }
    inline for(modules.__SaturnAllMods__) |M| {
        for(M.__SaturnModuleDescription__.arch) |supported| {
            if(arch.__SaturnTarget__ == supported) {
                @call(.never_inline, M.__SaturnModuleDescription__.init, .{}) catch {

                };
                // resolvendo modulo com base no seu tipo
                sw: switch(M.__SaturnModuleDescription__.type) {
                    .driver => {},
                    .syscall => {},
                    .interrupt => {},
                    .irq => {},
                    .filesystem => {
                        switch(M.__SaturnModuleDescription__.type.filesystem) {
                            // caso o modulo fs use compile, vamos fazer uma
                            // montagem do fs em tempo de compilacao
                            .compile => {}, // call mount
                            .dinamic => break :sw,
                        }
                    },
                }
                continue;
            }
        }
        if(!config.modules.IgnoreModuleWithArchNotSupported) {
            @compileError("module file " ++ @typeName(M) ++ " is not supported by target architecture " ++ @tagName(arch.__SaturnTarget__));
        }
    }
}
