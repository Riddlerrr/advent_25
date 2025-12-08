const std = @import("std");
const utils = @import("utils");

// ============== Data Structures ==============

const Grid = struct {
    lines: std.ArrayList([]const u8),
    width: usize,
    start_col: usize,
    start_row: usize,

    fn deinit(self: *Grid, allocator: std.mem.Allocator) void {
        self.lines.deinit(allocator);
    }

    fn getCell(self: *const Grid, row: usize, col: usize) u8 {
        return self.lines.items[row][col];
    }

    fn rowCount(self: *const Grid) usize {
        return self.lines.items.len;
    }
};

const Simulation = struct {
    allocator: std.mem.Allocator,
    grid: Grid,

    const Self = @This();

    fn init(allocator: std.mem.Allocator, content: []const u8) !Self {
        var lines: std.ArrayList([]const u8) = .empty;

        var iter = utils.file.lines(content);
        while (iter.next()) |line| {
            try lines.append(allocator, line);
        }

        if (lines.items.len == 0) {
            return .{
                .allocator = allocator,
                .grid = .{
                    .lines = lines,
                    .width = 0,
                    .start_col = 0,
                    .start_row = 0,
                },
            };
        }

        const width = lines.items[0].len;

        // Find starting position S
        const start_row: usize = 0;
        const start_col = std.mem.indexOfScalar(u8, lines.items[0], 'S') orelse 0;

        return .{
            .allocator = allocator,
            .grid = .{
                .lines = lines,
                .width = width,
                .start_col = start_col,
                .start_row = start_row,
            },
        };
    }

    fn deinit(self: *Self) void {
        self.grid.deinit(self.allocator);
    }

    /// Check if a cell is a splitter
    fn isSplitter(cell: u8) bool {
        return cell == '^';
    }

    /// Part 1: Count the total number of times beams are split (beams merge at same position)
    fn solvePart1(self: *const Self) !usize {
        if (self.grid.rowCount() == 0) return 0;

        const width = self.grid.width;

        // Track unique beam positions (beams merge)
        var beams = std.AutoHashMap(usize, void).init(self.allocator);
        defer beams.deinit();
        var next_beams = std.AutoHashMap(usize, void).init(self.allocator);
        defer next_beams.deinit();

        try beams.put(self.grid.start_col, {});

        var total_splits: usize = 0;

        for ((self.grid.start_row + 1)..self.grid.rowCount()) |row_idx| {
            next_beams.clearRetainingCapacity();

            var iter = beams.keyIterator();
            while (iter.next()) |col_ptr| {
                const col = col_ptr.*;
                const cell = self.grid.getCell(row_idx, col);

                if (isSplitter(cell)) {
                    total_splits += 1;
                    if (col > 0) {
                        try next_beams.put(col - 1, {});
                    }
                    if (col + 1 < width) {
                        try next_beams.put(col + 1, {});
                    }
                } else {
                    try next_beams.put(col, {});
                }
            }

            std.mem.swap(std.AutoHashMap(usize, void), &beams, &next_beams);
        }

        return total_splits;
    }

    /// Part 2: Count total timelines (quantum splitting, timelines don't merge)
    fn solvePart2(self: *const Self) !usize {
        if (self.grid.rowCount() == 0) return 0;

        const width = self.grid.width;

        // Track timeline count at each position (timelines don't merge)
        var timelines = std.AutoHashMap(usize, usize).init(self.allocator);
        defer timelines.deinit();
        var next_timelines = std.AutoHashMap(usize, usize).init(self.allocator);
        defer next_timelines.deinit();

        try timelines.put(self.grid.start_col, 1);

        for ((self.grid.start_row + 1)..self.grid.rowCount()) |row_idx| {
            next_timelines.clearRetainingCapacity();

            var iter = timelines.iterator();
            while (iter.next()) |entry| {
                const col = entry.key_ptr.*;
                const count = entry.value_ptr.*;
                const cell = self.grid.getCell(row_idx, col);

                if (isSplitter(cell)) {
                    if (col > 0) {
                        const existing = next_timelines.get(col - 1) orelse 0;
                        try next_timelines.put(col - 1, existing + count);
                    }
                    if (col + 1 < width) {
                        const existing = next_timelines.get(col + 1) orelse 0;
                        try next_timelines.put(col + 1, existing + count);
                    }
                } else {
                    const existing = next_timelines.get(col) orelse 0;
                    try next_timelines.put(col, existing + count);
                }
            }

            std.mem.swap(std.AutoHashMap(usize, usize), &timelines, &next_timelines);
        }

        // Sum all timeline counts
        var total: usize = 0;
        var iter = timelines.valueIterator();
        while (iter.next()) |count| {
            total += count.*;
        }
        return total;
    }
};

// ============== Main ==============

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const content = try utils.file.readFileAlloc(allocator, "schema.txt");
    defer allocator.free(content);

    var sim = try Simulation.init(allocator, content);
    defer sim.deinit();

    const part1 = try sim.solvePart1();
    try utils.io.println("Part 1: {}", .{part1});

    const part2 = try sim.solvePart2();
    try utils.io.println("Part 2: {}", .{part2});
}
