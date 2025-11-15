// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test_tree.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const std: type = @import("std");
const types: type = @import("types.zig");
const tree: type = @import("tree.zig");
const test_types: type = @import("test/types.zig");

const PCIPhysIo_T: type = test_types.PCIPhysIo_T;
const PCIClass_T: type = test_types.PCIClass_T;
const PCIVendor_T: type = test_types.PCIVendor_T;

// === Teste Info ===
//
// OS: Gentoo Linux x86_64
// Zig: 0.15.2
// Tester: Linuxperoxo
// Status: MAYBE - FAILED WITH zig test -OReleaseSmall

// esse teste e bem grande, e eu preferi fazer uma parte separada
// para cada coisa, isso aumentou bastante o tamanho do codigo, mas
// podemos ter pelo menos que no userspace linux esta funcionando

const TestErr_T: type = error {
    FoundSomeDiff,
    ExistsButNotFound,
    BrotherHasBrother,
    BrotherNotLinked,
    BrothersDiffQuant,
    NoBrotherFree,
};

inline fn tree_clean() void {
    // esse funcao serve apenas para limpar a arvore,
    // isso so deve ser usado no teste, para evitar
    // problemas quanto executamos todos os testes
    // de uma vez
    for(0..tree.class_root.len) |i| {
        tree.class_root[i] = null;
    }
}

test "PhysIo Tree Brothers Identified Test" {
    const total_of_brothers: comptime_int = 14;
    var physio: PCIPhysIo_T = .{
        .bus = 0,
        .device = 0,
        .function = 0,
        .vendorID = @intCast(@intFromEnum(PCIVendor_T.amd)),
        .deviceID = 0xAB00,
        .class = @intCast(@intFromEnum(PCIClass_T.bridge)),
        .subclass = 0,
        .command = 0,
        .status = null,
        .prog = 0,
        .revision = null,
        .irq_line = 0,
        .irq_pin = 0,
        .bars = .{
            null
        } ** 6,
    };
    try tree.physio_register(physio);
    physio.bus += 1;
    for(0..total_of_brothers) |_| {
        try tree.physio_register(physio);
        physio.bus += 1;
    }
    const physio_found = tree.physio_search(
        .{
            .identified = .{
                .class = .bridge,
                .vendor = .amd,
            }
        }
    ) catch return TestErr_T.ExistsButNotFound;
    if(physio_found.brothers != total_of_brothers) return TestErr_T.BrothersDiffQuant;
    var brothers: [total_of_brothers]*types.PhysIo_T = undefined;
    try tree.physio_brother(physio_found, brothers[0..total_of_brothers]);
    for(brothers) |brother| {
        if(brother.brothers != 0) return TestErr_T.BrotherHasBrother;
        const phys_info: *types.PhysIoInfo_T = @alignCast(@ptrCast(brother.private));
        if(phys_info.brother != null) return TestErr_T.BrotherHasBrother;
        if(@intFromPtr(phys_info.older_brother) != @intFromPtr(physio_found.private)) return TestErr_T.BrotherNotLinked;
    }
    tree_clean();
}

test "PhysIo Tree Brothers Unidentified Test" {
    const total_of_brothers: comptime_int = 14;
    var physio: PCIPhysIo_T = .{
        .bus = 0,
        .device = 0,
        .function = 0,
        .vendorID = 0x9283,
        .deviceID = 0xAB00,
        .class = @intCast(@intFromEnum(PCIClass_T.bridge)),
        .subclass = 0,
        .command = 0,
        .status = null,
        .prog = 0,
        .revision = null,
        .irq_line = 0,
        .irq_pin = 0,
        .bars = .{
            null
        } ** 6,
    };
    try tree.physio_register(physio);
    physio.bus += 1;
    for(0..total_of_brothers) |_| {
        try tree.physio_register(physio);
        physio.bus += 1;
    }
    const physio_found = tree.physio_search(
        .{
            .unidentified = .{
                .class = .bridge,
                .vendor = 0x9283,
                .deviceID = 0xAB00,
            }
        }
    ) catch return TestErr_T.ExistsButNotFound;
    if(physio_found.brothers != total_of_brothers) return TestErr_T.BrothersDiffQuant;
    var brothers: [total_of_brothers]*types.PhysIo_T = undefined;
    try tree.physio_brother(physio_found, brothers[0..total_of_brothers]);
    for(brothers) |brother| {
        if(brother.brothers != 0) return TestErr_T.BrotherHasBrother;
        const phys_info: *types.PhysIoInfo_T = @alignCast(@ptrCast(brother.private));
        if(phys_info.brother != null) return TestErr_T.BrotherHasBrother;
        if(@intFromPtr(phys_info.older_brother) != @intFromPtr(physio_found.private)) return TestErr_T.BrotherNotLinked;
    }
    tree_clean();
}

