// ┌──────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: buddy.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const std: type = @import("std");

pub fn BuddyAllocator(comptime order: usize) type {
    return struct {
        const Buddy: type = @This();

        const Block: type = struct {
            start_index: usize,
            next: ?*Block,
        };

        const Allocation: type = struct {
            initial: usize,
            size: usize,
            order: usize,
        };

        const total_elems: usize = @as(usize, 1) << order;
        const max_order: usize = order + 1;

        blocks: [total_elems]Block,
        free_blocks: [max_order]?*Block,

        pub inline fn init() Buddy {
            var buddy: Buddy = .{
                .blocks = undefined,
                .free_blocks = [_]?*Block {
                    null
                } ** max_order,
            };

            buddy.blocks[0] = .{
                .start_index = 0,
                .next = null,
            };

            buddy.free_blocks[order] = &buddy.blocks[0];

            return buddy;
        }

        pub fn alloc(self: *Buddy, alloc_order: usize) ?Allocation {
            if(order > max_order)
                return null;

            var current_order: usize = alloc_order;

            while(current_order <= order) : (current_order += 1) {
                if(self.free_blocks[current_order] != null) {
                    var division_order_block: usize = current_order;

                    while(division_order_block > alloc_order) : (division_order_block -= 1){
                        const top_order: *Block = self.free_blocks[division_order_block].?;

                        self.free_blocks[division_order_block] = top_order.next;

                        const half_size: usize = @as(usize, 1) << @as(u6, @intCast(division_order_block - 1));

                        const left_half: usize = top_order.start_index;
                        const right_half: usize = left_half + half_size;

                        self.blocks[left_half].start_index = left_half;
                        self.blocks[right_half].start_index = right_half;

                        const old_head: ?*Block = self.free_blocks[division_order_block - 1];

                        self.blocks[left_half].next = &self.blocks[right_half];
                        self.blocks[right_half].next = old_head;

                        self.free_blocks[division_order_block - 1] = &self.blocks[left_half];
                    }

                    defer {
                        self.free_blocks[alloc_order] = self.free_blocks[alloc_order].?.next;
                    }

                    const start_index: usize = self.free_blocks[alloc_order].?.start_index;
                    const block_size: usize = @as(usize, 1) << @as(u6, @intCast(alloc_order));

                    return .{
                        .initial = start_index,
                        .size = block_size,
                        .order = alloc_order,
                    };
                }
            }

            return null;
        }

        pub fn allocAt(self: *Buddy, start_index: usize, alloc_order: usize) ?Allocation {
            if (alloc_order > order or start_index >= total_elems)
                return null;

            const block_size: usize = @as(usize, 1) << @as(u6, @intCast(alloc_order));

            if (start_index % block_size != 0 or block_size > total_elems - start_index)
                return null;

            var found_order: ?usize = null;
            var parent_order: usize = alloc_order;

            while (parent_order <= order) : (parent_order += 1) {
                const parent_size: usize = @as(usize, 1) << @as(u6, @intCast(parent_order));
                const parent_start: usize = start_index & ~(parent_size - 1);

                var previous_block: ?*Block = null;
                var current_block: ?*Block = self.free_blocks[parent_order];

                while (current_block) |block| {
                    if (block.start_index == parent_start) {
                        if (previous_block) |previous| {
                            previous.next = block.next;
                        } else {
                            self.free_blocks[parent_order] = block.next;
                        }

                        found_order = parent_order;
                        break;
                    }

                    previous_block = block;
                    current_block = block.next;
                }

                if (found_order != null)
                    break;
            }

            if (found_order == null)
                return null;

            var current_start: usize = start_index & ~((@as(usize, 1) << @as(u6, @intCast(parent_order))) - 1);

            while (parent_order > alloc_order) {
                parent_order -= 1;

                const half_size: usize = @as(usize, 1) << @as(u6, @intCast(parent_order));
                const right_start: usize = current_start + half_size;
                const target_is_left: bool = start_index < right_start;
                const sibling_start: usize = if (target_is_left) right_start else current_start;
                const old_head: ?*Block = self.free_blocks[parent_order];

                self.blocks[sibling_start] = .{
                    .start_index = sibling_start,
                    .next = old_head,
                };
                self.free_blocks[parent_order] = &self.blocks[sibling_start];

                if (!target_is_left)
                    current_start = right_start;
            }

            return .{
                .initial = start_index,
                .size = block_size,
                .order = alloc_order,
            };
        }

        pub fn free(self: *Buddy, allocation: Allocation) void {
            if (allocation.order > order)
                return;

            const block_size: usize = @as(usize, 1) << @as(u6, @intCast(allocation.order));

            if (allocation.size != block_size or allocation.initial >= total_elems or
                allocation.initial % block_size != 0 or block_size > total_elems - allocation.initial)
            {
                return;
            }

            var check_order: usize = allocation.order;

            while (check_order <= order) : (check_order += 1) {
                const check_size: usize = @as(usize, 1) << @as(u6, @intCast(check_order));
                const check_start: usize = allocation.initial & ~(check_size - 1);
                var current_block: ?*Block = self.free_blocks[check_order];

                while (current_block) |block| {
                    if (block.start_index == check_start)
                        return;

                    current_block = block.next;
                }
            }

            var current_index: usize = allocation.initial;
            var current_order: usize = allocation.order;

            while (current_order < order) {
                const current_size: usize = @as(usize, 1) << @as(u6, @intCast(current_order));
                const buddy_index: usize = current_index ^ current_size;

                var previous_block: ?*Block = null;
                var buddy_block: ?*Block = self.free_blocks[current_order];
                var buddy_found: bool = false;

                while (buddy_block) |block| {
                    if (block.start_index == buddy_index) {
                        if (previous_block) |previous| {
                            previous.next = block.next;
                        } else {
                            self.free_blocks[current_order] = block.next;
                        }

                        buddy_found = true;
                        break;
                    }

                    previous_block = block;
                    buddy_block = block.next;
                }

                if (!buddy_found)
                    break;

                current_index = @min(current_index, buddy_index);
                current_order += 1;
            }

            self.blocks[current_index] = .{
                .start_index = current_index,
                .next = self.free_blocks[current_order],
            };
            self.free_blocks[current_order] = &self.blocks[current_index];
        }
    };
}

