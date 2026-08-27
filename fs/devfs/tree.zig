// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: tree.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const devices: type = @import("root").interfaces.devices;
const aux: type = @import("aux.zig");

pub inline fn treeSync(dev_list: *types.DevfsList) types.DevfsErr!void {
    aux.checkInit(dev_list) catch
        return types.DevfsErr.AllocatorFailed;

    for(0..(~@as(devices.Major, 0))) |major| {
        if(!devices.isAValidMajor(major))
            continue;
        for(0..(~@as(devices.Minor, 0))) |minor| {
            if(!devices.isAValidMinor(major, minor))
                continue;

            const device_dentry = 

            dev_list.pushInList(&allocator.sba.allocator, data);
        }
    }
}
