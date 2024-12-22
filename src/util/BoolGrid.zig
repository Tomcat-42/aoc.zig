/// Cache Friendly 2D Grid of chars
const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const print = std.debug.print;

allocator: Allocator,

rows: usize = 0,
cols: usize = 0,
data: []bool,

pub fn init(allocator: Allocator, rows: usize, cols: usize) @This() {
    const data: []bool = allocator.alloc(bool, rows * cols) catch @panic("Out of memory");
    @memset(data, false);

    return @This(){
        .allocator = allocator,
        .data = data,
        .rows = rows,
        .cols = cols,
    };
}

pub fn deinit(this: @This()) void {
    this.allocator.free(this.data);
}

pub fn get(this: @This(), row: isize, col: isize) ?bool {
    return if (this.within_bounds(row, col)) this.data[
        @truncate(@as(usize, @intCast(row)) * this.cols + @as(usize, @intCast(col)))
    ] else null;
}

pub fn get_unchecked(this: @This(), row: usize, col: usize) bool {
    return this.data[row * this.cols + col];
}

pub fn set(this: @This(), row: isize, col: isize, value: bool) void {
    if (this.within_bounds(row, col)) this.data[
        @truncate(@as(usize, @intCast(row)) * this.cols + @as(usize, @intCast(col)))
    ] = value;
}

pub fn set_unchecked(this: @This(), row: usize, col: usize, value: bool) void {
    this.data[row * this.cols + col] = value;
}

pub fn within_bounds(this: @This(), row: isize, col: isize) bool {
    return row >= 0 and col >= 0 and row < this.rows and col < this.cols;
}

pub fn format(this: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
    for (0..this.rows) |i| {
        for (0..this.cols) |j| try writer.print("{d}", .{
            @intFromBool(this.data[i * this.cols + j]),
        });
        try writer.print("\n", .{});
    }
}
