// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: tree.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const pci: type = if(!builtin.is_test) @import("root").kernel.io.pci else @import("test.zig");
const allocator: type = @import("allocator.zig");
const aux: type = @import("aux.zig");
const builtin: type = @import("builtin");
const @"test": type = @import("test.zig");

const UNIDENTIFIED: u1 = 0;
const IDENTIFIED: u1 = 1;

var class_root = [_]?*types.VendorRoot_T {
    null,
} ** if(!builtin.is_test) @typeInfo(pci.PCIClass_T).@"enum".fields.len else
    @typeInfo(@"test".PCIClass_T).@"enum".fields.len;

fn physio_mov_infos(noalias dest: *types.PhysIoInfo_T, noalias src: *const pci.PCIPhysIo_T, ident: u1) void {
    dest.* = types.PhysIoInfo_T {
        .phys = .{
            .device = src.*,
            .status = .active,
            .refs = 0,
            .flags = .{
                .find = 1,
                .hit = 0,
                .link = 0,
                .save = 0,
                .identified = ident,
            },
            .private = dest,
        },
        .next = null,
        .prev = null,
        .brother = null,
    };
}

fn physio_unidentified_vendor_register(class_entry: *types.VendorRoot_T, phys: *const pci.PCIPhysIo_T) types.PhysIoErr_T!void {
    if(class_entry.unidentified == null) {
        class_entry.unidentified = @call(.always_inline, types.PhysIoInfo_T.alloc_this, .{}) catch return types.PhysIoErr_T.InternalError;
        @call(.always_inline, physio_mov_infos, .{
            class_entry.unidentified.?, phys, UNIDENTIFIED
        });
        return;
    }
    var current: *types.PhysIoInfo_T = class_entry.unidentified.?;
    if(current.phys.device.deviceID.? > phys.deviceID.?) {
        // precisamos fazer essa primeira verificacao para alterar a propria head da lista
        const first: **types.PhysIoInfo_T = &class_entry.unidentified.?;
        first.* = @call(.always_inline, types.PhysIoInfo_T.alloc_this, .{}) catch return types.PhysIoErr_T.InternalError;
        @call(.always_inline, physio_mov_infos, .{
            first.*, phys, UNIDENTIFIED
        });
        first.*.next = current;
        return;
    }
    var prev: *types.PhysIoInfo_T = class_entry.unidentified.?;
    const search_type: enum { independent, brother } = .independent;
    sw: switch(search_type) {
        .independent => while(current.next != null) : (current = current.next.?) {
            if(current.phys.device.deviceID.? > phys.deviceID.?) {
                prev.next = @call(.always_inline, types.PhysIoInfo_T.alloc_this, .{}) catch return types.PhysIoErr_T.InternalError;
                @call(.always_inline, physio_mov_infos, .{
                    prev.next.?, phys, UNIDENTIFIED
                });
                prev.next.?.next = current;
                return;
            }
            if(current.phys.device.deviceID.? == phys.deviceID.?) {
                if(current.brother == null) {
                    current.brother = @call(.never_inline, types.PhysIoInfo_T.alloc_this, .{}) catch return types.PhysIoErr_T.InternalError;
                    @call(.always_inline, physio_mov_infos, .{
                        current.brother.?, phys, UNIDENTIFIED
                    });
                    return;
                }
                continue :sw .brother;
            }
            prev = current;
        },
        .brother => while(current.next != null) : (current = current.next.?) {},
    }
    current.next = @call(.always_inline, types.PhysIoInfo_T.alloc_this, .{}) catch return types.PhysIoErr_T.InternalError;
    @call(.always_inline, physio_mov_infos, .{
        current.next.?, phys, UNIDENTIFIED
    });
    current.next.?.prev = current;
}

fn physio_identified_vendor_register(class_entry: *types.VendorRoot_T, vendor_index: u8, phys: *const pci.PCIPhysIo_T) types.PhysIoErr_T!void {
    if(class_entry.identified == null) {
        @branchHint(.unlikely);
        class_entry.alloc_this_identified() catch return types.PhysIoErr_T.InternalError;
    }
    if(class_entry.identified.?[vendor_index] == null) {
        class_entry.identified.?[vendor_index] = @call(.never_inline, types.PhysIoInfo_T.alloc_this, .{}) catch return types.PhysIoErr_T.InternalError;
        @call(.always_inline, physio_mov_infos, .{
            class_entry.identified.?[vendor_index].?, phys, IDENTIFIED
        });
        return;
    }
    var current: *types.PhysIoInfo_T = class_entry.identified.?[vendor_index].?;
    const search_type: enum { independent, brother } = .independent;
    sw: switch(search_type) {
        .independent => while(current.next != null) : (current = current.next.?) {
            if(current.phys.device.deviceID.? == phys.deviceID.?) {
                if(current.brother == null) {
                    current.brother = @call(.never_inline, types.PhysIoInfo_T.alloc_this, .{}) catch return types.PhysIoErr_T.InternalError;
                    @call(.always_inline, physio_mov_infos, .{
                        current.brother.?, phys, IDENTIFIED
                    });
                    return;
                }
                continue :sw .brother;
            }
        },
        .brother => while(current.next != null) : (current = current.next.?) {},
    }
    current.next = @call(.never_inline, types.PhysIoInfo_T.alloc_this, .{}) catch return types.PhysIoErr_T.InternalError;
    @call(.always_inline, physio_mov_infos, .{
        current.next.?, phys, IDENTIFIED
    });
    current.next.?.prev = current;
}

