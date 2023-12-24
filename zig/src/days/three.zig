const std = @import("std");
const expect = std.testing.expect;
const utils = @import("../utils.zig");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

fn is_symbol(byte: u8) bool {
    return byte != '.' and !std.ascii.isDigit(byte) and byte != '\n';
}

fn into_one_dimension(x: i64, y: i64, board_width: i64) usize {
    const result = (y * board_width + x - 1);
    if (result < 0) {
        return 0;
    }
    return @intCast(result);
}

fn into_two_dimenstions(position: i64, board_width: i64) std.meta.Tuple(&[_]type{ i64, i64 }) {
    return .{ @rem(position, board_width), @divTrunc(position, board_width) };
}

fn print_char(char: u8) void {
    if (std.ascii.isDigit(char)) {
        std.debug.print("\x1B[43m{c}\x1B[0m", .{char});
        return;
    }
    if (is_symbol(char)) {
        std.debug.print("\x1B[46m{c}\x1B[0m", .{char});
        return;
    }
    std.debug.print("{c}", .{char});
}

test "Position conversion" {
    const board_width = 32;
    try expect(into_one_dimension(2, 1, board_width) == 33);
    try expect(into_one_dimension(31, 0, board_width) == 30);
    var pos = into_two_dimenstions(33, board_width);
    try expect(pos[0] == 2 and pos[1] == 1);
    pos = into_two_dimenstions(31, 32);
    try expect(pos[0] == 2 and pos[1] == 1);
}

const ESCAPE_CONTROL_CHAR: u8 = '\x1B';

pub fn day_three(allocator: Allocator, file: File, part_to_run: []const u8) !u128 {
    const part_two = std.mem.eql(u8, part_to_run, "two");
    _ = part_two;
    var buf = try file.readToEndAlloc(allocator, utils.mb * 100);
    const board_width: i64 = @intCast(std.mem.indexOfScalar(u8, buf, '\n').?);
    const board_height: i64 = @divTrunc(@as(i64, @intCast(buf.len - 1)), board_width);
    std.debug.print("Calculated width: {d} and height: {d}\n", .{ board_width, board_height });
    defer allocator.free(buf);
    var accumulator: u128 = 0;
    var last_digit_index: ?usize = null;
    for (buf, 0..) |byte, index| {
        print_char(byte);
        if (std.ascii.isDigit(byte)) {
            if (last_digit_index == null) {
                last_digit_index = index;
            }
            continue;
        }
        defer last_digit_index = null;
        if (last_digit_index != null) {
            var offset = index - last_digit_index.? + 1;
            const part_string = buf[last_digit_index.?..index];
            const part_number = try std.fmt.parseUnsigned(u64, part_string, 10);
            var valid = false;
            for (last_digit_index.?..index) |i| {
                const pos = into_two_dimenstions(@intCast(i), board_width);
                for (0..3) |y_offset| {
                    for (0..3) |x_offset| {
                        const t_offset_x = @as(i64, @intCast(x_offset)) - 1;
                        const t_offset_y = @as(i64, @intCast(y_offset)) - 1;
                        const next_x = pos[0] + t_offset_x;
                        const next_y = pos[1] + t_offset_y;
                        // std.debug.print("Offset: x: {d} y: {d}\n", .{ t_offset_x, t_offset_y });
                        if (next_x < 0 or next_x > board_width) {
                            continue;
                        }
                        if (next_y < 0 or next_y > board_height) {
                            continue;
                        }
                        const check_pos = into_one_dimension(next_x, next_y, board_width);
                        const char = buf[check_pos];
                        // std.debug.print("At x: {d} and y: {d} char: {c} is symbol: {s}\n", .{ next_x, next_y, char, if (is_symbol(char)) "Yes" else "No" });
                        if (is_symbol(char)) {
                            valid = true;
                        }
                    }
                }
            }
            const color: u8 = if (valid) 41 else 42;
            if (byte == '\n') {
                std.debug.print("\x1B[1F\x1B[{d}C", .{board_width});
                offset -= 1;
            }
            std.debug.print("\x1B[{d}D\x1B[{d}m{s}\x1B[0m", .{ offset, color, part_string });
            print_char(byte);
            if (!valid) {
                _ = try std.io.getStdIn().reader().readByte();
            } else {
                accumulator += part_number;
            }
        }
    }
    std.debug.print("accumulator {d}", .{accumulator});
    return accumulator;
}
