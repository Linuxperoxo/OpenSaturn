// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fun.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const PhysIo_T: type = @import("types.zig").PhysIo_T;

const ports: type = @import("root").kernel.io.ports;
const pci: type = @import("root").kernel.io.pci;

const physIoRegister = @import("core.zig").physIoRegister;

pub fn physIoScan() void {
    // TODO: Documentar
    // TODO: Fazer o klog, aqui so deve mostrar os dispositivos achados caso
    // a config de verbose esteja iniciada
    const regsToScan = [_]pci.PCIRegsOffset_T {
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
            const deviceExists = @call(.always_inline, &pci.pci_config_read, .{
                pci.PCIAddress_T {
                    .register = .vendorID,
                    .function = @as(u3, 0),
                    .device = @as(u5, @intCast(dev)),
                    .bus = @as(u8, @intCast(bus)),
                    .enable = 1,
                },
            });
            if(deviceExists == pci.PCI_UNDEFINED_RETURN) continue;
            const multiFunction: bool = ((@call(.always_inline, &pci.pci_config_read, .{
                pci.PCIAddress_T {
                    .register = .headerType,
                    .function = @as(u3, 0),
                    .device = @as(u5, @intCast(dev)),
                    .bus = @as(u8, @intCast(bus)),
                    .enable = 1,
                },
            }) >> 7) & 0x01) == 1;
            for(0..8) |fun| {
                var physConfigSpace: PhysIo_T = .{
                    .device = .{
                        .bus = @as(u8, @intCast(bus)),
                        .device = @as(u5, @intCast(dev)),
                        .function = @as(u3, @intCast(fun)),
                        .vendorID = null,
                        .deviceID = null,
                        .class = null,
                        .subclass = null,
                        .command = null,
                        .status = null,
                        .prog = null,
                        .revision = null,
                        .irq_line = null,
                        .irq_pin = null,
                        .bars = .{
                            null
                        } ** 6,
                    },
                };
                inline for(regsToScan) |reg| {
                    const pciReturn = @call(.always_inline, &pci.pci_config_read, .{
                        pci.PCIAddress_T {
                            .register = reg,
                            .function = @as(u3, @intCast(fun)),
                            .device = @as(u5, @intCast(dev)),
                            .bus = @as(u8, @intCast(bus)),
                            .enable = 1,
                        },
                    });
                    if(pciReturn != pci.PCI_UNDEFINED_RETURN) @field(physConfigSpace.device, @tagName(reg)) = @intCast(pciReturn);
                }
                for(0..6) |i| {
                    const barOffset = @intFromEnum(pci.PCIRegsOffset_T.bar0) + (4 * i);
                    const barResult = @call(.always_inline, &pci.pci_config_read, .{
                        pci.PCIAddress_T {
                            .register = @as(pci.PCIRegsOffset_T, @enumFromInt(barOffset)),
                            .function = @as(u3, @intCast(fun)),
                            .device = @as(u5, @intCast(dev)),
                            .bus = @as(u8, @intCast(bus)),
                            .enable = 1,
                        },
                    });
                    physConfigSpace.device.bars[i] = r: {
                        if(barResult == 0 or barResult == ~ @as(u32, 0)) break :r null;
                        break :r .{
                            .type = @enumFromInt(barResult & 0x01),
                            .addrs = (barResult & ~@as(u32, if((barResult & 0x01) == 1) 0x01 else 0x0F)),
                        };
                    };
                }
                @call(.always_inline, &physIoRegister, .{
                });
                if(!multiFunction) break;
            }
        }
    }
}

pub fn physIoConfig() void {

}

pub fn physIoMakeName() []const u8 {

}
