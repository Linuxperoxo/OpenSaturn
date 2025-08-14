// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: major.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const Mod_T: type = @import("types.zig").Mod_T;
const ModErr_T: type = @import("types.zig").ModErr_T;
const ModMajor_T: type = @import("types.zig").ModMajor_T;
const MajorInfo_T: type = @import("types.zig").MajorInfo_T;
const ModMajorStatus_T: type = @import("types.zig").ModMajorStatus_T;

// Dividir em arquivos para cada tipo de major

// Majors Queue
pub var drivers: ModMajor_T = .{
    .next = null,
    .status = null,
    .module = null,
};

pub var filesystem: ModMajor_T = .{
    .next = null,
    .status = null,
    .module = null,
};

pub var syscall: ModMajor_T = .{
    .next = null,
    .status = null,
    .module = null,
};

const majors = [_]MajorInfo_T {

    // O=====================================
    // | Drivers
    // O=====================================

    .{
        .majors = &drivers,
        .in = &struct {
            pub fn in(_: *const Mod_T) ModErr_T!void {

            }
        }.in,
        .rm = &struct {
            pub fn rm(_: *const Mod_T) ModErr_T!void {

            }
        }.rm,
    },

    // O=====================================
    // | Filesystem
    // O=====================================

    .{
        .majors = &filesystem,
        .in = &struct {
            const Fs_T: type = @import("root").interfaces.fs.Fs_T;
            const Allocator = @import("interfaces.zig").Allocator;
            const registerfs = @import("root").interfaces.fs.registerfs;

            pub fn in(M: *const Mod_T) ModErr_T!void {
                @call(.never_inline, &registerfs, .{
                    @as(*Fs_T, @alignCast(@ptrCast(M.private.?))).*
                }) catch return ModErr_T.InternalError;

                var majorN: ?*ModMajor_T = filesystem.next;
                var majorC: *ModMajor_T = if(filesystem.status) |_| &filesystem else {
                    filesystem.status = .running;
                    filesystem.module.? = M.*;
                    return {};
                };

                while(majorN) |_| {
                    if(majorC.module.?.init == M.init) {
                        return ModErr_T.IsInitialized;
                    }
                    majorC = majorC.next.?;
                    majorN = majorN.?.next;
                }

                majorC.next = mC_n: {
                    const allocArea = @call(.never_inline, &Allocator.kmalloc, .{
                        ModMajor_T,
                        1,
                    }) catch {
                        return ModErr_T.AllocatorError;
                    };
                    break :mC_n &allocArea[0];
                };
                majorC.next.?.status = .running;
                majorC.next.?.module.? = M.*;
            }
        }.in,
        .rm = &struct {
            pub fn rm(_: *const Mod_T) ModErr_T!void {

            }
        }.rm,
    },

    // O=====================================
    // | Syscalls
    // O=====================================

    .{
        .majors = &syscall,
        .in = &struct {
            pub fn in(_: *const Mod_T) ModErr_T!void {

            }
        }.in,
        .rm = &struct {
            pub fn rm(_: *const Mod_T) ModErr_T!void {

            }
        }.rm,
    }
};

pub fn inMajor(M: *const Mod_T) ModErr_T!void {
    return @call(.never_inline, majors[@intFromEnum(M.type)].in, .{
        M,
    });
}

pub fn rmMajor(M: *const Mod_T) ModErr_T!void {
    return @call(.never_inline, majors[@intFromEnum(M.type)].rm, .{
        M,
    });
}
