// ┌─────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: allocators.zig  │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘


const arch: type = @import("root").interfaces.arch;
const mm: type = @import("root").__SaturnArchImpl__.mm;

// === i386 spea allocator support

const spea_fns: type = opaque {
    pub fn alloc() anyerror!arch.ArchDescription.Allocation_T {
        var virtual_page: mm.AllocPage_T = try mm.alloc_page();

        return arch.ArchDescription.Allocation_T {
            .private = &virtual_page,
            .ptr = virtual_page.virtual,
        };
    }

    pub fn free(virtual_page: *anyopaque) anyerror!void {
        return mm.free_page(@ptrCast(@alignCast(virtual_page)));
    }
};

pub const spea: arch.ArchDescription.Allocator_T = .{
    .page = 4096,
    .alloc_fn = &spea_fns.alloc,
    .free_fn = &spea_fns.free,
};

// === EO spea allocator
