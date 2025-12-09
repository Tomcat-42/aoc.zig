const std = @import("std");
const Allocator = mem.Allocator;
const mem = std.mem;

pub const Delimiter = union(enum) {
    scalar: u8,
    sequence: []const u8,
    any: []const u8,
};

pub fn Iterator(
    comptime T: type,
    comptime delimiter: Delimiter,
    comptime parseFn: fn ([]const u8) anyerror!T,
) type {
    const delimiter_type: mem.DelimiterType = switch (delimiter) {
        .scalar => .scalar,
        .sequence => .sequence,
        .any => .any,
    };

    return struct {
        tokens: mem.TokenIterator(u8, delimiter_type),

        pub fn init(input: []const u8) @This() {
            return .{
                .tokens = .{
                    .index = 0,
                    .buffer = input,
                    .delimiter = switch (delimiter) {
                        .scalar => |v| v,
                        .sequence => |v| v,
                        .any => |v| v,
                    },
                },
            };
        }

        pub fn next(self: *@This()) !?T {
            const token = self.tokens.next() orelse return null;
            return try parseFn(token);
        }

        pub fn rest(self: *@This()) []const u8 {
            return self.tokens.rest();
        }

        pub fn reset(self: *@This()) void {
            self.tokens.reset();
        }

        pub fn collect(this: *@This(), allocator: Allocator) ![]T {
            var list: std.ArrayList(T) = .empty;
            errdefer list.deinit(allocator);

            while (try this.next()) |item| try list.append(allocator, item);
            return list.toOwnedSlice(allocator);
        }
    };
}

test "scalar delimiter" {
    const IntIterator = Iterator(i32, .{ .scalar = ',' }, struct {
        fn parse(s: []const u8) !i32 {
            return std.fmt.parseInt(i32, s, 10);
        }
    }.parse);

    var it: IntIterator = .init("1,2,3,4,5");
    try std.testing.expectEqual(1, try it.next());
    try std.testing.expectEqual(2, try it.next());
    try std.testing.expectEqual(3, try it.next());
    try std.testing.expectEqual(4, try it.next());
    try std.testing.expectEqual(5, try it.next());
    try std.testing.expectEqual(null, try it.next());
}

test "sequence delimiter" {
    const BlockIterator = Iterator([]const u8, .{ .sequence = "\n\n" }, struct {
        fn parse(s: []const u8) ![]const u8 {
            return s;
        }
    }.parse);

    var it: BlockIterator = .init("block1\n\nblock2\n\nblock3");
    try std.testing.expectEqualStrings("block1", (try it.next()).?);
    try std.testing.expectEqualStrings("block2", (try it.next()).?);
    try std.testing.expectEqualStrings("block3", (try it.next()).?);
    try std.testing.expectEqual(null, try it.next());
}

test "any delimiter" {
    const WordIterator = Iterator([]const u8, .{ .any = " \t," }, struct {
        fn parse(s: []const u8) ![]const u8 {
            return s;
        }
    }.parse);

    var it: WordIterator = .init("hello world,foo\tbar");
    try std.testing.expectEqualStrings("hello", (try it.next()).?);
    try std.testing.expectEqualStrings("world", (try it.next()).?);
    try std.testing.expectEqualStrings("foo", (try it.next()).?);
    try std.testing.expectEqualStrings("bar", (try it.next()).?);
    try std.testing.expectEqual(null, try it.next());
}
