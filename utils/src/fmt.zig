const std = @import("std");

/// Parses an integer from a string with base 10.
/// Returns 0 if parsing fails for any reason.
pub fn parseInt(comptime T: type, str: []const u8) T {
    return std.fmt.parseInt(T, str, 10) catch 0;
}