pub fn physio_register(phys: pci.PCIPhysIo_T) types.PhysIoErr_T!void {
    return if(phys.class == null or phys.vendorID == null) types.PhysIoErr_T.UnableRegister else r: {
        const class_index, const vendor_index = @call(.always_inline, aux.resolve_all_index, .{
            @as(pci.PCIClass_T, @enumFromInt(phys.class.?)),
            @as(pci.PCIVendor_T, @enumFromInt(phys.vendorID.?))
        });
        if(class_index == null) return types.PhysIoErr_T.UnidentifiedPhysError;
        const class_entry = if(class_root[class_index.?]) |NoNull| NoNull else t: {
            @branchHint(.likely);
            const branch = allocator.sba.alloc(
                @sizeOf(types.VendorRoot_T)
            ) catch return types.PhysIoErr_T.InternalError;
            class_root[class_index.?] = @alignCast(@ptrCast(branch.ptr));
            class_root[class_index.?].?.identified = null;
            class_root[class_index.?].?.unidentified = null;
            break :t class_root[class_index.?];
        };
        if(vendor_index == null) {
            break :r @call(.always_inline, physio_unidentified_vendor_register, .{
                class_entry.?, &phys
            });
        }
        break :r @call(.always_inline, physio_identified_vendor_register, .{
            class_entry.?, vendor_index.?, &phys
        });
    };
}

pub fn physio_expurg(phys: *types.PhysIo_T) types.PhysIoErr_T!void {
    const node_info: *types.PhysIoInfo_T = @alignCast(@ptrCast(phys.private));
    const node_prev: *types.PhysIoInfo_T = node_info.prev;
    const node_next: *types.PhysIoInfo_T = node_info.next;
    types.PhysIoInfo_T.free_this(node_info) catch types.PhysIoErr_T.InternalError;
    if(node_prev != null)
        node_prev.next = node_next;
    if(node_next != null)
        node_next.prev = node_prev;
}

fn physio_search_identified(class: types.PhysIoClass_T, vendor: types.PhysIoVendor_T) types.PhysIoErr_T!*types.PhysIo_T {
    if(class_root[@intFromEnum(class)] == null
        or class_root[@intFromEnum(class)].?.identified.?[@intFromEnum(vendor)] == null) return types.PhysIoErr_T.NonFound;
    return &class_root[@intFromEnum(class)].?.identified.?[@intFromEnum(vendor)].?.phys;
}

fn physio_search_unidentified(class: types.PhysIoClass_T, vendor: u16, deviceID: u16) types.PhysIoErr_T!*types.PhysIo_T {
    if(class_root[@intFromEnum(class)] == null
        or class_root[@intFromEnum(class)].?.unidentified == null) return types.PhysIoErr_T.NonFound;
    var current: ?*types.PhysIoInfo_T = class_root[@intFromEnum(class)].?.unidentified.?;
    while(current != null) : (current = current.?.next) {
        if(current.?.phys.device.deviceID.? == deviceID) {
            if(current.?.phys.device.vendorID.? == vendor) return &current.?.phys;
            var brother: ?*types.PhysIoInfo_T = current.?.brother;
            while(brother != null) : (brother = brother.?.next) {
                if(brother.?.phys.device.vendorID == vendor) return &brother.?.phys;
            }
        }
    }
    return types.PhysIoErr_T.NonFound;
}

pub fn physio_search(
    phys: union(enum(u1)) {
        identified: struct {
            class: types.PhysIoClass_T,
            vendor: types.PhysIoVendor_T,
        },
        unidentified: struct {
            class: types.PhysIoClass_T,
            vendor: u16,
            deviceID: u16,
        },
    },
) types.PhysIoErr_T!*types.PhysIo_T {
    return switch(phys) {
        .identified => |fields| @call(.always_inline, physio_search_identified, .{
            fields.class, fields.vendor
        }),
        .unidentified => |fields| @call(.always_inline, physio_search_unidentified, .{
            fields.class, fields.vendor, fields.deviceID
        }),
    };
}
