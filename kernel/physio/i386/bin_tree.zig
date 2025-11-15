// ┌─────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: bin_tree.zig    │
// │            Author: Linuxperoxo                  │
// └─────────────────────────────────────────────────┘

pub fn TreeBuild(
    comptime T: type,
    comptime allocator: anytype
) type {
    return struct {
        const TreeNode_T: type = struct {
            left: ?*@This(),
            right: ?*@This(),
            id: ?usize,
            private: ?*T,
        };

        const Direct_T: type = enum {
            right,
            left,
        };

        const TreeErr_T: type = error {
            NoNFound,
            OutMemory,
            AllocError,
            UnreachableCode,
        };

        var tree_root: TreeNode_T = .{
            .left = null,
            .right = null,
            .id = null,
            .private = null,
        };

        inline fn solve_path(node: *TreeNode_T) enum { all_null, left_null, right_null, no_null } {
            if(node.right != null and node.left != null) return .all_null;
            if(node.right != null) return .left_null;
            if(node.left != null) return .right_null;
            return .no_null;
        }

        fn find_node(id: usize) TreeErr_T!struct{ *TreeNode_T, *TreeNode_T, Direct_T } {
            var prev_branch: *TreeNode_T = &tree_root;
            var current_branch: *TreeNode_T = &tree_root;
            var direct: ?Direct_T = null;
            while(current_branch.id != null) {
                if(id < current_branch.id.? and current_branch.left != null) {
                    direct = .left;
                    prev_branch = current_branch;
                    current_branch = current_branch.left.?;
                    continue;
                }
                if(id > current_branch.id.? and current_branch.right != null) {
                    direct = .right;
                    prev_branch = current_branch;
                    current_branch = current_branch.right.?;
                    continue;
                }
                return .{
                    prev_branch,
                    current_branch,
                    direct.?,
                };
            }
            return TreeErr_T.NoNFound;
        }

        pub fn put_in_tree(id: usize, some: *T) TreeErr_T!void {
            var current_brach: *TreeNode_T = &tree_root;
            while(current_brach.id != null) {
                if(id < current_brach.id.?) {
                    if(current_brach.left != null) {
                        current_brach = current_brach.left.?;
                        continue;
                    }
                    current_brach.left = allocator.alloc(
                        @sizeOf(TreeNode_T)
                    ) catch return TreeErr_T.AllocError;
                    current_brach.left.?.* = .{
                        .left = null,
                        .right = null,
                        .id = id,
                        .private = some,
                    };
                    return;
                }
                if(id > current_brach.id.?) {
                    if(current_brach.right != null) {
                        current_brach = current_brach.right.?;
                        continue;
                    }
                    current_brach.left = allocator.alloc(
                        @sizeOf(TreeNode_T)
                    ) catch return TreeErr_T.AllocError;
                    current_brach.left.?.* = .{
                        .left = null,
                        .right = null,
                        .id = id,
                        .private = some,
                    };
                    return;
                }
            }
            current_brach.id = id;
            current_brach.private = some;
        }

        pub fn drop_in_tree(id: usize) TreeErr_T!void {
            var prev, var current, const direct = @call(.always_inline, find_node, .{
                id
            }) catch |err| return err;
            sw: switch(solve_path(current)) {
                .no_null => {
                    const prev_ptr  = if(direct == .right) prev.right.? else prev.left.?;
                    current = current.right.?;
                    var last_node_prev = current.right.?;
                    while(current.left != null) : (current = current.left) {
                        last_node_prev = current.right.?;
                    }
                    prev_ptr.* = .{
                        .id = current.id,
                        .private = current.private,
                        .left = prev.left,
                        .right = prev.right,
                    };
                    if(last_node_prev != null and last_node_prev.right.? == current.?) {
                        last_node_prev.right = if(current.right != null) current.right else null;
                        break :sw {};
                    }
                    if(last_node_prev != null)
                        last_node_prev.right = if(current.right != null) current.right else null;
                },
                .all_null => {
                    if(direct == .right) {
                        prev.right = null;
                        break :sw {};
                    }
                    prev.left = null;
                },
                .left_null, .right_null => |prev_dir| {
                    const prev_ptr  = if(direct == .right) &prev.right.? else &prev.left.?;
                    if(prev_dir == .right_null) {
                        prev_ptr.* = current.left;
                        break :sw {};
                    }
                    prev_ptr.* = current.left;
                },
            }
            allocator.free(
                @as([*]u8, @ptrCast(current))[0..@sizeOf(TreeNode_T)]
            );
        }

        pub fn search_in_tree(id: usize) TreeErr_T!*T {
            _, const node, _ = @call(.always_inline, find_node, .{
                id
            }) catch |err| return err;
            return node.private;
        }
    };
}
