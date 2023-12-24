const std = @import("std");
const expect = std.testing.expect;

pub const kb = 1_000;
pub const mb = kb * 1_000;
pub const gb = mb * 1_000;

pub fn StaticString(comptime size: usize) type {
    return struct {
        const Self = @This();

        /// Indexing past `len` may return garbage data
        buffer: [size]u8,
        len: usize,
        slice: []const u8,

        pub fn init() Self {
            const buffer: [size]u8 = undefined;
            return Self{ .buffer = buffer, .len = 0, .slice = buffer[0..0] };
        }

        pub fn append(self: *Self, bytes: []const u8) void {
            for (bytes) |byte| {
                if (self.len == self.buffer.len) {
                    break;
                }
                self.buffer[self.len] = byte;
                self.len += 1;
            }
            self.slice = self.buffer[0..self.len];
        }

        pub fn discard_first(self: *Self) void {
            std.mem.copyForwards(u8, &self.buffer, self.buffer[1..self.len]);
            self.len -= 1;
            self.slice = self.buffer[0..self.len];
        }

        pub fn reset(self: *Self) void {
            self.len = 0;
            self.slice = self.buffer[0..self.len];
        }
    };
}

test "Static string" {
    var str = StaticString(3).init();
    try expect(std.mem.eql(u8, "", str.slice));
    str.append("a");
    try expect(std.mem.eql(u8, "a", str.slice));
    str.append("b");
    try expect(std.mem.eql(u8, "ab", str.slice));
    str.append("c");
    try expect(std.mem.eql(u8, "abc", str.slice));
    str.append("c");
    try expect(std.mem.eql(u8, "abc", str.slice));
    str.discard_first();
    std.debug.print("STR {s}\n", .{str.slice});
    try expect(std.mem.eql(u8, "bc", str.slice));
    str.discard_first();
    try expect(std.mem.eql(u8, "c", str.slice));
    str.reset();
    try expect(std.mem.eql(u8, "", str.slice));
}

pub fn parse_digit(buf: []const u8) ?u8 {
    // Apparently we can't match on strings... oh well
    if (std.mem.eql(u8, buf, "zero")) {
        return 0;
    }
    if (std.mem.eql(u8, buf, "one")) {
        return 1;
    }
    if (std.mem.eql(u8, buf, "two")) {
        return 2;
    }
    if (std.mem.eql(u8, buf, "three")) {
        return 3;
    }
    if (std.mem.eql(u8, buf, "four")) {
        return 4;
    }
    if (std.mem.eql(u8, buf, "five")) {
        return 5;
    }
    if (std.mem.eql(u8, buf, "six")) {
        return 6;
    }
    if (std.mem.eql(u8, buf, "seven")) {
        return 7;
    }
    if (std.mem.eql(u8, buf, "eight")) {
        return 8;
    }
    if (std.mem.eql(u8, buf, "nine")) {
        return 9;
    }
    return null;
}

test "parse digit" {
    try expect(parse_digit("zero") == 0);
    try expect(parse_digit("one") == 1);
    try expect(parse_digit("two") == 2);
    try expect(parse_digit("three") == 3);
    try expect(parse_digit("four") == 4);
    try expect(parse_digit("five") == 5);
    try expect(parse_digit("six") == 6);
    try expect(parse_digit("seven") == 7);
    try expect(parse_digit("eight") == 8);
    try expect(parse_digit("nine") == 9);
}

pub fn partial_match(partial: []const u8, expected: []const u8) usize {
    const first = if (partial.len > expected.len) partial[0..expected.len] else partial;
    const second = expected[0..first.len];
    if (std.mem.eql(u8, first, second)) {
        return first.len;
    }
    return 0;
}

test "partial match" {
    try expect(partial_match("n", "one") == 0);
    try expect(partial_match("o", "one") == 1);
    try expect(partial_match("on", "one") == 2);
    try expect(partial_match("one", "one") == 3);
    try expect(partial_match("onew", "one") == 3);
}