test "PhysIo Tree Register Test" {
    var physio: PCIPhysIo_T = .{
        .bus = 0,
        .device = 0,
        .function = 0,
        .vendorID = 0,
        .deviceID = 0xAB00,
        .class = 0,
        .subclass = 0,
        .command = 0,
        .status = null,
        .prog = 0,
        .revision = null,
        .irq_line = 0,
        .irq_pin = 0,
        .bars = .{
            null
        } ** 6,
    };
    inline for(0..6) |c| {
        physio.class = @intCast(@typeInfo(PCIClass_T).@"enum".fields[c].value);
        inline for(0..11) |v| {
            physio.vendorID = @intCast(@typeInfo(PCIVendor_T).@"enum".fields[v].value);
            try tree.physio_register(physio);
            const physio_found = tree.physio_search(
                .{
                    .identified = .{
                        .class = @as(types.PhysIoClass_T, @enumFromInt(@typeInfo(types.PhysIoClass_T).@"enum".fields[c].value)),
                        .vendor = @as(types.PhysIoVendor_T, @enumFromInt(@typeInfo(types.PhysIoVendor_T).@"enum".fields[v].value)),
                    }
                }
            ) catch return TestErr_T.ExistsButNotFound;
            if(physio_found.device.class != physio.class or physio_found.device.vendorID != physio.vendorID)
                return TestErr_T.FoundSomeDiff;
        }
    }
    tree_clean();
}

test "PhysIo Tree Register Unidentified Test" {
    var physio: PCIPhysIo_T = .{
        .bus = 0,
        .device = 0,
        .function = 0,
        .vendorID = 0,
        .deviceID = 0xAB00,
        .class = 0,
        .subclass = 0,
        .command = 0,
        .status = null,
        .prog = 0,
        .revision = null,
        .irq_line = 0,
        .irq_pin = 0,
        .bars = .{
            null
        } ** 6,
    };
    inline for(0..6) |c| {
        physio.class = @intCast(@typeInfo(PCIClass_T).@"enum".fields[c].value);
        inline for(0..11) |v| {
            physio.vendorID = @intCast(v);
            try tree.physio_register(physio);
            const physio_found = tree.physio_search(
                .{
                    .unidentified = .{
                        .class = @as(types.PhysIoClass_T, @enumFromInt(@typeInfo(types.PhysIoClass_T).@"enum".fields[c].value)),
                        .vendor = physio.vendorID,
                        .deviceID = physio.deviceID,
                    }
                }
            ) catch return TestErr_T.ExistsButNotFound;
            if(physio_found.device.class != physio.class or physio_found.device.vendorID != physio.vendorID)
                return TestErr_T.FoundSomeDiff;
        }
    }
    tree_clean();
}

test "PhysIo Tree Register Unidentified DeviceID Collision Test" {
    const base_vendorID: comptime_int = 0xAB00;
    var physio: PCIPhysIo_T = .{
        .bus = 0,
        .device = 0,
        .function = 0,
        .vendorID = 0,
        .deviceID = 0xAB00,
        .class = @intFromEnum(PCIClass_T.storage),
        .subclass = 0,
        .command = 0,
        .status = null,
        .prog = 0,
        .revision = null,
        .irq_line = 0,
        .irq_pin = 0,
        .bars = .{
            null
        } ** 6,
    };
    for(0..32) |d| {
        physio.vendorID = @intCast(base_vendorID + d);
        try tree.physio_register(physio);
    }
    for(0..32) |d| {
        const physio_found: *types.PhysIo_T = tree.physio_search(.{
            .unidentified = .{
                .class = .storage,
                .deviceID = 0xAB00,
                .vendor = @intCast(base_vendorID + d),
            }
        }) catch return TestErr_T.ExistsButNotFound;
        if(physio_found.device.vendorID != base_vendorID + d)
            return TestErr_T.FoundSomeDiff;
    }
    tree_clean();
}

test "PhysIo Tree Register Unidentified VendorID Collision Test" {
    const base_deviceID: comptime_int = 0xAB00;
    var physio: PCIPhysIo_T = .{
        .bus = 0,
        .device = 0,
        .function = 0,
        .vendorID = 0x7162,
        .deviceID = 0,
        .class =  @intFromEnum(PCIClass_T.storage),
        .subclass = 0,
        .command = 0,
        .status = null,
        .prog = 0,
        .revision = null,
        .irq_line = 0,
        .irq_pin = 0,
        .bars = .{
            null
        } ** 6,
    };
    for(0..32) |d| {
        physio.deviceID = @intCast(base_deviceID + d);
        try tree.physio_register(physio);
    }
    for(0..32) |d| {
        const physio_found: *types.PhysIo_T = tree.physio_search(
            .{
                .unidentified = .{
                    .class = .storage,
                    .deviceID = @intCast(base_deviceID + d),
                    .vendor = 0x7162,
                }
            }
        ) catch return TestErr_T.ExistsButNotFound;
        if(physio_found.device.deviceID != base_deviceID + d)
            return TestErr_T.FoundSomeDiff;
    }
    tree_clean();
}

