// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: modules.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const arch: type = @import("arch.zig");

const ModuleInfo_T: type = @import("modules/types.zig").ModuleInfo_T;
const ModuleResolved_T: type = @import("modules/types.zig").ModuleResolved_T;
const ModuleInfoResolvedInit_T: type = @import("modules/types.zig").ModuleInfoResolvedInit_T;

const compileError = @import("modules/utils.zig").compileError;
const cmpModsNames = @import("modules/utils.zig").cmpModsNames;

pub const ModuleDescriptionTarget_T: type = arch.target_T;
pub const ModuleDescription_T: type = struct {
    name: []const u8,
    init: *const fn() anyerror!void,
    optional: bool,
    arch: []const ModuleDescription_T,
    type: union(enum) {
        driver: void,
        syscall: void,
        interrupt: void,
        irq: void,
        fs: union(enum) {
            compile: []const u8,
            dinamic: void,
        },
    },
};

// Esse arquivo serve para o kernel detectar os modulos
// que devem ser linkados a ele. Como o kernel nao depende
// de nenhum modulo, se nao tiver um intermediario como esse,
// nenhum modulo seria iniciado pelo kernel, isso facilita tanto
// a implementaçao de novos modulos tanto a legibilidade, imagine
// sempre que fossemos colocar um novo modulo tivessemos que ir no
// codigo fonte do kernel e adicionar a chamada ao modulo explicitamente.

// Como criar modulos para o saturn?
//  Para cria um modulo, alem de usar as interfaces pelo lib/saturn/interfaces/interfaces.zig,
//  voce deve ter explicitamente 3 declaraçoes dentro do arquivo do seu modulo
//      * pub const __linkable_module_name__: []const u8 -> Diz o nome do modulo (Obrigatorio)
//      * pub const __linkable_module_init__: *const fn() anyerror!void -> Aponta para a funçao init do modulo (Obrigatorio)
//      * pub const __linkable_module_optional__: bool -> Diz se o modulo deve ter escolha de ser selecionado ou nao no menuconfig (Nao Obrigatorio)
//                                                        caso nao definido sera sempre carregado no kernel
//
//      * pub const __linkable_module_arch__: target_T/[_]target_T -> Pode ser um array ou de apenas um valor. Diz quais arquiteturas sao suportadas pelo
//                                                                    modulo
//
// Feito isso, voce deve adicionar o arquivo com essas declaraçoes dentro de __SaturnAllMods__ usando o @import()



// --- SATURN MODULES ---
pub const __SaturnAllMods__ = [_]type {
    @import("fs/rootfs/module.zig"),
};



pub const __SaturnModulesInfos__ = SMR: {
    // Verificação de modulos
    var saturnMods: [__SaturnAllMods__.len]ModuleInfo_T = undefined;
        for(0..saturnMods.len) |i| {
            // Module Name Decl
            saturnMods[i].name = n: {
            const declName: []const u8 = "__linkable_module_name__";
            if(!@hasDecl(__SaturnAllMods__[i], declName)) {
                compileError(@typeName(__SaturnAllMods__[i]), declName, null);
            }
            if(@TypeOf(__SaturnAllMods__[i].__linkable_module_name__) != []const u8) {
                compileError(@typeName(__SaturnAllMods__[i]), declName, @as(?[]const u8, @typeName([]const u8)));
            }
            break :n __SaturnAllMods__[i].__linkable_module_name__;
        };

        // Module Arch Decl
        aD: {
            const declName: []const u8 = "__linkable_module_arch__";
            if(!@hasDecl(__SaturnAllMods__[i], declName)) {
                compileError(@typeName(__SaturnAllMods__[i]), declName, null);
            }
            const typeInfo = @typeInfo(@TypeOf(__SaturnAllMods__[i].__linkable_module_arch__));
            switch(typeInfo) {
                .array => |A| {
                    if(A.child != arch.target_T) {
                        @compileError(
                            declName ++ " is defined in the module file" ++ @typeName(__SaturnAllMods__[i]) ++
                            ", but it must be an [_]" ++ @typeName(arch.target_T)
                        );
                    }
                    for(__SaturnAllMods__[i].__linkable_module_arch__) |modArch| {
                        if(modArch == arch.__SaturnTarget__) {
                            break :aD;
                        }
                    }
                },
                else => {
                    if(@TypeOf(__SaturnAllMods__[i].__linkable_module_arch__) != arch.target_T) {
                        @compileError(
                            "__linkable_module_arch__ is defined in the module file" ++ @typeName(__SaturnAllMods__[i]) ++
                            " but it must be an " ++ @typeName(arch.target_T) ++ " or [_]" ++ @typeName(arch.target_T)
                        );
                    }
                    if(__SaturnAllMods__[i].__linkable_module_arch__ == arch.__SaturnTarget__) {
                        break :aD;
                    }
                },
            }
            @compileError("module file " ++ @typeName(__SaturnAllMods__[i]) ++ " is not supported by target architecture " ++ @tagName(arch.__SaturnTarget__));
        }

        // Module Optional Decl
        saturnMods[i].optional = o: {
            const declName: []const u8 = "__linkable_module_optional__";
            if(@hasDecl(__SaturnAllMods__[i], declName)) {
                if(@TypeOf(__SaturnAllMods__[i].__linkable_module_optional__) != bool) {
                    compileError(@typeName(__SaturnAllMods__[i]), declName, @as(?[]const u8, @typeName(bool)));
                }
                break :o __SaturnAllMods__[i].__linkable_module_optional__;
            }
            break :o false;
        };
    }
    break :SMR saturnMods;
};

