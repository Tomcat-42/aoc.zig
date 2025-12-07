const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const util = @import("util");
const CharGrid = util.CharGrid;

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = .{io};

    var grid: CharGrid = try .init(allocator, input);
    defer grid.deinit(allocator);

    const start_col: usize = start: {
        for (0..grid.cols) |c| for (0..grid.rows) |r|
            if (grid.at_unchecked(r, c) == 'S')
                break :start c;
        return null;
    };

    var current = try allocator.alloc(bool, grid.cols);
    defer allocator.free(current);
    var next_row = try allocator.alloc(bool, grid.cols);
    defer allocator.free(next_row);

    @memset(current, false);
    current[start_col] = true;

    var hit_splitters: usize = 0;

    for (1..grid.rows) |row| {
        @memset(next_row, false);

        for (0..grid.cols) |col| {
            if (!current[col]) continue;

            const cell = grid.at_unchecked(row, col);

            switch (cell) {
                '^' => {
                    hit_splitters += 1;
                    if (col > 0) next_row[col - 1] = true;
                    if (col + 1 < grid.cols) next_row[col + 1] = true;
                },
                else => next_row[col] = true,
            }
        }

        const tmp = current;
        current = next_row;
        next_row = tmp;
    }

    return hit_splitters;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = .{io};

    var grid: CharGrid = try .init(allocator, input);
    defer grid.deinit(allocator);

    const start_col: usize = start: {
        for (0..grid.cols) |c| for (0..grid.rows) |r|
            if (grid.at_unchecked(r, c) == 'S')
                break :start c;
        return null;
    };

    var current = try allocator.alloc(usize, grid.cols);
    defer allocator.free(current);
    var next_row = try allocator.alloc(usize, grid.cols);
    defer allocator.free(next_row);

    @memset(current, 0);
    current[start_col] = 1;

    var total_timelines: usize = 0;

    for (1..grid.rows) |row| {
        @memset(next_row, 0);

        for (0..grid.cols) |col| {
            const timelines = current[col];
            if (timelines == 0) continue;

            const cell = grid.at_unchecked(row, col);

            switch (cell) {
                '^' => {
                    if (col > 0) {
                        next_row[col - 1] += timelines;
                    } else {
                        total_timelines += timelines;
                    }
                    if (col + 1 < grid.cols) {
                        next_row[col + 1] += timelines;
                    } else {
                        total_timelines += timelines;
                    }
                },
                else => next_row[col] += timelines,
            }
        }

        const tmp = current;
        current = next_row;
        next_row = tmp;
    }

    for (current) |t| total_timelines += t;

    return total_timelines;
}

test "it should do nothing" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
    ;

    try std.testing.expectEqual(21, try part1(io, allocator, input));
    try std.testing.expectEqual(40, try part2(io, allocator, input));
}
