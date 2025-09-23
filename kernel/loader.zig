// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: loader.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Esse arquivo e responsavel por 2 coisas, carregar
// recursos do kernel, e fazer verificacoes, se alguma
// coisa caiu em um @compileError, pode ter certeza que
// foi nesse arquivo

const cpu: type = @import("root").cpu;
const config: type = @import("root").config;
const modules: type = @import("root").modules;
const supervisor: type = @import("root").supervisor;
const interfaces: type = @import("root").interfaces;

pub fn SaturnArch() void {
    const Arch: type = cpu.Arch;
    const Entry: type = cpu.Entry;
    const Interrupt: type = cpu.Interrupt;

    // === Arch Verify ===
    comptime {
        if(!@hasDecl(Arch, "__SaturnArchDescription__")) {
            @compileError(
                "expected a declaration __SaturnArchDescription__ for architecture " ++
                @tagName(config.arch.options.Target)
            );
        }
        if(@TypeOf(Arch.__SaturnArchDescription__) != interfaces.arch.arch_T) {
            @compileError(
                "declaration __SaturnArchDescription__ for architecture " ++
                @tagName(config.arch.options.Target) ++
                " must be type: " ++
                @typeName(interfaces.arch.arch_T)
            );
        }
        if(!Arch.__SaturnArchDescription__.usable) {
            @compileError(
                "target kernel cpu architecture " ++
                @tagName(config.arch.options.Target) ++
                " has no guarantee of functioning by the developer"
            );
        }
    }
    // ===================

    // === Arch Entry Verify ===
    comptime {
        if(!@hasDecl(Entry, "__SaturnEntryDescription__")) {
            @compileError(
                "expected a declaration __SaturnEntryDescription__ for architecture " ++
                @tagName(config.arch.options.Target)
            );
        }
        if(@TypeOf(Entry.__SaturnEntryDescription__) != interfaces.arch.entry_T) {
            @compileError(
                "declaration __SaturnArchDescription__ for architecture " ++
                @tagName(config.arch.options.Target) ++
                " must be type: " ++
                @typeName(interfaces.arch.entry_T)
            );
        }
        @export(Entry.__SaturnEntryDescription__.entry, .{
            .name = Entry.__SaturnEntryDescription__.label,
            .section = Entry.__SaturnEntryDescription__.section,
        });
    }
    // =========================

    // Fazendo chamada para o init da arquitetura
    @call(.never_inline, Arch.__SaturnArchDescription__.init, .{});

    // === Arch Interrupt Verify ===
    comptime {
        // TODO: Fazer um type struct para interrupt, para assim ter 3 tipos
        // para as 3 bases de arquitetura para o kernel

        // Caso a arquitetura queira usar o supervisor, o saturn
        // precisa que a arquitetura tenha uma funçao para configurar
        // suas interrupçoes juntamente com o supervisor, caso contrario
        // o saturn nao pode garantir que as interrupçoes estao funcionando
        //
        // O uso do supervisor nao e obrigatorio, por exemplo, para microcontroladores
        // e desejavel ter maior controle sobre as interrupçoes
        switch(Arch.__SaturnArchDescription__.interrupt) {
            .raw => {},
            .supervisor => {
                if(!@hasDecl(Interrupt.supervisor, "__SaturnSupervisorTable__")) {
                    @compileError(
                        "__SaturnSupervisorTable__ must be defined within the file"
                    );
                }
                switch(@typeInfo(@TypeOf(Interrupt.supervisor.__SaturnSupervisorTable__))) {
                    .array => |A| {
                        if(A.child != supervisor.supervisor_T) {
                            @compileError(
                                "__SaturnSupervisorTable__ must be an array of " ++
                                @typeName(supervisor.supervisor_T)
                            );
                        }
                        if(@TypeOf(Interrupt.supervisor.init) != fn([A.len]*const fn() callconv(.c) void) void) {
                            @compileError(
                                "supervisor interrupt init function must be an " ++
                                @typeName(fn([A.len]*const fn() callconv(.c) void) void)
                            );
                        }
                    },
                    else => {
                        @compileError(
                            "__SaturnSupervisorTable__ must be an array of " ++
                            @typeName(supervisor.supervisor_T)
                        );
                    },
                }
            },
        }
    }
    // =============================

    // Fazendo chamada para o init da interrupt da arquitetura
    switch(comptime Arch.__SaturnArchDescription__.interrupt) {
        .raw => @call(.never_inline, &Interrupt.raw.init, .{}), // without supervisor
        .supervisor => @call(.never_inline, &Interrupt.supervisor.init, .{ supervisor.supervisorHandlerPerIsr }), // with supervisor
    }
}

pub fn SaturnModules() void {
    comptime {
        for(modules.__SaturnAllMods__) |M| {
            if(!@hasDecl(M, "__SaturnModuleDescription__")) {
                @compileError(
                    "__SaturnModuleDescription__ is not defined in the module file" ++
                    @typeName(M)
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
                for(M.__SaturnModuleDescription__.arch) |A| {
                    if(config.arch.options.Target == A) {
                        break :arch;
                    }
                }
                if(!config.modules.options.IgnoreModuleWithArchNotSupported) {
                    @compileError("module file " ++
                        @typeName(M) ++
                        " is not supported by target architecture " ++
                        @tagName(config.arch.options.Target));
                }
                break :skip;
            }
            switch(comptime M.__SaturnModuleDescription__.load) {
                .dinamic => {},
                .unlinkable => {},
                .linkable => {
                    // comptime apenas para deixar explicito
                    comptime {
                        if(config.modules.options.UseMenuconfigAsRef) {
                            if(!@hasField(config.modules.menuconfig.Menuconfig_T, M.__SaturnModuleDescription__.name)) {
                                @compileError(
                                    "module " ++
                                    M.__SaturnModuleDescription__.name ++
                                    " in file " ++
                                    @typeName(M) ++
                                    " needs to be added in Menuconfig_T"
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
