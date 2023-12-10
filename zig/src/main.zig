const std = @import("std");
const Allocator = std.mem.Allocator;
const OpenFlags = std.fs.File.OpenFlags;
const File = std.fs.File;
const FileBytesIterator = @import("fs.zig").FileBytesIterator(.{});
const day_one = @import("days/one.zig").day_one;
const day_two = @import("days/two.zig").day_two;

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
    var file_bytes_iterator = FileBytesIterator.init(file);
    if (std.mem.eql(u8, day_to_run, "one")) {
        _ = try day_one(allocator, file_bytes_iterator.iterator(), part_to_run);
    }
    if (std.mem.eql(u8, day_to_run, "two")) {
        _ = try day_two(allocator, file_bytes_iterator.iterator(), part_to_run);
    }
}
