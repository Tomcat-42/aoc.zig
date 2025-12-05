const std = @import("std");
const mem = std.mem;
const print = std.debug.print;
const assert = std.debug.assert;
const fmt = std.fmt;
const math = std.math;
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Machine = struct {
    const COST = struct {
        const a: isize = 3;
        const b: isize = 1;
    };
    buttons: struct {
        a: struct {
            x: isize,
            y: isize,
        },
        b: struct {
            x: isize,
            y: isize,
        },
    },
    prize: struct {
        x: isize,
        y: isize,
    },

    inline fn cost(a: isize, b: isize) isize {
        return a * Machine.COST.a + b * Machine.COST.b;
    }

    //https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm
    fn gcd(a: isize, b: isize) struct { d: isize, x: isize, y: isize } {
        if (b == 0) return .{ .d = a, .x = 1, .y = 0 };
        const ret = gcd(b, @mod(a, b));
        return .{ .d = ret.d, .x = ret.y, .y = ret.x - @divTrunc(a, b) * ret.y };
    }

    // https://cp-algorithms.com/algebra/linear-diophantine-equation.html#find-the-solution-with-minimum-value-of-x-y
    pub fn solve(this: @This()) isize {
        assert(this.buttons.a.x != 0 and this.buttons.a.y != 0);
        const det = this.buttons.a.x * this.buttons.b.y - this.buttons.a.y * this.buttons.b.x;
        assert(det != 0);

        const x0 = math.divExact(isize, this.prize.x * this.buttons.b.y - this.prize.y * this.buttons.b.x, det) catch return 0;
        const y0 = math.divExact(isize, this.prize.y * this.buttons.a.x - this.prize.x * this.buttons.a.y, det) catch return 0;
        const t = @divTrunc(this.prize.x, gcd(this.buttons.a.x, this.buttons.a.y).d);

        var min: isize = math.maxInt(isize);
        var x = x0;
        var y = y0;

        while (x + t > 0 and y > 0) {
            min = @min(min, cost(x, y));
            x += t;
            y -= t;
        }
        return min;
    }

    pub fn format(this: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Machine {{\n", .{});
        try writer.print("  Buttons: {{\n", .{});
        try writer.print("    A: {{ X={d}, Y={d} }},\n", .{ this.buttons.a.x, this.buttons.a.y });
        try writer.print("    B: {{ X={d}, Y={d} }},\n", .{ this.buttons.b.x, this.buttons.b.y });
        try writer.print("  }},\n", .{});
        try writer.print("  Prize: {{ X={d}, Y={d} }},\n", .{ this.prize.x, this.prize.y });
        try writer.print("}}", .{});
    }

    pub fn scan(machine: []const u8) @This() {
        // Button A: X+BAX, Y+BAY
        // Button B: X+BBX, Y+BBY
        // Prize: X=PX, Y=PY
        var lines = mem.tokenizeScalar(u8, machine, '\n');

        // Button A: X+BAX, Y+BAY
        var str = lines.next().?;
        var it = mem.tokenizeSequence(
            u8,
            str,
            ": ",
        );
        _ = it.next().?;
        str = it.rest(); // X+BAX, Y+BAY
        it = mem.tokenizeSequence(u8, str, ", ");
        str = it.next().?;
        const bax = fmt.parseUnsigned(isize, str[2..], 10) catch @panic("Failed to Parse Integer");
        str = it.next().?;
        const bay = fmt.parseUnsigned(isize, str[2..], 10) catch @panic("Failed to Parse Integer");

        // Button B: X+BBX, Y+BBY
        str = lines.next().?;
        it = mem.tokenizeSequence(
            u8,
            str,
            ": ",
        );
        _ = it.next().?;
        str = it.rest(); // X+BAX, Y+BAY
        it = mem.tokenizeSequence(u8, str, ", ");
        str = it.next().?;
        const bbx = fmt.parseUnsigned(isize, str[2..], 10) catch @panic("Failed to Parse Integer");
        str = it.next().?;
        const bby = fmt.parseUnsigned(isize, str[2..], 10) catch @panic("Failed to Parse Integer");

        // Prize: X=PX, Y=PY
        str = lines.next().?;
        it = mem.tokenizeSequence(
            u8,
            str,
            ": ",
        );
        _ = it.next().?;
        str = it.rest(); // X=PX, Y=PY
        it = mem.tokenizeSequence(u8, str, ", ");
        str = it.next().?;
        const px = fmt.parseUnsigned(isize, str[2..], 10) catch @panic("Failed to Parse Integer");
        str = it.next().?;
        const py = fmt.parseUnsigned(isize, str[2..], 10) catch @panic("Failed to Parse Integer");

        return .{
            .buttons = .{
                .a = .{ .x = bax, .y = bay },
                .b = .{ .x = bbx, .y = bby },
            },
            .prize = .{ .x = px, .y = py },
        };
    }
};

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?isize {
    _ = .{ io, allocator };
    var machines = mem.tokenizeSequence(u8, input, "\n\n");
    var sum: isize = 0;
    while (machines.next()) |str| sum += Machine.scan(str).solve();

    return sum;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?isize {
    _ = .{ io, allocator };
    var machines = mem.tokenizeSequence(u8, input, "\n\n");
    const additional = 10000000000000;

    var sum: isize = 0;
    while (machines.next()) |str| {
        var machine = Machine.scan(str);
        machine.prize.x += additional;
        machine.prize.y += additional;
        sum += machine.solve();
    }

    return sum;
}

test "it should do nothing" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\Button A: X+94, Y+34
        \\Button B: X+22, Y+67
        \\Prize: X=8400, Y=5400
        \\
        \\Button A: X+26, Y+66
        \\Button B: X+67, Y+21
        \\Prize: X=12748, Y=12176
        \\
        \\Button A: X+17, Y+86
        \\Button B: X+84, Y+37
        \\Prize: X=7870, Y=6450
        \\
        \\Button A: X+69, Y+23
        \\Button B: X+27, Y+71
        \\Prize: X=18641, Y=10279
    ;

    try std.testing.expectEqual(480, try part1(io, allocator, input));
    try std.testing.expectEqual(null, try part2(io, allocator, input));
}
