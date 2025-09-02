// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: SOA.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// === Saturn Object Allocator ===
//      A SLUB-like allocator
// === === === === === === === ===

pub fn buildObjAllocator(comptime T: type, comptime O: usize, comptime flood: usize, comptime alignment: ?u4) type {
    return if(O == 0) void else struct {
        pub const err_T: type = error {
            OutOfMemory,
            DoubleFree,
            IndexOutBounds,
            UndefinedAction,
        };

        pub const State_T: type = enum(u1) {
            free,
            busy,
        };

        // * continuos: vai tentar alocar a memoria de forma continua (mais lenta, mas sempre vai achar)
        // * fast: quando possivel vai tentar otimizar a alocacao (mais rapida. Pode haver penalidade caso nao tenha como otimizar)
        // * auto: decide qual sera o melhor caminho (recomenda)
        pub const Alloc_T: type = enum(u1) {
            continuos,
            fast,
            auto,
        };

        pub const BitMap: type = packed struct {
            b0: State_T,
            b1: State_T,
            b2: State_T,
            b3: State_T,
            b4: State_T,
            b5: State_T,
            b6: State_T,
            b7: State_T,
        };

        // TODO: objf tera mas de 1 indice para fazer fast alloc

        objs: [O]T align(alignment),
        obja: usize,
        objf: ?[] switch(O) {
            0...255 => u8,
            256...65535 => u16,
            else => u32,
        },
        objl: ?usize,
        objm: [r: {
            const bitmaps: comptime_int = O / (@sizeOf(BitMap) * 8);
            const rest: comptime_int = O % (@sizeOf(BitMap) * 8);
            if(bitmaps == 0) break :r 1;
            if(rest != 0) break :r bitmaps + 1;
            break :r bitmaps;
        }]BitMap,

        fn bit(self: *@This(), index: usize) err_T!*State_T {
            return if(index >= O) return err_T.IndexOutBounds else r: {
                const bitmapIndex: usize = index / @sizeOf(BitMap) * 8;
                const offset: usize = index - ((@sizeOf(BitMap) * 8) * bitmapIndex);
                break :r @as(*State_T, @ptrFromInt(@intFromPtr(&self.objm[bitmapIndex]) + offset));
            };
        }

        fn auto(_: *@This()) err_T!*T {
            // TODO:
        }

        fn fast(self: *@This()) err_T!*T {
            if(self.objf) |objf| {
                @branchHint(.likely);
                const bitPtr: *State_T = @call(.always_inline, &bit, .{
                    self,
                    self.objf.?
                }) catch return err_T.UndefinedAction;
                if(bitPtr.* == .free) {
                    @branchHint(.likely);
                    self.objf = null;
                    self.obja += 1;
                    bitPtr.* = .busy;
                    return &self.objs[objf];
                }
            }
            return @call(.always_inline, &@This().continuos, .{
                self, 0
            });
        }

        fn continuos(self: *@This(), start: usize) err_T!*T {
            for(start..O) |i| {
                const bitPtr: *State_T = @call(.always_inline, &bit, .{
                    self,
                    i
                }) catch unreachable;
                if(bitPtr.* == .free) {
                    @branchHint(.unlikely);
                    self.obja += 1;
                    bitPtr.* = .busy;
                    return &self.objs[i];
                }
            }
            return err_T.OutOfMemory;
        }

        pub fn init(comptime self: *@This()) void {
            self.obja = 0;
            self.objl = null;
            self.objf = null;
            for(&self.objm) |*objm| {
                @as(*u8, @ptrCast(objm)).* = @intFromEnum(State_T.free);
            }
        }

        pub fn alloc(self: *@This(), comptime how: Alloc_T) err_T!*T {
            return if(self.obja >= O) return err_T.OutOfMemory else r: {
                switch(comptime how) {
                    .auto => break :r @call(.never_inline, &@This().fast, .{
                        self
                    }),
                    .fast => break :r @call(.never_inline, &@This().fast, .{
                        self
                    }),
                    .continuos => break :r @call(.never_inline, &@This().continuos, .{
                        self, 0
                    }),
                }
            };
        }

        pub fn free(self: *@This(), I: usize) err_T!void {
            return if((@call(.never_inline, &bit, .{self, I}) catch |err| return err).* == .free) return err_T.DoubleFree else r: {
                (@call(.always_inline, &bit, .{self, I}) catch unreachable).* = .free;
                self.obja -= 1;
                self.objf = if(self.objf) |_| if(self.objf.? > I) I else break :r {} else I;
            };
        }
    };
}
