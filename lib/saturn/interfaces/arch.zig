// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: arch.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const modules: type = @import("root").config.modules;
const fusium: type = @import("root").config.fusium;

pub const Target_T: type = @TypeOf(@import("root").config.arch.options.Target);
pub const ArchDescription_T: type = struct {
    usable: bool,
    entry: struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.naked) noreturn,
    },
    init: ?struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.c) void,
    },
    interrupts: ?struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.c) void,
    },
    mm: ?struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.c) void,
    },
    physio: ?struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.c) void,
        sync: *const fn() void,
    },
    symbols: Symbols_T,
    extra: ?[]const Extra_T,
    data: ?[]const Data_T,
    overrider: Overrider_T,

    pub const Extra_T: type = struct {
        maintainer: []const u8,
        label: []const u8,
        entry: union(enum(u1)) {
            // apenas para deixar mais explicito, @ptrCast
            // e capaz de mudar o callconv, parametros e return
            c: *const fn() callconv(.c) void,
            naked: *const fn() callconv(.naked) void,

            pub fn actived_field(comptime self: *const @This()) @FieldType(@This(), if(self.* == .c) "c" else "naked") {
                return switch(self.*) {
                    .c => |c| c,
                    .naked => |naked| naked,
                };
            }
        },
    };

    pub const Symbols_T: type = struct {
        segments: u1,
    };

    pub const Data_T: type = struct {
        label: []const u8,
        section: ?[]const u8,
        ptr: *const anyopaque,
    };

    pub const ModuleOverrider_T: type = struct {
        module: []const u8,
        value: modules.menuconfig.Load_T,
    };

    pub const Fusium_T: type = struct {
        default: ?fusium.menuconfig.Load_T,
        overriders: []const FusiumOverrider_T,
    };

    pub const FusiumOverrider_T: type = struct {
        fusioner: []const u8,
        value: fusium.menuconfig.Load_T,
    };

    pub const Overrider_T: type = struct {
        modules: ?[]const ModuleOverrider_T,
        fusioners: ?Fusium_T,
    };
};
