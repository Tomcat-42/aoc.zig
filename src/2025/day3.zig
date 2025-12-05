const std = @import("std");
const math = std.math;
const fmt = std.fmt;
const mem = std.mem;
const AutoHashMapUnmanaged = std.AutoHashMapUnmanaged;
const Allocator = std.mem.Allocator;
const Io = std.Io;

const BatIterator = struct {
    tokens: mem.TokenIterator(u8, .scalar),

    pub fn init(input: []const u8) @This() {
        return BatIterator{ .tokens = mem.tokenizeScalar(u8, input, '\n') };
    }

    pub fn next(this: *@This()) ?[]const u8 {
        return this.tokens.next();
    }
};

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = .{ io, allocator };

    var result: usize = 0;
    var bats: BatIterator = .init(input);
    while (bats.next()) |bat| result += biggestKDigits(bat, 2);
    return result;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = .{ io, allocator };

    var result: usize = 0;
    var bats: BatIterator = .init(input);
    while (bats.next()) |bat| result += biggestKDigits(bat, 12);
    return result;
}

fn biggestKDigits(line: []const u8, k: usize) usize {
    if (line.len < k) return 0;

    var result: usize = 0;
    var start: usize = 0;

    for (0..k) |i| {
        const remaining_picks = k - i - 1;
        const end = line.len - remaining_picks;

        var best_idx = start;
        var best_digit: u8 = 0;
        for (start..end) |j| {
            const d = line[j] - '0';
            if (d > best_digit) {
                best_digit = d;
                best_idx = j;
            }
        }

        result = result * 10 + best_digit;
        start = best_idx + 1;
    }

    return result;
}

test "it should do nothing" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;

    try std.testing.expectEqual(357, try part1(io, allocator, input));
    try std.testing.expectEqual(null, try part2(io, allocator, input));
}

