const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const print = std.debug.print;
const StringHashMap = std.StringHashMap;
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?u64 {
    _ = .{ io, allocator };
    var idx: usize = 0;
    const len: usize = input.len;

    var sum: u64 = 0;
    var first: ?u64 = null;
    var last: ?u64 = null;

    while (idx < len) : (idx += 1) {
        switch (parseChar(input[idx])) {
            .alpha => {},
            .numeric => |n| {
                if (first == null) {
                    first = n;
                    last = n;
                } else {
                    last = n;
                }
            },
            .newline => {
                sum += (first.? * 10) + last.?;
                first = null;
                last = null;
            },
        }
    }

    return sum;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?u64 {
    _ = io;
    var idx: usize = 0;
    const len: usize = input.len;

    var sum: u64 = 0;
    var first: ?u64 = null;
    var last: ?u64 = null;

    var digit_map: StringHashMap(u64) = .init(allocator);
    defer digit_map.deinit();

    try digit_map.put("one", 1);
    try digit_map.put("two", 2);
    try digit_map.put("three", 3);
    try digit_map.put("four", 4);
    try digit_map.put("five", 5);
    try digit_map.put("six", 6);
    try digit_map.put("seven", 7);
    try digit_map.put("eight", 8);
    try digit_map.put("nine", 9);

    var start: usize = 0;
    var end: usize = 0;

    outer: while (idx < len) {
        switch (parseChar(input[idx])) {
            // simple case, already have a number, just save it
            .numeric => |n| {
                if (first == null) first = n;
                last = n;

                idx += 1;
                continue :outer;
            },
            // end of current line, add to the sum the 2 digit number formed
            .newline => {
                sum += (first.? * 10) + last.?;

                first = null;
                last = null;

                idx += 1;
                continue :outer;
            },
            .alpha => {
                // current char is a possible range start
                start = idx;
                end = idx;

                inner_loop: while (end < len) : (end += 1) {
                    // Found a digit word, save it and continue
                    if (digit_map.get(input[start .. end + 1])) |n| {
                        if (first == null) first = n;
                        last = n;

                        idx = end;
                        continue :outer;
                    }

                    // if the current char is a letter, continue to inner loop because there is a possibility that it is part of a word
                    // else, if the current char is not a letter, the outer loop will handle it
                    switch (parseChar(input[end])) {
                        .alpha => continue :inner_loop,
                        .newline, .numeric => {
                            idx += 1;
                            continue :outer;
                        },
                    }
                }
            },
        }
    }
    return sum;
}

inline fn parseChar(char: u8) union(enum) { alpha: u8, numeric: u64, newline } {
    if (char >= '0' and char <= '9')
        return .{ .numeric = char - '0' };

    if (char == '\n')
        return .newline;

    return .{ .alpha = char };
}

test "[part1] it should parse one line" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input = "12aaaaaaaaaaaaaa3\n";

    try std.testing.expectEqual(13, try part1(io, allocator, input));
}

test "[part2] it should parse one line" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input = "12aaaaaaaaone3two\n";

    try std.testing.expectEqual(12, try part2(io, allocator, input));
}

test "[part2] Test line 100 edge case" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input = "drflhlxphzspnnzdbcfbpcbtddvd8three56\n";

    try std.testing.expectEqual(86, try part2(io, allocator, input));
}

test "[part2] Test tricky edge case" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input = "sevenine\n";

    try std.testing.expectEqual(79, try part2(io, allocator, input));
}

test "[part2] Example input" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
        \\
    ;

    try std.testing.expectEqual(281, try part2(io, allocator, input));
}
