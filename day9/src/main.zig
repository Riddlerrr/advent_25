const std = @import("std");
const utils = @import("utils");

pub const Tile = struct {
    x: i64,
    y: i64,

    pub fn eql(a: Tile, b: Tile) bool {
        return a.x == b.x and a.y == b.y;
    }
};

const TileContext = struct {
    pub fn hash(_: TileContext, tile: Tile) u64 {
        var hasher = std.hash.Wyhash.init(0);
        hasher.update(std.mem.asBytes(&tile.x));
        hasher.update(std.mem.asBytes(&tile.y));
        return hasher.final();
    }

    pub fn eql(_: TileContext, a: Tile, b: Tile) bool {
        return Tile.eql(a, b);
    }
};

const TileSet = std.HashMap(Tile, void, TileContext, std.hash_map.default_max_load_percentage);

/// Helper for 2D grid operations with 1D storage
const Grid = struct {
    data: []bool,
    width: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Grid {
        const data = try allocator.alloc(bool, width * height);
        @memset(data, false);
        return .{ .data = data, .width = width, .allocator = allocator };
    }

    pub fn deinit(self: *Grid) void {
        self.allocator.free(self.data);
    }

    pub fn set(self: *Grid, x: usize, y: usize, value: bool) void {
        self.data[y * self.width + x] = value;
    }

    pub fn get(self: Grid, x: usize, y: usize) bool {
        return self.data[y * self.width + x];
    }
};

/// Summed Area Table for efficient rectangle sum queries
const SummedAreaTable = struct {
    data: []i64,
    width: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, grid: Grid, height: usize) !SummedAreaTable {
        const width = grid.width;
        const data = try allocator.alloc(i64, width * height);

        for (0..height) |yi| {
            for (0..width) |xi| {
                var sum: i64 = if (grid.get(xi, yi)) 1 else 0;

                if (xi > 0) sum += data[yi * width + (xi - 1)];
                if (yi > 0) sum += data[(yi - 1) * width + xi];
                if (xi > 0 and yi > 0) sum -= data[(yi - 1) * width + (xi - 1)];

                data[yi * width + xi] = sum;
            }
        }

        return .{ .data = data, .width = width, .allocator = allocator };
    }

    pub fn deinit(self: *SummedAreaTable) void {
        self.allocator.free(self.data);
    }

    /// Query sum of rectangle from (x1, y1) to (x2, y2) inclusive
    pub fn query(self: SummedAreaTable, x1: usize, y1: usize, x2: usize, y2: usize) i64 {
        var sum = self.data[y2 * self.width + x2];
        if (x1 > 0) sum -= self.data[y2 * self.width + (x1 - 1)];
        if (y1 > 0) sum -= self.data[(y1 - 1) * self.width + x2];
        if (x1 > 0 and y1 > 0) sum += self.data[(y1 - 1) * self.width + (x1 - 1)];
        return sum;
    }
};

