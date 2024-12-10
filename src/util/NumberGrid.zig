/// Cache Friendly 2D Grid of u8s
const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const print = std.debug.print;

allocator: Allocator,

rows: usize = 0,
cols: usize = 0,
data: []u8,

pub fn init(allocator: Allocator, str: []const u8, delimiter: u8) @This() {
    var it = mem.tokenizeScalar(u8, str, delimiter);

    var data: []u8 = allocator.alloc(u8, 0) catch @panic("Out of memory");
    var rows: usize = 0;
    while (it.next()) |line| : (rows += 1) {
        data = allocator.realloc(data, data.len + line.len) catch @panic("Out of memory");
        for (data[data.len - line.len .. data.len], line) |*i, j| i.* = j - '0';
    }

    return @This(){
        .allocator = allocator,
        .data = data,
        .rows = rows,
        .cols = if (rows > 0) data.len / rows else 0,
    };
}

pub fn deinit(this: @This()) void {
    this.allocator.free(this.data);
}

pub fn at(this: @This(), row: isize, col: isize) ?u8 {
    return if (this.within_bounds(row, col)) this.data[
        @truncate(@as(usize, @intCast(row)) * this.cols + @as(usize, @intCast(col)))
    ] else null;
}

pub fn at_unchecked(this: @This(), row: usize, col: usize) u8 {
    return this.data[row * this.cols + col];
}

pub fn within_bounds(this: @This(), row: isize, col: isize) bool {
    return row >= 0 and col >= 0 and row < this.rows and col < this.cols;
}

pub fn format(this: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
    for (0..this.rows) |i| {
        for (0..this.cols) |j| try writer.print("{d} ", .{this.data[i * this.cols + j]});
        try writer.print("\n", .{});
    }
}

test "NumberGrid.init" {
    // const expectEqual = std.testing.expectEqual;
    const allocator = std.heap.page_allocator;
    const str = "123\n456\n789\n";
    const grid = try @This().init(
        allocator,
        str,
        '\n',
    );
    print("{grid}\n", .{grid});
}
