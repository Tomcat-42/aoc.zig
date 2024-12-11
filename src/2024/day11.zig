const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const math = std.math;
const heap = std.heap;
const print = std.debug.print;
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = mem.Allocator;

input: []const u8,
allocator: mem.Allocator,

const Stones = struct {
    const MemoEntry = struct { usize, usize };

    allocator: Allocator,
    list: []usize,
    memo: AutoHashMap(MemoEntry, usize),

    pub fn init(allocator: Allocator, input: []const u8) !Stones {
        var it = mem.tokenizeScalar(u8, input, ' ');
        var stones = ArrayList(usize).init(allocator);
        while (it.next()) |v| try stones.append(try fmt.parseUnsigned(usize, v, 10));

        return .{
            .allocator = allocator,
            .list = try stones.toOwnedSlice(),
            .memo = AutoHashMap(MemoEntry, usize).init(allocator),
        };
    }

    pub fn deinit(this: *@This()) void {
        this.allocator.free(this.list);
        this.memo.deinit();
    }

    fn process(this: *@This(), n: usize, level: usize) !usize {
        if (this.memo.get(.{ n, level })) |val| return val;
        const val = compute: {
            if (level == 0) break :compute 1;
            if (n == 0) break :compute try this.process(1, level - 1);

            const nDigits = numOfDigits(n);
            if (nDigits % 2 == 0) {
                const splitted = splitDigits(n, nDigits);

                const n1 = try this.process(splitted[0], level - 1);
                const n2 = try this.process(splitted[1], level - 1);

                break :compute n1 + n2;
            }

            break :compute try this.process(n * 2024, level - 1);
        };
        try this.memo.put(.{ n, level }, val);

        return val;
    }

    pub fn simulate(this: *@This(), n: usize) !usize {
        var sum: usize = 0;
        for (this.list) |val| sum += try this.process(val, n);
        return sum;
    }
};

inline fn splitDigits(n: usize, digits: usize) [2]usize {
    assert(digits % 2 == 0);
    const half = digits / 2;
    const divisor = math.pow(usize, 10, half);

    return .{ n / divisor, n % divisor };
}
inline fn numOfDigits(n: usize) usize {
    assert(n > 0);
    return math.log10(n) + 1;
}

pub fn part1(this: *const @This()) !?usize {
    var stones = try Stones.init(this.allocator, this.input[0 .. this.input.len - 1]);
    defer stones.deinit();

    return try stones.simulate(25);
}

pub fn part2(this: *const @This()) !?usize {
    var stones = try Stones.init(this.allocator, this.input[0 .. this.input.len - 1]);
    defer stones.deinit();

    return try stones.simulate(75);
}

test "Example Input" {
    const allocator = std.testing.allocator;

    const input =
        \\125 17
        \\
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(55312, try problem.part1());
}
