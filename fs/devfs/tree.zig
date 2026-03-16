// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: tree.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const devices: type = @import("root").interfaces.devices;
const aux: type = @import("aux.zig");

pub inline fn tree_sync(dev_list: *types.DevfsList_T) types.DevfsErr_T!void {
    aux.check_init(dev_list) catch
        return types.DevfsErr_T.AllocatorFailed;

    for(0..(~@as(devices.Major_T, 0))) |major| {
        if(!devices.valid_major(major))
            continue;
        for(0..(~@as(devices.Minor_T, 0))) |minor| {
            if(!devices.valid_minor(major, minor))
                continue;

            const device_dentry = 

            dev_list.push_in_list(&allocator.sba.allocator, data);
        }
    }
}
