///This is a generic grid that convert the chars of a string into a 2D grid
const std = @import("std");
const Io = std.Io;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

data: [][]u8,
rows: usize,
cols: usize,

pub fn init(allocator: Allocator, data: []const u8) !@This() {
    var lines: ArrayList([]u8) = .empty;
    var it = mem.tokenizeScalar(u8, data, '\n');
    while (it.next()) |line| try lines.append(
        allocator,
        try allocator.dupe(u8, line),
    );
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

pub fn transpose(self: *@This(), allocator: Allocator) !void {
    var transposed_data: ArrayList([]u8) = .empty;

    for (0..self.cols) |col_idx| {
        const new_row = try allocator.alloc(u8, self.rows);
        for (0..self.rows) |row_idx| new_row[row_idx] = self.data[row_idx][col_idx];
        try transposed_data.append(allocator, new_row);
    }

    for (self.data) |row| allocator.free(row);
    allocator.free(self.data);

    self.data = try transposed_data.toOwnedSlice(allocator);
    const old_rows = self.rows;
    self.rows = self.cols;
    self.cols = old_rows;
}

pub inline fn at(self: @This(), x: anytype, y: @TypeOf(x)) u8 {
    return self.data[@as(usize, x)][@as(usize, y)];
}

pub inline fn within_bounds(self: @This(), x: i128, y: i128) bool {
    return x >= 0 and y >= 0 and x < @as(i128, self.rows) and y < @as(i128, self.cols);
}

pub fn format(self: @This(), writer: *Io.Writer) !void {
    for (self.data) |row| try writer.print("{s}\n", .{row});
}
