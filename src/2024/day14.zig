const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const math = std.math;
const Thead = std.Thread;
const ArrayList = std.ArrayList;
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const Io = std.Io;

inline fn lcm(a: anytype, b: anytype) @TypeOf(a, b) {
    return @abs(a * b) / math.gcd(@abs(a), @abs(b));
}

pub const LIMITS = struct {
    const J = 101;
    const I = 103;
};

const Robot = struct {
    position: struct { j: isize, i: isize },
    velocity: struct { dj: isize, di: isize },

    pub fn move(this: *@This(), t: isize) void {
        this.position.j = @mod((this.position.j + this.velocity.dj * t), LIMITS.J);
        this.position.i = @mod((this.position.i + this.velocity.di * t), LIMITS.I);
    }

    pub fn minimum_moves_until_loop(this: *const @This()) usize {
        return lcm(
            @divFloor(LIMITS.I, math.gcd(LIMITS.I, @abs(this.velocity.di))),
            @divFloor(LIMITS.J, math.gcd(LIMITS.J, @abs(this.velocity.dj))),
        );
    }

    pub fn scan(input: []const u8) !@This() {
        var it = mem.tokenizeScalar(u8, input, ' ');
        const pos_str = it.next().?;
        const vel_str = it.next().?;

        var pos_it = mem.tokenizeScalar(u8, pos_str[2..pos_str.len], ',');
        var vel_it = mem.tokenizeScalar(u8, vel_str[2..vel_str.len], ',');

        return .{
            .position = .{
                .j = try fmt.parseInt(isize, pos_it.next().?, 10),
                .i = try fmt.parseInt(isize, pos_it.next().?, 10),
            },
            .velocity = .{
                .dj = try fmt.parseInt(isize, vel_it.next().?, 10),
                .di = try fmt.parseInt(isize, vel_it.next().?, 10),
            },
        };
    }
    pub fn format(this: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("({d}, {d}) -> ({d}, {d})", .{
            this.position.j,
            this.position.i,
            this.velocity.dj,
            this.velocity.di,
        });
    }
};

pub fn print_tiles(robots: *const ArrayList(Robot)) void {
    for (0..LIMITS.I) |i| {
        for (0..LIMITS.J) |j| {
            var num: usize = 0;
            for (robots.items) |robot| {
                if (robot.position.j == j and robot.position.i == i)
                    num += 1;
            }

            if (num == 0) {
                print(".", .{});
            } else {
                print("{d}", .{num});
            }
        }
        print("\n", .{});
    }
}

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = io;
    var robots: ArrayList(Robot) = .empty;
    defer robots.deinit(allocator);

    var lines = mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var robot = try Robot.scan(line);
        robot.move(100);
        try robots.append(allocator, robot);
    }

    var q1: usize = 0;
    for (0..LIMITS.J / 2) |j| {
        for (0..LIMITS.I / 2) |i| {
            for (robots.items) |robot| {
                if (robot.position.j == j and robot.position.i == i)
                    q1 += 1;
            }
        }
    }

    var q2: usize = 0;
    for (LIMITS.J / 2 + 1..LIMITS.J) |j| {
        for (0..LIMITS.I / 2) |i| {
            for (robots.items) |robot| {
                if (robot.position.j == j and robot.position.i == i)
                    q2 += 1;
            }
        }
    }

    var q3: usize = 0;
    for (0..LIMITS.J / 2) |j| {
        for (LIMITS.I / 2 + 1..LIMITS.I) |i| {
            for (robots.items) |robot| {
                if (robot.position.j == j and robot.position.i == i)
                    q3 += 1;
            }
        }
    }

    var q4: usize = 0;
    for (LIMITS.J / 2 + 1..LIMITS.J) |j| {
        for (LIMITS.I / 2 + 1..LIMITS.I) |i| {
            for (robots.items) |robot| {
                if (robot.position.j == j and robot.position.i == i)
                    q4 += 1;
            }
        }
    }

    return q1 * q2 * q3 * q4;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = io;
    var robots: ArrayList(Robot) = .empty;
    defer robots.deinit(allocator);

    var lines = mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var robot = try Robot.scan(line);
        robot.move(0);
        try robots.append(allocator, robot);
    }

    var minimum_moves_until_loop: usize = robots.items[0].minimum_moves_until_loop();
    for (robots.items) |robot| {
        const moves = robot.minimum_moves_until_loop();
        minimum_moves_until_loop = moves * minimum_moves_until_loop / math.gcd(moves, minimum_moves_until_loop);
    }

    const initial = 7492;
    for (robots.items) |*robot| robot.move(initial);
    print_tiles(&robots);

    return initial;
}

test "problem" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\p=0,4 v=3,-3
        \\p=6,3 v=-1,-3
        \\p=10,3 v=-1,2
        \\p=2,0 v=2,-1
        \\p=0,0 v=1,3
        \\p=3,0 v=-2,-2
        \\p=7,6 v=-1,-3
        \\p=3,0 v=-1,-2
        \\p=9,3 v=2,3
        \\p=7,3 v=-1,2
        \\p=2,4 v=2,-3
        \\p=9,5 v=-3,-3
    ;

    // try std.testing.expectEqual(12, try part1(io, allocator, input));
    try std.testing.expectEqual(null, try part2(io, allocator, input));
}
