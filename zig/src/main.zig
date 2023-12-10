const std = @import("std");
const Allocator = std.mem.Allocator;
const OpenFlags = std.fs.File.OpenFlags;
const File = std.fs.File;
const ArrayList = std.ArrayList;
const expect = std.testing.expect;

fn parse_digit(buf: []const u8) ?u8 {
    // Yes, this is how we are doing it
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

fn partial_match(partial: []const u8, expected: []const u8) usize {
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

pub const StaticString = struct {
    const Self = @This();

    /// Do not access this buffer directly as it might be garbage
    buffer: []u8,
    capacity: usize,
    len: usize,
    slice: []const u8,

    fn init(allocator: Allocator, size: usize) !Self {
        const buffer = try allocator.alloc(u8, size);
        return Self{ .buffer = buffer, .capacity = size, .len = 0, .slice = buffer[0..0] };
    }

    fn deinit(self: *const Self, allocator: Allocator) void {
        allocator.free(self.buffer);
    }

    fn append(self: *Self, bytes: []const u8) void {
        for (bytes) |byte| {
            if (self.len == self.capacity) {
                break;
            }
            self.buffer[self.len] = byte;
            self.len += 1;
        }
        self.slice = self.buffer[0..self.len];
    }

    fn reset(self: *Self) void {
        self.len = 0;
        self.slice = self.buffer[0..self.len];
    }
};

test "Static string" {
    const allocator = std.testing.allocator;
    var str = try StaticString.init(allocator, 3);
    defer str.deinit(allocator);
    try expect(std.mem.eql(u8, "", str.slice));
    str.append("a");
    try expect(std.mem.eql(u8, "a", str.slice));
    str.append("b");
    try expect(std.mem.eql(u8, "ab", str.slice));
    str.append("c");
    try expect(std.mem.eql(u8, "abc", str.slice));
    str.append("c");
    try expect(std.mem.eql(u8, "abc", str.slice));
    str.reset();
    try expect(std.mem.eql(u8, "", str.slice));
}

fn day_one(allocator: std.mem.Allocator, file: File, part_to_run: []const u8) !u128 {
    const consider_words_as_digits = std.mem.eql(u8, part_to_run, "two");
    const digit_words = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
    var current_word = try StaticString.init(allocator, 5);
    defer current_word.deinit(allocator);
    var running_sum: u128 = 0;
    var buffer: [1024]u8 = undefined;
    var first_digit: ?u8 = null;
    var second_digit: ?u8 = null;
    var bytes_read: usize = try file.read(&buffer);
    while (bytes_read != 0) {
        const slice = buffer[0..bytes_read];
        for (slice) |byte| {
            if (byte == '\n') {
                const first = first_digit orelse 0;
                const second = second_digit orelse 0;
                std.debug.print("Summing {d} to {d}\n", .{ first * 10 + second, running_sum });
                running_sum += (first * 10) + second;
                std.debug.print("Total: {d}\n", .{running_sum});
                first_digit = null;
                second_digit = null;
                current_word.reset();
                continue;
            }
            if (std.ascii.isDigit(byte) == false) {
                if (consider_words_as_digits) {
                    var matched = false;
                    current_word.append(&[_]u8{byte});
                    for (digit_words) |digit_word| {
                        const matching_chars = partial_match(current_word.slice, digit_word);
                        if (matching_chars == 0) {
                            continue;
                        }
                        matched = true;
                        if (matching_chars == digit_word.len) {
                            current_word.reset();
                            const digit = parse_digit(digit_word).?;
                            if (first_digit == null) {
                                first_digit = digit;
                            }
                            second_digit = digit;
                            break;
                        }
                    }
                    if (!matched) {
                        current_word.reset();
                        current_word.append(&[_]u8{byte});
                    }
                }
                continue;
            }
            const digit = try std.fmt.parseUnsigned(u8, &[_]u8{byte}, 0);
            if (first_digit == null) {
                first_digit = digit;
            }
            second_digit = digit;
        }
        bytes_read = try file.read(&buffer);
    }
    const first = first_digit orelse 0;
    const second = second_digit orelse 0;
    std.debug.print("Summing first {d} second {d}, total sum {d}\n", .{ first, second, running_sum });
    running_sum += (first * 10) + second;
    std.debug.print("Total sum is {d}", .{running_sum});
    return running_sum;
}

test "day one: part one" {
    const allocator = std.testing.allocator;
    const tmpDir = std.testing.tmpDir(.{}).dir;
    try tmpDir.writeFile("day_one_part_one", "1abc2\npqr3tsu8vwx\na1b2c3d4e5f\ntreb7uchet");
    const file = try tmpDir.openFile("day_one_part_one", OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    try expect(try day_one(allocator, file, "one") == 142);
}

test "day one: part two" {
    const allocator = std.testing.allocator;
    const tmpDir = std.testing.tmpDir(.{}).dir;
    try tmpDir.writeFile("day_one_part_two", "two1nine\neighttwothree\nabcone2threexyz\nxtwone3four\n4nineeightseven2\nzoneight234\n7pqrstsixteen");
    var file = try tmpDir.openFile("day_one_part_two", OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    try expect(try day_one(allocator, file, "two") == 281);
    try tmpDir.writeFile("day_one_part_two_2", "9dlvndqbddghpxc\nrtkrbtthree8sixfoureight6\nfdxrqmfxdkstpmcj7lmphgsmqqnmjrtwo3tcbc\nonetjcsmgk57nvmkvcvkdtqtsksgpchsfsjzkkmb\nsix8threepvlxttc85two\n8five9ttqst2one2vz\nhbrmhsnjeight64dgdnvdbspk7ninetzbvjczqrj\nfourtwofivesix5\n3gksfourqf48\n7one1tnqxfvhmjvjzfive\nsevenmcjs3lmlmxmcgptwobjggfive6four\nseven8five3\n5sfknxsn5sevenfour446\nbxc5two67seven2\njcsfivefive89seven85\nnine296\n7cns\nmsnronenine43three1threefrv\n35448284\n5z\n4");
    file = try tmpDir.openFile("day_one_part_two_2", OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    try expect(try day_one(allocator, file, "two") == 99 + 36 + 73 + 17 + 62 + 82 + 89 + 45 + 38 + 75 + 74 + 73 + 56 + 52 + 55 + 96 + 77 + 13 + 34 + 55 + 44);
}

fn day_two(allocator: Allocator, file: File, part_to_run: []const u8) !void {
    _ = part_to_run;
    _ = file;
    _ = allocator;
}

fn get_input_file(allocator: Allocator, input_path: ?[]u8, day: []const u8) !File {
    const flags = OpenFlags{ .mode = std.fs.File.OpenMode.read_only };
    if (input_path != null) {
        var allocated = false;
        var absolute_path: []u8 = input_path.?;
        if (std.fs.path.isAbsolute(input_path.?) == false) {
            absolute_path = try std.fs.cwd().realpathAlloc(allocator, input_path.?);
            allocated = true;
        }
        const file_path = try std.fs.path.join(allocator, &[_][]const u8{ absolute_path, day });
        defer allocator.free(file_path);
        const file = std.fs.openFileAbsolute(file_path, flags);
        if (allocated) {
            allocator.free(absolute_path);
        }
        return file;
    }
    var cwd_buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    const cwd = try std.os.getcwd(&cwd_buf);
    const default_path = try std.fs.path.join(allocator, &[_][]const u8{ cwd, "inputs/", day });
    return std.fs.openFileAbsolute(default_path, flags);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const input_path: ?[]u8 = if (args.len >= 2) args[1] else undefined;
    const day_to_run = if (args.len >= 3) args[2] else "one";
    const part_to_run = if (args.len >= 4) args[3] else "one";
    const file = try get_input_file(allocator, input_path, day_to_run);
    if (std.mem.eql(u8, day_to_run, "one")) {
        _ = try day_one(allocator, file, part_to_run);
    }
    if (std.mem.eql(u8, day_to_run, "two")) {
        try day_two(allocator, file, part_to_run);
    }
}
