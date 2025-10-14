// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: loader.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Esse arquivo e responsavel por 2 coisas, carregar
// recursos do kernel, e fazer verificacoes, se alguma
// coisa caiu em um @compileError, pode ter certeza que
// foi nesse arquivo

const arch: type = @import("root").arch;
const decls: type = @import("root").decls;
const config: type = @import("root").config;
const modules: type = @import("root").modules;
const supervisor: type = @import("root").supervisor;
const interfaces: type = @import("root").interfaces;

pub fn saturn_arch_verify() void {
    const decl = decls.saturn_especial_decls[
        @intFromEnum(decls.DeclsOffset_T.arch)
    ];
    if(!@hasDecl(arch, decl)) {
        @compileError("Error");
    }
    const decl_type = @TypeOf(arch.__SaturnArchDescription__);
    const decl_expect_type = decls.saturn_especial_decls_types[
        @intFromEnum(decls.DeclsOffset_T.arch)
    ];
    if(decl_type != decl_expect_type) {
        @compileError("Error");
    }
    const arch_fields = [_][]const u8 {
        "entry", "init", "interrupts", "mm"
    };
    for(arch_fields) |field| {
        @export(
            (@field(arch.__SaturnArchDescription__, field)).entry,
            .{
                .section = arch.__SaturnArchDescription__.text,
                .name = (@field(arch.__SaturnArchDescription__, field)).label
            },
        );
    }
}

pub fn saturn_kernel_config_maker() void {
    const fmt: type = opaque {
        fn numSize(comptime num: usize) usize {
            var context: usize = num;
            var size: usize = 0;
            while(context != 0) : (context /= 10) {
                size += 1;
            }
            return size;
        }

        pub fn intFromSlice(comptime num: usize) [r: {
            if(num == 0) break :r 1;
            break :r numSize(num);
        }]u8 {
            const size = numSize(num);
            var context: usize = num;
            var result = [_]u8 {
                0
            } ** size;
            context = num;
            for(0..size) |i| {
                result[(size - 1) - i] = (context % 10) + '0';
                context /= 10;
            }
            return result;
        }
    };
    asm volatile(
        ".set opensaturn_phys_address, " ++ fmt.intFromSlice(config.kernel.options.kernel_phys_address) ++ "\n" ++
        ".set opensaturn_virtual_address, " ++ fmt.intFromSlice(config.kernel.options.kernel_virtual_address) ++ "\n" ++
        ".globl opensaturn_phys_address" ++ "\n" ++
        ".globl opensaturn_virtual_address"
    );
}

pub fn saturn_modules_loader() void {
    comptime {
        for(modules.__SaturnAllMods__) |M| {
            if(!@hasDecl(M, "__SaturnModuleDescription__")) {
                @compileError(
                    "__SaturnModuleDescription__ is not defined in the module file" ++
                    @typeName(M)
                );
            }
            if(@TypeOf(M.__SaturnModuleDescription__) != interfaces.module.ModuleDescription_T) {
                // ERROR
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
