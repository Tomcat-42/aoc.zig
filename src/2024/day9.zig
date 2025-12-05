/// Thats some shitty code up ahead, procceed with caution
const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = mem.Allocator;
const Io = std.Io;

const Filesystem = struct {
    allocator: Allocator,
    blocks: []Block,

    fn init(allocator: Allocator, input: []const u8) !@This() {
        var it = mem.window(u8, input, 2, 2);
        var entries: ArrayList(Block) = .empty;
        defer entries.deinit(allocator);

        var id: usize = 0;
        while (it.next()) |window| : (id += 1) {
            try entries.appendNTimes(
                allocator,
                .{ .id = id, .tag = .file },
                window[0] - '0',
            );

            if (window.len == 2 and window[1] != '0')
                try entries.appendNTimes(
                    allocator,
                    .{ .id = id, .tag = .frag },
                    window[1] - '0',
                );
        }

        return .{
            .allocator = allocator,
            .blocks = try entries.toOwnedSlice(allocator),
        };
    }

    fn deinit(this: *@This()) void {
        defer this.allocator.free(this.blocks);
    }

    fn checksum(this: *@This()) usize {
        var sum: usize = 0;
        for (this.blocks, 0..) |b, i|
            switch (b.tag) {
                .file => sum += b.id * i,
                else => {},
            };
        return sum;
    }

    fn compact(this: *@This()) void {
        var left: usize = 0;
        var right: usize = this.blocks.len - 1;

        while (left < right) {
            while (this.blocks[left].tag != .frag) : (left += 1) {}
            while (this.blocks[right].tag != .file) : (right -= 1) {}
            if (left < right) mem.swap(Block, &this.blocks[left], &this.blocks[right]);
        }
    }

    fn last_file_ending_at(this: *@This(), end: usize) ?Range {
        var right = end;
        while (this.blocks[right].tag == .frag) : (right -= 1) {
            if (right == 0) break;
        }

        var begin = right;
        while (this.blocks[begin].tag == .file and
            this.blocks[begin].id == this.blocks[right].id) : (begin -|= 1)
        {
            if (begin == 0) break;
        }

        return if (begin < right) Range{
            .begin = if (begin == 0) 0 else begin + 1,
            .end = if (right == 0) 0 else right + 1,
        } else null;
    }

    fn first_frag_in_range(this: *@This(), range: Range) ?Range {
        var left: usize = range.begin;
        while (this.blocks[left].tag != .frag) : (left += 1) {
            if (left == this.blocks.len - 1) break;
        }

        var right = left;
        while (right < range.end and
            this.blocks[right].tag == .frag) : (right += 1)
        {
            if (right == this.blocks.len - 1) break;
        }

        return if (left < right) .{
            .begin = left,
            .end = right,
        } else null;
    }

    fn defrag(this: *@This()) void {
        // const left: usize = 0;
        var right: usize = this.blocks.len - 1;
        while (this.last_file_ending_at(right)) |file_range| {
            var begin: usize = 0;
            while (this.first_frag_in_range(Range{ .begin = begin, .end = file_range.end })) |frag_range| {
                if (file_range.len() <= frag_range.len()) {
                    const from = this.blocks[file_range.begin..file_range.end];
                    const to = this.blocks[frag_range.begin .. frag_range.begin + file_range.len()];

                    for (from, to) |*f, *t|
                        mem.swap(Block, f, t);

                    break;
                }
                begin = frag_range.end;
            }
            right = file_range.begin -| 1;
        }
    }

    pub fn format(this: @This(), comptime f: []const u8, o: std.fmt.FormatOptions, writer: anytype) !void {
        for (this.blocks) |block|
            try block.format(f, o, writer);

        try writer.print("\n", .{});
    }

    const Block = struct {
        const Tag = enum { file, frag };

        id: usize,
        tag: Tag,

        pub fn format(this: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            switch (this.tag) {
                .file => try writer.print("{d}", .{this.id}),
                .frag => try writer.print(".", .{}),
            }
        }
    };

    const Range = struct {
        begin: usize,
        end: usize,

        pub fn len(this: @This()) usize {
            return this.end - this.begin;
        }
    };
};

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = io;
    var fs = try Filesystem.init(
        allocator,
        input[0 .. input.len - 1], // stray newline
    );
    defer fs.deinit();

    fs.compact();

    return fs.checksum();
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?usize {
    _ = io;
    var fs = try Filesystem.init(
        allocator,
        input[0 .. input.len - 1], // stray newline
    );
    defer fs.deinit();

    fs.defrag();

    return fs.checksum();
}

test "Example Input" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\2333133121414131402
        \\
    ;

    try std.testing.expectEqual(1928, try part1(io, allocator, input));
    try std.testing.expectEqual(2858, try part2(io, allocator, input));
}
