const interfaces: type = @import("root").interfaces;

pub const __SaturnFusiumDescription__: interfaces.fusium.FusiumDescription_T  = .{
    .arch = &[_]interfaces.fusium.FusiumDescriptionTarget_T {
        .i386,
    },
    .author = "Linuxperoxo",
    .flags = .{
        .blocked = 0,
    },
    .fusioner = struct { pub fn some() void { @compileError(""); } },
    .init = null,
    .name = "some1",
};
