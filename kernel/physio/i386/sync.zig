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

const PCIPhysIo: type = root.code.lib.kernel.io.pci.PCIPhysIo;
const PCIAddress: type = root.code.lib.kernel.io.pci.PCIAddress;
const PCIRegsOffset: type = root.code.lib.kernel.io.pci.PCIRegsOffset;

const pciConfigRead = root.code.lib.kernel.io.pci.pciConfigRead;

const pci_undefined_return = root.code.lib.kernel.io.pci.pci_undefined_return;

fn tryListener(config_space: *PCIPhysIo) bool {
    const listener_found = listeners.physioListenerSearch(
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
    tree.physioRegister(null, listener_found) catch return false;
    return true;
}

// NOTE: fazer essa funcao de scan um device no PCI ser generica, isso
// vai evitar repetir codigo tanto no scan quando aqui

// TODO: Detectar os dispositivos que foram desconectados

pub fn physioSync() void {
    const regs_to_scan = [_]PCIRegsOffset {
        .vendor_id,
        .device_id,
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
            const device_exists = @call(.always_inline, &pciConfigRead, .{
                PCIAddress {
                    .register = .revision,
                    .function = @as(u3, 0),
                    .device = @as(u5, @intCast(dev)),
                    .bus = @as(u8, @intCast(bus)),
                    .enable = 1,
                },
            });
            if(device_exists == pci_undefined_return) continue;
            const multi_function: bool = ((@call(.always_inline, &pciConfigRead, .{
                PCIAddress {
                    .register = .header_type,
                    .function = @as(u3, 0),
                    .device = @as(u5, @intCast(dev)),
                    .bus = @as(u8, @intCast(bus)),
                    .enable = 1,
                },
            }) >> 7) & 0x01) == 1;
            for(0..8) |fun| {
                var phys_config_space: PCIPhysIo = .{
                    .bus = @as(u8, @intCast(bus)),
                    .device = @as(u5, @intCast(dev)),
                    .function = @as(u3, @intCast(fun)),
                    .vendor_id = 0,
                    .device_id = 0,
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
                inline for(regs_to_scan) |reg| {
                    const pci_return = @call(.always_inline, &pciConfigRead, .{
                        PCIAddress {
                            .register = reg,
                            .function = @as(u3, @intCast(fun)),
                            .device = @as(u5, @intCast(dev)),
                            .bus = @as(u8, @intCast(bus)),
                            .enable = 1,
                        },
                    });
                    if(pci_return != pci_undefined_return) @field(phys_config_space, @tagName(reg)) = @intCast(pci_return);
                }
                for(0..6) |i| {
                    const bar_offset = @intFromEnum(PCIRegsOffset.bar0) + (4 * i);
                    const bar_result = @call(.always_inline, &pciConfigRead, .{
                        PCIAddress {
                            .register = @as(PCIRegsOffset, @enumFromInt(bar_offset)),
                            .function = @as(u3, @intCast(fun)),
                            .device = @as(u5, @intCast(dev)),
                            .bus = @as(u8, @intCast(bus)),
                            .enable = 1,
                        },
                    });
                    phys_config_space.bars[i] = r: {
                        if(bar_result == 0 or bar_result == ~@as(u32, 0)) break :r null;
                        break :r .{
                            .type = @enumFromInt(bar_result & 0x01),
                            .addrs = (bar_result & ~@as(u32, if((bar_result & 0x01) == 1) 0x01 else 0x0F)),
                        };
                    };
                }
                r: {
                    const class, const vendor = aux.resolveAllIndex(
                        @enumFromInt(phys_config_space.class), @enumFromInt(phys_config_space.vendor_id)
                    );
                    _ = tree.physioSearch(
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
                                .vendor = phys_config_space.vendor_id,
                                .device_id = phys_config_space.device_id,
                            },
                        },
                    ) catch |err| switch(err) {
                        types.PhysIoErr.NonFound => {
                            if(@call(.always_inline, tryListener, .{
                                &phys_config_space
                            })) break :r {};
                            tree.physioRegister(phys_config_space, null) catch {
                                // klog();
                                break :r {};
                            };
                        },
                        else => {
                            // klog();
                            break :r {};
                        } // EO switch(err)
                    }; // EO catch tree.physioSearch
                    const wait = waiting.physioWaitSearch(phys_config_space.class, phys_config_space.vendor_id);
                    if(wait) |waitFound| {
                        waitFound(
                            tree.physioSearch(
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
                                        .vendor = phys_config_space.vendor_id,
                                        .device_id = phys_config_space.device_id,
                                    },
                                },
                            ) catch {
                                // klog();
                                break :r {};
                            }
                        );
                        waiting.physioWaitDrop(phys_config_space.class, phys_config_space.vendor_id) catch {
                            // No Critical Error
                            // klog()
                        };
                    } else |_| {}
                } // EO r:
                if(!multi_function) break;
            }
        }
    }
}
