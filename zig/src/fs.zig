const std = @import("std");
const File = std.fs.File;
const OpenFlags = File.OpenFlags;
const FileReadError = File.ReadError;
const expect = std.testing.expect;
const TryIterator = @import("iterators/try_iterator.zig").TryIterator;

const FileBytesIteratorOptions = struct { buffer_size: usize = 512 };

pub fn FileBytesIterator(comptime options: FileBytesIteratorOptions) type {
    comptime {
        if (options.buffer_size == 0) {
            @compileError("invalid buffer_size value 0");
        }
    }
    return struct {
        const Self = @This();
        const FileByteIteratorType = TryIterator(u8, FileReadError);
        const vtable = FileByteIteratorType.VTable{ .next = next };

        file: File,
        file_reader: File.Reader,
        buffer: [options.buffer_size]u8,
        last_bytes_read: usize,
        current_index: usize,

        pub fn init(file: File) Self {
            return Self{ .file = file, .file_reader = file.reader(), .buffer = undefined, .last_bytes_read = 1, .current_index = 1 };
        }

        pub fn iterator(self: *Self) FileByteIteratorType {
            return FileByteIteratorType{ .ptr = self, .vtable = &vtable };
        }

        fn next(ctx: *anyopaque) !?u8 {
            const self: *Self = @ptrCast(@alignCast(ctx));
            if (self.last_bytes_read == 0) {
                return null;
            }
            if (self.current_index == self.last_bytes_read) {
                self.last_bytes_read = try self.file_reader.read(&self.buffer);
                if (self.last_bytes_read == 0) {
                    return null;
                }
                self.current_index = 0;
            }
            const byte = self.buffer[self.current_index];
            self.current_index += 1;
            return byte;
        }
    };
}

test "FileBytesIterator.next.buffer_size smaller than file bytes" {
    const tmpDir = std.testing.tmpDir(.{}).dir;
    try tmpDir.writeFile("file_bytes_iterator", "\nHello");
    var file = try tmpDir.openFile("file_bytes_iterator", OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    var file_bytes_iterator = FileBytesIterator(.{ .buffer_size = 5 }).init(file);
    var iterator = file_bytes_iterator.iterator();
    try expect(try iterator.next() == '\n');
    try expect(try iterator.next() == 'H');
    try expect(try iterator.next() == 'e');
    try expect(try iterator.next() == 'l');
    try expect(try iterator.next() == 'l');
    try expect(try iterator.next() == 'o');
    try expect(try iterator.next() == null);
    try expect(try iterator.next() == null);
}

test "FileBytesIterator.next.buffer_size same as file bytes" {
    const tmpDir = std.testing.tmpDir(.{}).dir;
    try tmpDir.writeFile("file_bytes_iterator", "\nHello");
    var file = try tmpDir.openFile("file_bytes_iterator", OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    var file_bytes_iterator = FileBytesIterator(.{ .buffer_size = 6 }).init(file);
    var iterator = file_bytes_iterator.iterator();
    try expect(try iterator.next() == '\n');
    try expect(try iterator.next() == 'H');
    try expect(try iterator.next() == 'e');
    try expect(try iterator.next() == 'l');
    try expect(try iterator.next() == 'l');
    try expect(try iterator.next() == 'o');
    try expect(try iterator.next() == null);
    try expect(try iterator.next() == null);
}

test "FileBytesIterator.next.buffer_size bigger than file bytes" {
    const tmpDir = std.testing.tmpDir(.{}).dir;
    try tmpDir.writeFile("file_bytes_iterator", "\nHello");
    var file = try tmpDir.openFile("file_bytes_iterator", OpenFlags{ .mode = std.fs.File.OpenMode.read_only });
    var file_bytes_iterator = FileBytesIterator(.{ .buffer_size = 7 }).init(file);
    var iterator = file_bytes_iterator.iterator();
    try expect(try iterator.next() == '\n');
    try expect(try iterator.next() == 'H');
    try expect(try iterator.next() == 'e');
    try expect(try iterator.next() == 'l');
    try expect(try iterator.next() == 'l');
    try expect(try iterator.next() == 'o');
    try expect(try iterator.next() == null);
    try expect(try iterator.next() == null);
}
