const std = @import("std");

/// Error type for file operations
pub const FileError = error{
    FileNotFound,
    AccessDenied,
    OutOfMemory,
    ReadError,
};

/// Reads the entire contents of a file and returns it as a slice.
/// The caller owns the returned memory and must free it using the provided allocator.
///
/// Example:
/// ```zig
/// const content = try utils.file.readFileAlloc(allocator, "src/input.txt");
/// defer allocator.free(content);
/// ```
pub fn readFileAlloc(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        return switch (err) {
            error.FileNotFound => error.FileNotFound,
            error.AccessDenied => error.AccessDenied,
            else => error.ReadError,
        };
    };
    defer file.close();

    return file.readToEndAlloc(allocator, 1024 * 1024 * 10) catch |err| {
        return switch (err) {
            error.OutOfMemory => error.OutOfMemory,
            else => error.ReadError,
        };
    };
}

/// Reads the entire contents of a file with a custom max size.
/// The caller owns the returned memory and must free it using the provided allocator.
pub fn readFileAllocWithMaxSize(allocator: std.mem.Allocator, path: []const u8, max_size: usize) ![]u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        return switch (err) {
            error.FileNotFound => error.FileNotFound,
            error.AccessDenied => error.AccessDenied,
            else => error.ReadError,
        };
    };
    defer file.close();

    return file.readToEndAlloc(allocator, max_size) catch |err| {
        return switch (err) {
            error.OutOfMemory => error.OutOfMemory,
            else => error.ReadError,
        };
    };
}

/// Iterator for iterating over non-empty lines in file content.
/// Handles both Unix (\n) and Windows (\r\n) line endings.
pub const LineIterator = struct {
    inner: std.mem.SplitIterator(u8, .any),

    pub fn init(content: []const u8) LineIterator {
        return .{
            .inner = std.mem.splitAny(u8, content, "\n\r"),
        };
    }

    /// Returns the next non-empty, trimmed line.
    pub fn next(self: *LineIterator) ?[]const u8 {
        while (self.inner.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \t");
            if (trimmed.len > 0) {
                return trimmed;
            }
        }
        return null;
    }

    /// Resets the iterator to the beginning.
    pub fn reset(self: *LineIterator) void {
        self.inner.reset();
    }
};

/// Creates a line iterator over the given content.
/// Skips empty lines and trims whitespace.
///
/// Example:
/// ```zig
/// const content = try utils.file.readFileAlloc(allocator, "input.txt");
/// defer allocator.free(content);
///
/// var lines = utils.file.lines(content);
/// while (lines.next()) |line| {
///     // process line
/// }
/// ```
pub fn lines(content: []const u8) LineIterator {
    return LineIterator.init(content);
}

/// Reads a file and returns a line iterator.
/// This is a convenience function that combines readFileAlloc and lines.
/// The caller owns the returned content and must free it.
///
/// Example:
/// ```zig
/// const result = try utils.file.readLines(allocator, "input.txt");
/// defer allocator.free(result.content);
///
/// while (result.iter.next()) |line| {
///     // process line
/// }
/// ```
pub const ReadLinesResult = struct {
    content: []u8,
    iter: LineIterator,
};

pub fn readLines(allocator: std.mem.Allocator, path: []const u8) !ReadLinesResult {
    const content = try readFileAlloc(allocator, path);
    return .{
        .content = content,
        .iter = lines(content),
    };
}

// Tests
test "LineIterator skips empty lines" {
    const content = "line1\n\nline2\r\n\r\nline3";
    var iter = lines(content);

    try std.testing.expectEqualStrings("line1", iter.next().?);
    try std.testing.expectEqualStrings("line2", iter.next().?);
    try std.testing.expectEqualStrings("line3", iter.next().?);
    try std.testing.expect(iter.next() == null);
}

test "LineIterator trims whitespace" {
    const content = "  line1  \n\tline2\t\n   line3   ";
    var iter = lines(content);

    try std.testing.expectEqualStrings("line1", iter.next().?);
    try std.testing.expectEqualStrings("line2", iter.next().?);
    try std.testing.expectEqualStrings("line3", iter.next().?);
    try std.testing.expect(iter.next() == null);
}
