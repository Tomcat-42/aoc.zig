const std = @import("std");
const mem = std.mem;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const util = @import("util");
const NumberGrid = util.NumberGrid;
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Position = struct {
    i: isize,
    j: isize,
};

fn trail_score(grid: *const NumberGrid, initial: Position, allocator: Allocator) !usize {
    var s: ArrayList(Position) = .empty;
    defer s.deinit(allocator);
    var reachable: AutoHashMap(Position, void) = .init(allocator);
    defer reachable.deinit();

    try s.append(allocator, initial);
    while (s.pop()) |current_position| {
        const current_value = grid.at_unchecked(
            @intCast(current_position.i),
            @intCast(current_position.j),
        );
        if (current_value == 9) {
            try reachable.put(current_position, {});
            continue;
        }

        // - b -
        // a x c
        // - d -
        const to: [4]Position = .{
            .{ .i = current_position.i - 1, .j = current_position.j },
            .{ .i = current_position.i, .j = current_position.j + 1 },
            .{ .i = current_position.i + 1, .j = current_position.j },
            .{ .i = current_position.i, .j = current_position.j - 1 },
        };

        for (to) |new_pos| {
            if (grid.at(new_pos.i, new_pos.j)) |new_value|
                if (new_value == current_value + 1)
                    try s.append(allocator, new_pos);
        }
    }

    return reachable.count();
}

fn trail_rating(grid: *const NumberGrid, initial: Position, allocator: Allocator) !usize {
    var s: ArrayList(Position) = .empty;
    defer s.deinit(allocator);
    var reachable: usize = 0;

    try s.append(allocator, initial);
    while (s.pop()) |current_position| {
        const current_value = grid.at_unchecked(
            @intCast(current_position.i),
            @intCast(current_position.j),
        );
        if (current_value == 9) {
            reachable += 1;
            continue;
        }

        // - b -
        // a x c
        // - d -
        const to: [4]Position = .{
            .{ .i = current_position.i - 1, .j = current_position.j },
            .{ .i = current_position.i, .j = current_position.j + 1 },
            .{ .i = current_position.i + 1, .j = current_position.j },
            .{ .i = current_position.i, .j = current_position.j - 1 },
        };

        for (to) |new_pos| {
            if (grid.at(new_pos.i, new_pos.j)) |new_value|
                if (new_value == current_value + 1)
                    try s.append(allocator, new_pos);
        }
    }

    return reachable;
}

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = io;
    const grid = NumberGrid.init(allocator, input, '\n');
    defer grid.deinit();

    var sum: usize = 0;
    for (0..grid.rows) |i|
        for (0..grid.cols) |j| {
            if (grid.at_unchecked(i, j) == 0)
                sum += try trail_score(&grid, .{
                    .i = @intCast(i),
                    .j = @intCast(j),
                }, allocator);
        };

    return sum;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = io;
    const grid = NumberGrid.init(allocator, input, '\n');
    defer grid.deinit();

    var sum: usize = 0;
    for (0..grid.rows) |i|
        for (0..grid.cols) |j| {
            if (grid.at_unchecked(i, j) == 0)
                sum += try trail_rating(&grid, .{
                    .i = @intCast(i),
                    .j = @intCast(j),
                }, allocator);
        };

    return sum;
}

test "Example Input" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;

    try std.testing.expectEqual(36, try part1(io, allocator, input));
    try std.testing.expectEqual(81, try part2(io, allocator, input));
}
