// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: listeners.zig   │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

const builtin: type = @import("builtin");
const types: type = @import("types.zig");
const allocator: type = @import("allocator.zig");
const pci: type = if(!builtin.is_test) @import("root").kernel.io.pci else @import("test_types.zig");

pub var listeners_tree_root: types.ListenersNode_T = .{
    .left = null,
    .right = null,
    .phys = null,
};

pub inline fn physio_tree_id(phys: *types.PhysIo_T) usize {
    return
        (@as(usize, phys.device.bus) << 8) |
        (@as(usize, phys.device.device) << 5) |
        (@as(usize, phys.device.function) << 3);
}

// NOTE: kernel nao deve usar recursao, pode estourar a stack, usar recursao
// e esperar uma bomba relogio explodir

pub fn physio_listen(phys: *types.PhysIo_T) types.PhysIoErr_T!void {
    var branch: ?*types.ListenersNode_T = &listeners_tree_root;
    while(branch.?.phys != null) {
        const phys_to_listen = physio_tree_id(phys);
        const phys_tree = physio_tree_id(branch.?.phys.?);
        if(phys_to_listen < phys_tree) {
            if(branch.?.left != null) {
                branch = branch.?.left;
                continue;
            }
            branch.?.left = @call(.always_inline, allocator.sba.alloc_type_single, .{
                types.ListenersNode_T
            }) catch return types.PhysIoErr_T.InternalError;
            branch.?.left.?.* = .{
                .right = null,
                .left = null,
                .phys = phys,
            };
            return;
        }
        if(phys_to_listen > phys_tree) {
            if(branch.?.right != null) {
                branch = branch.?.right;
                continue;
            }
            branch.?.right = @call(.always_inline, allocator.sba.alloc_type_single, .{
                types.ListenersNode_T
            }) catch return types.PhysIoErr_T.InternalError;
            branch.?.right.?.* = .{
                .right = null,
                .left = null,
                .phys = phys
            };
            return;
        }
        return types.PhysIoErr_T.ListenerCollision;
    }
    branch.?.phys = phys;
}

inline fn solve_path(branch: *types.ListenersNode_T) enum { all_null, right_null, left_null, no_null } {
    if(branch.right == null and branch.left == null) return .all_null;
    if(branch.right != null and branch.left != null) return .no_null;
    if(branch.right != null) return .left_null;
    return .right_null;
}

pub fn physio_listen_rm(phys: *types.PhysIo_T) types.PhysIoErr_T!void {
    var prev: *types.ListenersNode_T = &listeners_tree_root;
    var branch: ?*types.ListenersNode_T = &listeners_tree_root;
    var direct: enum(u1) { left, right } = .right;
    while(branch.?.phys != null) {
        const phys_to_listen = physio_tree_id(phys);
        const phys_tree = physio_tree_id(branch.?.phys.?);
        if(phys_to_listen < phys_tree) {
            if(branch.?.left != null) {
                direct = .left;
                prev = branch.?;
                branch = branch.?.left;
                continue;
            }
            return types.PhysIoErr_T.NoNListener;
        }
        if(phys_to_listen > phys_tree) {
            if(branch.?.right != null) {
                direct = .right;
                prev = branch.?;
                branch = branch.?.right;
                continue;
            }
            return types.PhysIoErr_T.NoNListener;
        }
        break;
    }
    switch(solve_path(branch.?)) {
        .all_null => {
            if(direct == .left) prev.left = null else prev.right = null;
        },

        .no_null => {
            var next_node: *types.ListenersNode_T = branch.?.left.?;
            var prev_node: *types.ListenersNode_T = branch.?.left.?;
            while(next_node.right != null) : (next_node = next_node.right.?) {
                prev_node = next_node;
            }
            branch.?.phys = next_node.phys;
            if(prev_node == next_node) branch.?.left = next_node.left else prev_node.right = next_node.left;
            branch = next_node;
        },

        .right_null => {
            if(direct == .right) prev.right = branch.?.left else prev.left = branch.?.left;
        },

        .left_null => {
            if(direct == .right) prev.right = branch.?.right else prev.left = branch.?.right;
        },
    }
    allocator.sba.free_type_single(
        types.ListenersNode_T,
        branch.?
    ) catch return types.PhysIoErr_T.InternalError;
}

pub fn physio_listener_search(phys: *types.PhysIo_T) bool {
    var branch: ?*types.ListenersNode_T = &listeners_tree_root;
    while(branch.?.phys != null) {
        const phys_to_listen = physio_tree_id(phys);
        const phys_tree = physio_tree_id(branch.?.phys.?);
        if(phys_to_listen < phys_tree) {
            if(branch.?.left != null) {
                branch = branch.?.left;
                continue;
            }
            return false;
        }
        if(phys_to_listen > phys_tree) {
            if(branch.?.right != null) {
                branch = branch.?.right;
                continue;
            }
            return false;
        }
        return true;
    }
    return false;
}
