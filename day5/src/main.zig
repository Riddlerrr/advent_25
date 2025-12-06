const std = @import("std");
const utils = @import("utils");

const Range = struct {
    start: u64,
    end: u64,

    fn parse(line: []const u8) ?Range {
        var parts = std.mem.splitScalar(u8, line, '-');
        const start = std.fmt.parseInt(u64, parts.next() orelse return null, 10) catch return null;
        const end = std.fmt.parseInt(u64, parts.next() orelse return null, 10) catch return null;
        return .{ .start = start, .end = end };
    }

    fn contains(self: Range, id: u64) bool {
        return id >= self.start and id <= self.end;
    }

    fn lessThan(_: void, a: Range, b: Range) bool {
        return a.start < b.start;
    }
};

const Database = struct {
    allocator: std.mem.Allocator,
    ranges: std.ArrayList(Range),
    ids_section: []const u8,

    fn init(allocator: std.mem.Allocator, content: []const u8) !Database {
        var sections = std.mem.splitSequence(u8, content, "\n\n");
        const ranges_section = sections.next() orelse return error.InvalidFormat;
        const ids_section = sections.next() orelse return error.InvalidFormat;

        var ranges: std.ArrayList(Range) = .empty;
        var lines = utils.file.lines(ranges_section);
        while (lines.next()) |line| {
            if (Range.parse(line)) |range| {
                try ranges.append(allocator, range);
            }
        }

        return .{
            .allocator = allocator,
            .ranges = ranges,
            .ids_section = ids_section,
        };
    }

    fn deinit(self: *Database) void {
        self.ranges.deinit(self.allocator);
    }

    fn isFresh(self: *const Database, id: u64) bool {
        for (self.ranges.items) |range| {
            if (range.contains(id)) return true;
        }
        return false;
    }

    fn countFreshIds(self: *const Database) u64 {
        var count: u64 = 0;
        var lines = utils.file.lines(self.ids_section);
        while (lines.next()) |line| {
            const id = std.fmt.parseInt(u64, line, 10) catch continue;
            if (self.isFresh(id)) count += 1;
        }
        return count;
    }

    fn countUniqueFreshIds(self: *Database) u64 {
        const ranges = self.ranges.items;
        if (ranges.len == 0) return 0;

        std.mem.sort(Range, ranges, {}, Range.lessThan);

        var total: u64 = 0;
        var current_start = ranges[0].start;
        var current_end = ranges[0].end;

        for (ranges[1..]) |range| {
            if (range.start <= current_end + 1) {
                current_end = @max(current_end, range.end);
            } else {
                total += current_end - current_start + 1;
                current_start = range.start;
                current_end = range.end;
            }
        }
        return total + current_end - current_start + 1;
    }
};

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const content = try utils.file.readFileAlloc(allocator, "db.txt");
    defer allocator.free(content);

    var db = try Database.init(allocator, content);
    defer db.deinit();

    try utils.io.println("Part 1: {}", .{db.countFreshIds()});
    try utils.io.println("Part 2: {}", .{db.countUniqueFreshIds()});
}
