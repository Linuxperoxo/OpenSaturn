// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Mod_T: type = @import("types.zig").Mod_T;
const ModType_T: type = @import("types.zig").ModType_T;
const ModErr_T: type = @import("types.zig").ModErr_T;
const ModHandler_T: type = @import("types.zig").ModHandler_T;
const ModRoot_T: type = @import("types.zig").ModRoot_T;
const ModErrInternal_T: type = @import("types.zig").ModErrInternal_T;

const builtin: type = @import("builtin");
const allocator: type = @import("allocator.zig");
const mem: type = if(!builtin.is_test) @import("root").kernel.utils.mem else @import("test/mem.zig");
const fs: type = @import("root").interfaces.fs;

// poderiamos colocar os tipos nos index
// @intFromEnum() do array, mas decidi deixar
// assim do jeito que esta ja que sao poucos
// tipos de modulos

const handlers = [_]ModHandler_T {
    .{
        .filesystem = if(builtin.is_test) {} else .{
            .install = fs.registerfs,
            .remove = fs.unregisterfs,
        },
    },
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

pub const test_fn = if(!builtin.is_test) @compileError("only in tests") else opaque {
    pub fn entry_init_flag(index: usize) u1 {
        return modules_entries[index].flags.init;
    }
};

inline fn module_root_entry(mod_type: ModType_T) *ModRoot_T {
    for(&modules_entries) |*entry| {
        if(entry.type == mod_type) return entry;
    }
    unreachable;
}

inline fn find_handler(mod_type: ModType_T) *const ModHandler_T {
    for(&handlers) |*handler| {
        switch(handler.*) {
            .filesystem => if(mod_type == .filesystem) return handler else continue,
            else => unreachable,
        }
    }
    unreachable;
}

inline fn resolve_mod_type(mod: *const Mod_T) ModType_T {
    return switch(mod.private) {
        .filesystem => ModType_T.filesystem,
        else => unreachable,
    };
}

inline fn module_iterator(
    module_root: *ModRoot_T,
    name: ?[]const u8,
    cmp: ?*const Mod_T,
    comptime handler: *const fn(*const Mod_T, ?*const Mod_T, ?[]const u8) anyerror!void
) ModErrInternal_T!*const Mod_T {
    module_root.list.iterator_reset() catch unreachable;
    while(module_root.list.iterator()) |module| {
        handler(
            module,
            cmp,
            name,
        ) catch continue;
        return module;
    } else |err| return switch(err) {
        @TypeOf(module_root.list).ListErr_T.EndOfIterator => ModErrInternal_T.EndOfIterator,
        else => ModErrInternal_T.IteratorInternalError,
    };
}

inline fn calling_handler(mod: *const Mod_T, comptime op: enum { install, remove }) ModErr_T!void {
    const handler: *const ModHandler_T = find_handler(
        resolve_mod_type(mod)
    );
    switch(handler.*) {
        .filesystem => |f| {
            switch(@typeInfo(@TypeOf(f))) {
                .void => return,
                else => {},
            }
            if(@field(f, @tagName(op)) != null) {
                @call(.never_inline, @field(f, @tagName(op)).?, .{
                    &mod.private.filesystem
                }) catch return ModErr_T.SectionHandlerError;
            }
        },
        else => unreachable,
    }
}

/// * search module by name and type
pub fn srchmod(name: []const u8, mod_type: ModType_T) ModErr_T!*const Mod_T {
    const module_root: *ModRoot_T = module_root_entry(
        mod_type
    );
    if(module_root.flags.init == 0) return ModErr_T.NoNFound;
    return module_iterator(
        @constCast(module_root),
        name,
        null,
        &opaque {
            pub fn handler(
                module: *const Mod_T,
                _: ?*const Mod_T,
                module_name: ?[]const u8,
            ) anyerror!void {
                return if(!mem.eql(module.name, module_name.?, .{ .case = true })) error.NoNFoundContinue
                    else {};
            }
        }.handler,
    ) catch |err| return switch(err) {
        ModErrInternal_T.EndOfIterator => ModErr_T.NoNFound,
        ModErrInternal_T.IteratorInternalError => ModErr_T.IteratorFailed,
    };
}

/// * install module
pub fn inmod(mod: *const Mod_T) ModErr_T!void {
    const module_root: *ModRoot_T = module_root_entry(
        resolve_mod_type(mod)
    );
    module_root.flags.init = if(module_root.flags.init == 1) module_root.flags.init else r: {
        module_root.list.init(&allocator.sba.allocator)
            catch return ModErr_T.ListInitFailed;
        break :r 1;
    };
    module_root.list.push_in_list(
        &allocator.sba.allocator,
        mod
    ) catch return ModErr_T.ListOperationError;
    calling_handler(mod, .install) catch {
        @branchHint(.unlikely);
        module_root.list.drop_on_list(
            // last vai retornar justamente o modulo que acabou de
            // ser adicionado a lista
            module_root.list.last_index() catch unreachable,
            &allocator.sba.allocator,
        ) catch return ModErr_T.ListOperationError;
    };
}

/// * remove module
pub fn rmmod(mod: *const Mod_T) ModErr_T!void {
    const module_root: *ModRoot_T = module_root_entry(
        resolve_mod_type(mod)
    );
    // esse iterator serve para colocar o index do iterator exatamente
    // no modulo que queremos
    _ = module_iterator(
        module_root,
        null,
        mod,
        &opaque {
            pub fn handler(
                module: *const Mod_T,
                module_to_find: ?*const Mod_T,
                _: ?[]const u8,
            ) anyerror!void {
                return if(module_to_find.? != module) error.NoNFoundContinue
                    else {};
            }
        }.handler,
    ) catch |err| return switch(err) {
        ModErrInternal_T.EndOfIterator => ModErr_T.NoNFound,
        ModErrInternal_T.IteratorInternalError => ModErr_T.IteratorFailed,
    };
    module_root.list.drop_on_list(
        // o index do iterator - 1 vai estar exatamente no modulo
        // que queremos
        (module_root.list.iterator_index() catch unreachable) - 1,
        &allocator.sba.allocator,
    ) catch return ModErr_T.AllocatorError; // aqui so pode dar erro do alocador
    module_root.flags.init = @intFromBool(module_root.list.how_many_nodes() > 0);
    calling_handler(mod, .remove) catch {
        @branchHint(.unlikely);
        return ModErr_T.RemovedButWithHandlerError;
    };
}
