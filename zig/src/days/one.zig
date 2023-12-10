const std = @import("std");
// const main = @import("main");
const Allocator = std.mem.Allocator;
const ByteArrayIterator = @import("../iterators/try_iterator.zig").TryIterator(u8, std.fs.File.ReadError);
// const ArrayIterator = @import("../iterators/array_iterator.zig").ArrayIterator;
const utils = @import("../utils.zig");
const StaticString = utils.StaticString;
const partial_match = utils.partial_match;
const parse_digit = utils.parse_digit;
const expect = std.testing.expect;

pub fn day_one(allocator: std.mem.Allocator, iterator: ByteArrayIterator, part_to_run: []const u8) !u128 {
    _ = allocator;
    const consider_words_as_digits = std.mem.eql(u8, part_to_run, "two");
    const digit_words = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
    var current_word = StaticString(5).init();
    var running_sum: u128 = 0;
    var first_digit: ?u8 = null;
    var second_digit: ?u8 = null;
    while (try iterator.next()) |byte| {
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
    const first = first_digit orelse 0;
    const second = second_digit orelse 0;
    std.debug.print("Summing first {d} second {d}, total sum {d}\n", .{ first, second, running_sum });
    running_sum += (first * 10) + second;
    std.debug.print("Total sum is {d}", .{running_sum});
    return running_sum;
}

// test "day one: part one" {
//     const buf = "1abc2\npqr3tsu8vwx\na1b2c3d4e5f\ntreb7uchet";
//     const iterator = ArrayIterator(u8).init(buf);
//     const allocator = std.testing.allocator;
//     try expect(try day_one(allocator, iterator.iterator(), "one") == 142);
// }
//
// test "day one: part two" {
//     const allocator = std.testing.allocator;
//     var buf = "two1nine\neighttwothree\nabcone2threexyz\nxtwone3four\n4nineeightseven2\nzoneight234\n7pqrstsixteen";
//     var iterator = ArrayIterator(u8).init(buf);
//     try expect(try day_one(allocator, iterator.iterator(), "two") == 281);
//     buf = "9dlvndqbddghpxc\nrtkrbtthree8sixfoureight6\nfdxrqmfxdkstpmcj7lmphgsmqqnmjrtwo3tcbc\nonetjcsmgk57nvmkvcvkdtqtsksgpchsfsjzkkmb\nsix8threepvlxttc85two\n8five9ttqst2one2vz\nhbrmhsnjeight64dgdnvdbspk7ninetzbvjczqrj\nfourtwofivesix5\n3gksfourqf48\n7one1tnqxfvhmjvjzfive\nsevenmcjs3lmlmxmcgptwobjggfive6four\nseven8five3\n5sfknxsn5sevenfour446\nbxc5two67seven2\njcsfivefive89seven85\nnine296\n7cns\nmsnronenine43three1threefrv\n35448284\n5z\n4";
//     iterator = ArrayIterator(u8).init(buf);
//     try expect(try day_one(allocator, iterator.iterator(), "two") == 99 + 36 + 73 + 17 + 62 + 82 + 89 + 45 + 38 + 75 + 74 + 73 + 56 + 52 + 55 + 96 + 77 + 13 + 34 + 55 + 44);
// }
