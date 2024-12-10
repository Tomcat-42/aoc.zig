const std = @import("std");
const mem = std.mem;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const util = @import("util");
const NumberGrid = util.NumberGrid;

input: []const u8,
allocator: mem.Allocator,

const Position = struct {
    i: isize,
    j: isize,
};

fn trail_score(grid: *const NumberGrid, initial: Position) !usize {
    var s = ArrayList(Position).init(grid.allocator);
    defer s.deinit();
    var reachable = AutoHashMap(Position, void).init(grid.allocator);
    defer reachable.deinit();

    try s.append(initial);
    while (s.popOrNull()) |current_position| {
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
                    try s.append(new_pos);
        }
    }

    return reachable.count();
}

fn trail_rating(grid: *const NumberGrid, initial: Position) !usize {
    var s = ArrayList(Position).init(grid.allocator);
    defer s.deinit();
    var reachable: usize = 0;

    try s.append(initial);
    while (s.popOrNull()) |current_position| {
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
                    try s.append(new_pos);
        }
    }

    return reachable;
}

pub fn part1(this: *const @This()) !?usize {
    const grid = NumberGrid.init(this.allocator, this.input, '\n');
    defer grid.deinit();

    var sum: usize = 0;
    for (0..grid.rows) |i|
        for (0..grid.cols) |j| {
            if (grid.at_unchecked(i, j) == 0)
                sum += try trail_score(&grid, .{
                    .i = @intCast(i),
                    .j = @intCast(j),
                });
        };

    return sum;
}

pub fn part2(this: *const @This()) !?usize {
    const grid = NumberGrid.init(this.allocator, this.input, '\n');
    defer grid.deinit();

    var sum: usize = 0;
    for (0..grid.rows) |i|
        for (0..grid.cols) |j| {
            if (grid.at_unchecked(i, j) == 0)
                sum += try trail_rating(&grid, .{
                    .i = @intCast(i),
                    .j = @intCast(j),
                });
        };

    return sum;
}

test "Example Input" {
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

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(36, try problem.part1());
    try std.testing.expectEqual(81, try problem.part2());
}
