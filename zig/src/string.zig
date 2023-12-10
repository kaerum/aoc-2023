const std = @import("std");

pub const StringIterator = struct {
    const Self = @This();

    buf: []const u8,
    cur: usize,

    fn next(ctx: *anyopaque) ?u8 {
        const self: *Self = @ptrCast(@alignCast(ctx));
        if (self.cur >= self.buf.len) {
            return null;
        }
        const value = self.buf[self.cur];
        self.cur += 1;
        return value;
    }
};

// Todo test
