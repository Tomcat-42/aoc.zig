const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const print = std.debug.print;
const ArrayList = std.ArrayList;

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?i64 {
    var lines = mem.tokenizeScalar(
        u8,
        this.input,
        '\n',
    );

    var counter: i64 = 0;
    outer: while (lines.next()) |line| {
        var numbers = mem.tokenizeScalar(
            u8,
            line,
            ' ',
        );

        // The "at least two per line" invariant should hold true
        var last_n: i64 = try fmt.parseInt(i64, numbers.next().?, 10);
        var last_diff: i64 = try fmt.parseInt(
            i64,
            numbers.peek().?,
            10,
        ) - last_n;

        while (numbers.next()) |number| {
            const n = try fmt.parseInt(i64, number, 10);
            const diff = n - last_n;

            // if diff and last_diff have different signals
            // or abs(diff) < 1 or abs(diff) > 3 then break
            if ((diff ^ last_diff) < 0 or @abs(diff) < 1 or @abs(diff) > 3)
                continue :outer;

            last_n = n;
            last_diff = diff;
        }
        counter += 1;
    }
    return counter;
}

pub fn part2(this: *const @This()) !?i64 {
    var lines = mem.tokenizeScalar(
        u8,
        this.input,
        '\n',
    );

    var counter: i64 = 0;
    l1: while (lines.next()) |line| {
        var numbers = mem.tokenizeScalar(
            u8,
            line,
            ' ',
        );

        // The len should be known upfront
        var arr = ArrayList(i64).init(this.allocator);
        defer arr.deinit();

        while (numbers.next()) |number|
            try arr.append(try fmt.parseInt(i64, number, 10));

        const len = arr.items.len;

        // +1 to trigger a no-skip last iteration
        l2: for (0..len + 1) |toSkip| {
            var last_n: ?i64 = null;
            var last_diff: ?i64 = null;
            l3: for (0..len) |i| {
                if (i == toSkip) continue;

                const n = arr.items[i];
                if (last_n == null) {
                    last_n = n;
                    continue :l3;
                }

                if (last_diff == null) last_diff = n - last_n.?;

                const diff = n - last_n.?;

                // if diff and last_diff have different signals
                // or abs(diff) < 1 or abs(diff) > 3 then break
                if ((diff ^ last_diff.?) < 0 or @abs(diff) < 1 or @abs(diff) > 3)
                    continue :l2;

                last_n = n;
                last_diff = diff;
            }
            counter += 1;
            continue :l1;
        }
    }
    return counter;
}

test "it should do nothing" {
    const allocator = std.testing.allocator;
    const input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(2, try problem.part1());
    try std.testing.expectEqual(4, try problem.part2());
}
