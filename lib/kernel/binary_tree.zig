// ┌───────────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: binary_tree.zig   │
// │            Author: Linuxperoxo                    │
// └───────────────────────────────────────────────────┘

pub fn binaryTree(comptime t: type) type {
    return struct {
        root: ?*TreeNode = null,

        const TreeNode: type = struct {
            left: ?*@This(),
            right: ?*@This(),
            id: ?usize,
            private: ?t,
        };

        const Direct: type = enum {
            right,
            left,
        };

        pub const TreeErr: type = error{
            NoNFound,
            OutMemory,
            AllocError,
            UnreachableCode,
            Collision,
            AllocatorFreeErr,
        };

        inline fn solvePath(node: *TreeNode) enum { all_null, left_null, right_null, no_null } {
            if (node.right != null and node.left != null) return .no_null;
            if (node.right != null) return .left_null;
            if (node.left != null) return .right_null;
            return .all_null;
        }

        fn allocatorVerify(allocator: type) void {
            if (true)
                return;
            const allocator_type = switch (@typeInfo(allocator)) {
                .pointer => |info| info.child,
                .@"struct" => allocator,
                else => @compileError(
                    \\ expect allocator struct or pointer to allocator struct
                ),
            };
            if (@hasDecl(allocator_type, "alloc")) {
                sw: switch (@typeInfo(@TypeOf(allocator_type.alloc))) {
                    .@"fn" => |info| {
                        if (info.return_type == null or info.return_type.?) {
                            continue :sw @typeInfo(void);
                        }
                    },
                    else => @compileError(
                        \\
                    ),
                }
            }
            if (!@hasDecl(allocator_type, "free")) {
                sw: switch (@typeInfo(@TypeOf(allocator_type.free))) {
                    .@"fn" => |info| {
                        if (info.return_type == null or info.return_type.? != void or info.params.len != 2 or info.params[0].type != *allocator_type or info.params[1].type != []u8) {
                            continue :sw @typeInfo(void);
                        }
                    },
                    else => @compileError(
                        \\
                    ),
                }
            }
        }

        fn findNode(self: *@This(), id: usize) TreeErr!struct { *TreeNode, *TreeNode } {
            if (self.root == null) return TreeErr.NoNFound;
            var prev_branch: *TreeNode = self.root.?;
            var current_branch: *TreeNode = self.root.?;
            var direct: ?Direct = null;
            while (current_branch.id != null) {
                if (id < current_branch.id.?) {
                    if (current_branch.left != null) {
                        direct = .left;
                        prev_branch = current_branch;
                        current_branch = current_branch.left.?;
                        continue;
                    }
                    return TreeErr.NoNFound;
                }
                if (id > current_branch.id.?) {
                    if (current_branch.right != null) {
                        direct = .right;
                        prev_branch = current_branch;
                        current_branch = current_branch.right.?;
                        continue;
                    }
                    return TreeErr.NoNFound;
                }
                return .{
                    prev_branch,
                    current_branch,
                };
            }
            return TreeErr.NoNFound;
        }

        pub fn putInTree(self: *@This(), id: usize, some: t, sba: anytype) TreeErr!void {
            comptime allocatorVerify(@TypeOf(sba));
            if (self.root == null) {
                const alloc = sba.alloc(@sizeOf(TreeNode)) catch return TreeErr.AllocError;
                self.root = @ptrCast(@alignCast(alloc.ptr));
                self.root.?.* = .{
                    .left = null,
                    .right = null,
                    .id = null,
                    .private = null,
                };
            }
            var current_brach: *TreeNode = self.root.?;
            while (current_brach.id != null) {
                if (id < current_brach.id.?) {
                    if (current_brach.left != null) {
                        current_brach = current_brach.left.?;
                        continue;
                    }
                    const alloc = sba.alloc(@sizeOf(TreeNode)) catch return TreeErr.AllocError;
                    current_brach.left = @ptrCast(@alignCast(alloc.ptr));
                    current_brach.left.?.* = .{
                        .left = null,
                        .right = null,
                        .id = id,
                        .private = some,
                    };
                    return;
                }
                if (id > current_brach.id.?) {
                    if (current_brach.right != null) {
                        current_brach = current_brach.right.?;
                        continue;
                    }
                    const alloc = sba.alloc(@sizeOf(TreeNode)) catch return TreeErr.AllocError;
                    current_brach.right = @ptrCast(@alignCast(alloc.ptr));
                    current_brach.right.?.* = .{
                        .left = null,
                        .right = null,
                        .id = id,
                        .private = some,
                    };
                    return;
                }
                return TreeErr.Collision;
            }
            current_brach.id = id;
            current_brach.private = some;
        }

        pub fn dropInTree(self: *@This(), id: usize, sba: anytype) TreeErr!void {
            comptime allocatorVerify(@TypeOf(sba));
            var prev, var current = @call(.always_inline, findNode, .{ self, id }) catch |err| return err;
            sw: switch (solvePath(current)) {
                .no_null => {
                    var prev_node: *TreeNode = current.left.?;
                    var next_node: *TreeNode = current.left.?;
                    while (next_node.right != null) : (next_node = next_node.right.?) {
                        prev_node = next_node;
                    }
                    current.id = next_node.id;
                    current.private = next_node.private;
                    if (prev_node == next_node) current.left = next_node.left else prev_node.right = next_node.left;
                    current = next_node;
                },

                .all_null => {
                    if (prev == current) {
                        self.root = null;
                        break :sw {};
                    }
                    if (prev.left == current) prev.left = null else prev.right = null;
                },

                .right_null => {
                    if (prev == current) {
                        self.root = self.root.?.left;
                        break :sw {};
                    }
                    if (prev.left == current) prev.left = current.left else prev.right = current.left;
                },

                .left_null => {
                    if (prev == current) {
                        self.root = self.root.?.right;
                        break :sw {};
                    }
                    if (prev.left == current) prev.left = current.right else prev.right = current.right;
                },
            }
            sba.free(@as([*]u8, @ptrCast(current))[0..@sizeOf(TreeNode)]) catch return TreeErr.AllocatorFreeErr;
        }

        pub fn searchInTree(self: *@This(), id: usize) TreeErr!t {
            _, const node = @call(.always_inline, findNode, .{ self, id }) catch |err| return err;
            return node.private.?;
        }
    };
}
