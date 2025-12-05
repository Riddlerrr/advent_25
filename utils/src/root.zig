const std = @import("std");

pub const file = @import("file.zig");

test {
    std.testing.refAllDecls(@This());
}
