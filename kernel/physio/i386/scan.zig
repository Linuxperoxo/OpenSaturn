// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: scan.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const root: type = @import("root");
const types: type = @import("types.zig");
const core: type = @import("core.zig");

const PhysIo_T: type = types.PhysIo_T;
const PCIPhysIo_T: type = root.kernel.io.pci.PCIPhysIo_T;
const PCIAddress_T: type = root.kernel.io.pci.PCIAddress_T;
const PCIRegsOffset_T: type = root.kernel.io.pci.PCIRegsOffset_T;

const pci_config_read = root.kernel.io.pci.pci_config_read;
const register_physio = core.register_physio;

const PCI_UNDEFINED_RETURN = root.kernel.io.pci.PCI_UNDEFINED_RETURN;

pub fn physio_scan() void {
    // TODO: O log deve ser [PCI] {domain}:{bus}:{device}.{function} {class}: {vendor} {device} (rev {revision})
    // TODO: Documentar
    // OPTIMIZE: Fazer bitwise para distribuir os regs para as classes,
    // podemos pegar vendorID deviceID em uma unica leitura, mesma coisa
    // para revision prog subclass e class, cada um desses registradores
    // tem 1 byte de tamanho, ou seja, podemos pegar os 4 de uma vez, isso
    // iria acelerar o tempo de busca
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
                @call(.always_inline, register_physio, .{
                    physConfigSpace
                });
                if(!multiFunction) break;
            }
        }
    }
}

