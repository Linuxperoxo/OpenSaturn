// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: SOA.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// === Saturn Object Allocator ===
//      A SLUB-like allocator

pub fn buildObjAllocator(comptime T: type, comptime O: usize) type {
    return struct {
        pub const err_T: type = error {
            OutOfMemory,
            DoubleFree,
            IndexOutBounds,
        };

        objs: [O]T,
        objm: [O]enum { free, busy },
        obja: usize,
        objf: ?usize,

        pub fn alloc(self: *@This()) err_T!*T {
            return if(self.obja >= O) return err_T.OutOfMemory else r: {
                if(self.objf) |objf| {
                    self.objm[self.objf.?] = .busy;
                    self.objf = null;
                    self.obja += 1;
                    break :r &self.objs[objf];
                }
                for(&self.objm, 0..O) |*objm, i| {
                    if(objm.* == .free) {
                        objm.* = .busy;
                        self.obja += 1;
                        break :r &self.objs[i];
                    }
                }
                unreachable;
            };
        }

        pub fn free(self: *@This(), I: usize) err_T!void {
            return if(I >= O) return err_T.IndexOutBounds else if(self.objm[I] == .free) return err_T.DoubleFree else r: {
                self.objm[I] = .free;
                self.obja -= 1;
                self.objf = if(self.objf) |_| if(self.objf.? > I) I else break :r {} else I;
            };
        }
    };
}
