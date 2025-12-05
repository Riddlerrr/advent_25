const std = @import("std");
const utils = @import("utils");

const Roll = struct {
    x: usize,
    y: usize,
    grid: *const Grid,

    const directions = [_][2]i32{
        .{ -1, -1 }, .{ 0, -1 }, .{ 1, -1 }, // top row
        .{ -1, 0 }, .{ 1, 0 }, // middle row (left, right)
        .{ -1, 1 }, .{ 0, 1 }, .{ 1, 1 }, // bottom row
    };

    pub fn init(grid: *const Grid, x: usize, y: usize) ?Roll {
        if (grid.rows.items[y][x] == '@') {
            return Roll{ .x = x, .y = y, .grid = grid };
        }
        return null;
    }

    pub fn neighborCount(self: Roll) u32 {
        var count: u32 = 0;
        const rows = self.grid.items();
        for (directions) |dir| {
            const nx: i64 = @as(i64, @intCast(self.x)) + dir[0];
            const ny: i64 = @as(i64, @intCast(self.y)) + dir[1];

            if (nx >= 0 and ny >= 0 and ny < rows.len) {
                const uy: usize = @intCast(ny);
                const ux: usize = @intCast(nx);
                if (ux < rows[uy].len and rows[uy][ux] == '@') {
                    count += 1;
                }
            }
        }
        return count;
    }

    pub fn canBeRemoved(self: Roll) bool {
        return self.neighborCount() <= 3;
    }
};

const RollIterator = struct {
    grid: *const Grid,
    x: usize,
    y: usize,

    pub fn init(grid: *const Grid) RollIterator {
        return RollIterator{ .grid = grid, .x = 0, .y = 0 };
    }

    pub fn next(self: *RollIterator) ?Roll {
        const rows = self.grid.items();
        while (self.y < rows.len) {
            while (self.x < rows[self.y].len) {
                const x = self.x;
                const y = self.y;
                self.x += 1;
                if (Roll.init(self.grid, x, y)) |roll| {
                    return roll;
                }
            }
            self.x = 0;
            self.y += 1;
        }
        return null;
    }
};

const Grid = struct {
    allocator: std.mem.Allocator,
    rows: std.ArrayList([]u8),

    pub fn init(allocator: std.mem.Allocator, content: []const u8) !Grid {
        var rows: std.ArrayList([]u8) = .empty;
        var line_iter = utils.file.lines(content);
        while (line_iter.next()) |line| {
            const mutable_row = try allocator.alloc(u8, line.len);
            @memcpy(mutable_row, line);
            try rows.append(allocator, mutable_row);
        }
        return Grid{ .allocator = allocator, .rows = rows };
    }

    pub fn deinit(self: *Grid) void {
        for (self.rows.items) |row| {
            self.allocator.free(row);
        }
        self.rows.deinit(self.allocator);
    }

    pub fn items(self: *const Grid) [][]u8 {
        return self.rows.items;
    }

    pub fn rolls(self: *const Grid) RollIterator {
        return RollIterator.init(self);
    }

    fn collectRemovableRolls(self: *const Grid) !std.ArrayList(Roll) {
        var removable: std.ArrayList(Roll) = .empty;
        var iter = self.rolls();
        while (iter.next()) |roll| {
            if (roll.canBeRemoved()) {
                try removable.append(self.allocator, roll);
            }
        }
        return removable;
    }

    pub fn countRemovableRolls(self: *const Grid) !u64 {
        var removable = try self.collectRemovableRolls();
        defer removable.deinit(self.allocator);
        return removable.items.len;
    }

    pub fn removeRemovableRolls(self: *Grid) !u64 {
        var removable = try self.collectRemovableRolls();
        defer removable.deinit(self.allocator);

        for (removable.items) |roll| {
            self.rows.items[roll.y][roll.x] = '.';
        }

        return removable.items.len;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const content = try utils.file.readFileAlloc(allocator, "map.txt");
    defer allocator.free(content);

    var grid = try Grid.init(allocator, content);
    defer grid.deinit();

    // Part 1: count removable rolls before any removal
    const part1 = try grid.countRemovableRolls();

    // Part 2: iteratively remove rolls
    var total_removed: u64 = 0;
    while (true) {
        const removed = try grid.removeRemovableRolls();
        if (removed == 0) break;
        total_removed += removed;
    }

    try utils.io.println("Part 1: {d}", .{part1});
    try utils.io.println("Part 2: {d}", .{total_removed});
}
