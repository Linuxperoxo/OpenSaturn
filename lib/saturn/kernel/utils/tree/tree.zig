// ┌───────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: tree.zig      │
// │            Author: Linuxperoxo                │
// └───────────────────────────────────────────────┘

const std: type = @import("std");

pub fn TreeBuild(
    comptime T: type
) type {
    return struct {
        root: ?*TreeNode_T = null,

        const TreeNode_T: type = struct {
            left: ?*@This(),
            right: ?*@This(),
            id: ?usize,
            private: ?T,
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
            Collision,
            AllocatorFreeErr,
        };

        inline fn solve_path(node: *TreeNode_T) enum { all_null, left_null, right_null, no_null } {
            if(node.right != null and node.left != null) return .no_null;
            if(node.right != null) return .left_null;
            if(node.left != null) return .right_null;
            return .all_null;
        }

        fn allocator_verify(Allocator_T: type) void {
            const A = switch(@typeInfo(Allocator_T)) {
                .@"pointer" => |info| info.child,
                .@"struct" => Allocator_T,
                else => @compileError(
                    \\ expect allocator struct or pointer to allocator struct
                ),
            };
            if(@hasDecl(A, "alloc")) {
                sw: switch(@typeInfo(@TypeOf(A.alloc))) {
                    .@"fn" => |info| {
                        if(info.return_type == null or info.return_type.?) {
                            continue :sw @typeInfo(void);
                        }
                    },
                    else => @compileError(
                        \\
                    ),
                }
            }
            if(!@hasDecl(A, "free")) {
                sw: switch(@typeInfo(@TypeOf(A.free))) {
                    .@"fn" => |info| {
                        if(info.return_type == null or info.return_type.? != void or info.params.len != 2
                            or info.params[0].type != *A or info.params[1].type != []u8) {
                            continue :sw @typeInfo(void);
                        }
                    },
                    else => @compileError(
                        \\
                    ),
                }
            }
        }

        fn find_node(self: *@This(), id: usize) TreeErr_T!struct{ *TreeNode_T, *TreeNode_T } {
            if(self.root == null) return TreeErr_T.NoNFound;
            var prev_branch: *TreeNode_T = self.root.?;
            var current_branch: *TreeNode_T = self.root.?;
            var direct: ?Direct_T = null;
            while(current_branch.id != null) {
                if(id < current_branch.id.?) {
                    if(current_branch.left != null) {
                        direct = .left;
                        prev_branch = current_branch;
                        current_branch = current_branch.left.?;
                        continue;
                    }
                    return TreeErr_T.NoNFound;
                }
                if(id > current_branch.id.?) {
                    if(current_branch.right != null) {
                        direct = .right;
                        prev_branch = current_branch;
                        current_branch = current_branch.right.?;
                        continue;
                    }
                    return TreeErr_T.NoNFound;
                }
                return .{
                    prev_branch,
                    current_branch,
                };
            }
            return TreeErr_T.NoNFound;
        }

        pub fn put_in_tree(self: *@This(), id: usize, some: T, sba: anytype) TreeErr_T!void {
            comptime allocator_verify(@TypeOf(sba));
            if(self.root == null) {
                const alloc = sba.alloc(
                    @sizeOf(TreeNode_T)
                ) catch return TreeErr_T.AllocError;
                self.root = @alignCast(@ptrCast(alloc.ptr));
                self.root.?.* = .{
                    .left = null,
                    .right = null,
                    .id = null,
                    .private = null,
                };
            }
            var current_brach: *TreeNode_T = self.root.?;
            while(current_brach.id != null) {
                if(id < current_brach.id.?) {
                    if(current_brach.left != null) {
                        current_brach = current_brach.left.?;
                        continue;
                    }
                    const alloc = sba.alloc(
                        @sizeOf(TreeNode_T)
                    ) catch return TreeErr_T.AllocError;
                    current_brach.left = @alignCast(@ptrCast(alloc.ptr));
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
                    const alloc = sba.alloc(
                        @sizeOf(TreeNode_T)
                    ) catch return TreeErr_T.AllocError;
                    current_brach.right = @alignCast(@ptrCast(alloc.ptr));
                    current_brach.right.?.* = .{
                        .left = null,
                        .right = null,
                        .id = id,
                        .private = some,
                    };
                    return;
                }
                return TreeErr_T.Collision;
            }
            current_brach.id = id;
            current_brach.private = some;
        }

        pub fn drop_in_tree(self: *@This(), id: usize, sba: anytype) TreeErr_T!void {
            comptime allocator_verify(@TypeOf(sba));
            var prev, var current = @call(.always_inline, find_node, .{
                self, id
            }) catch |err| return err;
            sw: switch(solve_path(current)) {
                .no_null => {
                    var prev_node: *TreeNode_T = current.left.?;
                    var next_node: *TreeNode_T = current.left.?;
                    while(next_node.right != null) : (next_node = next_node.right.?) {
                        prev_node = next_node;
                    }
                    current.id = next_node.id;
                    current.private = next_node.private;
                    if(prev_node == next_node) current.left = next_node.left else prev_node.right = next_node.left;
                    current = next_node;
                },

                .all_null => {
                    if(prev == current) {
                        self.root = null;
                        break :sw {};
                    }
                    if(prev.left == current) prev.left = null else prev.right = null;
                },

                .right_null => {
                    if(prev == current) {
                        self.root = self.root.?.left;
                        break :sw {};
                    }
                    if(prev.left == current) prev.left = current.left else prev.right = current.left;
                },

                .left_null => {
                    if(prev == current) {
                        self.root = self.root.?.right;
                        break :sw {};
                    }
                    if(prev.left == current) prev.left = current.right else prev.right = current.right;
                },
            }
            sba.free(
                @as([*]u8, @ptrCast(current))[0..@sizeOf(TreeNode_T)]
            ) catch return TreeErr_T.AllocatorFreeErr;
        }

        pub fn search_in_tree(self: *@This(), id: usize) TreeErr_T!T {
            _, const node = @call(.always_inline, find_node, .{
                self, id
            }) catch |err| return err;
            return node.private.?;
        }
    };
}
