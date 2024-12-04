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
    @",",
    invalid: u8,

    const TagType = @typeInfo(@This()).@"union".tag_type.?;

    pub const Iterator = struct {
        src: []const u8,
        pos: usize,

        pub fn init(input: []const u8) Iterator {
            return .{ .src = input, .pos = 0 };
        }

        pub fn next(this: *@This()) ?Token {
            if (this.pos >= this.src.len) return null;
            defer this.pos += 1;

            return dfa: switch (this.src[this.pos]) {
                '(' => .@"(",
                ')' => .@")",
                ',' => .@",",

                else => {
                    // try integer
                    if (ascii.isDigit(this.src[this.pos]))
                        if (this.parseInteger()) |integer| break :dfa integer;

                    // keyword
                    if (ascii.isAlphabetic(this.src[this.pos]))
                        if (this.parseKeyword()) |keyword| break :dfa keyword;

                    // rinse and repeat
                    break :dfa .{ .invalid = this.src[this.pos] };
                },
            };
        }

        pub fn peek(this: *@This()) ?Token {
            const oldPos = this.pos;
            defer this.pos = oldPos;

            return this.next();
        }

        pub fn expect(this: *@This(), comptime expected: TagType) ?Token {
            return switch (this.peek() orelse return null) {
                expected => this.next(),
                else => null,
            };
        }

        pub fn collect(this: *@This(), allocator: Allocator) ![]Token {
            var tokens = ArrayList(Token).init(allocator);
            errdefer tokens.deinit();

            while (this.next()) |token| try tokens.append(token);
            return tokens.toOwnedSlice();
        }

        fn parseKeyword(this: *@This()) ?Token {
            var idx = this.pos;

            while (idx < this.src.len and ascii.isAlphabetic(this.src[idx])) : (idx += 1) {}

            if (LOOKUP_TABLE.get(this.src[this.pos..idx])) |token| {
                this.pos = idx - 1;
                return token;
            }

            return null;
        }

        fn parseInteger(this: *@This()) ?Token {
            var idx = this.pos;
            while (idx < this.src.len and ascii.isDigit(this.src[idx])) : (idx += 1) {}
            defer this.pos = idx - 1;

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

const Instruction = union(enum) {
    mul: MulInstruction,

    pub fn parse(tokens: *Token.Iterator) ?@This() {
        return switch (tokens.peek() orelse return null) {
            .mul => blk: {
                if (MulInstruction.parse(tokens)) |mul| break :blk .{ .mul = mul };
                break :blk null;
            },
            else => null,
        };
    }

    pub fn eval(this: *const @This()) u64 {
        return switch (this.*) {
            inline else => |instruction| return instruction.eval(),
        };
    }

    pub const MulInstruction = struct {
        mul: Token,
        @"(": Token,
        a: Token,
        @",": Token,
        b: Token,
        @")": Token,

        pub fn parse(tokens: *Token.Iterator) ?@This() {
            const mul = tokens.expect(.mul) orelse return null;
            const @"(" = tokens.expect(.@"(") orelse return null;
            const a = tokens.expect(.integer) orelse return null;
            const @"," = tokens.expect(.@",") orelse return null;
            const b = tokens.expect(.integer) orelse return null;
            const @")" = tokens.expect(.@")") orelse return null;

            return .{
                .mul = mul,
                .@"(" = @"(",
                .a = a,
                .@"," = @",",
                .b = b,
                .@")" = @")",
            };
        }

        pub fn eval(this: *const @This()) u64 {
            const a = this.a.integer;
            const b = this.b.integer;

            return a * b;
        }
    };

    pub const Iterator = struct {
        tokens: *Token.Iterator,

        pub fn init(tokens: *Token.Iterator) Iterator {
            return .{ .tokens = tokens };
        }

        pub fn next(this: *@This()) ?Instruction {
            while (this.tokens.peek()) |_| {
                if (Instruction.parse(this.tokens)) |instruction|
                    return instruction;

                _ = this.tokens.next();
            }

            return null;
        }

        pub fn collect(this: *@This(), allocator: Allocator) ![]Instruction {
            var instructions = ArrayList(Instruction).init(allocator);
            errdefer instructions.deinit();
            while (this.next()) |instruction| try instructions.append(instruction);
            return instructions.toOwnedSlice();
        }
    };
};

pub fn part1(this: *const @This()) !?u128 {
    var it = Token.Iterator.init(this.input);
    var instructions = Instruction.Iterator.init(&it);

    var sum: u64 = 0;
    while (instructions.next()) |instruction|
        sum += instruction.eval();

    return sum;
}

pub fn part2(this: *const @This()) !?i64 {
    _ = this;
    return null;
}

test "Example Input" {
    const allocator = std.testing.allocator;
    const input =
        \\xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(161, try problem.part1());
    try std.testing.expectEqual(null, try problem.part2());
}

test "Token.Iterator" {
    const expectEqualDeep = std.testing.expectEqualDeep;

    const allocator = std.testing.allocator;
    const input =
        \\xmul(2,4)amul3,7
    ;

    const expected: []const Token = &.{
        .{ .invalid = 'x' },
        .mul,
        .@"(",
        .{ .integer = 2 },
        .@",",
        .{ .integer = 4 },
        .@")",
        .{ .invalid = 'a' },
        .mul,
        .{ .integer = 3 },
        .@",",
        .{ .integer = 7 },
    };

    var it = Token.Iterator.init(input);
    const actual = try it.collect(allocator);
    defer allocator.free(actual);

    try expectEqualDeep(expected, actual);
}

test "Instruction.Iterator" {
    const expectEqualDeep = std.testing.expectEqualDeep;

    const allocator = std.testing.allocator;

    const input =
        \\xmul(2,4)zzzzzzzmul2,3mul(3,7)
    ;

    const expected: []const Instruction = &.{
        .{
            .mul = .{
                .mul = .mul,
                .@"(" = .@"(",
                .a = .{ .integer = 2 },
                .@"," = .@",",
                .b = .{ .integer = 4 },
                .@")" = .@")",
            },
        },
        .{
            .mul = .{
                .mul = .mul,
                .@"(" = .@"(",
                .a = .{ .integer = 3 },
                .@"," = .@",",
                .b = .{ .integer = 7 },
                .@")" = .@")",
            },
        },
    };

    var it = Token.Iterator.init(input);
    var instructions = Instruction.Iterator.init(&it);

    const actual = try instructions.collect(allocator);
    defer allocator.free(actual);

    try expectEqualDeep(expected, actual);
}

test "Parse MulInstruction" {
    const expectEqualDeep = std.testing.expectEqualDeep;
    const expectEqual = std.testing.expectEqual;

    const input =
        \\mul(2,4)
    ;

    const expected: Instruction.MulInstruction = .{
        .mul = .mul,
        .@"(" = .@"(",
        .a = .{ .integer = 2 },
        .@"," = .@",",
        .b = .{ .integer = 4 },
        .@")" = .@")",
    };
    var it = Token.Iterator.init(input);
    const actual = Instruction.MulInstruction.parse(&it) orelse unreachable;

    try expectEqualDeep(expected, actual);
    try expectEqual(8, actual.eval());
}

test "Parse Instruction" {
    const expectEqualDeep = std.testing.expectEqualDeep;
    const expectEqual = std.testing.expectEqual;
    const input =
        \\mul(2,4)adjaslkdjaslkdjmul(3,7)
    ;

    const expected: Instruction = .{
        .mul = .{
            .mul = .mul,
            .@"(" = .@"(",
            .a = .{ .integer = 2 },
            .@"," = .@",",
            .b = .{ .integer = 4 },
            .@")" = .@")",
        },
    };
    var it = Token.Iterator.init(input);
    const actual = Instruction.parse(&it) orelse unreachable;

    try expectEqualDeep(expected, actual);
    try expectEqual(8, actual.eval());
}
