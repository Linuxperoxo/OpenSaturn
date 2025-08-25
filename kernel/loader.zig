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

pub fn SaturnArch() void {
    const EnabledArch: type = comptime switch(config.arch.options.Target) {
        .x86 => arch.SupportedArch[0],
        .x86_64 => arch.SupportedArch[1],
        .arm => arch.SupportedArch[2],
        .avr => arch.SupportedArch[3],
    };
    // Comptime para fazer verificacao geral sobre a arch
    comptime {
        if(!@hasDecl(EnabledArch, "__SaturnArchDescription__")) {
            @compileError(
                \\ Arch Error
            );
        }
        if(!EnabledArch.__SaturnArchDescription__.usable) {
            @compileError(
                "target kernel cpu architecture " ++ @tagName(config.arch.options.Target) ++ " has no guarantee of functioning by the developer"
            );
        }
    }
    // Fazendo chamada para o init da arquitetura
    @call(.never_inline, EnabledArch.__SaturnArchDescription__.init, .{});
    // Comptime para fazer verificacao das interrupçoes
    comptime {
        // OPTIMIZE:

        // Caso a arquitetura queira usar o supervisor, o saturn
        // precisa que a arquitetura tenha uma funçao para configurar
        // suas interrupçoes juntamente com o supervisor, caso contrario
        // o saturn nao pode garantir que as interrupçoes estao funcionando
        //
        // O uso do supervisor nao e obrigatorio, por exemplo, para microcontroladores
        // e desejavel ter maior controle sobre as interrupçoes
        const InterruptArch: type = switch(EnabledArch.__SaturnArchDescription__.interrupt) {
            // TODO:
            .raw => if(@hasDecl(interrupts, "raw"))
                interrupts.raw
            else
                @compileError(""),
            .supervisor => if(@hasDecl(interrupts, "supervisor"))
                interrupts.supervisor
            else
                @compileError(""),
        };
        if(!@hasDecl(InterruptArch, "init")) {
            // TODO:
            @compileError("");
        }
        if(EnabledArch.__SaturnArchDescription__.interrupt == .supervisor) {
            if(!@hasDecl(interrupts, "__SaturnSupervisorTable__")) {
                @compileError(
                    "__SaturnSupervisorTable__ must be defined within the file"
                );
            }
            switch(@typeInfo(@TypeOf(interrupts.__SaturnSupervisorTable__))) {
                .array => |A| {
                    if(A.child != supervisor.supervisor_T) {
                        @compileError(
                            "__SaturnSupervisorTable__ must be an array of '" ++ @typeName(supervisor.supervisor_T) ++ "'"
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
                        "__SaturnSupervisorTable__ must be an array of '" ++ @typeName(supervisor.supervisor_T) ++ "'"
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

pub fn SaturnModules() void {
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
        // Skip nao pode ser comptime se nao vamos ter um
        // erro de compilacao, ja que ele vai tentar carregar
        // os modulos em comptime
        skip: {
            // Precisamos forçar um comptime aqui para evitar 
            // erro de compilacao
            comptime arch: {
                for(M.__SaturnModuleDescription__.arch) |supported| {
                    if(arch.__SaturnTarget__ == supported) {
                        break :arch;
                    }
                }
                if(!config.modules.options.IgnoreModuleWithArchNotSupported) {
                    @compileError("module file " ++ @typeName(M) ++ " is not supported by target architecture " ++ @tagName(arch.__SaturnTarget__));
                }
                break :skip;
            }
            switch(comptime M.__SaturnModuleDescription__.load) {
                .dinamic => {},
                .unlinkable => {},
                .linkable => {
                    // comptime nao necessario, mas preciso ter certeza que ele vai resolver em
                    // compilacao, por mais que tenha o @compileError
                    comptime {
                        if(config.modules.options.UseMenuconfigAsRef) {
                            if(!@hasField(config.modules.menuconfig.Menuconfig_T, M.__SaturnModuleDescription__.name)) {
                                @compileError(
                                    "module " ++ M.__SaturnModuleDescription__.name ++ " in file " ++ @typeName(M) ++ " needs to be added in Menuconfig_T"
                                );
                            }
                            switch(@field(config.modules.menuconfig.ModulesSelection, M.__SaturnModuleDescription__.name)) {
                                .yes => {},
                                .no => break :skip,
                            }
                        }
                    }
                    @call(.never_inline, M.__SaturnModuleDescription__.init, .{}) catch {
                    };
                },
            }
            // resolvendo modulo com base no seu tipo
            switch(comptime M.__SaturnModuleDescription__.type) {
                .driver => {},
                .syscall => {},
                .interrupt => {},
                .irq => {},
                .filesystem => {
                    switch(comptime M.__SaturnModuleDescription__.type.filesystem) {
                        // caso o modulo fs use compile, vamos fazer uma
                        // montagem do fs em tempo de compilacao
                        .compile => {}, // call mount
                        .dinamic => break :skip,
                    }
                },
            }
        }
    }
}
