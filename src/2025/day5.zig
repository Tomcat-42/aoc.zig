const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const Allocator = std.mem.Allocator;
const Io = std.Io;

const util = @import("util");
const IntervalMap = util.IntervalMap;

const IntervalIterator = struct {
    tokens: mem.TokenIterator(u8, .scalar),

    pub fn init(input: []const u8) IntervalIterator {
        return .{ .tokens = mem.tokenizeScalar(u8, input, '\n') };
    }

    pub fn next(this: *IntervalIterator) !?IntervalMap.Interval {
        const n = this.tokens.next() orelse return null;
        const idx = mem.findScalar(u8, n, '-') orelse
            return error.InvalidIntervalFormat;

        return .{
            try fmt.parseInt(i64, n[0..idx], 10),
            try fmt.parseInt(i64, n[idx + 1 ..], 10),
        };
    }
};

const QueriesIterator = struct {
    tokens: mem.TokenIterator(u8, .scalar),

    pub fn init(input: []const u8) QueriesIterator {
        return .{ .tokens = mem.tokenizeScalar(u8, input, '\n') };
    }

    pub fn next(this: *QueriesIterator) !?i64 {
        const n = this.tokens.next() orelse return null;
        return try fmt.parseInt(i64, n, 10);
    }
};

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

test "it should do nothing" {
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

