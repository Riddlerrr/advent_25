const std = @import("std");
const utils = @import("utils");

// ============== Data Structures ==============

const Operator = struct {
    pos: usize,
    op: u8,
};

const Problem = struct {
    operator: Operator,
    width: usize,
};

const Worksheet = struct {
    allocator: std.mem.Allocator,
    lines: std.ArrayList([]const u8),
    problems: std.ArrayList(Problem),

    const Self = @This();

    fn init(allocator: std.mem.Allocator, content: []const u8) !Self {
        var lines: std.ArrayList([]const u8) = .empty;
        var problems: std.ArrayList(Problem) = .empty;

        // Parse lines preserving whitespace
        var iter = std.mem.splitAny(u8, content, "\n\r");
        while (iter.next()) |line| {
            if (line.len > 0) {
                try lines.append(allocator, line);
            }
        }

        if (lines.items.len == 0) {
            return .{ .allocator = allocator, .lines = lines, .problems = problems };
        }

        const operator_line = lines.items[lines.items.len - 1];
        const number_lines = lines.items[0 .. lines.items.len - 1];

        // Find operators and calculate max line length
        var operators: std.ArrayList(Operator) = .empty;
        defer operators.deinit(allocator);

        for (operator_line, 0..) |c, i| {
            if (c == '+' or c == '*') {
                try operators.append(allocator, .{ .pos = i, .op = c });
            }
        }

        var max_len: usize = operator_line.len;
        for (number_lines) |line| {
            if (line.len > max_len) max_len = line.len;
        }

        // Create problems with boundaries
        for (operators.items, 0..) |op, i| {
            const end = if (i + 1 < operators.items.len) operators.items[i + 1].pos else max_len;
            try problems.append(allocator, .{
                .operator = op,
                .width = end - op.pos,
            });
        }

        return .{ .allocator = allocator, .lines = lines, .problems = problems };
    }

    fn deinit(self: *Self) void {
        self.lines.deinit(self.allocator);
        self.problems.deinit(self.allocator);
    }

    fn numberLines(self: *const Self) []const []const u8 {
        if (self.lines.items.len == 0) return &.{};
        return self.lines.items[0 .. self.lines.items.len - 1];
    }

    // ============== Part 1 ==============

    fn solvePart1(self: *Self) !u64 {
        if (self.problems.items.len == 0) return 0;

        // Collect numbers for each problem
        var problem_numbers: std.ArrayList(std.ArrayList(u64)) = .empty;
        defer {
            for (problem_numbers.items) |*nums| nums.deinit(self.allocator);
            problem_numbers.deinit(self.allocator);
        }

        for (self.problems.items) |_| {
            try problem_numbers.append(self.allocator, .empty);
        }

        // Parse numbers sequentially from each line
        for (self.numberLines()) |line| {
            var col: usize = 0;
            var problem_idx: usize = 0;

            while (col < line.len and problem_idx < self.problems.items.len) {
                // Skip spaces
                while (col < line.len and line[col] == ' ') col += 1;
                if (col >= line.len) break;

                // Read number
                const num_start = col;
                while (col < line.len and line[col] >= '0' and line[col] <= '9') col += 1;

                if (col > num_start) {
                    const num = std.fmt.parseInt(u64, line[num_start..col], 10) catch continue;
                    try problem_numbers.items[problem_idx].append(self.allocator, num);
                    problem_idx += 1;
                }
            }
        }

        // Calculate grand total
        var total: u64 = 0;
        for (problem_numbers.items, self.problems.items) |nums, problem| {
            total += applyOperator(problem.operator.op, nums.items);
        }
        return total;
    }

    // ============== Part 2 ==============

    const NumberPos = struct {
        str: []const u8,
        start: usize,
        end: usize,
    };

    fn solvePart2(self: *Self) !u64 {
        if (self.problems.items.len == 0) return 0;

        var total: u64 = 0;
        var numbers: std.ArrayList(NumberPos) = .empty;
        defer numbers.deinit(self.allocator);

        for (self.problems.items) |problem| {
            const start = problem.operator.pos;
            const end = start + problem.width;

            // Collect number positions for this problem
            numbers.clearRetainingCapacity();
            for (self.numberLines()) |line| {
                if (start >= line.len) continue;
                const segment = line[start..@min(end, line.len)];

                // Find contiguous number in segment
                if (findNumber(segment)) |num_pos| {
                    try numbers.append(self.allocator, num_pos);
                }
            }

            total += self.calculatePart2Problem(numbers.items, problem);
        }

        return total;
    }

    fn calculatePart2Problem(self: *const Self, numbers: []const NumberPos, problem: Problem) u64 {
        _ = self;
        var result_buf: [100]u64 = undefined;
        var count: usize = 0;

        // Read columns from right to left
        var col: usize = problem.width;
        while (col > 0) {
            col -= 1;
            var num: u64 = 0;
            var has_digit = false;

            // Read top to bottom for this column
            for (numbers) |n| {
                if (col >= n.start and col < n.end) {
                    const c = n.str[col - n.start];
                    if (c >= '0' and c <= '9') {
                        num = num * 10 + (c - '0');
                        has_digit = true;
                    }
                }
            }

            if (has_digit and count < 100) {
                result_buf[count] = num;
                count += 1;
            }
        }

        return applyOperator(problem.operator.op, result_buf[0..count]);
    }
};

// ============== Helper Functions ==============

fn applyOperator(operator: u8, numbers: []const u64) u64 {
    if (numbers.len == 0) return 0;
    var result = numbers[0];
    for (numbers[1..]) |num| {
        switch (operator) {
            '+' => result += num,
            '*' => result *= num,
            else => {},
        }
    }
    return result;
}

fn findNumber(segment: []const u8) ?Worksheet.NumberPos {
    var num_start: ?usize = null;
    var num_end: usize = 0;

    for (segment, 0..) |c, i| {
        if (c >= '0' and c <= '9') {
            if (num_start == null) num_start = i;
            num_end = i + 1;
        } else if (num_start != null) {
            break;
        }
    }

    if (num_start) |ns| {
        return .{ .str = segment[ns..num_end], .start = ns, .end = num_end };
    }
    return null;
}

// ============== Main ==============

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const content = try utils.file.readFileAlloc(allocator, "math.txt");
    defer allocator.free(content);

    var worksheet = try Worksheet.init(allocator, content);
    defer worksheet.deinit();

    try utils.io.println("Part 1: {}", .{try worksheet.solvePart1()});
    try utils.io.println("Part 2: {}", .{try worksheet.solvePart2()});
}
