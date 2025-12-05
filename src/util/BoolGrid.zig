/// Cache Friendly 2D Grid of bools
const std = @import("std");
const Io = std.Io;
const mem = std.mem;
const Allocator = std.mem.Allocator;

data: []bool,
rows: usize,
cols: usize,

pub fn init(allocator: Allocator, rows: usize, cols: usize) !@This() {
    const data = try allocator.alloc(bool, rows * cols);
    @memset(data, false);

    return .{
        .data = data,
        .rows = rows,
        .cols = cols,
    };
}

pub fn deinit(this: *@This(), allocator: Allocator) void {
    allocator.free(this.data);
}

pub fn get(this: @This(), row: isize, col: isize) ?bool {
    return if (this.within_bounds(row, col)) this.data[@as(usize, @intCast(row)) * this.cols + @as(usize, @intCast(col))] else null;
}

pub fn get_unchecked(this: @This(), row: usize, col: usize) bool {
    return this.data[row * this.cols + col];
}

pub fn set(this: @This(), row: isize, col: isize, value: bool) void {
    if (this.within_bounds(row, col))
        this.data[@as(usize, @intCast(row)) * this.cols + @as(usize, @intCast(col))] = value;
}

pub fn set_unchecked(this: @This(), row: usize, col: usize, value: bool) void {
    this.data[row * this.cols + col] = value;
}

pub fn within_bounds(this: @This(), row: isize, col: isize) bool {
    return row >= 0 and col >= 0 and row < @as(isize, @intCast(this.rows)) and col < @as(isize, @intCast(this.cols));
}

pub fn format(self: @This(), writer: *Io.Writer) !void {
    for (0..self.rows) |i| {
        for (0..self.cols) |j| try writer.print("{d}", .{
            @intFromBool(self.data[i * self.cols + j]),
        });
        try writer.print("\n", .{});
    }
}
