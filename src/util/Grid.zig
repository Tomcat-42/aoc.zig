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

pub fn format(self: @This(), writer: Io.Writer) !void {
    for (self.data) |row| try writer.print("{s}\n", .{row});
}

pub fn within_bounds(self: @This(), x: i128, y: i128) bool {
    return x >= 0 and y >= 0 and x < @as(i128, self.rows) and y < @as(i128, self.cols);
}
