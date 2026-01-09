// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: tree.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const pci: type = if(!builtin.is_test) @import("root").code.lib.kernel.io.pci else @import("test/types.zig");
const allocator: type = @import("allocator.zig");
const aux: type = @import("aux.zig");
const builtin: type = @import("builtin");
const test_types: type = @import("test/types.zig");
const std: type = @import("std");

const UNIDENTIFIED: u1 = 0;
const IDENTIFIED: u1 = 1;

pub var class_root = [_]?*types.VendorRoot_T {
    null,
} ** if(!builtin.is_test) @typeInfo(pci.PCIClass_T).@"enum".fields.len else
    @typeInfo(test_types.PCIClass_T).@"enum".fields.len;

// esse codigo e bem complexo, mas no futuro pretendo simplificar ao maximo
// essa parte, deixando tao simplificado quando o listeners e waiting

fn physio_mov_infos(noalias dest: *types.PhysIoInfo_T, noalias src: *const pci.PCIPhysIo_T, ident: u1, old: ?*types.PhysIo_T) types.PhysIoErr_T!void {
    if(old != null) {
        dest.* = .{
            .phys = old.?,
            .next = null,
            .brother = null,
            .prev = null,
            .older_brother = null,
        };
        return;
    }
    const phys_alloc: *types.PhysIo_T = allocator.sba.alloc_type_single(types.PhysIo_T) catch return types.PhysIoErr_T.InternalError;
    phys_alloc.* = .{
        .private = dest,
        .brothers = 0,
        .device =  src.*,
        .refs = 0,
        .status = .active,
        .flags = .{
            .find = 0,
            .hit = 1,
            .identified = ident,
            .link = 0,
            .save = 0,
        },
        .events = .{}
    };
    dest.* = .{
        .phys = phys_alloc,
        .next = null,
        .brother = null,
        .prev = null,
        .older_brother = null,
    };
}

fn try_alloc_first_brother(older_brother: *types.PhysIoInfo_T, phys: *const pci.PCIPhysIo_T, ident: u1, old: ?*types.PhysIo_T) types.PhysIoErr_T!bool {
    if(older_brother.brother == null) {
        older_brother.brother = @call(.never_inline, allocator.sba.alloc_type_single, .{
            types.PhysIoInfo_T
        }) catch return types.PhysIoErr_T.InternalError;
        try @call(.always_inline, physio_mov_infos, .{
            older_brother.brother.?, phys, ident, old
        });
        older_brother.phys.flags.identified = ident;
        older_brother.brother.?.older_brother = older_brother;
        older_brother.brother.?.prev = older_brother;
        return true;
    }
    return false;
}

fn physio_unidentified_vendor_register(class_entry: *types.VendorRoot_T, phys: *const pci.PCIPhysIo_T, old: ?*types.PhysIo_T) types.PhysIoErr_T!void {
    if(class_entry.unidentified == null) {
        class_entry.unidentified = @call(.always_inline, allocator.sba.alloc_type_single, .{
            types.PhysIoInfo_T
        }) catch return types.PhysIoErr_T.InternalError;
        try @call(.always_inline, physio_mov_infos, .{
            class_entry.unidentified.?, phys, UNIDENTIFIED, old
        });
        return;
    }
    var current: *types.PhysIoInfo_T = class_entry.unidentified.?;
    if(current.phys.device.deviceID > phys.deviceID) {
        // precisamos fazer essa primeira verificacao para alterar a propria head da lista
        const first: **types.PhysIoInfo_T = &class_entry.unidentified.?;
        first.* = @call(.always_inline, allocator.sba.alloc_type_single, .{
            types.PhysIoInfo_T
        }) catch return types.PhysIoErr_T.InternalError;
        try @call(.always_inline, physio_mov_infos, .{
            first.*, phys, UNIDENTIFIED, old
        });
        first.*.next = current;
        return;
    }
    var prev: *types.PhysIoInfo_T = class_entry.unidentified.?;
    var older_brother: ?*types.PhysIoInfo_T = null;
    const search_type: enum { independent,  brother } = .independent;
    sw: switch(search_type) {
        .independent => {
            // caso seja o primeiro irmao, entao current.next == null
            if(current.phys.device.deviceID == phys.deviceID) continue :sw .brother;
            while(current.next != null) : (current = current.next.?) {
                if(current.phys.device.deviceID == phys.deviceID) continue :sw .brother;
                if(current.phys.device.deviceID > phys.deviceID) {
                    prev.next = @call(.always_inline, allocator.sba.alloc_type_single, .{
                        types.PhysIoInfo_T
                    }) catch return types.PhysIoErr_T.InternalError;
                    try @call(.always_inline, physio_mov_infos, .{
                        prev.next.?, phys, UNIDENTIFIED, old
                    });
                    prev.next.?.next = current;
                    return;
                }
                prev = current;
            }
        },
        .brother => {
            current.phys.brothers += 1;
            older_brother = current;
            if(try @call(.always_inline, try_alloc_first_brother, .{
                current, phys, UNIDENTIFIED, old
            })) return;
            current = current.brother.?;
            while(current.next != null) : (current = current.next.?) {}
        },
    }
    current.next = @call(.always_inline, allocator.sba.alloc_type_single, .{
        types.PhysIoInfo_T
    }) catch return types.PhysIoErr_T.InternalError;
    try @call(.always_inline, physio_mov_infos, .{
        current.next.?, phys, UNIDENTIFIED, old
    });
    current.next.?.older_brother = older_brother;
    current.next.?.prev = current;
}

