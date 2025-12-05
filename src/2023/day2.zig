const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?u64 {
    _ = io;
    var it = mem.tokenizeScalar(u8, input, '\n');
    var id: usize = 1;
    var sum: u64 = 0;
    while (it.next()) |line| : (id += 1) {
        const game = try parse_game(allocator, line);
        defer allocator.free(game);

        var toSum = true;
        for (game) |round| {
            if (@reduce(.Or, round > @Vector(3, u64){ 12, 13, 14 })) {
                toSum = false;
                break;
            }
        }
        if (toSum) sum += id;
    }

    return sum;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?u64 {
    _ = io;
    var it = mem.tokenizeScalar(u8, input, '\n');
    var sum: u64 = 0;
    while (it.next()) |line| {
        const game = try parse_game(allocator, line);
        defer allocator.free(game);

        var max = @Vector(3, u64){ 0, 0, 0 };
        for (game) |round| {
            max = @select(
                u64,
                @Vector(3, bool){
                    round[0] > max[0],
                    round[1] > max[1],
                    round[2] > max[2],
                },
                round,
                max,
            );
        }

        sum += @reduce(.Mul, max);
    }

    return sum;
}

pub fn parse_game(
    allocator: Allocator,
    input: []const u8,
) ![]const @Vector(3, u64) {
    // 1. ignore the head: "Game {id}: "
    var it = mem.splitSequence(u8, input, ": ");
    _ = it.next().?;

    const tail = it.peek().?;
    it = mem.splitSequence(u8, tail, "; ");

    var rounds: ArrayList(@Vector(3, u64)) = .empty;
    defer rounds.deinit(allocator);

    while (it.next()) |round| {
        var r = @Vector(3, u64){ 0, 0, 0 };
        var cubes = mem.splitSequence(u8, round, ", ");
        while (cubes.next()) |item| {
            var cube = mem.splitScalar(u8, item, ' ');
            const n = try fmt.parseUnsigned(u64, cube.next().?, 10);
            const color = cube.next().?;

            if (mem.eql(u8, color, "red")) {
                r[0] += n;
            } else if (mem.eql(u8, color, "green")) {
                r[1] += n;
            } else if (mem.eql(u8, color, "blue")) {
                r[2] += n;
            }
        }
        try rounds.append(allocator, r);
    }

    return rounds.toOwnedSlice(allocator);
}

test "[part1] example" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;

    try std.testing.expectEqual(8, try part1(io, allocator, input));
}
