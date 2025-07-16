pub const idtEntry_T: type = @import("interrupts.zig").idtEntry_T;
pub const lidt_T: type = @import("interfaces.zig").lidt_T;

pub const init: fn() void = @import("management.zig").init;
