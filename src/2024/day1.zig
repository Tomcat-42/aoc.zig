const std = @import("std");
const mem = std.mem;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const sort = std.sort;

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?u64 {
    var l1 = ArrayList(i64).init(this.allocator);
    defer l1.deinit();
    var l2 = ArrayList(i64).init(this.allocator);
    defer l2.deinit();

    var it = std.mem.tokenizeAny(
        u8,
        this.input,
        " \n",
    );

    while (it.peek()) |_| {
        try l1.append(try std.fmt.parseInt(i64, it.next().?, 10));
        try l2.append(try std.fmt.parseInt(i64, it.next().?, 10));
    }

    mem.sort(i64, l1.items, {}, sort.asc(i64));
    mem.sort(i64, l2.items, {}, sort.asc(i64));

    return d: {
        var sum = @as(u64, 0);
        for (l1.items, l2.items) |a, b|
            sum += @abs(a - b);
        break :d sum;
    };
}

pub fn part2(this: *const @This()) !?i64 {
    var l1 = ArrayList(i64).init(this.allocator);
    defer l1.deinit();
    var l2 = AutoHashMap(i64, i64).init(this.allocator);
    defer l2.deinit();

    var it = std.mem.tokenizeAny(
        u8,
        this.input,
        " \n",
    );

    while (it.peek()) |_| {
        try l1.append(try std.fmt.parseInt(i64, it.next().?, 10));
        const entry = try l2.getOrPutValue(
            try std.fmt.parseInt(i64, it.next().?, 10),
            0,
        );
        entry.value_ptr.* += 1;
    }

    return d: {
        var sum = @as(i64, 0);

        for (l1.items) |a| {
            if (l2.get(a)) |n| sum += a * n;
        }

        break :d sum;
    };
}

test "example case" {
    const allocator = std.testing.allocator;
    const input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(11, try problem.part1());
    try std.testing.expectEqual(31, try problem.part2());
}