fn physio_identified_vendor_register(class_entry: *types.VendorRoot_T, vendor_index: u8, phys: *const pci.PCIPhysIo_T, old: ?*types.PhysIo_T) types.PhysIoErr_T!void {
    if(class_entry.identified == null) {
        @branchHint(.unlikely);
        class_entry.alloc_this_identified() catch return types.PhysIoErr_T.InternalError;
    }
    if(class_entry.identified.?[vendor_index] == null) {
        class_entry.identified.?[vendor_index] = @call(.never_inline, allocator.sba.alloc_type_single, .{
            types.PhysIoInfo_T
        }) catch return types.PhysIoErr_T.InternalError;
        try @call(.always_inline, physio_mov_infos, .{
            class_entry.identified.?[vendor_index].?, phys, IDENTIFIED, old
        });
        return;
    }
    var current: *types.PhysIoInfo_T = class_entry.identified.?[vendor_index].?;
    var older_brother: ?*types.PhysIoInfo_T = null;
    const search_type: enum { independent, brother } = .independent;
    sw: switch(search_type) {
        // caso seja o primeiro irmao, entao current.next == null
        .independent => {
            if(current.phys.device.deviceID == phys.deviceID) continue :sw .brother;
            while(current.next != null) : (current = current.next.?) {
                if(current.phys.device.deviceID == phys.deviceID) continue :sw .brother;
            }
        },
        .brother => {
            current.phys.brothers += 1;
            older_brother = current;
            if(try @call(.always_inline, try_alloc_first_brother, .{
                current, phys, IDENTIFIED, old
            })) return;
            current = current.brother.?;
            while(current.next != null) : (current = current.next.?) {}
        },
    }
    current.next = @call(.never_inline, allocator.sba.alloc_type_single, .{
        types.PhysIoInfo_T
    }) catch return types.PhysIoErr_T.InternalError;
    try @call(.always_inline, physio_mov_infos, .{
        current.next.?, phys, IDENTIFIED, old
    });
    current.next.?.older_brother = older_brother;
    current.next.?.prev = current;
}

pub fn physio_register(pci_info: ?pci.PCIPhysIo_T, old: ?*types.PhysIo_T) types.PhysIoErr_T!void {
    const phys: pci.PCIPhysIo_T = pci_info orelse old.?.device;
    const class_index, const vendor_index = @call(.always_inline, aux.resolve_all_index, .{
        @as(pci.PCIClass_T, @enumFromInt(phys.class)),
        @as(pci.PCIVendor_T, @enumFromInt(phys.vendorID))
    });
    if(class_index == null) return types.PhysIoErr_T.UnidentifiedPhysError;
    const class_entry = if(class_root[class_index.?]) |NoNull| NoNull else t: {
        @branchHint(.likely);
        class_root[class_index.?] = @call(.always_inline, allocator.sba.alloc_type_single, .{
            types.VendorRoot_T
        }) catch return types.PhysIoErr_T.InternalError;
        class_root[class_index.?].?.identified = null;
        class_root[class_index.?].?.unidentified = null;
        break :t class_root[class_index.?];
    };
    if(vendor_index == null) {
        return @call(.always_inline, physio_unidentified_vendor_register, .{
            class_entry.?, &phys, old
        });
    }
    return @call(.always_inline, physio_identified_vendor_register, .{
        class_entry.?, vendor_index.?, &phys, old
    });
}

