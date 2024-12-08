const std = @import("std");
const mem = std.mem;
const utils = @import("util");
const ascii = std.ascii;
const print = std.debug.print;

const Grid = utils.Grid;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

input: []const u8,
allocator: mem.Allocator,

const Node = struct {
    frequency: u8,
    position: Position,

    const Position = struct {
        x: usize,
        y: usize,
    };
};

fn find_nodes(grid: *const Grid, allocator: mem.Allocator) ![]const Node {
    var nodes = ArrayList(Node).init(allocator);
    defer nodes.deinit();

    for (0..grid.rows) |x| for (0..grid.cols) |y| if (ascii.isAlphanumeric(grid.data[x][y]))
        try nodes.append(Node{
            .frequency = grid.data[x][y],
            .position = Node.Position{ .x = x, .y = y },
        });

    return nodes.toOwnedSlice();
}

fn count_anti_nodes(grid: *const Grid, nodes: []const Node, allocator: mem.Allocator) !usize {
    var anti_nodes = AutoHashMap(Node, void).init(allocator);
    defer anti_nodes.deinit();

    for (0..nodes.len) |i| for (i + 1..nodes.len) |j| {
        if (nodes[i].frequency != nodes[j].frequency) continue;

        const i_diff = @as(i128, nodes[i].position.x) - @as(i128, nodes[j].position.x);
        const j_diff = @as(i128, nodes[i].position.y) - @as(i128, nodes[j].position.y);

        if (grid.within_bounds(nodes[i].position.x - i_diff * -1, nodes[i].position.y - j_diff * -1))
            try anti_nodes.put(
                Node{
                    .frequency = '#',
                    .position = Node.Position{
                        .x = @as(usize, @intCast(nodes[i].position.x - i_diff * -1)),
                        .y = @as(usize, @intCast(nodes[i].position.y - j_diff * -1)),
                    },
                },
                {},
            );

        if (grid.within_bounds(nodes[j].position.x + i_diff * -1, nodes[j].position.y + j_diff * -1))
            try anti_nodes.put(
                Node{
                    .frequency = '#',
                    .position = Node.Position{
                        .x = @as(usize, @intCast(nodes[j].position.x + i_diff * -1)),
                        .y = @as(usize, @intCast(nodes[j].position.y + j_diff * -1)),
                    },
                },
                {},
            );
    };

    return anti_nodes.count();
}

fn count_resonant_anti_nodes(grid: *const Grid, nodes: []const Node, allocator: mem.Allocator) !usize {
    var anti_nodes = AutoHashMap(Node, void).init(allocator);
    defer anti_nodes.deinit();

    for (0..nodes.len) |i| for (i + 1..nodes.len) |j| {
        if (nodes[i].frequency != nodes[j].frequency) continue;

        const i_diff = @as(i128, nodes[i].position.x) - @as(i128, nodes[j].position.x);
        const j_diff = @as(i128, nodes[i].position.y) - @as(i128, nodes[j].position.y);
        var step: usize = 0;

        while (grid.within_bounds(
            nodes[i].position.x - i_diff * -1 * step,
            nodes[i].position.y - j_diff * -1 * step,
        )) : (step += 1)
            try anti_nodes.put(
                Node{
                    .frequency = '#',
                    .position = Node.Position{
                        .x = @as(usize, @intCast(nodes[i].position.x - i_diff * -1 * step)),
                        .y = @as(usize, @intCast(nodes[i].position.y - j_diff * -1 * step)),
                    },
                },
                {},
            );

        step = 0;
        while (grid.within_bounds(
            nodes[j].position.x + i_diff * -1 * step,
            nodes[j].position.y + j_diff * -1 * step,
        )) : (step += 1)
            try anti_nodes.put(
                Node{
                    .frequency = '#',
                    .position = Node.Position{
                        .x = @as(usize, @intCast(nodes[j].position.x + i_diff * -1 * step)),
                        .y = @as(usize, @intCast(nodes[j].position.y + j_diff * -1 * step)),
                    },
                },
                {},
            );
    };

    return anti_nodes.count();
}

pub fn part1(this: *const @This()) !?usize {
    var grid = try Grid.init(this.allocator, this.input);
    defer grid.deinit();

    const nodes = try find_nodes(&grid, this.allocator);
    defer this.allocator.free(nodes);

    const num_anti_nodes = try count_anti_nodes(&grid, nodes, this.allocator);

    return num_anti_nodes;
}

pub fn part2(this: *const @This()) !?usize {
    var grid = try Grid.init(this.allocator, this.input);
    defer grid.deinit();

    const nodes = try find_nodes(&grid, this.allocator);
    defer this.allocator.free(nodes);

    const num_anti_nodes = try count_resonant_anti_nodes(&grid, nodes, this.allocator);

    return num_anti_nodes;
}

test "Example Input" {
    const allocator = std.testing.allocator;
    const input =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(14, try problem.part1());
    try std.testing.expectEqual(34, try problem.part2());
}

