const std = @import("std");
const expect = std.testing.expect;

pub fn TryIterator(comptime kind: type, comptime error_kind: type) type {
    return struct {
        const Self = @This();

        pub const VTable = struct { next: *const fn (ctx: *anyopaque) error_kind!?kind };

        ptr: *anyopaque,
        vtable: *const VTable,

        pub fn next(self: Self) !?kind {
            return try self.vtable.next(self.ptr);
        }
    };
}
