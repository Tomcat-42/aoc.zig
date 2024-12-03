const std = @import("std");
const mem = std.mem;
const meta = std.meta;
const ascii = std.ascii;
const fmt = std.fmt;
const print = std.debug.print;
const StaticStringMap = std.StaticStringMap;
const ArrayList = std.ArrayList;
const Allocator = mem.Allocator;

input: []const u8,
allocator: mem.Allocator,

const Token = union(enum) {
    mul,
    @"(",
    integer: u64,
    @")",

    pub const Iterator = struct {
        src: []const u8,
        pos: usize,

        pub fn init(input: []const u8) !Iterator {
            return .{ .src = input, .pos = 0 };
        }

        pub fn next(this: *@This()) !?Token {
            if (this.pos >= this.src.len) return null;
            defer this.pos += 1;

            return dfa: switch (this.src[this.pos]) {
                '(' => .@"(",
                ')' => .@")",
                else => {
                    // try integer
                    if (ascii.isDigit(this.src[this.pos]))
                        if (try this.parseInteger()) |integer| break :dfa integer;

                    // keyword
                    if (ascii.isAlphabetic(this.src[this.pos]))
                        if (try this.parseKeyword()) |keyword| break :dfa keyword;

                    // rinse and repeat
                    if (this.pos >= this.src.len) break :dfa null;
                    continue :dfa this.src[this.pos];
                },
            };
        }

        pub fn peek(this: *@This()) !?Token {
            const oldPos = this.pos;
            defer this.pos = oldPos;

            return this.next();
        }

        pub fn collect(this: *@This(), allocator: Allocator) ![]Token {
            print("collect => {d}\n", .{this.pos});
            var tokens = ArrayList(Token).init(allocator);
            errdefer tokens.deinit();

            while (try this.next()) |token| try tokens.append(token);
            return tokens.toOwnedSlice();
        }

        fn parseKeyword(this: *@This()) !?Token {
            print("parseKeyword => {d} {c}\n", .{ this.pos, this.src[this.pos] });
            var idx = this.pos;

            while (idx < this.src.len and ascii.isAlphabetic(this.src[idx])) : (idx += 1) {}

            if (LOOKUP_TABLE.get(this.src[this.pos..idx])) |token| {
                this.pos = idx;
                return token;
            }

            return null;
        }

        fn parseInteger(this: *@This()) !?Token {
            var idx = this.pos;
            while (idx < this.src.len and ascii.isDigit(this.src[idx])) : (idx += 1) {}
            defer this.pos = idx;

            const integer = fmt.parseInt(u64, this.src[this.pos..idx], 10) catch return null;
            return .{ .integer = integer };
        }
    };

    pub const LOOKUP_TABLE = table: {
        const fields = meta.fields(@This());
        var tuple: [fields.len]struct { []const u8, @This() } = undefined;
        for (fields, 0..) |field, i|
            tuple[i] = .{ field.name, @unionInit(@This(), field.name, undefined) };

        break :table StaticStringMap(@This()).initComptime(tuple);
    };
};

pub fn part1(this: *const @This()) !?i64 {
    _ = this; // autofix
    return null;
}

pub fn part2(this: *const @This()) !?i64 {
    _ = this;
    return null;
}

test "token iterator" {
    // const expectEqualDeep = std.testing.expectEqualDeep;

    const allocator = std.testing.allocator;
    const input =
        \\xmul(2,4)
    ;

    const expected: []const Token = &.{
        .mul,               .@"(",             .{ .integer = 2 }, .{ .integer = 4 },  .@")",
        .mul,               .{ .integer = 3 }, .{ .integer = 7 }, .mul,               .@"(",
        .{ .integer = 5 },  .{ .integer = 5 }, .@")",             .mul,               .{ .integer = 32 },
        .{ .integer = 64 }, .mul,              .@"(",             .{ .integer = 11 }, .{ .integer = 8 },
        .@")",              .mul,              .@"(",             .{ .integer = 8 },  .{ .integer = 5 },
        .@")",
    };

    var it = try Token.Iterator.init(input);
    const actual = try it.collect(allocator);
    defer allocator.free(actual);
    print("actual: \n", .{});
    for (actual) |token| {
        print("{any}\n", .{token});
    }

    print("\nexpected: \n", .{});
    for (expected) |token| {
        print("{any}\n", .{token});
    }

    // try expectEqualDeep(expected, actual);
}

// test "it should do nothing" {
//     const allocator = std.testing.allocator;
//     const input =
//         \\xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
//     ;
//
//     const problem: @This() = .{
//         .input = input,
//         .allocator = allocator,
//     };
//
//     try std.testing.expectEqual(161, try problem.part1());
//     try std.testing.expectEqual(null, try problem.part2());
// }
