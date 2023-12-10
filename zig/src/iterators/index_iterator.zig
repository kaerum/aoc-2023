const std = @import("std");
const Iterator = @import("iterator.zig").Iterator;
const ArrayIterator = @import("array_iterator.zig").ArrayIterator;
const expect = std.testing.expect;

pub fn IndexIterator(comptime kind: type) type {
    return struct {
        const Self = @This();
        const IndexIteratorReturnType = std.meta.Tuple(&[_]type{ usize, kind });
        const IndexIteratorType = Iterator(IndexIteratorReturnType);
        const vtable = IndexIteratorType.VTable{ .next = next };

        inner_iterator: Iterator(kind),
        current_index: usize,

        pub fn init(iter: Iterator(kind)) Self {
            return Self{ .inner_iterator = iter, .current_index = 0 };
        }

        pub fn iterator(self: *Self) IndexIteratorType {
            return IndexIteratorType{ .ptr = self, .vtable = &vtable };
        }

        fn next(ctx: *anyopaque) ?IndexIteratorReturnType {
            const self: *Self = @ptrCast(@alignCast(ctx));
            const nxt = self.inner_iterator.next();
            if (nxt == null) {
                return null;
            }
            const value = .{ self.current_index, nxt.? };
            self.current_index += 1;
            return value;
        }
    };
}

test "Index Iterator" {
    const buf = "\nHello\n";
    var bytes_iterator = ArrayIterator(u8).init(buf);
    var index_iterator = IndexIterator(u8).init(bytes_iterator.iterator());
    var value = index_iterator.iterator().next();
    try expect(value.?[0] == 0);
    try expect(value.?[1] == '\n');
    value = index_iterator.iterator().next();
    try expect(value.?[0] == 1);
    try expect(value.?[1] == 'H');
    value = index_iterator.iterator().next();
    try expect(value.?[0] == 2);
    try expect(value.?[1] == 'e');
    value = index_iterator.iterator().next();
    try expect(value.?[0] == 3);
    try expect(value.?[1] == 'l');
    value = index_iterator.iterator().next();
    try expect(value.?[0] == 4);
    try expect(value.?[1] == 'l');
    value = index_iterator.iterator().next();
    try expect(value.?[0] == 5);
    try expect(value.?[1] == 'o');
    value = index_iterator.iterator().next();
    try expect(value.?[0] == 6);
    try expect(value.?[1] == '\n');
    try expect(index_iterator.iterator().next() == null);
    try expect(index_iterator.iterator().next() == null);
}
