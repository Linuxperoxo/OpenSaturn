// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Mod_T: type = @import("types.zig").Mod_T;
const ModType_T: type = @import("types.zig").ModType_T;
const ModErr_T: type = @import("types.zig").ModErr_T;
const ModHandler_T: type = @import("types.zig").ModHandler_T;
const ModRoot_T: type = @import("types.zig").ModRoot_T;

const allocator: type = @import("allocator.zig");
const utils: type = @import("root").kernel.utils;
const fs: type = @import("root").interfaces.fs;

// poderiamos colocar os tipos nos index
// @intFromEnum() do array, mas decidi deixar
// assim do jeito que esta ja que sao poucos
// tipos de modulos

const handlers = [_]ModHandler_T {
    .{
        .filesystem = .{
            .install = &fs.registerfs,
            .remove = &fs.unregisterfs,
        },
    }
};

// nenhuma das outras partes do kernel tem obrigacao de salvar
// os modulos do seu tipo, caso por exemplo, o fs queira procurar
// o certo fs, ele vai chamar o srchmod, isso deixa o kernel em geral
// mais limpo

var modules_entries = [_]ModRoot_T {
    .{
        .list = .{},
        .type = .filesystem,
        .flags = .{
            .init = 0
        },
    },
};

fn module_root_entry(mod_type: ModType_T) *ModRoot_T {
    for(&modules_entries) |*entry| {
        if(entry.type == mod_type) return entry;
    }
}

fn find_handler(mod_type: ModType_T) *ModHandler_T {
    for(&handlers) |*handler| {
        switch(handler) {
            .filesystem => if(mod_type == .filesystem) return handler else continue,
        }
    }
    unreachable;
}

inline fn resolve_mod_type(mod: *const Mod_T) ModType_T {
    return switch(mod.private) {
        .filesystem => ModType_T.filesystem,
    };
}

fn calling_handler(mod: *const Mod_T, comptime op: enum { install, remove }) ModErr_T!void {
    const handler: ModHandler_T = @call(.always_inline, find_handler, .{
        resolve_mod_type(mod)
    });
    switch(handler) {
        .filesystem => |f| {
            switch(@typeInfo(@TypeOf(@field(f, @tagName(op))))) {
                .void => return,
                else => {},
            }
            @call(.never_inline, @field(f, @tagName(op)), .{
                &mod.private.filesystem
            }) catch return ModErr_T.SectionHandlerError;
        },
    }
}

pub fn srchmod(name: []const u8, mod_type: ModType_T) ModErr_T!*const Mod_T {
    const module_root: ModRoot_T = @call(.always_inline, module_root_entry, .{
        mod_type
    });
    if(module_root.flags.init == 0) return ModErr_T.NoNInitialized;
    while(module_root.list.iterator()) |mod| {
        // consideramos cases para modulos
        if(utils.mem.eql(mod.name, name, .{ .case = true })) return mod;
    } else |err| switch(err) {
        @TypeOf(module_root.list).ListErr_T.EndOfIterator => return ModErr_T.NoNFound,
        else => return ModErr_T.InteratorFailed,
    }
}

pub fn inmod(mod: *const Mod_T) ModErr_T!void {
    const module_root: ModRoot_T = @call(.always_inline, module_root_entry, .{
        resolve_mod_type(mod)
    });
    module_root.list.push_in_list(
        allocator.sba.allocator,
        mod
    );
    @call(.always_inline, calling_handler, .{
        mod, .install
    });
}

pub fn rmmod(mod: *const Mod_T) ModErr_T!void {
    const module_root: ModRoot_T = @call(.always_inline, module_root_entry, .{
        resolve_mod_type(mod)
    });
    module_root.list.drop_on_list(
        ?,
        allocator.sba.allocator,
    );
    @call(.always_inline, calling_handler, .{
        mod, .remove
    });
}
