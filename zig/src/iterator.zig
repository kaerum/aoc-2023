const std = @import("std");
const expect = std.testing.expect;

pub fn Iterator(comptime kind: type) type {
    return struct {
        const Self = @This();

        pub const VTable = struct { next: *const fn (ctx: *anyopaque) ?kind };

        ptr: *anyopaque,
        vtable: *const VTable,

        fn next(self: Self) ?kind {
            return self.vtable.next(self.ptr);
        }
    };
}
