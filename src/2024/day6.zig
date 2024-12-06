const std = @import("std");
const mem = std.mem;
const util = @import("util");
const math = std.math;
const print = std.debug.print;
const AutoHashMap = std.AutoHashMap;
const EnumSet = std.EnumSet;
const Grid = util.Grid;

input: []const u8,
allocator: mem.Allocator,

const Position = struct { row: usize, col: usize };
const Direction = enum { Up, Down, Left, Right, None };
const State = struct { position: Position, direction: Direction, walked: usize = 0 };

fn walkUntilNextObstacle(map: *Grid, direction: Direction, position: Position) ?State {
    var newPosition = position;
    var walked: usize = 0;
    return loop: switch (direction) {
        .Up => {
            while (newPosition.row > 0 and
                map.data[newPosition.row - 1][newPosition.col] != '#') : (newPosition.row -= 1)
            {
                if (map.data[newPosition.row][newPosition.col] != 'X') {
                    map.data[newPosition.row][newPosition.col] = 'X';
                    walked += 1;
                }
            }

            break :loop .{
                .position = newPosition,
                .direction = if (newPosition.row > 0) .Right else .None,
                .walked = walked,
            };
        },
        .Right => {
            while (newPosition.col < map.cols - 1 and
                map.data[newPosition.row][newPosition.col + 1] != '#') : (newPosition.col += 1)
            {
                if (map.data[newPosition.row][newPosition.col] != 'X') {
                    map.data[newPosition.row][newPosition.col] = 'X';
                    walked += 1;
                }
            }
            break :loop .{
                .position = newPosition,
                .direction = if (newPosition.col < map.cols - 1) .Down else .None,
                .walked = walked,
            };
        },
        .Left => {
            while (newPosition.col > 0 and
                map.data[newPosition.row][newPosition.col - 1] != '#') : (newPosition.col -= 1)
            {
                if (map.data[newPosition.row][newPosition.col] != 'X') {
                    map.data[newPosition.row][newPosition.col] = 'X';
                    walked += 1;
                }
            }
            break :loop .{
                .position = newPosition,
                .direction = if (newPosition.col > 0) .Up else .None,
                .walked = walked,
            };
        },
        .Down => {
            while (newPosition.row < map.rows - 1 and
                map.data[newPosition.row + 1][newPosition.col] != '#') : (newPosition.row += 1)
            {
                if (map.data[newPosition.row][newPosition.col] != 'X') {
                    map.data[newPosition.row][newPosition.col] = 'X';
                    walked += 1;
                }
            }
            break :loop .{
                .position = newPosition,
                .direction = if (newPosition.row < map.rows - 1) .Left else .None,
                .walked = walked,
            };
        },
        .None => break :loop null,
    };
}

fn cyclic(map: *Grid, initialState: State) bool {
    var cache = std.AutoHashMap(Position, EnumSet(Direction)).init(map.allocator);
    defer cache.deinit();

    var state: ?State = initialState;

    return ret: while (state) |s| {
        const directions = cache.getOrPutValue(s.position, EnumSet(Direction){}) catch {
            @panic("Failed to get or put value");
        };
        if (directions.value_ptr.contains(s.direction)) break :ret true;
        directions.value_ptr.insert(s.direction);

        state = walkUntilNextObstacle(map, s.direction, s.position);
    } else false;
}

pub fn part1(this: *const @This()) !?usize {
    var map = try Grid.init(this.allocator, this.input);
    defer map.deinit();

    // find the guard
    var state: ?State = .{
        .position = pos: {
            for (0..map.rows) |row| for (0..map.cols) |col|
                if (map.data[row][col] == '^')
                    break :pos .{
                        .row = row,
                        .col = col,
                    };

            @panic("Guard not found");
        },
        .direction = .Up,
    };

    return ret: {
        var count: usize = 1;

        while (state) |s| {
            const newstate = walkUntilNextObstacle(
                &map,
                s.direction,
                s.position,
            );
            if (newstate) |ns| count += ns.walked;
            state = newstate;
        }
        break :ret count;
    };
}

pub fn part2(this: *const @This()) !?usize {
    var map = try Grid.init(this.allocator, this.input);
    defer map.deinit();

    // find the guard
    const initialState: State = .{
        .position = pos: {
            for (0..map.rows) |row| for (0..map.cols) |col|
                if (map.data[row][col] == '^')
                    break :pos .{
                        .row = row,
                        .col = col,
                    };

            @panic("Guard not found");
        },
        .direction = .Up,
    };
    // print("cycle: {any}\n", .{cyclic(&map, initialState)});
    // return 0;
    return ret: {
        var count: usize = 0;

        for (0..map.rows) |i| for (0..map.cols) |j| {
            if (i == initialState.position.row and j == initialState.position.col) continue;

            if (map.data[i][j] != '#') {
                map.data[i][j] = '#';
                const cycle = cyclic(&map, initialState);
                count += @intFromBool(cycle);
                map.data[i][j] = '.';
            }
        };

        break :ret count;
    };
}

test "Example Input" {
    const allocator = std.testing.allocator;
    const input =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(41, try problem.part1());
    try std.testing.expectEqual(6, try problem.part2());
}
