// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: tree.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const pci: type = @import("root").__SaturnArchImpl__.lib.kernel.io.pci;
const allocator: type = @import("allocator.zig");
const aux: type = @import("aux.zig");

const unidentified: u1 = 0;
const identified: u1 = 1;

pub var class_root = [_]?*types.VendorRoot {
    null,
} ** @typeInfo(pci.PCIClass).@"enum".fields.len;

// esse codigo e bem complexo, mas no futuro pretendo simplificar ao maximo
// essa parte, deixando tao simplificado quando o listeners e waiting

fn physioMovInfos(noalias dest: *types.PhysIoInfo, noalias src: *const pci.PCIPhysIo, ident: u1, old: ?*types.PhysIo) types.PhysIoErr!void {
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
    const phys_alloc: *types.PhysIo = allocator.sba.allocTypeSingle(types.PhysIo) catch return types.PhysIoErr.InternalError;
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

fn tryAllocFirstBrother(older_brother: *types.PhysIoInfo, phys: *const pci.PCIPhysIo, ident: u1, old: ?*types.PhysIo) types.PhysIoErr!bool {
    if(older_brother.brother == null) {
        older_brother.brother = @call(.never_inline, allocator.sba.allocTypeSingle, .{
            types.PhysIoInfo
        }) catch return types.PhysIoErr.InternalError;
        try @call(.always_inline, physioMovInfos, .{
            older_brother.brother.?, phys, ident, old
        });
        older_brother.phys.flags.identified = ident;
        older_brother.brother.?.older_brother = older_brother;
        older_brother.brother.?.prev = older_brother;
        return true;
    }
    return false;
}

fn physioUnidentifiedVendorRegister(class_entry: *types.VendorRoot, phys: *const pci.PCIPhysIo, old: ?*types.PhysIo) types.PhysIoErr!void {
    if(class_entry.unidentified == null) {
        class_entry.unidentified = @call(.always_inline, allocator.sba.allocTypeSingle, .{
            types.PhysIoInfo
        }) catch return types.PhysIoErr.InternalError;
        try @call(.always_inline, physioMovInfos, .{
            class_entry.unidentified.?, phys, unidentified, old
        });
        return;
    }
    var current: *types.PhysIoInfo = class_entry.unidentified.?;
    if(current.phys.device.device_id > phys.device_id) {
        // precisamos fazer essa primeira verificacao para alterar a propria head da lista
        const first: **types.PhysIoInfo = &class_entry.unidentified.?;
        first.* = @call(.always_inline, allocator.sba.allocTypeSingle, .{
            types.PhysIoInfo
        }) catch return types.PhysIoErr.InternalError;
        try @call(.always_inline, physioMovInfos, .{
            first.*, phys, unidentified, old
        });
        first.*.next = current;
        return;
    }
    var prev: *types.PhysIoInfo = class_entry.unidentified.?;
    var older_brother: ?*types.PhysIoInfo = null;
    const search_type: enum { independent,  brother } = .independent;
    sw: switch(search_type) {
        .independent => {
            // caso seja o primeiro irmao, entao current.next == null
            if(current.phys.device.device_id == phys.device_id) continue :sw .brother;
            while(current.next != null) : (current = current.next.?) {
                if(current.phys.device.device_id == phys.device_id) continue :sw .brother;
                if(current.phys.device.device_id > phys.device_id) {
                    prev.next = @call(.always_inline, allocator.sba.allocTypeSingle, .{
                        types.PhysIoInfo
                    }) catch return types.PhysIoErr.InternalError;
                    try @call(.always_inline, physioMovInfos, .{
                        prev.next.?, phys, unidentified, old
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
            if(try @call(.always_inline, tryAllocFirstBrother, .{
                current, phys, unidentified, old
            })) return;
            current = current.brother.?;
            while(current.next != null) : (current = current.next.?) {}
        },
    }
    current.next = @call(.always_inline, allocator.sba.allocTypeSingle, .{
        types.PhysIoInfo
    }) catch return types.PhysIoErr.InternalError;
    try @call(.always_inline, physioMovInfos, .{
        current.next.?, phys, unidentified, old
    });
    current.next.?.older_brother = older_brother;
    current.next.?.prev = current;
}

fn physioIdentifiedVendorRegister(class_entry: *types.VendorRoot, vendor_index: u8, phys: *const pci.PCIPhysIo, old: ?*types.PhysIo) types.PhysIoErr!void {
    if(class_entry.identified == null) {
        @branchHint(.unlikely);
        class_entry.allocThisIdentified() catch return types.PhysIoErr.InternalError;
    }
    if(class_entry.identified.?[vendor_index] == null) {
        class_entry.identified.?[vendor_index] = @call(.never_inline, allocator.sba.allocTypeSingle, .{
            types.PhysIoInfo
        }) catch return types.PhysIoErr.InternalError;
        try @call(.always_inline, physioMovInfos, .{
            class_entry.identified.?[vendor_index].?, phys, identified, old
        });
        return;
    }
    var current: *types.PhysIoInfo = class_entry.identified.?[vendor_index].?;
    var older_brother: ?*types.PhysIoInfo = null;
    const search_type: enum { independent, brother } = .independent;
    sw: switch(search_type) {
        // caso seja o primeiro irmao, entao current.next == null
        .independent => {
            if(current.phys.device.device_id == phys.device_id) continue :sw .brother;
            while(current.next != null) : (current = current.next.?) {
                if(current.phys.device.device_id == phys.device_id) continue :sw .brother;
            }
        },
        .brother => {
            current.phys.brothers += 1;
            older_brother = current;
            if(try @call(.always_inline, tryAllocFirstBrother, .{
                current, phys, identified, old
            })) return;
            current = current.brother.?;
            while(current.next != null) : (current = current.next.?) {}
        },
    }
    current.next = @call(.never_inline, allocator.sba.allocTypeSingle, .{
        types.PhysIoInfo
    }) catch return types.PhysIoErr.InternalError;
    try @call(.always_inline, physioMovInfos, .{
        current.next.?, phys, identified, old
    });
    current.next.?.older_brother = older_brother;
    current.next.?.prev = current;
}

pub fn physioRegister(pci_info: ?pci.PCIPhysIo, old: ?*types.PhysIo) types.PhysIoErr!void {
    const phys: pci.PCIPhysIo = pci_info orelse old.?.device;
    const class_index, const vendor_index = @call(.always_inline, aux.resolveAllIndex, .{
        @as(pci.PCIClass, @enumFromInt(phys.class)),
        @as(pci.PCIVendor, @enumFromInt(phys.vendor_id))
    });
    if(class_index == null) return types.PhysIoErr.UnidentifiedPhysError;
    const class_entry = if(class_root[class_index.?]) |non_null| non_null else t: {
        @branchHint(.likely);
        class_root[class_index.?] = @call(.always_inline, allocator.sba.allocTypeSingle, .{
            types.VendorRoot
        }) catch return types.PhysIoErr.InternalError;
        class_root[class_index.?].?.identified = null;
        class_root[class_index.?].?.unidentified = null;
        break :t class_root[class_index.?];
    };
    if(vendor_index == null) {
        return @call(.always_inline, physioUnidentifiedVendorRegister, .{
            class_entry.?, &phys, old
        });
    }
    return @call(.always_inline, physioIdentifiedVendorRegister, .{
        class_entry.?, vendor_index.?, &phys, old
    });
}

pub fn physioExpurg(phys: *types.PhysIo) types.PhysIoErr!void {
    if(phys.status != .active) return types.PhysIoErr.ExpurgAnAlreadyExpurged;
    const node_info: *types.PhysIoInfo = @alignCast(@ptrCast(phys.private));
    const node_prev: ?*types.PhysIoInfo = node_info.prev;
    const node_next: ?*types.PhysIoInfo = node_info.next;
    r: {
        if(node_info.older_brother != null) {
            // brother
            const older_brother: *types.PhysIoInfo = node_info.older_brother.?;
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
    @call(.always_inline, allocator.sba.freeTypeSingle, .{
        types.PhysIoInfo,
        node_info
    }) catch |err| switch(err) {
        allocator.sba.AllocatorErr.DoubleFree => return types.PhysIoErr.ExpurgAnAlreadyExpurged,
        else => return types.PhysIoErr.InternalError,
    };
}

pub fn physioBrother(phys: *types.PhysIo, noalias dest: []*types.PhysIo) types.PhysIoErr!void {
    var current: ?*types.PhysIoInfo = @alignCast(@ptrCast(phys.private));
    if(phys.brothers == 0 or current.?.brother == null) return types.PhysIoErr.NoBrothers;
    if(dest.len < phys.brothers) return types.PhysIoErr.OutMemoryForBrothers;
    current = current.?.brother;
    for(0..dest.len) |i| {
        if(current == null) return types.PhysIoErr.NotAllBrothersCopied;
        dest[i] = current.?.phys;
        current = current.?.next;
    }
}

fn physioSearchIdentified(class: types.PhysIoClass, vendor: types.PhysIoVendor) types.PhysIoErr!*types.PhysIo {
    if(class_root[@intFromEnum(class)] == null
        or class_root[@intFromEnum(class)].?.identified.?[@intFromEnum(vendor)] == null) return types.PhysIoErr.NonFound;
    class_root[@intFromEnum(class)].?.identified.?[@intFromEnum(vendor)].?.phys.flags.hit = 1;
    class_root[@intFromEnum(class)].?.identified.?[@intFromEnum(vendor)].?.phys.flags.link = 1;
    return class_root[@intFromEnum(class)].?.identified.?[@intFromEnum(vendor)].?.phys;
}

fn physioSearchUnidentified(class: types.PhysIoClass, vendor: u16, device_id: u16) types.PhysIoErr!*types.PhysIo {
    if(class_root[@intFromEnum(class)] == null
        or class_root[@intFromEnum(class)].?.unidentified == null) return types.PhysIoErr.NonFound;
    var current: ?*types.PhysIoInfo = class_root[@intFromEnum(class)].?.unidentified.?;
    while(current != null) : (current = current.?.next) {
        if(current.?.phys.device.device_id == device_id) {
            if(current.?.phys.device.vendor_id == vendor) return current.?.phys;
            var brother: ?*types.PhysIoInfo = current.?.brother;
            while(brother != null) : (brother = brother.?.next) {
                if(brother.?.phys.device.vendor_id == vendor) return brother.?.phys;
            }
        }
    }
    return types.PhysIoErr.NonFound;
}

pub fn physioSearch(
    phys: union(enum(u1)) {
        identified: struct {
            class: types.PhysIoClass,
            vendor: types.PhysIoVendor,
        },
        unidentified: struct {
            class: types.PhysIoClass,
            vendor: u16,
            device_id: u16,
        },
    },
) types.PhysIoErr!*types.PhysIo {
    return switch(phys) {
        .identified => |fields| @call(.always_inline, physioSearchIdentified, .{
            fields.class, fields.vendor
        }),
        .unidentified => |fields| @call(.always_inline, physioSearchUnidentified, .{
            fields.class, fields.vendor, fields.device_id
        }),
    };
}
