const std = @import("std");
const sort = std.sort;
const mem = std.mem;
const fmt = std.fmt;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Io = std.Io;

const util = @import("util");
const UnionFind = util.UnionFind;

const Point = @Vector(3, usize);

pub inline fn distance(a: Point, b: Point) usize {
    const diff = @max(a, b) - @min(a, b);
    const squared = diff * diff;
    return @reduce(.Add, squared);
}

const PointIterator = struct {
    tokens: mem.TokenIterator(u8, .scalar),

    pub fn init(input: []const u8) @This() {
        return .{ .tokens = mem.tokenizeScalar(u8, input, '\n') };
    }

    pub fn next(this: *PointIterator) !?Point {
        const line = this.tokens.next() orelse return null;
        var it = mem.tokenizeScalar(u8, line, ',');

        return .{
            try fmt.parseUnsigned(usize, it.next() orelse return null, 10),
            try fmt.parseUnsigned(usize, it.next() orelse return null, 10),
            try fmt.parseUnsigned(usize, it.next() orelse return null, 10),
        };
    }
};

const Edge = struct {
    i: usize,
    j: usize,
    dist: usize,
};

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = io;

    var points: ArrayList(Point) = .empty;
    defer points.deinit(allocator);

    var it: PointIterator = .init(input);
    while (try it.next()) |p| try points.append(allocator, p);

    var edges: ArrayList(Edge) = .empty;
    defer edges.deinit(allocator);

    for (0..points.items.len) |i| for (i + 1..points.items.len) |j| {
        const dist = distance(points.items[i], points.items[j]);
        try edges.append(allocator, .{ .i = i, .j = j, .dist = dist });
    };

    sort.heap(
        Edge,
        edges.items,
        {},
        struct {
            pub fn lessThan(_: void, a: Edge, b: Edge) bool {
                return a.dist < b.dist;
            }
        }.lessThan,
    );

    var sets: UnionFind = try .init(allocator, points.items.len);
    defer sets.deinit(allocator);

    const connections = @min(if (points.items.len <= 20) @as(usize, 10) else 1000, edges.items.len);
    for (edges.items[0..connections]) |edge| sets.@"union"(edge.i, edge.j);

    const roots = try sets.roots(allocator);
    defer allocator.free(roots);

    const sizes: []usize = try allocator.alloc(usize, roots.len);
    defer allocator.free(sizes);

    for (roots, 0..) |root, index| sizes[index] = sets.size(root);

    sort.heap(usize, sizes, {}, sort.desc(usize));

    assert(sizes.len >= 3);
    return sizes[0] * sizes[1] * sizes[2];
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = io;

    var points: ArrayList(Point) = .empty;
    defer points.deinit(allocator);

    var it: PointIterator = .init(input);
    while (try it.next()) |p| try points.append(allocator, p);

    var edges: ArrayList(Edge) = .empty;
    defer edges.deinit(allocator);

    for (0..points.items.len) |i| for (i + 1..points.items.len) |j| {
        const dist = distance(points.items[i], points.items[j]);
        try edges.append(allocator, .{ .i = i, .j = j, .dist = dist });
    };

    sort.heap(
        Edge,
        edges.items,
        {},
        struct {
            pub fn lessThan(_: void, a: Edge, b: Edge) bool {
                return a.dist < b.dist;
            }
        }.lessThan,
    );

    var sets: UnionFind = try .init(allocator, points.items.len);
    defer sets.deinit(allocator);

    var numCircuits = points.items.len;
    var lastEdge: Edge = undefined;

    for (edges.items) |edge| if (sets.find(edge.i) != sets.find(edge.j)) {
        sets.@"union"(edge.i, edge.j);
        numCircuits -= 1;
        lastEdge = edge;
        if (numCircuits == 1) break;
    };

    return points.items[lastEdge.i][0] * points.items[lastEdge.j][0];
}

test "problem" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
    ;

    try std.testing.expectEqual(40, try part1(io, allocator, input));
    try std.testing.expectEqual(25272, try part2(io, allocator, input));
}
