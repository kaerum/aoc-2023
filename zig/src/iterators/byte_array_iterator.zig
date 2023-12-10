const std = @import("std");
const Iterator = @import("iterator.zig").Iterator;
const ByteArrayIteratorType = @import("array_iterator.zig").ArrayIterator(u8);
const expect = std.testing.expect;

pub const ByteArrayIterator = struct {
    const Self = @This();
    const IteratorU8Array = Iterator([]const u8);
    const vtable = IteratorU8Array.VTable{ .next = next };

    bytes_iterator: ByteArrayIteratorType,
    delimiter: u8,
    last_line_index: usize,
    current_index: usize,

    pub fn init(buf: []const u8, delimiter: ?u8) Self {
        return Self{ .bytes_iterator = ByteArrayIteratorType.init(buf), .current_index = 0, .delimiter = delimiter orelse '\n', .last_line_index = 0 };
    }

    pub fn iterator(self: *Self) IteratorU8Array {
        return IteratorU8Array{ .ptr = self, .vtable = &vtable };
    }

    fn next(ctx: *anyopaque) ?[]const u8 {
        const self: *Self = @ptrCast(@alignCast(ctx));
        while (self.bytes_iterator.iterator().next()) |byte| {
            self.current_index += 1;
            if (byte == self.delimiter) {
                const slice = self.bytes_iterator.buf[self.last_line_index .. self.current_index - 1];
                self.last_line_index = self.current_index;
                return slice;
            }
        }
        if (self.last_line_index < self.bytes_iterator.buf.len) {
            const slice = self.bytes_iterator.buf[self.last_line_index..];
            self.last_line_index = self.bytes_iterator.buf.len;
            return slice;
        }
        return null;
    }
};

test "Lines Iterator" {
    var buf = "\nHello\nWorld!\n\n";
    var lines_iter = ByteArrayIterator.init(buf, null);
    var iterator = lines_iter.iterator();
    try expect(std.mem.eql(u8, iterator.next().?, ""));
    try expect(std.mem.eql(u8, iterator.next().?, "Hello"));
    try expect(std.mem.eql(u8, iterator.next().?, "World!"));
    try expect(std.mem.eql(u8, iterator.next().?, ""));
    try expect(iterator.next() == null);
    try expect(iterator.next() == null);
}