pub const __SaturnModulesResolved__ = SMR: {
    var resolved = r: {
        var modulesInfos: [__SaturnModulesInfos__.len]ModuleResolved_T = undefined;
        for(0..__SaturnModulesInfos__.len) |i| {
            modulesInfos[i].info = &__SaturnModulesInfos__[i];
            modulesInfos[i].action = if(modulesInfos[i].info.optional) .undef else .include; // Por padrão vamos incluir o modulo
        }
        break :r modulesInfos;
    };
    // Resolvendo modulos no arquivo modules.sm
    const loadedModFile = lMF: {
        const modFile = @embedFile("modules.sm");
        if(modFile.len == 0) {
            for(resolved) |mod| {
                if(mod.info.optional) {
                    @compileError(
                        "module " ++ mod.info.name ++ " is optional but it was not included in the module file, run 'zig build menuconfig'"
                    );
                }
            }
        }
        break :lMF modFile;
    };
    const loadedModFileLines = reading: {
        const linesNum = counting: {
            var count: usize = 1;
            for(0..loadedModFile.len) |i| {
                if(loadedModFile[i] == '\n') {
                    count += 1;
                }
            }
            break :counting count - 1; // FIXME:
        };
        const lines = separating: {
            var allLines: [linesNum][]const u8 = undefined;
            var initOfLine: usize = 0;
            var endOfLine: usize = 0;
            for(0..linesNum) |lines| {
                while(loadedModFile[endOfLine] != '\n') : (endOfLine += 1) {
                    if(endOfLine + 1 >= loadedModFile.len) {
                        break;
                    }
                }
                if(endOfLine > 0) {
                    allLines[lines] = loadedModFile[initOfLine..endOfLine];
                    endOfLine += 1;
                    initOfLine = endOfLine;
                }
            }
            break :separating allLines;
        };
        break :reading lines;
    };
    var modName: []u8 = undefined;
    var offset: usize = 0;
    var field: u8 = undefined;
    for(0..loadedModFileLines.len) |line| {
        while(loadedModFileLines[line][offset] != '=') : (offset += 1) {
            if(offset + 1 >= loadedModFileLines[line].len) {
                @compileError("error in module description: " ++ line ++ ":" ++ offset);
            }
        }
        modName = @constCast(loadedModFileLines[line][0..offset]);
        offset += 1;
        if(offset + 1 < loadedModFileLines[line].len) {
            @compileError("error in module description: " ++ line ++ ":" ++ offset);
        }
        field = loadedModFileLines[line][offset];
        for(&resolved) |*module| {
            if(@call(.compile_time, &cmpModsNames, .{module.info.name, modName})) {
                if(module.action != .undef) {
                    @compileError(
                        "double definition of inclusion of module " ++ module.info.name ++ ", run 'zig build menuconfig'"
                    );
                }
                switch(field) {
                    'y' => module.action = .include,
                    'n' => module.action = .skip,
                    else => module.action = .skip,
                }
            }
        }
        offset = 0;
    }
    break :SMR resolved;
};

pub const __SaturnModulesInfoResolvedInit__ = SMIR: {
    var modulesInfoResolvedInit: [__SaturnModulesResolved__.len]ModuleInfoResolvedInit_T = undefined;
    for(0..__SaturnModulesResolved__.len) |i| {
        // Module Init Decl
        {
            // So fazemos essa verificação aqui por causa do menuconfig, como ele
            // não tem todos os modulos import que o kernel tem, ele vai dar um erro
            // de compilação ao tentar resolver os arquivos que usarem os imports
            const declName: []const u8 = "__linkable_module_init__";
            if(!@hasDecl(__SaturnAllMods__[i], declName)) {
                compileError(
                    @typeName(__SaturnAllMods__[i]),
                    declName,
                    null
                );
            }
            if(@TypeOf(__SaturnAllMods__[i].__linkable_module_init__) != *const fn() anyerror!void) {
                compileError(
                    @typeName(__SaturnAllMods__[i]),
                    declName,
                    @as(?[]const u8, @typeName(*const fn() anyerror!void))
                );
            }
        }
        modulesInfoResolvedInit[i].resolved = &__SaturnModulesResolved__[i];
        modulesInfoResolvedInit[i].init = __SaturnAllMods__[i].__linkable_module_init__;
    }
    break :SMIR modulesInfoResolvedInit;
};

pub fn callLinkableMods() void {
    inline for(0..__SaturnModulesInfoResolvedInit__.len) |i| {
        if(comptime __SaturnModulesInfoResolvedInit__[i].resolved.action == .include) {
            @call(.never_inline, __SaturnModulesInfoResolvedInit__[i].init, .{}) catch {
                // TODO:
            };
        }
    }
}
