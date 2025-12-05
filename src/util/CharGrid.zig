/// Cache Friendly 2D Grid of chars
const std = @import("std");
const Io = std.Io;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

data: []u8,
rows: usize,
cols: usize,

pub fn init(allocator: Allocator, str: []const u8) !@This() {
    var data_list: ArrayList(u8) = .empty;
    var it = mem.tokenizeScalar(u8, str, '\n');
    var rows: usize = 0;

    while (it.next()) |line| : (rows += 1) {
        try data_list.appendSlice(allocator, line);
    }

    const data = try data_list.toOwnedSlice(allocator);
    const cols = if (rows > 0) data.len / rows else 0;

    return .{
        .data = data,
        .rows = rows,
        .cols = cols,
    };
}

pub fn deinit(this: *@This(), allocator: Allocator) void {
    allocator.free(this.data);
}

pub fn at(this: @This(), row: isize, col: isize) ?u8 {
    return if (this.within_bounds(row, col)) this.data[
        @as(usize, @intCast(row)) * this.cols + @as(usize, @intCast(col))
    ] else null;
}

pub fn at_unchecked(this: @This(), row: usize, col: usize) u8 {
    return this.data[row * this.cols + col];
}

pub fn set(this: @This(), row: isize, col: isize, value: u8) void {
    if (this.within_bounds(row, col))
        this.data[@as(usize, @intCast(row)) * this.cols + @as(usize, @intCast(col))] = value;
}

pub fn set_unchecked(this: @This(), row: usize, col: usize, value: u8) void {
    this.data[row * this.cols + col] = value;
}

pub fn within_bounds(this: @This(), row: isize, col: isize) bool {
    return row >= 0 and col >= 0 and row < @as(isize, @intCast(this.rows)) and col < @as(isize, @intCast(this.cols));
}

pub fn format(self: @This(), writer: *Io.Writer) !void {
    for (0..self.rows) |i| {
        for (0..self.cols) |j| try writer.print("{c}", .{self.data[i * self.cols + j]});
        try writer.print("\n", .{});
    }
}
