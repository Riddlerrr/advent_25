const std = @import("std");
const utils = @import("utils");

// ============== Data Structures ==============

const Digit = struct {
    value: u8,
    row: usize,
};

const Column = struct {
    digits: [100]Digit, // digits with their row indices
    count: usize,
    operator: ?u8, // if this column has an operator in last row
};

const Problem = struct {
    columns: std.ArrayList(Column), // columns right-to-left
    operator: u8,
    num_rows: usize,

    fn deinit(self: *Problem, allocator: std.mem.Allocator) void {
        self.columns.deinit(allocator);
    }

    /// Part 1: Each row's digits form a number, then apply operator vertically
    fn solvePart1(self: *const Problem) u64 {
        if (self.columns.items.len == 0 or self.num_rows == 0) return 0;

        // For each row, reconstruct the number from columns (left-to-right = reverse of our storage)
        var row_numbers: [100]u64 = undefined;
        for (0..self.num_rows) |row| {
            var num: u64 = 0;
            // Columns are stored right-to-left, so iterate in reverse for left-to-right
            var col_idx: usize = self.columns.items.len;
            while (col_idx > 0) {
                col_idx -= 1;
                const col = &self.columns.items[col_idx];
                // Find digit for this row in this column
                for (col.digits[0..col.count]) |d| {
                    if (d.row == row) {
                        num = num * 10 + d.value;
                        break;
                    }
                }
            }
            row_numbers[row] = num;
        }

        return self.applyOperator(row_numbers[0..self.num_rows]);
    }

    /// Part 2: Each column's digits form a number (top-to-bottom), then apply operator
    fn solvePart2(self: *const Problem) u64 {
        if (self.columns.items.len == 0) return 0;

        var col_numbers: [100]u64 = undefined;
        var count: usize = 0;

        // Columns are already right-to-left, each column forms a number top-to-bottom
        for (self.columns.items) |col| {
            if (col.count > 0) {
                var num: u64 = 0;
                for (col.digits[0..col.count]) |d| {
                    num = num * 10 + d.value;
                }
                col_numbers[count] = num;
                count += 1;
            }
        }

        return self.applyOperator(col_numbers[0..count]);
    }

    fn applyOperator(self: *const Problem, numbers: []const u64) u64 {
        if (numbers.len == 0) return 0;
        var result = numbers[0];
        for (numbers[1..]) |num| {
            switch (self.operator) {
                '+' => result += num,
                '*' => result *= num,
                else => {},
            }
        }
        return result;
    }
};

const Worksheet = struct {
    allocator: std.mem.Allocator,
    problems: std.ArrayList(Problem),

    const Self = @This();

    fn init(allocator: std.mem.Allocator, content: []const u8) !Self {
        var problems: std.ArrayList(Problem) = .empty;

        // Parse lines preserving whitespace
        var lines: std.ArrayList([]const u8) = .empty;
        defer lines.deinit(allocator);

        var iter = std.mem.splitAny(u8, content, "\n\r");
        while (iter.next()) |line| {
            if (line.len > 0) {
                try lines.append(allocator, line);
            }
        }

        if (lines.items.len == 0) {
            return .{ .allocator = allocator, .problems = problems };
        }

        const operator_line = lines.items[lines.items.len - 1];
        const number_lines = lines.items[0 .. lines.items.len - 1];
        const num_rows = number_lines.len;

        // Find max line width
        var max_width: usize = 0;
        for (lines.items) |line| {
            if (line.len > max_width) max_width = line.len;
        }

        // Parse columns right-to-left
        var current_problem: Problem = .{ .columns = .empty, .operator = 0, .num_rows = num_rows };
        var col: usize = max_width;

        while (col > 0) {
            col -= 1;

            // Check if this column is all whitespace (problem boundary)
            var all_whitespace = true;
            var column = Column{ .digits = undefined, .count = 0, .operator = null };

            // Check operator line
            if (col < operator_line.len) {
                const c = operator_line[col];
                if (c == '+' or c == '*') {
                    column.operator = c;
                    all_whitespace = false;
                } else if (c != ' ') {
                    all_whitespace = false;
                }
            }

            // Check number lines
            for (number_lines, 0..) |line, row| {
                const c = if (col < line.len) line[col] else ' ';
                if (c >= '0' and c <= '9') {
                    column.digits[column.count] = .{ .value = c - '0', .row = row };
                    column.count += 1;
                    all_whitespace = false;
                } else if (c != ' ') {
                    all_whitespace = false;
                }
            }

            if (all_whitespace) {
                // Problem boundary - save current problem if it has data
                if (current_problem.columns.items.len > 0 and current_problem.operator != 0) {
                    try problems.append(allocator, current_problem);
                    current_problem = .{ .columns = .empty, .operator = 0, .num_rows = num_rows };
                }
            } else {
                // Add column to current problem
                if (column.operator) |op| {
                    current_problem.operator = op;
                }
                if (column.count > 0) {
                    try current_problem.columns.append(allocator, column);
                }
            }
        }

        // Don't forget the last problem
        if (current_problem.columns.items.len > 0 and current_problem.operator != 0) {
            try problems.append(allocator, current_problem);
        }

        // Problems were added right-to-left, reverse to get left-to-right order
        std.mem.reverse(Problem, problems.items);

        return .{ .allocator = allocator, .problems = problems };
    }

    fn deinit(self: *Self) void {
        for (self.problems.items) |*p| {
            p.deinit(self.allocator);
        }
        self.problems.deinit(self.allocator);
    }

    fn solvePart1(self: *const Self) u64 {
        var total: u64 = 0;
        for (self.problems.items) |*p| {
            total += p.solvePart1();
        }
        return total;
    }

    fn solvePart2(self: *const Self) u64 {
        var total: u64 = 0;
        for (self.problems.items) |*p| {
            total += p.solvePart2();
        }
        return total;
    }
};

// ============== Main ==============

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const content = try utils.file.readFileAlloc(allocator, "math.txt");
    defer allocator.free(content);

    var worksheet = try Worksheet.init(allocator, content);
    defer worksheet.deinit();

    try utils.io.println("Part 1: {}", .{worksheet.solvePart1()});
    try utils.io.println("Part 2: {}", .{worksheet.solvePart2()});
}
