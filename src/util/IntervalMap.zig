/// A data structure for storing and merging intervals, with point-in-interval queries.
/// Intervals are stored sorted and non-overlapping (merged on insert).
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const Interval = struct { i64, i64 };

intervals: ArrayList(Interval) = .empty,

pub fn deinit(this: *@This(), allocator: Allocator) void {
    this.intervals.deinit(allocator);
}

/// Add an interval [start, end] (inclusive). Merges with any overlapping/adjacent intervals.
pub fn add(this: *@This(), allocator: Allocator, interval: Interval) !void {
    var new_start = interval[0];
    var new_end = interval[1];

    var i: usize = 0;
    while (i < this.intervals.items.len) {
        const iv = this.intervals.items[i];
        if (iv[1] + 1 >= new_start and new_end + 1 >= iv[0]) {
            new_start = @min(new_start, iv[0]);
            new_end = @max(new_end, iv[1]);
            _ = this.intervals.orderedRemove(i);
        } else {
            i += 1;
        }
    }

    var insert_pos: usize = 0;
    while (insert_pos < this.intervals.items.len and this.intervals.items[insert_pos][0] < new_start)
        insert_pos += 1;
    try this.intervals.insert(allocator, insert_pos, .{ new_start, new_end });
}

/// Check if a point falls within any interval.
pub fn contains(this: *const @This(), point: i64) bool {
    var lo: usize = 0;
    var hi: usize = this.intervals.items.len;

    while (lo < hi) {
        const mid = lo + (hi - lo) / 2;
        const iv = this.intervals.items[mid];

        if (point < iv[0]) {
            hi = mid;
        } else if (point > iv[1]) {
            lo = mid + 1;
        } else {
            return true;
        }
    }

    return false;
}

/// Returns the total number of points covered by all intervals.
pub fn coverage(this: *const @This()) u64 {
    var total: u64 = 0;
    for (this.intervals.items) |iv|
        total += @intCast(iv[1] - iv[0] + 1);
    return total;
}

/// Returns the number of stored intervals.
pub fn count(this: *const @This()) usize {
    return this.intervals.items.len;
}

test "IntervalMap basic operations" {
    const allocator = std.testing.allocator;

    var map: @This() = .{};
    defer map.deinit(allocator);

    try map.add(allocator, .{ 1, 9 });
    try std.testing.expectEqual(1, map.count());
    try std.testing.expect(map.contains(1));
    try std.testing.expect(map.contains(5));
    try std.testing.expect(map.contains(9));
    try std.testing.expect(!map.contains(0));
    try std.testing.expect(!map.contains(10));

    try map.add(allocator, .{ 7, 15 });
    try std.testing.expectEqual(1, map.count());
    try std.testing.expect(map.contains(1));
    try std.testing.expect(map.contains(15));
    try std.testing.expect(!map.contains(16));

    try map.add(allocator, .{ 20, 25 });
    try std.testing.expectEqual(2, map.count());
    try std.testing.expect(map.contains(22));
    try std.testing.expect(!map.contains(17));

    try map.add(allocator, .{ 16, 19 });
    try std.testing.expectEqual(1, map.count());
    try std.testing.expect(map.contains(17));
    try std.testing.expectEqual(25, map.coverage());
}
