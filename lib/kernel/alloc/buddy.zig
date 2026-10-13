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

        pub fn free(self: *Buddy, allocation: Allocation) void {
            _ = self;

            if(allocation.order > max_order)
                return;

            var current_order: usize = allocation.order;

            while(current_order <= order) : (current_order += 1) {

            }
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
