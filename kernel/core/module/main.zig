// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Mod_T: type = @import("types.zig").Mod_T;
const ModType_T: type = @import("types.zig").ModType_T;
const ModErr_T: type = @import("types.zig").ModErr_T;
const ModHandler_T: type = @import("types.zig").ModHandler_T;
const ModRoot_T: type = @import("types.zig").ModRoot_T;

const c: type = @import("root").lib.utils.c;
const aux: type = @import("aux.zig");
const builtin: type = @import("builtin");
const allocator: type = @import("allocator.zig");
const mem: type = if(!builtin.is_test) @import("root").lib.utils.mem else @import("test/mem.zig");
const fs: type = @import("root").interfaces.fs;
const devices: type = @import("root").interfaces.devices;

// nenhuma das outras partes do kernel tem obrigacao de salvar
// os modulos do seu tipo, mas podem sim querer salvar e deixar
// o modulo como anon

pub var modules_entries = [_]ModRoot_T {
    ModRoot_T {
        .list = .{},
        .type = .filesystem,
        .init = 0
    },

    ModRoot_T {
        .list = .{},
        .type = .driver,
        .init = 0,
    },
};

pub const test_fn = if(!builtin.is_test) @compileError("only in tests") else opaque {
    pub fn entry_init_flag(index: usize) u1 {
        return modules_entries[index].init;
    }
};

/// * search module by name and type
pub noinline fn srchmod(name: []const u8, mod_type: ModType_T) ModErr_T!*const Mod_T {
    const module_root: *ModRoot_T = aux.module_root_entry(mod_type);
    if(aux.search_by_module(module_root, null, name)) |mod_found| {
        if(mod_found.control.anon == 1)
            return ModErr_T.NoNFound;
        return mod_found;
    } else |err| {
        return err;
    }
}

/// * install module
pub noinline fn inmod(mod: *const Mod_T) ModErr_T!void {
    const module_root: *ModRoot_T = aux.module_root_entry(mod.type);

    module_root.init = if(module_root.init == 1) module_root.init else r: {
        module_root.list.init(&allocator.sba.allocator)
            catch return ModErr_T.ListInitFailed;
        break :r 1;
    };

    if(aux.search_by_module(module_root, mod, mod.name)) |_| {
        return ModErr_T.ModuleCollision;
    } else |err| switch(err) {
        ModErr_T.NoNFound => {},
        else => return err,
    }

    module_root.list.push_in_list(&allocator.sba.allocator, mod)
        catch return ModErr_T.ListOperationError;

    if(mod.control.init == 1)
        mod.init() catch return ModErr_T.InitFailed;
}

/// * remove module
pub noinline fn rmmod(mod: *const Mod_T) ModErr_T!void {
    const module_root: *ModRoot_T = aux.module_root_entry(mod.type);
    if(module_root.init == 0)
        return ModErr_T.NoNFound;

    // esse iterator serve para colocar o index do iterator exatamente
    // no modulo que queremos
    _ = try aux.search_by_module(module_root, mod, null);
    if(mod.control.remove == 0)
        return ModErr_T.OperationDenied;

    module_root.list.drop_on_list(
        // o index do iterator - 1 vai estar exatamente no modulo
        // que queremos
        (module_root.list.iterator_index() catch unreachable) - 1,
        &allocator.sba.allocator,
    ) catch return ModErr_T.AllocatorError; // aqui so pode dar erro do alocador

    module_root.init = @intFromBool(module_root.list.how_many_nodes() > 0);

    if(mod.control.exit == 1)
        mod.exit() catch return ModErr_T.ExitFailed;
}