pub const Map = struct {
    red_tiles: std.ArrayList(Tile),
    red_tile_set: TileSet,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, content: []const u8) Map {
        var red_tiles: std.ArrayList(Tile) = .empty;
        var red_tile_set = TileSet.init(allocator);

        var iter = utils.file.lines(content);
        while (iter.next()) |line| {
            if (line.len == 0) continue;

            var coords = std.mem.splitScalar(u8, line, ',');
            const x_str = coords.next() orelse continue;
            const y_str = coords.next() orelse continue;

            const tile = Tile{
                .x = utils.fmt.parseInt(i64, x_str),
                .y = utils.fmt.parseInt(i64, y_str),
            };

            red_tiles.append(allocator, tile) catch continue;
            red_tile_set.put(tile, {}) catch continue;
        }

        return .{
            .red_tiles = red_tiles,
            .red_tile_set = red_tile_set,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Map) void {
        self.red_tiles.deinit(self.allocator);
        self.red_tile_set.deinit();
    }

    pub fn maxAreaPart1(self: Map) i64 {
        var max_area: i64 = 0;

        for (self.red_tiles.items, 0..) |tile_a, i| {
            for (self.red_tiles.items[i + 1 ..]) |tile_b| {
                const width: i64 = @intCast(@abs(tile_b.x - tile_a.x) + 1);
                const height: i64 = @intCast(@abs(tile_b.y - tile_a.y) + 1);
                const area = width * height;

                max_area = @max(max_area, area);
            }
        }

        return max_area;
    }

    fn isRedTile(self: Map, x: i64, y: i64) bool {
        return self.red_tile_set.contains(.{ .x = x, .y = y });
    }

    fn isOnEdge(self: Map, x: i64, y: i64) bool {
        const n = self.red_tiles.items.len;

        for (0..n) |i| {
            const tile1 = self.red_tiles.items[i];
            const tile2 = self.red_tiles.items[(i + 1) % n];

            // Check horizontal line
            if (tile1.y == tile2.y and tile1.y == y) {
                const min_x = @min(tile1.x, tile2.x);
                const max_x = @max(tile1.x, tile2.x);
                if (x >= min_x and x <= max_x) return true;
            }

            // Check vertical line
            if (tile1.x == tile2.x and tile1.x == x) {
                const min_y = @min(tile1.y, tile2.y);
                const max_y = @max(tile1.y, tile2.y);
                if (y >= min_y and y <= max_y) return true;
            }
        }

        return false;
    }

    fn isInsidePolygon(self: Map, x: i64, y: i64) bool {
        var inside = false;
        const n = self.red_tiles.items.len;

        for (0..n) |i| {
            const tile1 = self.red_tiles.items[i];
            const tile2 = self.red_tiles.items[(i + 1) % n];

            if ((tile1.y > y) != (tile2.y > y)) {
                const x_intersect = tile1.x + @divTrunc((y - tile1.y) * (tile2.x - tile1.x), (tile2.y - tile1.y));
                if (x < x_intersect) {
                    inside = !inside;
                }
            }
        }

        return inside;
    }

    fn isValidTile(self: Map, x: i64, y: i64) bool {
        return self.isRedTile(x, y) or self.isOnEdge(x, y) or self.isInsidePolygon(x, y);
    }

    pub fn maxAreaPart2(self: Map) !i64 {
        if (self.red_tiles.items.len == 0) return 0;

        // Collect coordinates for compression
        var x_coords = try self.allocator.alloc(i64, self.red_tiles.items.len);
        defer self.allocator.free(x_coords);
        var y_coords = try self.allocator.alloc(i64, self.red_tiles.items.len);
        defer self.allocator.free(y_coords);

        for (self.red_tiles.items, 0..) |tile, i| {
            x_coords[i] = tile.x;
            y_coords[i] = tile.y;
        }

        // Sort and deduplicate coordinates
        var x_unique = try utils.slice.sortAndDedupe(i64, self.allocator, x_coords);
        defer x_unique.deinit(self.allocator);
        var y_unique = try utils.slice.sortAndDedupe(i64, self.allocator, y_coords);
        defer y_unique.deinit(self.allocator);

        const width = x_unique.items.len;
        const height = y_unique.items.len;

        // Build validity grid
        var grid = try Grid.init(self.allocator, width, height);
        defer grid.deinit();

        for (0..height) |yi| {
            for (0..width) |xi| {
                grid.set(xi, yi, self.isValidTile(x_unique.items[xi], y_unique.items[yi]));
            }
        }

        // Build summed-area table
        var sat = try SummedAreaTable.init(self.allocator, grid, height);
        defer sat.deinit();

        var max_area: i64 = 0;

        // Try all pairs of red tiles as rectangle corners
        for (self.red_tiles.items, 0..) |tile_a, i| {
            for (self.red_tiles.items[i + 1 ..]) |tile_b| {
                const rect_min_x = @min(tile_a.x, tile_b.x);
                const rect_max_x = @max(tile_a.x, tile_b.x);
                const rect_min_y = @min(tile_a.y, tile_b.y);
                const rect_max_y = @max(tile_a.y, tile_b.y);

                // Find compressed coordinates
                const x1_idx = std.mem.indexOfScalar(i64, x_unique.items, rect_min_x) orelse continue;
                const x2_idx = std.mem.indexOfScalar(i64, x_unique.items, rect_max_x) orelse continue;
                const y1_idx = std.mem.indexOfScalar(i64, y_unique.items, rect_min_y) orelse continue;
                const y2_idx = std.mem.indexOfScalar(i64, y_unique.items, rect_max_y) orelse continue;

                // Check if all cells in compressed rectangle are valid
                const sum = sat.query(x1_idx, y1_idx, x2_idx, y2_idx);
                const compressed_cells: i64 = @intCast((x2_idx - x1_idx + 1) * (y2_idx - y1_idx + 1));

                if (sum == compressed_cells) {
                    const actual_area = (rect_max_x - rect_min_x + 1) * (rect_max_y - rect_min_y + 1);
                    max_area = @max(max_area, actual_area);
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

    try utils.io.println("Part 1: {d}", .{map.maxAreaPart1()});
    try utils.io.println("Part 2: {d}", .{try map.maxAreaPart2()});
}

const test_data =
    \\7,1
    \\11,1
    \\11,7
    \\9,7
    \\9,5
    \\2,5
    \\2,3
    \\7,3
;

test "maxAreaPart1 should return 50 for test data" {
    var map = Map.init(std.testing.allocator, test_data);
    defer map.deinit();

    const max_area = map.maxAreaPart1();
    try std.testing.expectEqual(@as(i64, 50), max_area);
}

test "maxAreaPart2 should return correct area for test data" {
    var map = Map.init(std.testing.allocator, test_data);
    defer map.deinit();

    const max_area = try map.maxAreaPart2();
    try std.testing.expectEqual(@as(i64, 24), max_area);
}
