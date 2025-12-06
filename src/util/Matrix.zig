/// 2D Matrix of strings
const std = @import("std");
const Io = std.Io;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

data: []const [][]const u8,
rows: usize,
cols: usize,

pub fn init(allocator: Allocator, input: []const u8) !@This() {
    var lines: ArrayList([][]const u8) = .empty;
    var linesIt = mem.tokenizeScalar(u8, input, '\n');

    while (linesIt.next()) |line| {
        var elements: ArrayList([]const u8) = .empty;
        var elementsIt = mem.tokenizeScalar(u8, line, ' ');

        while (elementsIt.next()) |element| try elements.append(allocator, element);

        try lines.append(allocator, try elements.toOwnedSlice(allocator));
    }

    const rows = lines.items.len;
    const cols = if (lines.items.len > 0) lines.items[0].len else 0;
    return .{
        .data = try lines.toOwnedSlice(allocator),
        .rows = rows,
        .cols = cols,
    };
}

pub fn deinit(this: *@This(), allocator: Allocator) void {
    defer allocator.free(this.data);
    for (this.data) |row|
        allocator.free(row);
}

pub inline fn at(this: @This(), row: isize, col: isize) ?[]const u8 {
    return if (this.within_bounds(row, col))
        this.data[@as(usize, @intCast(row))][@as(usize, @intCast(col))]
    else
        null;
}

pub inline fn at_unchecked(this: @This(), row: usize, col: usize) []const u8 {
    return this.data[row][col];
}

pub inline fn within_bounds(this: @This(), row: isize, col: isize) bool {
    return row >= 0 and col >= 0 and row < @as(isize, @intCast(this.rows)) and col < @as(isize, @intCast(this.cols));
}

pub fn transpose(self: *@This(), allocator: Allocator) !void {
    var transposed_data: ArrayList([][]const u8) = .empty;

    for (0..self.cols) |col_idx| {
        var new_row: ArrayList([]const u8) = .empty;
        for (0..self.rows) |row_idx| {
            try new_row.append(allocator, self.data[row_idx][col_idx]);
        }
        try transposed_data.append(allocator, try new_row.toOwnedSlice(allocator));
    }

    // Free old data
    for (self.data) |row| allocator.free(row);
    allocator.free(self.data);

    self.data = try transposed_data.toOwnedSlice(allocator);
    const old_rows = self.rows;
    self.rows = self.cols;
    self.cols = old_rows;
}

pub fn format(self: @This(), writer: *Io.Writer) !void {
    for (self.data) |row| {
        for (row, 0..) |elem, j| {
            try writer.print("{s}", .{elem});
            if (j < row.len - 1) try writer.print(" ", .{});
        }
        try writer.print("\n", .{});
    }
}
