// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: arch.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const modules: type = @import("root").config.modules;
const fusium: type = @import("root").config.fusium;

pub const Target_T: type = @TypeOf(@import("root").config.arch.options.Target);

pub const ArchCoreCodeImpl_T: type = struct {
    maintainer: []const u8,
    label: []const u8,
    entry: *const fn() callconv(.c) void,
};

pub const ArchManifest_T: type = struct {
    pub const ContainerExposed_T: type = struct {
        name: []const u8,
        container: type
    };

    target: Target_T,
    arch: type,
    exposed: ?[]const ContainerExposed_T = null,
};

pub const ArchDescription_T: type = struct {
    // core code implement
    init: ?ArchCoreCodeImpl_T = null,
    interrupts: ?ArchCoreCodeImpl_T = null,
    mm: ?ArchCoreCodeImpl_T = null,
    physio: ?ArchCoreCodeImpl_T = null, // NOTE: converted to module (will be removed)

    allocators: ?Allocators_T = null,

    extra: ?[]const Extra_T = null,
    data: ?[]const Data_T = null,

    usable: bool,
    entry: struct {
        maintainer: []const u8,
        label: []const u8,
        entry: *const fn() callconv(.naked) noreturn,
    },
    symbols: Symbols_T,
    overrider: Overrider_T,

    pub const Allocation_T: type = struct {
        private: *anyopaque,
        ptr: []u8,
    };

    pub const Allocator_T: type = struct {
        page: usize,
        alloc_fn: *const fn() anyerror!Allocation_T,
        free_fn: *const fn(*anyopaque) anyerror!void,
    };

    pub const Allocators_T: type = struct {
        spea: ?Allocator_T,
    };

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
