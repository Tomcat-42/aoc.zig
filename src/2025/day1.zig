const std = @import("std");
const math = std.math;
const fmt = std.fmt;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Dial = struct {
    pub const Movement = union(enum(u8)) { left: i64, right: i64 };
    actual: i64 = 50,

    pub fn move(this: *Dial, movement: Movement) i64 {
        return r: switch (movement) {
            .left => |v| {
                const touches = if (this.actual > 0)
                    @divFloor(v - this.actual + 100, 100)
                else
                    @divFloor(v, 100);
                this.actual = @mod(this.actual - v, 100);
                break :r touches;
            },
            .right => |v| {
                const touches = @divFloor(this.actual + v, 100);
                this.actual = @mod(this.actual + v, 100);
                break :r touches;
            },
        };
    }
};

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?i64 {
    _ = .{ io, allocator };
    var dial: Dial = .{};
    var total: i64 = 0;

    var lines = mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const direction = line[0];
        const value = try fmt.parseInt(i64, line[1..], 10);
        const move: Dial.Movement = switch (direction) {
            'L' => .{ .left = value },
            'R' => .{ .right = value },
            else => return error.InvalidInput,
        };
        _ = dial.move(move);

        total += @intFromBool(dial.actual == 0);
    }

    return total;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?i64 {
    _ = .{ io, allocator };
    var dial: Dial = .{};
    var total: i64 = 0;

    var lines = mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const direction = line[0];
        const value = try fmt.parseInt(i64, line[1..], 10);
        const move: Dial.Movement = switch (direction) {
            'L' => .{ .left = value },
            'R' => .{ .right = value },
            else => return error.InvalidInput,
        };

        total += dial.move(move);
    }

    return total;
}

test "it should do nothing" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;

    try std.testing.expectEqual(3, try part1(io, allocator, input));
    try std.testing.expectEqual(6, try part2(io, allocator, input));
}

test "edge case 1" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\L1000
        \\R1000
    ;

    try std.testing.expectEqual(0, try part1(io, allocator, input));
    try std.testing.expectEqual(20, try part2(io, allocator, input));
}

test "edge case 2" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\L0
        \\R0
    ;

    try std.testing.expectEqual(0, try part1(io, allocator, input));
    try std.testing.expectEqual(0, try part2(io, allocator, input));
}

test "edge case 3" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\R100
    ;

    try std.testing.expectEqual(0, try part1(io, allocator, input));
    try std.testing.expectEqual(1, try part2(io, allocator, input));
}

test "edge case 4" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\R49
        \\R1
    ;

    try std.testing.expectEqual(1, try part1(io, allocator, input));
    try std.testing.expectEqual(1, try part2(io, allocator, input));
}

test "edge case 5" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\L50
        \\R99
        \\L99
    ;

    try std.testing.expectEqual(2, try part1(io, allocator, input));
    try std.testing.expectEqual(2, try part2(io, allocator, input));
}
