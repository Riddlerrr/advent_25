const std = @import("std");

/// Buffered stdout writer for convenient output.
pub const Stdout = struct {
    file: std.fs.File,
    buf: [4096]u8 = undefined,

    const Self = @This();

    pub fn init() Self {
        return .{ .file = std.fs.File.stdout() };
    }

    /// Print formatted output to stdout.
    pub fn print(self: *Self, comptime fmt: []const u8, args: anytype) !void {
        const str = std.fmt.bufPrint(&self.buf, fmt, args) catch return error.BufferTooSmall;
        try self.file.writeAll(str);
    }

    /// Print formatted output followed by a newline.
    pub fn println(self: *Self, comptime fmt: []const u8, args: anytype) !void {
        const str = std.fmt.bufPrint(&self.buf, fmt ++ "\n", args) catch return error.BufferTooSmall;
        try self.file.writeAll(str);
    }

    /// Write a string directly to stdout.
    pub fn write(self: *Self, bytes: []const u8) !void {
        try self.file.writeAll(bytes);
    }

    /// Write a string followed by a newline.
    pub fn writeLine(self: *Self, bytes: []const u8) !void {
        try self.file.writeAll(bytes);
        try self.file.writeAll("\n");
    }
};

// Thread-local stdout buffer for convenience functions
threadlocal var print_buf: [4096]u8 = undefined;

/// Convenience function to print a line to stdout directly.
pub fn println(comptime fmt: []const u8, args: anytype) !void {
    const stdout = std.fs.File.stdout();
    const str = std.fmt.bufPrint(&print_buf, fmt ++ "\n", args) catch return error.BufferTooSmall;
    try stdout.writeAll(str);
}

/// Print without newline.
pub fn print(comptime fmt: []const u8, args: anytype) !void {
    const stdout = std.fs.File.stdout();
    const str = std.fmt.bufPrint(&print_buf, fmt, args) catch return error.BufferTooSmall;
    try stdout.writeAll(str);
}
