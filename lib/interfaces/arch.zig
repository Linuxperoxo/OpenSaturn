// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: arch.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const modules: type = @import("root").config.modules;
const fusium: type = @import("root").config.fusium;

pub const Target: type = @TypeOf(@import("root").config.arch.options.target);

pub const ArchCoreCodeImpl: type = struct {
    maintainer: []const u8,
    label: []const u8,
    entry: *const fn() callconv(.c) void,
};

pub const ArchManifest: type = struct {
    pub const ContainerExposed: type = struct {
        name: []const u8,
        container: type
    };

    target: Target,
    arch: type,
    exposed: ?[]const ContainerExposed = null,
};

pub const ArchDescription: type = struct {
    // core code implement
    init: ?ArchCoreCodeImpl = null,
    interrupts: ?ArchCoreCodeImpl = null,
    mm: ?ArchCoreCodeImpl = null,
    physio: ?ArchCoreCodeImpl = null, // NOTE: converted to module (will be removed)

    extra: ?[]const Extra = null,
    data: ?[]const Data = null,

    usable: bool,
    entry: struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.naked) noreturn,
    },
    symbols: Symbols,
    overrider: Overrider,

    pub const Extra: type = struct {
        maintainer: []const u8,
        label: []const u8,
        entry: union(enum(u1)) {
            // apenas para deixar mais explicito, @ptrCast
            // e capaz de mudar o callconv, parametros e return
            c: *const fn() callconv(.c) void,
            naked: *const fn() callconv(.naked) void,

            pub fn activedField(comptime self: *const @This()) @FieldType(@This(), if(self.* == .c) "c" else "naked") {
                return switch(self.*) {
                    .c => |c| c,
                    .naked => |naked| naked,
                };
            }
        },
    };

    pub const Symbols: type = struct {
        segments: u1,
    };

    pub const Data: type = struct {
        label: []const u8,
        section: ?[]const u8,
        ptr: *const anyopaque,
    };

    pub const ModuleOverrider: type = struct {
        module: []const u8,
        value: modules.menuconfig.Load,
    };

    pub const Fusium: type = struct {
        default: ?fusium.menuconfig.Load,
        overriders: []const FusiumOverrider,
    };

    pub const FusiumOverrider: type = struct {
        fusioner: []const u8,
        value: fusium.menuconfig.Load,
    };

    pub const Overrider: type = struct {
        modules: ?[]const ModuleOverrider,
        fusioners: ?Fusium,
    };
};
