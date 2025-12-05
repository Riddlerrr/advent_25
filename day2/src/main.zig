const std = @import("std");
const day2 = @import("day2");

const IdRange = struct {
    start: u64,
    end: u64,

    pub fn init(start: u64, end: u64) IdRange {
        return IdRange{
            .start = start,
            .end = end,
        };
    }
};

const IdRangeList = struct {
    allocator: std.mem.Allocator,
    id_ranges: std.ArrayList(IdRange),
    current_index: usize,

    pub fn init(allocator: std.mem.Allocator) IdRangeList {
        return IdRangeList{
            .allocator = allocator,
            .id_ranges = .empty,
            .current_index = 0,
        };
    }

    pub fn append(self: *IdRangeList, id_range: IdRange) !void {
        try self.id_ranges.append(self.allocator, id_range);
    }

    pub fn items(self: *IdRangeList) []const IdRange {
        return self.id_ranges.items;
    }

    pub fn next(self: *IdRangeList) ?IdRange {
        if (self.current_index >= self.id_ranges.items.len) {
            return null;
        }
        const id_range = self.id_ranges.items[self.current_index];
        self.current_index += 1;
        return id_range;
    }

    pub fn deinit(self: *IdRangeList) void {
        self.id_ranges.deinit(self.allocator);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = "52500467-52574194,655624494-655688785,551225-576932,8418349387-8418411293,678-1464,33-79,74691-118637,8787869169-8787890635,9898977468-9899009083,548472423-548598890,337245835-337375280,482823-543075,926266-991539,1642682920-1642753675,3834997-3940764,1519-2653,39697698-39890329,3-21,3251796-3429874,3467-9298,26220798-26290827,80-124,200638-280634,666386-710754,21329-64315,250-528,9202893-9264498,819775-903385,292490-356024,22-32,2663033-2791382,133-239,56514707-56704320,432810-458773,4949427889-4949576808";
    var id_list = try parseIds(allocator, input);
    defer id_list.deinit();

    // Part 1: Find invalid IDs (first half equals second half)
    var invalid_ids_part1 = std.ArrayList(u64).empty;
    defer invalid_ids_part1.deinit(allocator);

    for (id_list.items()) |range| {
        var id = range.start;
        while (id <= range.end) : (id += 1) {
            if (isInvalidIdPart1(id)) {
                try invalid_ids_part1.append(allocator, id);
            }
        }
    }

    var sum_part1: u64 = 0;
    for (invalid_ids_part1.items) |id| {
        sum_part1 += id;
    }

    // Part 2: Find invalid IDs (any repeating sequence at least twice)
    var invalid_ids_part2 = std.ArrayList(u64).empty;
    defer invalid_ids_part2.deinit(allocator);

    for (id_list.items()) |range| {
        var id = range.start;
        while (id <= range.end) : (id += 1) {
            if (isInvalidIdPart2(id)) {
                try invalid_ids_part2.append(allocator, id);
            }
        }
    }

    var sum_part2: u64 = 0;
    for (invalid_ids_part2.items) |id| {
        sum_part2 += id;
    }

    // Print results to stdout
    const stdout = std.fs.File.stdout();
    var buf: [64]u8 = undefined;

    const part1_str = std.fmt.bufPrint(&buf, "Part 1: {d}\n", .{sum_part1}) catch return;
    try stdout.writeAll(part1_str);

    const part2_str = std.fmt.bufPrint(&buf, "Part 2: {d}\n", .{sum_part2}) catch return;
    try stdout.writeAll(part2_str);
}

fn parseIds(allocator: std.mem.Allocator, input: []const u8) !IdRangeList {
    var id_list = IdRangeList.init(allocator);

    var range_iter = std.mem.splitScalar(u8, input, ',');
    while (range_iter.next()) |range_str| {
        var dash_iter = std.mem.splitScalar(u8, range_str, '-');
        const start_str = dash_iter.next() orelse continue;
        const end_str = dash_iter.next() orelse continue;

        const start = std.fmt.parseInt(u64, start_str, 10) catch continue;
        const end = std.fmt.parseInt(u64, end_str, 10) catch continue;

        try id_list.append(IdRange.init(start, end));
    }

    return id_list;
}

// Part 1: Check if first half equals second half (only for even length numbers)
fn isInvalidIdPart1(id: u64) bool {
    var buf: [24]u8 = undefined;
    const digits = std.fmt.bufPrint(&buf, "{d}", .{id}) catch return false;
    const len = digits.len;

    if (len % 2 == 0) {
        const half = len / 2;
        if (std.mem.eql(u8, digits[0..half], digits[half..])) {
            return true;
        }
    }

    return false;
}

// Part 2: Check if made of any repeating sequence (at least 2 times)
fn isInvalidIdPart2(id: u64) bool {
    var buf: [24]u8 = undefined;
    const digits = std.fmt.bufPrint(&buf, "{d}", .{id}) catch return false;
    const len = digits.len;

    // Try all possible pattern lengths from 1 to len/2
    var pattern_len: usize = 1;
    while (pattern_len <= len / 2) : (pattern_len += 1) {
        // Pattern must divide evenly into the total length
        if (len % pattern_len == 0) {
            const pattern = digits[0..pattern_len];
            var is_repeating = true;

            // Check if all subsequent chunks match the pattern
            var i: usize = pattern_len;
            while (i < len) : (i += pattern_len) {
                if (!std.mem.eql(u8, digits[i .. i + pattern_len], pattern)) {
                    is_repeating = false;
                    break;
                }
            }

            if (is_repeating) {
                return true;
            }
        }
    }

    return false;
}
