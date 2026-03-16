const main: type = @import("main.zig");
const ops: type = @import("ops.zig");
const devices: type = @import("devices.zig");
const types: type = @import("types.zig");

test "Device Operations" {
    var dev = comptime devices.new_dev(.char, &types.DevOps_T {
        .write = &opaque {
            pub fn write(_: types.Minor_T, _: []const u8, _: usize) anyerror!void {
                return error.OperationOk;
            }
        }.write,
    });
    try main.dev_add(0, &dev);
    if(main.dev_add(0, &dev)) |_| { return error.NoNCollision; } else |_| {}
    if(!main.valid_major(0)) return error.UnexpectedAction;
    if(ops.write(0, 0, "Hello, World!", 0)) |_| {
        return error.UnexpectedAction;
    } else |err| switch(err) {
        error.OperationOk => {},
        else => return err,
    }
    if(ops.read(0, 0, 0)) |_| { return error.UnexpectedAction; } else |_| {}
    if(main.dev_minor_add(0, 0)) |_| { return error.UnexpectedAction; } else |err| {
        if(err != types.DevErr_T.MainMinorOperation) return error.UnexpectedAction;
    }
    if(main.dev_minor_add(0, 1)) |_| { return error.InvalidMinorAddOperation; } else |_| {}
    dev.flags.control.minor = 1;
    dev.flags.control.max = 1;
    main.dev_minor_add(0, 1) catch |err| return err;
    if(dev.flags.internal.total != 1) return error.UnexpectMinorTotal;
}
