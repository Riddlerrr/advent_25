const std = @import("std");
const utils = @import("utils");

pub const Tile = struct {
    x: i64,
    y: i64,
};

pub const Map = struct {
    red_tiles: std.ArrayList(Tile),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, content: []const u8) Map {
        var red_tiles: std.ArrayList(Tile) = .empty;
        var iter = utils.file.lines(content);
        while (iter.next()) |line| {
            if (line.len == 0) continue;
            var coords = std.mem.splitScalar(u8, line, ',');

            const x_str = coords.next() orelse continue;
            const y_str = coords.next() orelse continue;

            const x = utils.fmt.parseInt(i64, x_str);
            const y = utils.fmt.parseInt(i64, y_str);

            red_tiles.append(allocator, Tile{ .x = x, .y = y }) catch continue;
        }
        return Map{
            .red_tiles = red_tiles,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Map) void {
        self.red_tiles.deinit(self.allocator);
    }

    pub fn maxRectangleArea(self: Map) i64 {
        var max_area: i64 = 0;

        for (self.red_tiles.items, 0..) |tile_a, i| {
            for (self.red_tiles.items[i + 1 ..]) |tile_b| {
                const width = @as(i64, @intCast(@abs(tile_b.x - tile_a.x))) + 1;
                const height = @as(i64, @intCast(@abs(tile_b.y - tile_a.y))) + 1;

                var area: i64 = 0;
                if (width == 0 or height == 0) {
                    area = @max(width, height);
                } else {
                    area = width * height;
                }

                if (area > max_area) {
                    max_area = area;
                }
            }
        }
        return max_area;
    }
};

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const content = try utils.file.readFileAlloc(allocator, "tiles.txt");
    defer allocator.free(content);

    var map = Map.init(allocator, content);
    defer map.deinit();

    try utils.io.println("Red tiles count: {d}", .{map.red_tiles.items.len});
    try utils.io.println("Part 1: {d}", .{map.maxRectangleArea()});
}
