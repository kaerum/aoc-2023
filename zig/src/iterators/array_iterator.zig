const std = @import("std");
const Iterator = @import("iterator.zig").Iterator;
const expect = std.testing.expect;

pub fn ArrayIterator(comptime kind: type) type {
    return struct {
        const Self = @This();
        const IteratorType = Iterator(kind);
        const vtable = IteratorType.VTable{ .next = next };

        buf: []const u8,
        cur: usize,

        pub fn init(buf: []const kind) Self {
            return Self{ .buf = buf, .cur = 0 };
        }

        pub fn iterator(self: *Self) IteratorType {
            return IteratorType{ .ptr = self, .vtable = &vtable };
        }

        fn next(ctx: *anyopaque) ?kind {
            const self: *Self = @ptrCast(@alignCast(ctx));
            if (self.cur >= self.buf.len) {
                return null;
            }
            const value = self.buf[self.cur];
            self.cur += 1;
            return value;
        }
    };
}

test "Bytes Iterator" {
    var buf = "\nHello World!\n";
    var str_iterator = ArrayIterator(u8){ .buf = buf, .cur = 0 };
    var iterator = str_iterator.iterator();
    try expect(iterator.next() == '\n');
    try expect(iterator.next() == 'H');
    try expect(iterator.next() == 'e');
    try expect(iterator.next() == 'l');
    try expect(iterator.next() == 'l');
    try expect(iterator.next() == 'o');
    try expect(iterator.next() == ' ');
    try expect(iterator.next() == 'W');
    try expect(iterator.next() == 'o');
    try expect(iterator.next() == 'r');
    try expect(iterator.next() == 'l');
    try expect(iterator.next() == 'd');
    try expect(iterator.next() == '!');
    try expect(iterator.next() == '\n');
}
