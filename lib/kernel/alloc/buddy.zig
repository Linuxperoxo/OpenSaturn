pub fn BuddyAllocator(
    comptime max_order: usize,
) type {
    const max_index: usize = @as(usize, 1) << max_order;

    return struct {
        const Buddy: type = @This();

        const OrderLayer: type = struct {
            first_index: ?usize = null,
            count: usize = 0,
        };

        const Block: type = struct {
            first_index: usize,
            order: usize,
        };

        next_block: [max_index]?usize,
        allocated_order: [max_index]?usize,
        orders: [max_order + 1]OrderLayer,

        pub inline fn init() Buddy {
            var orders: [max_order + 1]OrderLayer = [_]OrderLayer{
                .{},
            } ** (max_order + 1);

            orders[max_order].first_index = 0;
            orders[max_order].count = 1;

            return .{
                .orders = orders,
                .next_block = [_]?usize{null} ** max_index,
                .allocated_order = [_]?usize{null} ** max_index,
            };
        }

        pub fn alloc(
            self: *Buddy,
            requested_order: usize,
        ) ?Block {
            if (requested_order > max_order)
                return null;

            var current_order: usize = requested_order;

            while (current_order <= max_order) : (current_order += 1) {
                const layer: *OrderLayer = &self.orders[current_order];
                const block_index: usize = layer.first_index orelse continue;

                layer.first_index = self.next_block[block_index];
                layer.count -= 1;

                self.next_block[block_index] = null;

                var split_order: usize = current_order;

                while (split_order > requested_order) {
                    split_order -= 1;

                    const half_size: usize = @as(usize, 1) << @intCast(split_order);
                    const right_index: usize = block_index + half_size;

                    const split_layer: *OrderLayer = &self.orders[split_order];

                    self.next_block[right_index] = split_layer.first_index;

                    split_layer.first_index = right_index;
                    split_layer.count += 1;
                }

                self.allocated_order[block_index] = requested_order;

                return .{
                    .first_index = block_index,
                    .order = requested_order,
                };
            }

            return null;
        }

        pub fn allocAt(
            self: *Buddy,
            requested_index: usize,
            requested_order: usize,
        ) ?Block {
            if (requested_order > max_order or requested_index >= max_index)
                return null;

            const requested_size: usize = @as(usize, 1) << @intCast(requested_order);
            if (requested_index % requested_size != 0)
                return null;

            var current_order: usize = requested_order;
            var block_index: usize = requested_index;
            var block_found: bool = false;

            while (current_order <= max_order) : (current_order += 1) {
                const layer: *OrderLayer = &self.orders[current_order];
                const candidate_size: usize = @as(usize, 1) << @intCast(current_order);

                var previous_index: ?usize = null;
                var current_index: ?usize = layer.first_index;

                while (current_index) |index| {
                    if (requested_index >= index and requested_index < index + candidate_size) {
                        const next_index: ?usize = self.next_block[index];

                        if (previous_index) |previous| {
                            self.next_block[previous] = next_index;
                        } else {
                            layer.first_index = next_index;
                        }

                        self.next_block[index] = null;
                        layer.count -= 1;
                        block_index = index;
                        block_found = true;
                        break;
                    }

                    previous_index = index;
                    current_index = self.next_block[index];
                }

                if (block_found)
                    break;
            }

            if (!block_found)
                return null;

            while (current_order > requested_order) {
                current_order -= 1;

                const half_size: usize = @as(usize, 1) << @intCast(current_order);
                const right_index: usize = block_index + half_size;
                const target_is_right: bool = requested_index >= right_index;
                const free_index: usize = if (target_is_right) block_index else right_index;

                const layer: *OrderLayer = &self.orders[current_order];
                self.next_block[free_index] = layer.first_index;
                layer.first_index = free_index;
                layer.count += 1;

                block_index = if (target_is_right) right_index else block_index;
            }

            self.allocated_order[block_index] = requested_order;

            return .{
                .first_index = block_index,
                .order = requested_order,
            };
        }

        pub fn free(self: *Buddy, block: Block) void {
            if (block.order > max_order or block.first_index >= max_index)
                return;

            const block_size: usize = @as(usize, 1) << @intCast(block.order);
            if (block.first_index % block_size != 0)
                return;

            if (self.allocated_order[block.first_index] != block.order)
                return;

            self.allocated_order[block.first_index] = null;

            var first_index: usize = block.first_index;
            var order: usize = block.order;

            while (order < max_order) {
                const buddy_size: usize = @as(usize, 1) << @intCast(order);
                const buddy_index: usize = first_index ^ buddy_size;
                const layer: *OrderLayer = &self.orders[order];

                var previous_index: ?usize = null;
                var current_index: ?usize = layer.first_index;
                var buddy_found: bool = false;

                while (current_index) |index| {
                    if (index == buddy_index) {
                        const next_index: ?usize = self.next_block[index];

                        if (previous_index) |previous| {
                            self.next_block[previous] = next_index;
                        } else {
                            layer.first_index = next_index;
                        }

                        self.next_block[index] = null;
                        layer.count -= 1;
                        buddy_found = true;
                        break;
                    }

                    previous_index = index;
                    current_index = self.next_block[index];
                }

                if (!buddy_found)
                    break;

                if (buddy_index < first_index)
                    first_index = buddy_index;

                order += 1;
            }

            const layer: *OrderLayer = &self.orders[order];
            self.next_block[first_index] = layer.first_index;
            layer.first_index = first_index;
            layer.count += 1;
        }
    };
}
