const page_mapper: type = @import("PageMapper.zig");

pub const PageMapper: type = page_mapper;
pub const PageDirectory: type = page_mapper.PageDirectory;
pub const PageTable: type = page_mapper.PageTable;
pub const PageTables: type = page_mapper.PageTables;

// The architecture entry point is kept separate from mapper construction.
pub fn init() callconv(.c) void {}
