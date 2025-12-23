const std = @import("std");

/// Sorts and removes duplicates from a list, returning a new deduplicated list.
/// The input slice is sorted in-place as a side effect.
/// Returns an ArrayList containing only unique values in ascending order.
pub fn sortAndDedupe(comptime T: type, allocator: std.mem.Allocator, items: []T) !std.ArrayList(T) {
    var result: std.ArrayList(T) = .empty;

    if (items.len == 0) return result;

    std.mem.sort(T, items, {}, comptime std.sort.asc(T));

    try result.append(allocator, items[0]);
    for (items[1..]) |val| {
        if (val != result.items[result.items.len - 1]) {
            try result.append(allocator, val);
        }
    }

    return result;
}

test "sortAndDedupe with integers" {
    const allocator = std.testing.allocator;

    var items = [_]i64{ 5, 2, 8, 2, 5, 1, 8, 3 };
    var result = try sortAndDedupe(i64, allocator, &items);
    defer result.deinit(allocator);

    try std.testing.expectEqualSlices(i64, &[_]i64{ 1, 2, 3, 5, 8 }, result.items);
}

test "sortAndDedupe with empty slice" {
    const allocator = std.testing.allocator;

    var items = [_]i64{};
    var result = try sortAndDedupe(i64, allocator, &items);
    defer result.deinit(allocator);

    try std.testing.expectEqual(@as(usize, 0), result.items.len);
}

test "sortAndDedupe with all unique values" {
    const allocator = std.testing.allocator;

    var items = [_]i64{ 3, 1, 4, 2 };
    var result = try sortAndDedupe(i64, allocator, &items);
    defer result.deinit(allocator);

    try std.testing.expectEqualSlices(i64, &[_]i64{ 1, 2, 3, 4 }, result.items);
}

test "sortAndDedupe with all same values" {
    const allocator = std.testing.allocator;

    var items = [_]i64{ 5, 5, 5, 5 };
    var result = try sortAndDedupe(i64, allocator, &items);
    defer result.deinit(allocator);

    try std.testing.expectEqualSlices(i64, &[_]i64{5}, result.items);
}
