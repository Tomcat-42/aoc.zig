const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

///This is a generic grid that convert the chars of a string into a 2D grid
pub const Grid = struct {
    allocator: Allocator,

    data: [][]u8,
    rows: usize,
    cols: usize,

    pub fn init(allocator: Allocator, data: []const u8) !@This() {
        var lines = ArrayList([]u8).init(allocator);
        var it = mem.tokenizeScalar(u8, data, '\n');
        while (it.next()) |line| {
            try lines.append(try allocator.dupe(u8, line));
        }
        const rows = lines.items.len;
        const cols = if (lines.items.len > 0) lines.items[0].len else 0;
        return @This(){
            .allocator = allocator,
            .data = try lines.toOwnedSlice(),
            .rows = rows,
            .cols = cols,
        };
    }

    pub fn deinit(this: *@This()) void {
        defer this.allocator.free(this.data);
        for (this.data) |row|
            this.allocator.free(row);
    }
};
