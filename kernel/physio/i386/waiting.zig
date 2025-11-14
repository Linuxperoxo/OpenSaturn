// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: waiting.zig  │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const pci: type = if(!builtin.is_test) @import("root").kernel.io.pci else @import("test_types.zig");

pub var waiting_tree_root: types.WaitingNode_T = .{
    .left = null,
    .right = null,
    .id = null,
};

inline fn make_id(class: u8, vendor: u16) usize {
    return (vendor << 8) | class;
}

pub fn physio_wait_by(class: u8, vendor: u16) void {
    var current: *types.WaitingNode_T = &waiting_tree_root;
    const id = make_id(class, vendor);
    while(current.id != null) {
        if(id < current.id.?) {
            if(current.left != null) {
                current = current.?.left;
                continue;
            }
            current.left = @call(.always_inline, allocator.sba.alloc_type_single, .{
                types.WaitingNode_T
            });
            current.left.?.* = types.WaitingNode_T {
                .left = null,
                .right = null,
                .id = id,
            };
            return;
        }
        if(id > current.id.?) {
            if(current.right != null) {
                current = current.?.right;
                continue;
            }
            current.right = @call(.always_inline, allocator.sba.alloc_type_single, .{
                types.WaitingNode_T
            });
            current.right.?.* = types.WaitingNode_T {
                .right = null,
                .left = null,
                .id = id,
            };
            return;
        }
    }
    current.?.id = id;
}
