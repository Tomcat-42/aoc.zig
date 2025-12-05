const std = @import("std");
const mem = std.mem;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Io = std.Io;

const MatrixView = struct {
    allocator: Allocator,

    data: [][]const u8,
    rows: usize,
    cols: usize,

    pub fn init(allocator: Allocator, data: []const u8) !MatrixView {
        var lines: ArrayList([]const u8) = .empty;
        var it = mem.tokenizeScalar(u8, data, '\n');
        while (it.next()) |line| try lines.append(allocator, line);
        const rows = lines.items.len;
        const cols = if (lines.items.len > 0) lines.items[0].len else 0;
        return MatrixView{
            .allocator = allocator,
            .data = try lines.toOwnedSlice(allocator),
            .rows = rows,
            .cols = cols,
        };
    }

    pub fn deinit(this: *MatrixView) void {
        defer this.allocator.free(this.data);
    }
};

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?u64 {
    _ = io;
    var count: u64 = 0;
    var matrix = try MatrixView.init(
        allocator,
        input,
    );
    defer matrix.deinit();

    // First one, line scan
    for (0..matrix.rows) |i| {
        for (0..matrix.cols - 4) |j| {
            const c1 = matrix.data[i][j];
            const c2 = matrix.data[i][j + 1];
            const c3 = matrix.data[i][j + 2];
            const c4 = matrix.data[i][j + 3];

            if ((c1 == 'X' and c2 == 'M' and c3 == 'A' and c4 == 'S') or
                (c1 == 'S' and c2 == 'A' and c3 == 'M' and c4 == 'X'))
                count += 1;
        }
    }

    // Second one, column scan
    for (0..matrix.cols) |i| {
        for (0..matrix.rows - 3) |j| {
            const c1 = matrix.data[j][i];
            const c2 = matrix.data[j + 1][i];
            const c3 = matrix.data[j + 2][i];
            const c4 = matrix.data[j + 3][i];

            if ((c1 == 'X' and c2 == 'M' and c3 == 'A' and c4 == 'S') or
                (c1 == 'S' and c2 == 'A' and c3 == 'M' and c4 == 'X'))
                count += 1;
        }
    }

    const diagonals: usize = matrix.rows + matrix.cols - 1;

    // Third one, main diagonals
    for (0..diagonals) |d| {
        const from: usize = @as(usize, @intCast(@max(0, @as(i128, @intCast(d)) - matrix.cols + 1)));
        const to: usize = @min(matrix.rows, d + 1);

        if (to - from < 4) continue;

        for (from..to - 3) |i| {
            const j = d - i;
            const c1 = matrix.data[i][j];
            const c2 = matrix.data[i + 1][j - 1];
            const c3 = matrix.data[i + 2][j - 2];
            const c4 = matrix.data[i + 3][j - 3];

            if ((c1 == 'X' and c2 == 'M' and c3 == 'A' and c4 == 'S') or
                (c1 == 'S' and c2 == 'A' and c3 == 'M' and c4 == 'X'))
                count += 1;
        }
    }

    // Fourth one, anti-diagonals
    for (0..diagonals) |d| {
        const from: usize = @as(usize, @intCast(@max(0, @as(i128, @intCast(d)) - matrix.cols + 1)));
        const to: usize = @min(matrix.rows, d + 1);

        if (to - from < 4) continue;

        for (from..to - 3) |i| {
            const j = matrix.cols - 1 - (d - i);
            const c1 = matrix.data[i][j];
            const c2 = matrix.data[i + 1][j + 1];
            const c3 = matrix.data[i + 2][j + 2];
            const c4 = matrix.data[i + 3][j + 3];

            if ((c1 == 'X' and c2 == 'M' and c3 == 'A' and c4 == 'S') or
                (c1 == 'S' and c2 == 'A' and c3 == 'M' and c4 == 'X'))
                count += 1;
        }
    }

    return count;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?u64 {
    _ = io;
    var count: u64 = 0;
    var matrix = try MatrixView.init(
        allocator,
        input,
    );
    defer matrix.deinit();

    // Scan all of the 3x3 windows
    for (0..matrix.rows - 2) |i| {
        for (0..matrix.cols - 2) |j| {
            // The pattern should be like
            // M . S    c1 . c2
            // . A . => . c3  .
            // M . S    c4 . c5
            const c1 = matrix.data[i][j];
            const c2 = matrix.data[i][j + 2];
            const c3 = matrix.data[i + 1][j + 1];
            const c4 = matrix.data[i + 2][j];
            const c5 = matrix.data[i + 2][j + 2];

            if (((c1 == 'M' and c3 == 'A' and c5 == 'S') or
                (c1 == 'S' and c3 == 'A' and c5 == 'M')) and
                ((c2 == 'M' and c3 == 'A' and c4 == 'S') or
                (c2 == 'S' and c3 == 'A' and c4 == 'M')))
                count += 1;
        }
    }
    return count;
}

test "Example Part 1 Input 1" {
    const io = std.testing.io;
    const expectEqual = std.testing.expectEqual;
    const allocator = std.testing.allocator;
    const input =
        \\..X...
        \\.SAMX.
        \\.A..A.
        \\XMAS.S
        \\.X....
    ;

    try expectEqual(4, try part1(io, allocator, input));
}

test "Example Part 1 Input 2" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;

    try std.testing.expectEqual(18, try part1(io, allocator, input));
}

test "Example Part 2 Input 1" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\M.S
        \\.A.
        \\M.S
    ;

    _ = try part2(io, allocator, input);

    try std.testing.expectEqual(1, try part2(io, allocator, input));
}

test "Example Part 2 Input 2" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\.M.S......
        \\..A..MSMS.
        \\.M.S.MAA..
        \\..A.ASMSM.
        \\.M.S.M....
        \\..........
        \\S.S.S.S.S.
        \\.A.A.A.A..
        \\M.M.M.M.M.
        \\..........
    ;

    try std.testing.expectEqual(9, try part2(io, allocator, input));
}
