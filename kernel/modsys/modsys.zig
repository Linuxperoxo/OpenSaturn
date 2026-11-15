// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: modsys.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const config: type = @import("root").config;
const interfaces: type = @import("root").interfaces;
const deps: type = @import("deps.zig");

pub fn saturnModulesLoader() void {
    if(!config.modules.options.modules_enable)
        return;

    inline for(comptime deps.resolveDependencies()) |module| {
        skip: {
            switch(comptime module.load) {
                .dynamic, .unlinkable => break :skip {},

                .linkable => {
                    module.mod.insmod(module.insf) catch |err| {
                        switch(err) {
                            interfaces.module.ModErr.ObsoleteDependency,

                            interfaces.module.ModErr.InitFailed => {
                                // klog()
                                module.mod.rmmod() catch {
                                    // klog()
                                };
                            },

                            interfaces.module.ModErr.OperationFailed => {
                                // klog()
                            },

                            else => unreachable,
                        }

                        if(module.panic) {
                            // panic();
                            //unreachable;
                        }
                    };
                },
            }
        }
    }
}
