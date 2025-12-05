const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const Group = Io.Group;
const Atomic = std.atomic.Value;

const util = @import("util");
const CharGrid = util.CharGrid;

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = .{allocator};

    const PARTITIONS = 8;

    var grid: CharGrid = try .init(allocator, input);
    defer grid.deinit(allocator);

    const row_step = grid.rows / PARTITIONS;
    const col_step = grid.cols / PARTITIONS;

    var total = Atomic(usize).init(0);
    var group: Group = .init;

    for (0..PARTITIONS) |pi| for (0..PARTITIONS) |pj| {
        const x1 = pi * row_step;
        const x2 = if (pi == PARTITIONS - 1) grid.rows else (pi + 1) * row_step;
        const y1 = pj * col_step;
        const y2 = if (pj == PARTITIONS - 1) grid.cols else (pj + 1) * col_step;

        group.concurrent(io, numOfPapers, .{ &grid, .{ x1, x2 }, .{ y1, y2 }, &total }) catch
            numOfPapers(&grid, .{ x1, x2 }, .{ y1, y2 }, &total);
    };

    group.wait(io);

    return total.load(.seq_cst);
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = .{io};

    var grid: CharGrid = try .init(allocator, input);
    defer grid.deinit(allocator);

    var total: usize = 0;
    while (true) {
        var local: usize = 0;
        for (0..grid.rows) |i| for (0..grid.cols) |j| if (grid.at_unchecked(i, j) == '@')
            if (fewerThan4Neighbors(&grid, @intCast(i), @intCast(j))) {
                grid.set_unchecked(i, j, '.');
                local += 1;
            };

        if (local == 0) break;
        total += local;
    }

    return total;
}

fn numOfPapersAndDestroy(
    grid: *CharGrid,
    x: struct { usize, usize },
    y: struct { usize, usize },
    total: *Atomic(usize),
) void {
    const x1, const x2 = x;
    const y1, const y2 = y;

    var local_total: usize = 0;
    for (x1..x2) |i| for (y1..y2) |j| if (grid.at_unchecked(i, j) == '@') {
        local_total += @intFromBool(fewerThan4Neighbors(grid, @intCast(i), @intCast(j)));
        grid.set_unchecked(i, j, '.');
    };
    _ = total.fetchAdd(local_total, .seq_cst);
}

fn numOfPapers(
    grid: *const CharGrid,
    x: struct { usize, usize },
    y: struct { usize, usize },
    total: *Atomic(usize),
) void {
    const x1, const x2 = x;
    const y1, const y2 = y;

    var local_total: usize = 0;
    for (x1..x2) |i| for (y1..y2) |j| if (grid.at_unchecked(i, j) == '@') {
        local_total += @intFromBool(fewerThan4Neighbors(grid, @intCast(i), @intCast(j)));
    };
    _ = total.fetchAdd(local_total, .seq_cst);
}

inline fn fewerThan4Neighbors(
    grid: *const CharGrid,
    row: isize,
    col: isize,
) bool {
    const directions: []const struct { isize, isize } = &.{
        .{ -1, -1 },
        .{ -1, 0 },
        .{ -1, 1 },
        .{ 0, -1 },
        .{ 0, 1 },
        .{ 1, -1 },
        .{ 1, 0 },
        .{ 1, 1 },
    };

    var count: usize = 0;
    for (directions) |dir| {
        const xi, const yi = dir;
        if (grid.at(row + xi, col + yi)) |c| if (c == '@') {
            count += 1;
        };
    }

    return count < 4;
}

test "it should do nothing" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
    ;

    try std.testing.expectEqual(13, try part1(io, allocator, input));
    try std.testing.expectEqual(43, try part2(io, allocator, input));
}
