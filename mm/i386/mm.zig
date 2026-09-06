const mmu: type = @import("mmu.zig");

pub const AllocPage: type = struct {
    virtual: []u8,
};

pub const mmuInit = mmu.init;

pub fn allocPage() error{SomeError}!AllocPage {
    return error.SomeError;
}

pub fn freePage(_: *AllocPage) error{SomeError}!void {
    return error.SomeError;
}