test "allocation" {
    var buddy = BuddyAllocator(4).init();

    const a = buddy.alloc(0) orelse return error.AllocationFail;
    const b = buddy.alloc(1) orelse return error.AllocationFail;
    const c = buddy.alloc(2) orelse return error.AllocationFail;
    const d = buddy.alloc(0) orelse return error.AllocationFail;

    try std.testing.expectEqual(@as(usize, 0), a.initial);
    try std.testing.expectEqual(@as(usize, 1), a.size);
    try std.testing.expectEqual(@as(usize, 0), a.order);

    try std.testing.expectEqual(@as(usize, 2), b.initial);
    try std.testing.expectEqual(@as(usize, 2), b.size);
    try std.testing.expectEqual(@as(usize, 1), b.order);

    try std.testing.expectEqual(@as(usize, 4), c.initial);
    try std.testing.expectEqual(@as(usize, 4), c.size);
    try std.testing.expectEqual(@as(usize, 2), c.order);

    try std.testing.expectEqual(@as(usize, 1), d.initial);
    try std.testing.expectEqual(@as(usize, 1), d.size);
    try std.testing.expectEqual(@as(usize, 0), d.order);

    const e = buddy.alloc(3) orelse return error.AllocationFail;

    try std.testing.expectEqual(@as(usize, 8), e.initial);
    try std.testing.expectEqual(@as(usize, 8), e.size);

    try std.testing.expect(buddy.alloc(0) == null);
}