pub fn physio_expurg(phys: *types.PhysIo_T) types.PhysIoErr_T!void {
    if(phys.status != .active) return types.PhysIoErr_T.ExpurgAnAlreadyExpurged;
    const node_info: *types.PhysIoInfo_T = @alignCast(@ptrCast(phys.private));
    const node_prev: ?*types.PhysIoInfo_T = node_info.prev;
    const node_next: ?*types.PhysIoInfo_T = node_info.next;
    r: {
        if(node_info.older_brother != null) {
            // brother
            const older_brother: *types.PhysIoInfo_T = node_info.older_brother.?;
            older_brother.phys.brothers -= 1;
            // o primeiro brother usa o prev para se conectar ao older_brother, entao
            // para saber se e o primeiro irmao, basta comparar os 2
            if(node_info.older_brother == node_info.prev) {
                older_brother.brother = node_info.next; // ligando a outro irmao, nao tem problema caso seja null
                if(node_info.next != null) {
                    node_info.next.?.prev = older_brother;
                }
                break :r {};
            }
        }
        if(node_prev != null) node_prev.?.next = node_next;
        if(node_next != null) node_next.?.prev = node_prev;
    }
    node_info.brother = null;
    node_info.next = null;
    node_info.older_brother = null;
    node_info.prev = null;
    phys.status = .missing;
    phys.flags.link = 0;
    phys.flags.hit = 0;
    phys.brothers = 0;
    @call(.always_inline, allocator.sba.free_type_single, .{
        types.PhysIoInfo_T,
        node_info
    }) catch |err| switch(err) {
        allocator.sba.AllocatorErr_T.DoubleFree => return types.PhysIoErr_T.ExpurgAnAlreadyExpurged,
        else => return types.PhysIoErr_T.InternalError,
    };
}

pub fn physio_brother(phys: *types.PhysIo_T, noalias dest: []*types.PhysIo_T) types.PhysIoErr_T!void {
    var current: ?*types.PhysIoInfo_T = @alignCast(@ptrCast(phys.private));
    if(phys.brothers == 0 or current.?.brother == null) return types.PhysIoErr_T.NoBrothers;
    if(dest.len < phys.brothers) return types.PhysIoErr_T.OutMemoryForBrothers;
    current = current.?.brother;
    for(0..dest.len) |i| {
        if(current == null) return types.PhysIoErr_T.NotAllBrothersCopied;
        dest[i] = current.?.phys;
        current = current.?.next;
    }
}

fn physio_search_identified(class: types.PhysIoClass_T, vendor: types.PhysIoVendor_T) types.PhysIoErr_T!*types.PhysIo_T {
    if(class_root[@intFromEnum(class)] == null
        or class_root[@intFromEnum(class)].?.identified.?[@intFromEnum(vendor)] == null) return types.PhysIoErr_T.NonFound;
    class_root[@intFromEnum(class)].?.identified.?[@intFromEnum(vendor)].?.phys.flags.hit = 1;
    class_root[@intFromEnum(class)].?.identified.?[@intFromEnum(vendor)].?.phys.flags.link = 1;
    return class_root[@intFromEnum(class)].?.identified.?[@intFromEnum(vendor)].?.phys;
}

fn physio_search_unidentified(class: types.PhysIoClass_T, vendor: u16, deviceID: u16) types.PhysIoErr_T!*types.PhysIo_T {
    if(class_root[@intFromEnum(class)] == null
        or class_root[@intFromEnum(class)].?.unidentified == null) return types.PhysIoErr_T.NonFound;
    var current: ?*types.PhysIoInfo_T = class_root[@intFromEnum(class)].?.unidentified.?;
    while(current != null) : (current = current.?.next) {
        if(current.?.phys.device.deviceID == deviceID) {
            if(current.?.phys.device.vendorID == vendor) return current.?.phys;
            var brother: ?*types.PhysIoInfo_T = current.?.brother;
            while(brother != null) : (brother = brother.?.next) {
                if(brother.?.phys.device.vendorID == vendor) return brother.?.phys;
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
