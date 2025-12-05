const std = @import("std");
const day3 = @import("day3");
const utils = @import("utils");

/// Select N batteries greedily: at each step, pick the max digit from remaining positions
/// that still allows enough batteries to be selected afterward.
/// Returns the concatenated voltage as a number.
fn selectBatteries(line: []const u8, comptime count: usize) u64 {
    var selected: [count]u8 = undefined;
    var num_selected: usize = 0;
    var last_idx: usize = 0;

    while (num_selected < count) {
        const remaining_to_pick = count - num_selected - 1;
        var best_digit: u8 = 0;
        var best_idx: usize = 0;
        var found = false;

        const search_end = if (line.len > remaining_to_pick) line.len - remaining_to_pick else 0;

        for (last_idx..search_end) |idx| {
            const char = line[idx];
            if (char >= '0' and char <= '9') {
                const digit = char - '0';
                if (digit > best_digit) {
                    best_digit = digit;
                    best_idx = idx;
                    found = true;
                }
            }
        }

        if (!found) break;

        selected[num_selected] = best_digit;
        num_selected += 1;
        last_idx = best_idx + 1;
    }

    // Build the voltage number from selected digits
    var voltage: u64 = 0;
    for (0..num_selected) |i| {
        voltage = voltage * 10 + selected[i];
    }
    return voltage;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const content = try utils.file.readFileAlloc(allocator, "src/batteries.txt");
    defer allocator.free(content);

    var total_p1: u64 = 0;
    var total_p2: u64 = 0;

    var line_iter = utils.file.lines(content);
    while (line_iter.next()) |line| {
        total_p1 += selectBatteries(line, 2);
        total_p2 += selectBatteries(line, 12);
    }

    try utils.io.println("Part 1: {d}", .{total_p1});
    try utils.io.println("Part 2: {d}", .{total_p2});
}
