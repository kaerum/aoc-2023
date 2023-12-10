const std = @import("std");
const Allocator = std.mem.Allocator;
const ByteArrayIterator = @import("../iterators/try_iterator.zig").TryIterator(u8, std.fs.File.ReadError);

pub fn day_two(allocator: Allocator, file: ByteArrayIterator, part_to_run: []const u8) !u8 {
    _ = part_to_run;
    _ = file;
    _ = allocator;
    return 0;
}
