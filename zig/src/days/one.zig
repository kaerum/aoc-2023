const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;
const File = std.fs.File;
const utils = @import("../utils.zig");
const StaticString = utils.StaticString;
const partial_match = utils.partial_match;
const parse_digit = utils.parse_digit;

pub fn day_one(allocator: std.mem.Allocator, file: File, part_to_run: []const u8) !u128 {
    const consider_words_as_digits = std.mem.eql(u8, part_to_run, "two");
    const digit_words = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
    var buf = try file.readToEndAlloc(allocator, utils.mb * 100);
    defer allocator.free(buf);
    var split_iterator = std.mem.splitScalar(u8, buf, '\n');
    var running_sum: u128 = 0;
    var current_word = StaticString(5).init();
    const stdout = std.io.getStdOut();
    var current_line: u64 = 0;
    while (split_iterator.next()) |line| {
        current_line += 1;
        current_word.reset();
        std.debug.print("{d}    {s}    ", .{ current_line, line });
        var first_digit: u8 = 0;
        var second_digit: u8 = 0;
        for (line) |byte| {
            const digit: u8 = brk: {
                if (std.ascii.isDigit(byte)) {
                    current_word.reset();
                    break :brk try std.fmt.parseUnsigned(u8, &[_]u8{byte}, 10);
                }
                if (!consider_words_as_digits) {
                    break :brk 0;
                }
                current_word.append(&[_]u8{byte});
                var matched_more_than_zero = false;
                for (digit_words) |word| {
                    const matching_chars = partial_match(current_word.slice, word);
                    if (matching_chars == 0) {
                        continue;
                    }
                    matched_more_than_zero = true;
                    if (matching_chars == word.len) {
                        const parsed_digit = parse_digit(current_word.slice).?;
                        current_word.reset();
                        current_word.append(&[_]u8{byte});
                        break :brk parsed_digit;
                    }
                }
                if (!matched_more_than_zero) {
                    current_word.discard_first();
                }
                break :brk 0;
            };
            if (digit == 0) {
                continue;
            }
            if (first_digit == 0) {
                first_digit = digit;
            }
            second_digit = digit;
        }
        try std.fmt.format(stdout.writer(), "{d}\n", .{first_digit * 10 + second_digit});
        std.debug.print("First digit: {d} Second digit: {d}\n", .{ first_digit, second_digit });
        running_sum += first_digit * 10 + second_digit;
    }
    std.debug.print("Final: {d}\n", .{running_sum});
    return running_sum;
}

const test_file = "day_one";

test "day one: part one" {
    const allocator = std.testing.allocator;
    const tmpDir = std.testing.tmpDir(.{}).dir;
    try tmpDir.writeFile(test_file, "1abc2\npqr3tsu8vwx\na1b2c3d4e5f\ntreb7uchet");
    var file = try tmpDir.openFile(test_file, std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    try expect(try day_one(allocator, file, "one") == 142);
}

test "day one: part two" {
    const allocator = std.testing.allocator;
    const tmpDir = std.testing.tmpDir(.{}).dir;
    try tmpDir.writeFile(test_file, "two1nine\neighttwothree\nabcone2threexyz\nxtwone3four\n4nineeightseven2\nzoneight234\n7pqrstsixteen");
    var file = try tmpDir.openFile(test_file, std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    try expect(try day_one(allocator, file, "two") == 281);
    try tmpDir.writeFile(test_file, "9dlvndqbddghpxc\nrtkrbtthree8sixfoureight6\nfdxrqmfxdkstpmcj7lmphgsmqqnmjrtwo3tcbc\nonetjcsmgk57nvmkvcvkdtqtsksgpchsfsjzkkmb\nsix8threepvlxttc85two\n8five9ttqst2one2vz\nhbrmhsnjeight64dgdnvdbspk7ninetzbvjczqrj\nfourtwofivesix5\n3gksfourqf48\n7one1tnqxfvhmjvjzfive\nsevenmcjs3lmlmxmcgptwobjggfive6four\nseven8five3\n5sfknxsn5sevenfour446\nbxc5two67seven2\njcsfivefive89seven85\nnine296\n7cns\nmsnronenine43three1threefrv\n35448284\n5z\n4");
    file = try tmpDir.openFile(test_file, std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    try expect(try day_one(allocator, file, "two") == 99 + 36 + 73 + 17 + 62 + 82 + 89 + 45 + 38 + 75 + 74 + 73 + 56 + 52 + 55 + 96 + 77 + 13 + 34 + 55 + 44);
}

test "day one: part two single word digit" {
    const allocator = std.testing.allocator;
    const tmpDir = std.testing.tmpDir(.{}).dir;
    try tmpDir.writeFile(test_file, "one");
    var file = try tmpDir.openFile(test_file, std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    try expect(try day_one(allocator, file, "two") == 11);
}

test "day one: part two two word digits" {
    const allocator = std.testing.allocator;
    const tmpDir = std.testing.tmpDir(.{}).dir;
    try tmpDir.writeFile(test_file, "onetwo");
    var file = try tmpDir.openFile(test_file, std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    try expect(try day_one(allocator, file, "two") == 12);
}

test "day one: part two three overlapping word digits" {
    const allocator = std.testing.allocator;
    const tmpDir = std.testing.tmpDir(.{}).dir;
    try tmpDir.writeFile(test_file, "5twonine");
    var file = try tmpDir.openFile(test_file, std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    try expect(try day_one(allocator, file, "two") == 59);
}

test "day one: part two lookbehind" {
    const allocator = std.testing.allocator;
    const tmpDir = std.testing.tmpDir(.{}).dir;
    try tmpDir.writeFile(test_file, "seightfourkhpkprrcl6six");
    var file = try tmpDir.openFile(test_file, std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    try expect(try day_one(allocator, file, "two") == 86);
}

test "day one: part two word digits sharing chars" {
    const allocator = std.testing.allocator;
    const tmpDir = std.testing.tmpDir(.{}).dir;
    try tmpDir.writeFile(test_file, "11lttrkpcljbbrmponeightbb");
    var file = try tmpDir.openFile(test_file, std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    try expect(try day_one(allocator, file, "two") == 18);
}

test "day one: part two word digits completing across lines" {
    const allocator = std.testing.allocator;
    const tmpDir = std.testing.tmpDir(.{}).dir;
    try tmpDir.writeFile(test_file, "23on\ne");
    var file = try tmpDir.openFile(test_file, std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    try expect(try day_one(allocator, file, "two") == 23 + 0);
}

test "day one: part two single digit" {
    const allocator = std.testing.allocator;
    const tmpDir = std.testing.tmpDir(.{}).dir;
    try tmpDir.writeFile(test_file, "2");
    var file = try tmpDir.openFile(test_file, std.fs.File.OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    try expect(try day_one(allocator, file, "two") == 22);
}
