const std = @import("std");
const utils = @import("../utils.zig");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

pub fn day_two(allocator: Allocator, file: File, part_to_run: []const u8) !u128 {
    const part_two = std.mem.eql(u8, part_to_run, "two");
    var red: u32 = 12;
    var green: u32 = 13;
    var blue: u32 = 14;
    var buf = try file.readToEndAlloc(allocator, utils.mb * 100);
    defer allocator.free(buf);
    var games = std.mem.splitScalar(u8, buf, '\n');
    var accumulator: u128 = 0;
    var game_id: u32 = 1;
    while (games.next()) |game| : (game_id += 1) {
        if (game.len <= 0) {
            break;
        }
        if (part_two) {
            red = 0;
            green = 0;
            blue = 0;
        }
        std.debug.print("{d}:  ", .{game_id});
        var valid = if (part_two) false else true;
        const colon_index = std.mem.indexOfScalar(u8, game, ':').?;
        var subsets = std.mem.splitScalar(u8, game[colon_index + 1 ..], ';');
        subset_block: while (subsets.next()) |subset| {
            if (subset.len <= 0) {
                break;
            }
            var hands = std.mem.splitScalar(u8, subset, ',');
            while (hands.next()) |hand| {
                if (hand.len <= 0) {
                    break;
                }
                const trimmed_hand = std.mem.trim(u8, hand, &[_]u8{' '});
                var pair = std.mem.splitScalar(u8, trimmed_hand, ' ');
                const quantity_str = pair.next().?;
                const color = pair.next().?;
                const quantity = try std.fmt.parseUnsigned(u8, quantity_str, 10);
                if (std.mem.eql(u8, color, "red") and quantity > red) {
                    if (part_two) {
                        red = quantity;
                        continue;
                    }
                    valid = false;
                    break :subset_block;
                } else if (std.mem.eql(u8, color, "green") and quantity > green) {
                    if (part_two) {
                        green = quantity;
                        continue;
                    }
                    valid = false;
                    break :subset_block;
                } else if (std.mem.eql(u8, color, "blue") and quantity > blue) {
                    if (part_two) {
                        blue = quantity;
                        continue;
                    }
                    valid = false;
                    break :subset_block;
                }
            }
        }
        if (part_two) {
            std.debug.print(" Maximas R: {d} G: {d} B: {d}", .{ red, green, blue });
            accumulator += red * green * blue;
        }
        if (valid) {
            accumulator += game_id;
        }
        std.debug.print("    VALID = {s}\n", .{if (valid) "true" else "false"});
    }
    std.debug.print("Result: {d}\n", .{accumulator});
    return accumulator;
}
