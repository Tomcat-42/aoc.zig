const std = @import("std");
const mem = std.mem;
const meta = std.meta;
const ascii = std.ascii;
const fmt = std.fmt;
const print = std.debug.print;
const StaticStringMap = std.StaticStringMap;
const ArrayList = std.ArrayList;
const Allocator = mem.Allocator;
const Io = std.Io;

const Token = union(enum) {
    do,
    @"don't",
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
            var tokens: ArrayList(Token) = .empty;
            errdefer tokens.deinit(allocator);

            while (this.next()) |token| try tokens.append(allocator, token);
            return tokens.toOwnedSlice(allocator);
        }

        fn parseKeyword(this: *@This()) ?Token {
            var idx = this.pos;

            while (idx < this.src.len and (ascii.isAlphabetic(this.src[idx]) or this.src[idx] == '\'')) : (idx += 1) {}

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
    do: DoInstruction,
    @"don't": DontInstruction,

    pub fn parse(tokens: *Token.Iterator) ?@This() {
        return switch (tokens.peek() orelse return null) {
            .mul => blk: {
                if (MulInstruction.parse(tokens)) |mul| break :blk .{ .mul = mul };
                break :blk null;
            },
            .do => blk: {
                if (DoInstruction.parse(tokens)) |do| break :blk .{ .do = do };
                break :blk null;
            },
            .@"don't" => blk: {
                if (DontInstruction.parse(tokens)) |dont| break :blk .{ .@"don't" = dont };
                break :blk null;
            },
            else => null,
        };
    }

    pub fn eval(this: *const @This()) union(enum) { u64: u64, bool: bool } {
        return switch (this.*) {
            inline else => |instruction| return switch (@TypeOf(instruction.eval())) {
                u64 => .{ .u64 = instruction.eval() },
                bool => .{ .bool = instruction.eval() },
                else => unreachable,
            },
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

    pub const DoInstruction = struct {
        do: Token,
        @"(": Token,
        @")": Token,

        pub fn parse(tokens: *Token.Iterator) ?@This() {
            const do = tokens.expect(.do) orelse return null;
            const @"(" = tokens.expect(.@"(") orelse return null;
            const @")" = tokens.expect(.@")") orelse return null;

            return .{
                .do = do,
                .@"(" = @"(",
                .@")" = @")",
            };
        }

        pub fn eval(this: *const @This()) bool {
            _ = this; // autofix
            return true;
        }
    };

    pub const DontInstruction = struct {
        @"don't": Token,
        @"(": Token,
        @")": Token,

        pub fn parse(tokens: *Token.Iterator) ?@This() {
            const @"don't" = tokens.expect(.@"don't") orelse return null;
            const @"(" = tokens.expect(.@"(") orelse return null;
            const @")" = tokens.expect(.@")") orelse return null;

            return .{
                .@"don't" = @"don't",
                .@"(" = @"(",
                .@")" = @")",
            };
        }
        pub fn eval(this: *const @This()) bool {
            _ = this; // autofix
            return false;
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
            var instructions: ArrayList(Instruction) = .empty;
            errdefer instructions.deinit(allocator);
            while (this.next()) |instruction| try instructions.append(allocator, instruction);
            return instructions.toOwnedSlice(allocator);
        }
    };
};

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?u128 {
    _ = .{ io, allocator };
    var it = Token.Iterator.init(input);
    var instructions = Instruction.Iterator.init(&it);

    var sum: u64 = 0;
    while (instructions.next()) |instruction| switch (instruction.eval()) {
        .u64 => sum += instruction.eval().u64,
        else => {},
    };

    return sum;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?u128 {
    _ = .{ io, allocator };
    var it = Token.Iterator.init(input);
    var instructions = Instruction.Iterator.init(&it);

    var sum: u64 = 0;
    var mul: u64 = 1;
    while (instructions.next()) |instruction| switch (instruction.eval()) {
        .u64 => |val| sum += val * mul,
        .bool => |b| mul = @intFromBool(b),
    };

    return sum;
}

test "Example Input Part 1" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
    ;

    try std.testing.expectEqual(161, try part1(io, allocator, input));
}

test "Example Input Part 2" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))
    ;

    try std.testing.expectEqual(48, try part2(io, allocator, input));
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

test "Parse DoInstruction" {
    const expectEqualDeep = std.testing.expectEqualDeep;
    const expectEqual = std.testing.expectEqual;
    const input =
        \\do()
    ;
    const expected: Instruction.DoInstruction = .{
        .do = .do,
        .@"(" = .@"(",
        .@")" = .@")",
    };
    var it = Token.Iterator.init(input);
    const actual = Instruction.DoInstruction.parse(&it) orelse unreachable;
    try expectEqualDeep(expected, actual);
    try expectEqual(true, actual.eval());
}

test "Parse DontInstruction" {
    const expectEqualDeep = std.testing.expectEqualDeep;
    const expectEqual = std.testing.expectEqual;
    const input =
        \\don't()
    ;
    const expected: Instruction.DontInstruction = .{
        .@"don't" = .@"don't",
        .@"(" = .@"(",
        .@")" = .@")",
    };
    var it = Token.Iterator.init(input);
    const actual = Instruction.DontInstruction.parse(&it) orelse unreachable;
    try expectEqualDeep(expected, actual);
    try expectEqual(false, actual.eval());
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
    try expectEqual(8, actual.mul.eval());
}
