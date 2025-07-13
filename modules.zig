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

// Como Usar?
//  Para adicionar um modulo ao kernel voce deve criar seu modulo usando 
//  as interfaces disponibilizadas para a sua criaçao, para isso use o arquivo
//  lib/saturn/interfaces/interfaces.zig no seu arquivo zig para ter todas as
//  interfaces. Logo depois de criar seu modulo corretamente, voce vai precisar
//  linkar ele no kernel, para fazer isso voce deve usar a struct LinkModInKernel,
//  use @import(lib/saturn/interfaces/interfaces.zig).module.LinkModInKernel, agora
//  deve adicionar o seguinte codigo no seu modulo: 
//
//  pub const __linkable__: LinkModInKernel = .{
//      init = init, // Aqui voce deve colocar a funçao init do seu modulo
//  };
//
//  Feito isso, voce deve adicionar o arquivo do seu modulo dentro do array "modules"
//  dentro desse arquivo. O arquivo que voce for colocar ali deve ter o __linkable__
//  visivel dentro dele.

pub const LinkInKernel: type = @import("root").interfaces.module.LinkModInKernel;

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

pub const __SaturnAllMods__ = [_]type {
    @import("fs/rootfs/module.zig"),
};

pub const __SaturnInfoMods__ = resolve: {
    var exportedMods = exporting: {
        var mods: [__SaturnAllMods__.len]Module = undefined;
        for(0..__SaturnAllMods__.len) |i| {
            if(@hasDecl(__SaturnAllMods__[i], "__linkable__")) {
                if(@TypeOf(__SaturnAllMods__[i].__linkable__) == LinkInKernel) {
                    mods[i].name = __SaturnAllMods__[i].__linkable__.name;
                    mods[i].init = __SaturnAllMods__[i].__linkable__.init;
                    continue;
                }
                @compileError("the index file" ++ i ++ "contain __linkable__ declared but not the type" ++ @typeName(LinkInKernel));
            }
            @compileError("the index file" ++ i ++ "is placed as a module but does not contain '__linkable__' of the declared type" ++ @typeName(LinkInKernel));
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
    for(__SaturnInfoMods__) |module| {
        if(module.status == .active) {
            @call(.never_inline, module.init, .{}) catch {

            };
        }
    }
}
