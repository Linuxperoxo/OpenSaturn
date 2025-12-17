// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Mod_T: type = @import("types.zig").Mod_T;
const ModType_T: type = @import("types.zig").ModType_T;
const ModErr_T: type = @import("types.zig").ModErr_T;
const ModHandler_T: type = @import("types.zig").ModHandler_T;
const ModRoot_T: type = @import("types.zig").ModRoot_T;

const c: type = @import("root").kernel.utils.c;
const aux: type = @import("aux.zig");
const builtin: type = @import("builtin");
const allocator: type = @import("allocator.zig");
const mem: type = if(!builtin.is_test) @import("root").kernel.utils.mem else @import("test/mem.zig");
const fs: type = @import("root").interfaces.fs;

// poderiamos colocar os tipos nos index
// @intFromEnum() do array, mas decidi deixar
// assim do jeito que esta ja que sao poucos
// tipos de modulos

pub const handlers = [_]ModHandler_T {
    ModHandler_T {
        .filesystem = if(builtin.is_test) {} else .{
            .install = fs.register_fs,
            .remove = fs.unregister_fs,
        },
    },
};

// nenhuma das outras partes do kernel tem obrigacao de salvar
// os modulos do seu tipo, mas podem sim querer salvar e deixar
// o modulo como anon

pub var modules_entries = [_]ModRoot_T {
    ModRoot_T {
        .list = .{},
        .type = .filesystem,
        .flags = .{
            .init = 0
        },
    },
};

pub const test_fn = if(!builtin.is_test) @compileError("only in tests") else opaque {
    pub fn entry_init_flag(index: usize) u1 {
        return modules_entries[index].flags.init;
    }
};

/// * search module by name and type
pub fn srchmod(name: []const u8, mod_type: ModType_T) ModErr_T!*const Mod_T {
    const module_root: *ModRoot_T = aux.module_root_entry(
        mod_type
    );
    if(module_root.flags.init == 0) return ModErr_T.NoNFound;
    if(aux.search_by_module(module_root, null, name)) |mod_found| {
        const module, _ = mod_found;
        if(module.flags.control.anon == 1)
            return ModErr_T.NoNFound;
        return module;
    } else |err| {
        return err;
    }
}

/// * install module
pub fn inmod(mod: *Mod_T) ModErr_T!void {
    const module_root: *ModRoot_T = aux.module_root_entry(
        aux.resolve_mod_type(mod)
    );
    module_root.flags.init = if(module_root.flags.init == 1) module_root.flags.init else r: {
        module_root.list.init(&allocator.sba.allocator)
            catch return ModErr_T.ListInitFailed;
        break :r 1;
    };
    if(aux.search_by_module(module_root, mod, mod.name)) |mod_found| {
        const module, const collision = mod_found;
        @as(*u2, @alignCast(@ptrCast(&module.flags.internal.collision))).* = @as(u2, @intCast(@intFromEnum(collision)));
        return ModErr_T.ModuleCollision;
    } else |err| switch(err) {
        ModErr_T.NoNFound => {},
        else => return err,
    }
    module_root.list.push_in_list(&allocator.sba.allocator, mod)
        catch return ModErr_T.ListOperationError;
    mod.flags.internal.installed = 1;
    mod.flags.internal.removed = 0;
    if(mod.flags.control.call.init == 1) {
        mod.flags.internal.call.init = 1;
        mod.init() catch {
            mod.flags.internal.fault.call.init = 1;
            return;
        };
    }
    if(c.c_bool(mod.flags.control.call.handler.install)) {
        mod.flags.internal.call.handler.install = 1;
        aux.calling_handler(mod, .install) catch {
            mod.flags.internal.fault.call.handler.install = 1;
            // klog()
            // aqui nao deve dar return
        };
    }
    if(mod.flags.control.call.after == 1) {
        if(mod.after == null) {
            mod.flags.internal.fault.call.after = 1;
            return;
        }
        mod.flags.internal.call.after = 1;
        mod.after.?() catch {
            mod.flags.internal.fault.call.after = 1;
        };
    }
}

/// * remove module
pub fn rmmod(mod: *Mod_T) ModErr_T!void {
    const module_root: *ModRoot_T = aux.module_root_entry(
        aux.resolve_mod_type(mod)
    );
    // esse iterator serve para colocar o index do iterator exatamente
    // no modulo que queremos
    _ = try aux.search_by_module(module_root, mod, null);
    if(mod.flags.control.call.remove == 0) {
        mod.flags.internal.fault.remove = 1;
        return ModErr_T.OperationDenied;
    }
    module_root.list.drop_on_list(
        // o index do iterator - 1 vai estar exatamente no modulo
        // que queremos
        (module_root.list.iterator_index() catch unreachable) - 1,
        &allocator.sba.allocator,
    ) catch return ModErr_T.AllocatorError; // aqui so pode dar erro do alocador
    module_root.flags.init = @intFromBool(module_root.list.how_many_nodes() > 0);
    if(c.c_bool(mod.flags.control.call.handler.remove)) {
        mod.flags.internal.call.handler.remove = 1;
        aux.calling_handler(mod, .remove) catch {
            mod.flags.internal.fault.call.handler.remove = 1;
        };
    }
    mod.flags.internal.installed = 0;
    mod.flags.internal.removed = 1;
    if(mod.flags.control.call.exit == 1) {
        mod.flags.internal.call.exit = 1;
        mod.exit() catch {
            mod.flags.internal.fault.call.exit = 1;
        };
    }
}