test "PhysIo Tree Register Expurg Identified Brothers Test" {
    const total_of_brothers: comptime_int = 14;
    var physio: PCIPhysIo_T = .{
        .bus = 0,
        .device = 0,
        .function = 0,
        .vendorID = @intCast(@intFromEnum(PCIVendor_T.amd)),
        .deviceID = 0xAB00,
        .class = @intCast(@intFromEnum(PCIClass_T.bridge)),
        .subclass = 0,
        .command = 0,
        .status = null,
        .prog = 0,
        .revision = null,
        .irq_line = 0,
        .irq_pin = 0,
        .bars = .{
            null
        } ** 6,
    };
    try tree.physio_register(physio);
    physio.bus += 1;
    for(0..total_of_brothers) |_| {
        try tree.physio_register(physio);
        physio.bus += 1;
    }
    const physio_found = tree.physio_search(
        .{
            .identified = .{
                .class = .bridge,
                .vendor = .amd,
            }
        }
    ) catch return TestErr_T.ExistsButNotFound;
    if(physio_found.brothers != total_of_brothers) return TestErr_T.BrothersDiffQuant;
    var brothers: [total_of_brothers]*types.PhysIo_T = undefined;
    try tree.physio_brother(physio_found, brothers[0..total_of_brothers]);
    for(brothers, 0..) |brother, i| {
        try tree.physio_expurg(brother);
        if(physio_found.brothers == total_of_brothers - i) return TestErr_T.NoBrotherFree;
        var buffer: [total_of_brothers]*types.PhysIo_T = undefined;
        if(physio_found.brothers > 1)
            try tree.physio_brother(physio_found, buffer[0..total_of_brothers - (i + 1)]);
        for(buffer) |buffer_brother| {
            if(buffer_brother ==  brother) return TestErr_T.NoBrotherFree;
        }
        buffer[total_of_brothers - (i + 1)] = @ptrFromInt(0x10);
    }
    try tree.physio_expurg(physio_found);
    tree.physio_expurg(physio_found) catch {
        tree_clean(); return;
    };
    unreachable;
}

test "PhysIo Tree Register Expurg Unidentified Brothers Test" {
    const total_of_brothers: comptime_int = 14;
    var physio: PCIPhysIo_T = .{
        .bus = 0,
        .device = 0,
        .function = 0,
        .vendorID = 0x7232,
        .deviceID = 0xAB00,
        .class = @intCast(@intFromEnum(PCIClass_T.bridge)),
        .subclass = 0,
        .command = 0,
        .status = null,
        .prog = 0,
        .revision = null,
        .irq_line = 0,
        .irq_pin = 0,
        .bars = .{
            null
        } ** 6,
    };
    try tree.physio_register(physio);
    physio.bus += 1;
    for(0..total_of_brothers) |_| {
        try tree.physio_register(physio);
        physio.bus += 1;
    }
    const physio_found = tree.physio_search(
        .{
            .unidentified = .{
                .class = .bridge,
                .vendor = 0x7232,
                .deviceID = 0xAB00,
            }
        }
    ) catch return TestErr_T.ExistsButNotFound;
    if(physio_found.brothers != total_of_brothers) return TestErr_T.BrothersDiffQuant;
    var brothers: [total_of_brothers]*types.PhysIo_T = undefined;
    try tree.physio_brother(physio_found, brothers[0..total_of_brothers]);
    for(brothers, 0..) |brother, i| {
        try tree.physio_expurg(brother);
        if(physio_found.brothers == total_of_brothers - i) return TestErr_T.NoBrotherFree;
        var buffer: [total_of_brothers]*types.PhysIo_T = undefined;
        if(physio_found.brothers > 1)
            try tree.physio_brother(physio_found, buffer[0..total_of_brothers - (i + 1)]);
        for(buffer) |buffer_brother| {
            if(buffer_brother ==  brother) return TestErr_T.NoBrotherFree;
        }
        buffer[total_of_brothers - (i + 1)] = @ptrFromInt(0x10);
    }
    try tree.physio_expurg(physio_found);
    tree.physio_expurg(physio_found) catch {
        tree_clean(); return;
    };
    unreachable;
}
