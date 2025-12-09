const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const Allocator = std.mem.Allocator;
const Io = std.Io;

const util = @import("util");
const IntervalMap = util.IntervalMap;

const IntervalIterator = util.Iterator(IntervalMap.Interval, .{ .scalar = '\n' }, struct {
    fn p(line: []const u8) !IntervalMap.Interval {
        const idx = mem.findScalar(u8, line, '-') orelse
            return error.InvalidIntervalFormat;
        return .{
            try fmt.parseInt(i64, line[0..idx], 10),
            try fmt.parseInt(i64, line[idx + 1 ..], 10),
        };
    }
}.p);

const QueriesIterator = util.Iterator(i64, .{ .scalar = '\n' }, struct {
    fn p(line: []const u8) !i64 {
        return fmt.parseInt(i64, line, 10);
    }
}.p);

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?i64 {
    _ = .{io};

    const sep = mem.indexOf(u8, input, "\n\n") orelse return null;

    var total: i64 = 0;
    var intervals: IntervalMap = .{};
    defer intervals.deinit(allocator);

    var intervalsIt: IntervalIterator = .init(input[0..sep]);
    while (try intervalsIt.next()) |iv|
        try intervals.add(allocator, iv);

    var queriesIt: QueriesIterator = .init(input[sep + 2 ..]);
    while (try queriesIt.next()) |q| total += @intFromBool(intervals.contains(q));

    return total;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = .{io};

    const sep = mem.indexOf(u8, input, "\n\n") orelse return null;

    var intervals: IntervalMap = .{};
    defer intervals.deinit(allocator);

    var intervalsIt: IntervalIterator = .init(input[0..sep]);
    while (try intervalsIt.next()) |iv|
        try intervals.add(allocator, iv);

    return intervals.coverage();
}

test "problem" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    ;

    try std.testing.expectEqual(3, try part1(io, allocator, input));
    try std.testing.expectEqual(14, try part2(io, allocator, input));
}

