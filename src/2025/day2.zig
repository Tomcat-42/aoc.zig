const std = @import("std");
const fmt = std.fmt;
const Allocator = std.mem.Allocator;
const mem = std.mem;
const Io = std.Io;

const Id = struct {
    first: usize = 0,
    last: usize = 0,
};

const IdIterator = struct {
    tokens: mem.TokenIterator(u8, .scalar),

    pub fn init(input: []const u8) IdIterator {
        return .{
            .tokens = mem.tokenizeScalar(u8, input, ','),
        };
    }

    pub fn next(self: *IdIterator) !?Id {
        const token = self.tokens.next() orelse
            return null;

        const dash_index = mem.indexOfScalar(u8, token, '-') orelse
            return null;

        return .{
            .first = try fmt.parseInt(usize, token[0..dash_index], 10),
            .last = try fmt.parseInt(
                usize,
                mem.trim(u8, token[dash_index + 1 ..], " \n\r\t"),
                10,
            ),
        };
    }
};

inline fn hasSingleRepeatedPattern(n: u64) bool {
    if (n < 10) return false;
    if (n < 100) return n % 11 == 0;
    if (n < 1_000) return false;
    if (n < 10_000) return n % 101 == 0;
    if (n < 100_000) return false;
    if (n < 1_000_000) return n % 1001 == 0;
    if (n < 10_000_000) return false;
    if (n < 100_000_000) return n % 10001 == 0;
    if (n < 1_000_000_000) return false;
    if (n < 10_000_000_000) return n % 100001 == 0;
    if (n < 100_000_000_000) return false;
    if (n < 1_000_000_000_000) return n % 1000001 == 0;
    if (n < 10_000_000_000_000) return false;
    if (n < 100_000_000_000_000) return n % 10000001 == 0;
    if (n < 1_000_000_000_000_000) return false;
    if (n < 10_000_000_000_000_000) return n % 100000001 == 0;
    if (n < 100_000_000_000_000_000) return false;
    if (n < 1_000_000_000_000_000_000) return n % 1000000001 == 0;
    if (n < 10_000_000_000_000_000_000) return false;
    return n % 10000000001 == 0;
}

inline fn hasRepeatedPattern(n: u64) bool {
    if (n < 10) return false;
    if (n < 100) return n % 11 == 0;
    if (n < 1_000) return n % 111 == 0;
    if (n < 10_000) return n % 101 == 0;
    if (n < 100_000) return n % 11111 == 0;
    if (n < 1_000_000) return (n % 1001 == 0) or (n % 10101 == 0);
    if (n < 10_000_000) return n % 1111111 == 0;
    if (n < 100_000_000) return n % 10001 == 0;
    if (n < 1_000_000_000) return n % 1001001 == 0;
    if (n < 10_000_000_000) return (n % 100001 == 0) or (n % 101010101 == 0);
    if (n < 100_000_000_000) return n % 11111111111 == 0;
    if (n < 1_000_000_000_000) return (n % 1000001 == 0) or (n % 100010001 == 0);
    if (n < 10_000_000_000_000) return n % 1111111111111 == 0;
    if (n < 100_000_000_000_000) return (n % 10000001 == 0) or (n % 1010101010101 == 0);
    if (n < 1_000_000_000_000_000) return (n % 10000100001 == 0) or (n % 1001001001001 == 0);
    if (n < 10_000_000_000_000_000) return n % 100000001 == 0;
    if (n < 100_000_000_000_000_000) return n % 11111111111111111 == 0;
    if (n < 1_000_000_000_000_000_000) return (n % 1000000001 == 0) or (n % 1000001000001 == 0);
    if (n < 10_000_000_000_000_000_000) return n % 1111111111111111111 == 0;
    return false;
}

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?i64 {
    _ = .{ io, allocator };

    var total: i64 = 0;
    var ids: IdIterator = .init(input);
    while (try ids.next()) |id| for (id.first..id.last + 1) |num| if (hasSingleRepeatedPattern(num)) {
        total += @intCast(num);
    };

    return total;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?i64 {
    _ = .{ io, allocator };

    var total: i64 = 0;
    var ids: IdIterator = .init(input);
    while (try ids.next()) |id| for (id.first..id.last + 1) |num| if (hasRepeatedPattern(num)) {
        total += @intCast(num);
    };

    return total;
}

test "it should do nothing" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
    ;

    try std.testing.expectEqual(1227775554, try part1(io, allocator, input));
    try std.testing.expectEqual(4174379265, try part2(io, allocator, input));
}
