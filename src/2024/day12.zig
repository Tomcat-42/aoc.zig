const std = @import("std");
const mem = std.mem;
const meta = std.meta;
const print = std.debug.print;
const AutoArrayHashMap = std.AutoArrayHashMap;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const util = @import("util");
const CharGrid = util.CharGrid;
const BoolGrid = util.BoolGrid;
const Io = std.Io;

const Position = struct { i: isize, j: isize };

fn flood(allocator: Allocator, initial: Position, grid: *const CharGrid, visited: *const BoolGrid) !AutoArrayHashMap(Position, void) {
    var stack: ArrayList(Position) = .empty;
    defer stack.deinit(allocator);

    var region: AutoArrayHashMap(Position, void) = .init(allocator);

    try stack.append(allocator, initial);
    while (stack.pop()) |current_position| {
        const current_value = grid.at_unchecked(
            @intCast(current_position.i),
            @intCast(current_position.j),
        );
        if (current_value == grid.at_unchecked(@intCast(initial.i), @intCast(initial.j))) {
            visited.set_unchecked(@intCast(current_position.i), @intCast(current_position.j), true);
            try region.put(current_position, {});
        }

        // - d -
        // c x a
        // - b -
        const to: [4]Position = .{
            .{ .i = current_position.i - 1, .j = current_position.j },
            .{ .i = current_position.i, .j = current_position.j - 1 },
            .{ .i = current_position.i + 1, .j = current_position.j },
            .{ .i = current_position.i, .j = current_position.j + 1 },
        };

        for (to) |new_pos|
            if (grid.at(new_pos.i, new_pos.j)) |new_value|
                if (!visited.get_unchecked(@intCast(new_pos.i), @intCast(new_pos.j)) and new_value == current_value) try stack.append(allocator, new_pos);
    }

    return region;
}

fn areaAndPerimeter(region: *const AutoArrayHashMap(Position, void)) !struct { area: usize, perimeter: usize } {
    var area: usize = 0;
    var perimeter: usize = 0;
    for (region.keys()) |pos| {
        area += 1;
        const to: [4]Position = .{
            .{ .i = pos.i - 1, .j = pos.j },
            .{ .i = pos.i, .j = pos.j - 1 },
            .{ .i = pos.i + 1, .j = pos.j },
            .{ .i = pos.i, .j = pos.j + 1 },
        };
        for (to) |new_pos| {
            if (!region.contains(new_pos)) perimeter += 1;
        }
    }
    return .{ .area = area, .perimeter = perimeter };
}

fn areaAndSides(region: *const AutoArrayHashMap(Position, void)) !struct { area: usize, sides: usize } {
    var sides: usize = 0;
    for (region.keys()) |pos| {
        const to: [8]Position = .{
            .{ .i = pos.i - 1, .j = pos.j - 1 },
            .{ .i = pos.i - 1, .j = pos.j },
            .{ .i = pos.i - 1, .j = pos.j + 1 },
            .{ .i = pos.i, .j = pos.j - 1 },
            .{ .i = pos.i, .j = pos.j + 1 },
            .{ .i = pos.i + 1, .j = pos.j - 1 },
            .{ .i = pos.i + 1, .j = pos.j },
            .{ .i = pos.i + 1, .j = pos.j + 1 },
        };

        const nw = region.contains(to[0]);
        const w = region.contains(to[1]);
        const sw = region.contains(to[2]);
        const n = region.contains(to[3]);
        const s = region.contains(to[4]);
        const ne = region.contains(to[5]);
        const e = region.contains(to[6]);
        const se = region.contains(to[7]);

        if (n and w and !nw) sides += 1;
        if (n and e and !ne) sides += 1;
        if (s and w and !sw) sides += 1;
        if (s and e and !se) sides += 1;
        if (!(n or w)) sides += 1;
        if (!(n or e)) sides += 1;
        if (!(s or w)) sides += 1;
        if (!(s or e)) sides += 1;
    }

    return .{ .area = region.keys().len, .sides = sides };
}

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = io;
    const map = CharGrid.init(allocator, input);
    defer map.deinit();

    const visited = BoolGrid.init(allocator, map.rows, map.cols);
    defer visited.deinit();

    var sum: usize = 0;
    for (0..map.rows) |i| for (0..map.cols) |j| {
        if (!visited.get_unchecked(@intCast(i), @intCast(j))) {
            var region = try flood(
                allocator,
                .{ .i = @intCast(i), .j = @intCast(j) },
                &map,
                &visited,
            );
            defer region.deinit();

            const data = try areaAndPerimeter(&region);
            sum += data.area * data.perimeter;
        }
    };

    return sum;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = io;
    const map = CharGrid.init(allocator, input);
    defer map.deinit();

    const visited = BoolGrid.init(allocator, map.rows, map.cols);
    defer visited.deinit();

    var sum: usize = 0;
    for (0..map.rows) |i| for (0..map.cols) |j| {
        if (!visited.get_unchecked(@intCast(i), @intCast(j))) {
            var region = try flood(
                allocator,
                .{ .i = @intCast(i), .j = @intCast(j) },
                &map,
                &visited,
            );
            defer region.deinit();
            const data = try areaAndSides(&region);
            sum += data.area * data.sides;
        }
    };

    return sum;
}

test "Test Input Pt1" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\RRRRIICCFF
        \\RRRRIICCCF
        \\VVRRRCCFFF
        \\VVRCCCJFFF
        \\VVVVCJJCFE
        \\VVIVCCJJEE
        \\VVIIICJJEE
        \\MIIIIIJJEE
        \\MIIISIJEEE
        \\MMMISSJEEE
    ;

    try std.testing.expectEqual(1930, try part1(io, allocator, input));
    try std.testing.expectEqual(1206, try part2(io, allocator, input));
}
