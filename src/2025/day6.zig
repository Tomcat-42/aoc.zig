const std = @import("std");
const Allocator = std.mem.Allocator;
const Deque = std.Deque;
const ArrayList = std.ArrayList;
const Io = std.Io;
const mem = std.mem;

const util = @import("util");
const Matrix = util.Matrix;
const Grid = util.Grid;

const Op = enum(u8) { @"+" = '+', @"*" = '*' };

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = .{io};

    var matrix: Matrix = try .init(allocator, input);
    defer matrix.deinit(allocator);
    try matrix.transpose(allocator);

    var total: usize = 0;
    for (matrix.data) |row| {
        const op: Op = switch (row[row.len - 1][0]) {
            '+' => .@"+",
            '*' => .@"*",
            else => return error.InvalidOperator,
        };

        var local: usize = switch (op) {
            .@"+" => 0,
            .@"*" => 1,
        };

        for (row[0 .. row.len - 1]) |num_str| {
            const num = try std.fmt.parseInt(usize, num_str, 10);
            switch (op) {
                .@"+" => local += num,
                .@"*" => local *= num,
            }
        }

        total += local;
    }

    return total;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = .{ io, allocator };

    const line = mem.findScalarLast(u8, mem.trimEnd(u8, input, "\n\t\r "), '\n') orelse return null;

    var ops: Deque(Op) = .empty;
    defer ops.deinit(allocator);

    var it = mem.tokenizeScalar(
        u8,
        mem.trim(u8, input[line + 1 ..], "\n\t\r "),
        ' ',
    );
    while (it.next()) |op| try ops.pushBack(allocator, @enumFromInt(op[0]));

    var grid: Grid = try .init(allocator, input[0..line]);
    defer grid.deinit(allocator);
    try grid.transpose(allocator);

    var nums: ArrayList(usize) = .empty;
    defer nums.deinit(allocator);

    var total: usize = 0;

    for (grid.data) |row| {
        const trimmed = mem.trim(u8, row, " ");
        if (trimmed.len == 0) {
            const op = ops.popFront() orelse return null;
            var local: usize = switch (op) {
                .@"+" => 0,
                .@"*" => 1,
            };

            while (nums.pop()) |num| switch (op) {
                .@"+" => local += num,
                .@"*" => local *= num,
            };

            total += local;
            continue;
        }

        try nums.append(
            allocator,
            try std.fmt.parseInt(usize, trimmed, 10),
        );
    }

    if (nums.items.len > 0) {
        const op = ops.popFront() orelse return null;
        var local: usize = switch (op) {
            .@"+" => 0,
            .@"*" => 1,
        };
        while (nums.items.len > 0) {
            const num = nums.pop() orelse return null;
            switch (op) {
                .@"+" => local += num,
                .@"*" => local *= num,
            }
        }
        total += local;
    }

    return total;
}

test "problem" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\123 328  51 64 
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   +  
    ;

    try std.testing.expectEqual(4277556, try part1(io, allocator, input));
    try std.testing.expectEqual(3263827, try part2(io, allocator, input));
}
