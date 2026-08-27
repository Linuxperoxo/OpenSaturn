// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: scan.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const root: type = @import("root");
const types: type = @import("types.zig");
const tree: type = @import("tree.zig");

const PhysIo: type = types.PhysIo;
const PCIPhysIo: type = root.__SaturnArchImpl__.lib.kernel.io.pci.PCIPhysIo;
const PCIAddress: type = root.__SaturnArchImpl__.lib.kernel.io.pci.PCIAddress;
const PCIRegsOffset: type = root.__SaturnArchImpl__.lib.kernel.io.pci.PCIRegsOffset;

const pciConfigRead = root.__SaturnArchImpl__.lib.kernel.io.pci.pciConfigRead;
const physioRegister = tree.physioRegister;

const pci_undefined_return = root.__SaturnArchImpl__.lib.kernel.io.pci.pci_undefined_return;

pub fn physioScan() void {
    // TODO: O log deve ser [PCI] {domain}:{bus}:{device}.{function} {class}: {vendor} {device} (rev {revision})
    // TODO: Documentar
    // OPTIMIZE: Fazer bitwise para distribuir os regs para as classes,
    // podemos pegar vendor_id device_id em uma unica leitura, mesma coisa
    // para revision prog subclass e class, cada um desses registradores
    // tem 1 byte de tamanho, ou seja, podemos pegar os 4 de uma vez, isso
    // iria acelerar o tempo de busca
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
                @call(.always_inline, physioRegister, .{
                    phys_config_space, null
                }) catch {};
                if(!multi_function) break;
            }
        }
    }
}
