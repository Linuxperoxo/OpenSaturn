// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: aux.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const main: type = @import("main.zig");
const types: type = @import("types.zig");
const mem: type = if(!builtin.is_test) @import("root").kernel.utils.mem
    else @import("test/mem.zig");

const Mod_T: type = types.Mod_T;
const ModType_T: type = types.ModType_T;
const ModErr_T: type = types.ModErr_T;
const ModHandler_T: type = types.ModHandler_T;
const ModRoot_T: type = types.ModRoot_T;
const ModFoundByType_T: type = types.ModFoundByType_T;

pub inline fn module_root_entry(mod_type: ModType_T) *ModRoot_T {
    for(&main.modules_entries) |*entry| {
        if(entry.type == mod_type) return entry;
    }
    unreachable;
}

pub inline fn find_handler(mod_type: ModType_T) *const ModHandler_T {
    for(&main.handlers) |*handler| {
        switch(handler.*) {
            .filesystem => if(mod_type == .filesystem) return handler else continue,
            else => unreachable,
        }
    }
    unreachable;
}

pub inline fn resolve_mod_type(mod: *const Mod_T) ModType_T {
    return switch(mod.private) {
        .filesystem => ModType_T.filesystem,
        else => unreachable,
    };
}

pub inline fn calling_handler(mod: *Mod_T, comptime op: enum { install, remove }) ModErr_T!void {
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

pub fn search_by_module(module_root: *ModRoot_T, ptr: ?*const Mod_T, name: ?[]const u8) ModErr_T!struct { *Mod_T, ModFoundByType_T } {
    var param: struct {
        mod_ptr: ?*const Mod_T,
        mod_name: ?[]const u8,
        mod_found: ?ModFoundByType_T,
    } = .{
        .mod_ptr = ptr,
        .mod_name = name,
        .mod_found = null,
    };
    return .{
        module_root.list.iterator_handler(
            &param,
            &opaque {
                pub fn handler(iterator_mod: *Mod_T, mod_to_found: @TypeOf(&param)) anyerror!void {
                    if(mod_to_found.mod_ptr != null and iterator_mod == mod_to_found.mod_ptr.?) {
                        mod_to_found.mod_found = .pointer;
                        return;
                    }
                    if(mod_to_found.mod_name != null
                        and mem.eql(iterator_mod.name, mod_to_found.mod_name.?, .{ .case = true })) {
                        mod_to_found.mod_found = .pointer;
                        return;
                    }
                    return error.Continue;
                }
            }.handler,
        ) catch |err| return switch (err) {
            @TypeOf(module_root.list).ListErr_T.EndOfIterator,
            @TypeOf(module_root.list).ListErr_T.WithoutNodes => ModErr_T.NoNFound,
            else => ModErr_T.IteratorFailed,
        },
        param.mod_found.?,
    };
}
