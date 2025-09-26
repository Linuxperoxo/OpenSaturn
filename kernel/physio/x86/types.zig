// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const PhysIO_T: type = struct {
    pub const Bus_T: type = union(enum) {
        PIC: struct {
            bus: u16,
            device: u6,
            function: u4,
            vendorID: u16,
            deviceID: u16,
            class: u8,
            subclass: u8,
            command: u16,
            status: u16,
            prog: u8,
            revision: u8,
            irq_line: u8,
            irq_pin: u8,
            bars: [6]u32,
        },

        USB: struct {
            // TODO:
        },
    };

    pub const Status_T: type = enum {
        missing,
        active,
        working
    };

    mok: usize,
    bus: Bus_T,
    status: Status_T,
};
