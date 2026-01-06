// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: sync.zig        │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const root: type = @import("root");
const tree: type = @import("tree.zig");
const listeners: type = @import("listeners.zig");
const waiting: type = @import("waiting.zig");
const aux: type = @import("aux.zig");
const types: type = @import("types.zig");
const pci: type = @import("root").kernel.io.pci;

const PCIPhysIo_T: type = root.code.lib.kernel.io.pci.PCIPhysIo_T;
const PCIAddress_T: type = root.code.lib.kernel.io.pci.PCIAddress_T;
const PCIRegsOffset_T: type = root.code.lib.kernel.io.pci.PCIRegsOffset_T;

const pci_config_read = root.code.lib.kernel.io.pci.pci_config_read;

const PCI_UNDEFINED_RETURN = root.code.lib.kernel.io.pci.PCI_UNDEFINED_RETURN;

fn try_listener(config_space: *PCIPhysIo_T) bool {
    const listener_found = listeners.physio_listener_search(
        config_space.bus,
        config_space.device,
        config_space.function
    ) catch return false;
    if(listener_found.status == .missing) {
        //listener_found.status == .active;
        listener_found.flags.hit += if(listener_found.flags.hit < 2) 1 else 0;
        if(listener_found.events.connect != null) {
            listener_found.events.connect.?(listener_found);
            listener_found.flags.link = 1;
        }
    }
    tree.physio_register(null, listener_found) catch return false;
    return true;
}

// NOTE: fazer essa funcao de scan um device no PCI ser generica, isso
// vai evitar repetir codigo tanto no scan quando aqui

// TODO: Detectar os dispositivos que foram desconectados

pub fn physio_sync() void {
    const regsToScan = [_]PCIRegsOffset_T {
        .vendorID,
        .deviceID,
        .command,
        .status,
        .prog,
        .subclass,
        .class,
        .revision,
        .irq_line,
        .irq_pin,
    };
    for(0..256) |bus| {
        for(0..32) |dev| {
            const deviceExists = @call(.always_inline, &pci_config_read, .{
                PCIAddress_T {
                    .register = .revision,
                    .function = @as(u3, 0),
                    .device = @as(u5, @intCast(dev)),
                    .bus = @as(u8, @intCast(bus)),
                    .enable = 1,
                },
            });
            if(deviceExists == PCI_UNDEFINED_RETURN) continue;
            const multiFunction: bool = ((@call(.always_inline, &pci_config_read, .{
                PCIAddress_T {
                    .register = .headerType,
                    .function = @as(u3, 0),
                    .device = @as(u5, @intCast(dev)),
                    .bus = @as(u8, @intCast(bus)),
                    .enable = 1,
                },
            }) >> 7) & 0x01) == 1;
            for(0..8) |fun| {
                var physConfigSpace: PCIPhysIo_T = .{
                    .bus = @as(u8, @intCast(bus)),
                    .device = @as(u5, @intCast(dev)),
                    .function = @as(u3, @intCast(fun)),
                    .vendorID = 0,
                    .deviceID = 0,
                    .class = 0,
                    .subclass = 0,
                    .command = 0,
                    .status = null,
                    .prog = null,
                    .revision = null,
                    .irq_line = 0,
                    .irq_pin = 0,
                    .bars = .{
                        null
                    } ** 6,
                };
                inline for(regsToScan) |reg| {
                    const pciReturn = @call(.always_inline, &pci_config_read, .{
                        PCIAddress_T {
                            .register = reg,
                            .function = @as(u3, @intCast(fun)),
                            .device = @as(u5, @intCast(dev)),
                            .bus = @as(u8, @intCast(bus)),
                            .enable = 1,
                        },
                    });
                    if(pciReturn != PCI_UNDEFINED_RETURN) @field(physConfigSpace, @tagName(reg)) = @intCast(pciReturn);
                }
                for(0..6) |i| {
                    const barOffset = @intFromEnum(PCIRegsOffset_T.bar0) + (4 * i);
                    const barResult = @call(.always_inline, &pci_config_read, .{
                        PCIAddress_T {
                            .register = @as(PCIRegsOffset_T, @enumFromInt(barOffset)),
                            .function = @as(u3, @intCast(fun)),
                            .device = @as(u5, @intCast(dev)),
                            .bus = @as(u8, @intCast(bus)),
                            .enable = 1,
                        },
                    });
                    physConfigSpace.bars[i] = r: {
                        if(barResult == 0 or barResult == ~@as(u32, 0)) break :r null;
                        break :r .{
                            .type = @enumFromInt(barResult & 0x01),
                            .addrs = (barResult & ~@as(u32, if((barResult & 0x01) == 1) 0x01 else 0x0F)),
                        };
                    };
                }
                r: {
                    const class, const vendor = aux.resolve_all_index(
                        @enumFromInt(physConfigSpace.class), @enumFromInt(physConfigSpace.vendorID)
                    );
                    _ = tree.physio_search(
                        if(class != null and vendor != null)
                        .{
                            .identified = .{
                                .class = @enumFromInt(class.?),
                                .vendor = @enumFromInt(vendor.?),
                            },
                        }
                        else
                        .{
                            .unidentified = .{
                                .class = @enumFromInt(class.?),
                                .vendor = physConfigSpace.vendorID,
                                .deviceID = physConfigSpace.deviceID,
                            },
                        },
                    ) catch |err| switch(err) {
                        types.PhysIoErr_T.NonFound => {
                            if(@call(.always_inline, try_listener, .{
                                &physConfigSpace
                            })) break :r {};
                            tree.physio_register(physConfigSpace, null) catch {
                                // klog();
                                break :r {};
                            };
                        },
                        else => {
                            // klog();
                            break :r {};
                        } // EO switch(err)
                    }; // EO catch tree.physio_search
                    const wait = waiting.physio_wait_search(physConfigSpace.class, physConfigSpace.vendorID);
                    if(wait) |wait_found| {
                        wait_found(
                            tree.physio_search(
                                if(class != null and vendor != null)
                                .{
                                    .identified = .{
                                        .class = @enumFromInt(class.?),
                                        .vendor = @enumFromInt(vendor.?),
                                    },
                                }
                                else
                                .{
                                    .unidentified = .{
                                        .class = @enumFromInt(class.?),
                                        .vendor = physConfigSpace.vendorID,
                                        .deviceID = physConfigSpace.deviceID,
                                    },
                                },
                            ) catch {
                                // klog();
                                break :r {};
                            }
                        );
                        waiting.physio_wait_drop(physConfigSpace.class, physConfigSpace.vendorID) catch {
                            // No Critical Error
                            // klog()
                        };
                    } else |_| {}
                } // EO r:
                if(!multiFunction) break;
            }
        }
    }
}
