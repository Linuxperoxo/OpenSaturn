// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: modules.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

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
//      * pub const __linkable_module_opti__: bool -> Diz se o modulo deve ter escolha de ser selecionado ou nao no menuconfig (Nao Obrigatorio)
//                                                    caso nao definido sera sempre carregado no kernel
//
// Feito isso, voce deve adicionar o arquivo com essas declaraçoes dentro de __SaturnAllMods__ usando o @import()

// --- SATURN MODULES ---
pub const __SaturnAllMods__ = [_]type {
    @import("fs/rootfs/module.zig"),
};

const Module: type = struct {
    name: []const u8 = undefined,
    init: *const fn() anyerror!void = undefined,
    status: enum {active, disable, undef} = .undef,
};

fn cmpModsNames(
    comptime @"0": []u8,
    comptime @"1": []u8
) bool {
    if(@"0".len != @"1".len) {
        return false;
    }
    for(0..@"0".len) |i| {
        if(@"0"[i] != @"1"[i]) {
            return false;
        }
    }
    return true;
}

// OPTIMIZE:

pub const __SaturnInfoMods__ = resolve: {
    var exportedMods = exporting: {
        var mods: [__SaturnAllMods__.len]Module = undefined;
        for(0..__SaturnAllMods__.len) |i| {
            if(@hasDecl(__SaturnAllMods__[i], "__linkable_module_name__")) {
                if(@hasDecl(__SaturnAllMods__[i], "__linkable_module_init__")) {
                    if(@TypeOf(__SaturnAllMods__[i].__linkable_module_name__) == []const u8) {
                        if(@TypeOf(__SaturnAllMods__[i].__linkable_module_init__) == *const fn() anyerror!void) {
                            mods[i].name = __SaturnAllMods__[i].__linkable_module_name__;
                            mods[i].init = __SaturnAllMods__[i].__linkable_module_init__;
                            mods[i].status = block0: {
                                if(@hasDecl(__SaturnAllMods__[i], "__linkable_module_opti__")) {
                                    if(__SaturnAllMods__[i].__linkable_module_opti__) {
                                        break :block0 .active;
                                    }
                                    break :block0 .undef;
                                }
                                break :block0 .active;
                            };
                            continue;
                        }
                        @compileError("the index file" ++ i ++ "is placed as a module but does not contain '__linkable_module_init__' of the declared type" ++
                            @typeName(*const fn() anyerror!void));
                    }
                    @compileError("the index file" ++ i ++ "is placed as a module but does not contain '__linkable_module_init__' of the declared type" ++
                        @typeName([]const u8));
                }
                @compileError("the index file" ++ i ++ "is placed as a module but does not contain '__linkable_module_init__' of the declared type");
            }
            @compileError("the index file" ++ i ++ "is placed as a module but does not contain '__linkable_module_name__' of the declared type");
        }
        break :exporting mods;
    };
    const loadedModFile = @embedFile("modules.sm");
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
                @compileError("Error in module description: " ++ line ++ ":" ++ offset);
            }
        }
        modName = @constCast(loadedModFileLines[line][0..offset]);
        offset += 1;
        if(offset + 1 < loadedModFileLines[line].len) {
            @compileError("Error in module description: " ++ line ++ ":" ++ offset);
        }
        field = loadedModFileLines[line][offset];
        for(&exportedMods) |*module| {
            if(@call(.compile_time, &cmpModsNames, .{@constCast(module.name), modName})) {
                switch(field) {
                    'y' => module.status = .active,
                    'n' => module.status = .disable,
                    else => module.status = .undef,
                }
            }
        }
        offset = 0;
    }
    break :resolve exportedMods;
};

pub fn callLinkableMods() void {
    inline for(__SaturnInfoMods__) |module| {
        if(module.status == .active) {
            @call(.never_inline, module.init, .{}) catch {
                // TODO:
            };
        }
    }
}
