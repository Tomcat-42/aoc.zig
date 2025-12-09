const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Io = std.Io;

const util = @import("util");
const Iterator = util.Iterator;

const Point = @Vector(2, isize);

fn parse(input: []const u8) !Point {
    const @"," = mem.findScalar(u8, input, ',') orelse return error.InvalidInput;
    return .{
        try fmt.parseInt(isize, input[0..@","], 10),
        try fmt.parseInt(isize, input[@"," + 1 ..], 10),
    };
}

inline fn area(p1: Point, p2: Point) isize {
    return @reduce(
        .Mul,
        @as(Point, @intCast(@abs(p1 - p2))) + @as(Point, @splat(1)),
    );
}

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?isize {
    _ = .{io};

    var it: Iterator(Point, .{ .scalar = '\n' }, parse) = .init(input);
    const points = try it.collect(allocator);
    defer allocator.free(points);

    var largest: isize = 0;
    for (0..points.len) |i| for (i + 1..points.len) |j| {
        largest = @max(
            largest,
            area(points[i], points[j]),
        );
    };

    return largest;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?isize {
    _ = .{ io, allocator, input };

    return null;
}

test "problem" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\7,1
        \\11,1
        \\11,7
        \\9,7
        \\9,5
        \\2,5
        \\2,3
        \\7,3
    ;

    try std.testing.expectEqual(50, try part1(io, allocator, input));
    try std.testing.expectEqual(24, try part2(io, allocator, input));
}
