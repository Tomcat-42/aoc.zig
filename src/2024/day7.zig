const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const ArrayList = std.ArrayList;
const DoublyLinkedList = std.DoublyLinkedList;
const Allocator = mem.Allocator;
const StaticStringMap = std.StaticStringMap;
const print = std.debug.print;
const math = std.math;

input: []const u8,
allocator: mem.Allocator,

pub fn ExponentialOperationTree(comptime NodeType: type) type {
    return struct {
        children: ?[NCHILDREN]*@This() = null,
        node: NodeType,

        pub fn init(node: NodeType) @This() {
            return @This(){
                .node = node,
            };
        }

        pub fn add(this: *@This(), val: NodeType.T, ally: Allocator) !void {
            if (this.children == null) {
                this.children = [_]*@This(){undefined} ** NCHILDREN;

                inline for (@typeInfo(NodeType.Operation).@"enum".fields, 0..) |field, i| {
                    this.children.?[i] = try ally.create(@This());
                    this.children.?[i].* = @This().init(.{
                        .value = val,
                        .operation = @enumFromInt(field.value),
                    });
                }
                return;
            }

            for (this.children.?) |child|
                try child.add(val, ally);
        }

        pub fn deinit(this: *@This(), alloc: Allocator) void {
            if (this.children) |children| for (children) |child| {
                defer alloc.destroy(child);
                child.deinit(alloc);
            };
        }

        pub fn walk(this: *@This(), target: u64, current: u64) !bool {
            if (this.children == null) return current == target;

            for (this.children.?) |child|
                if (try child.walk(target, try child.node.eval(current))) return true;

            return false;
        }

        const NCHILDREN = @typeInfo(NodeType.Operation).@"enum".fields.len;
    };
}

pub fn part1(this: *const @This()) !?u64 {
    const AddMul = struct {
        const Operation = enum { add, mul };
        const T = u64;

        value: T = 0,
        operation: Operation = .add,

        pub fn eval(t: *@This(), current: T) !T {
            return switch (t.operation) {
                .add => current + t.value,
                .mul => current * t.value,
            };
        }
    };

    var lines = mem.tokenizeScalar(u8, this.input, '\n');
    var sum: u64 = 0;
    while (lines.next()) |line| {
        var it = mem.tokenizeSequence(u8, line, ": ");

        const target = try fmt.parseUnsigned(u64, it.next().?, 10);
        const params = it.next().?;

        var params_it = mem.tokenizeScalar(u8, params, ' ');
        const first = try fmt.parseUnsigned(
            u64,
            params_it.next().?,
            10,
        );

        var tree = ExponentialOperationTree(AddMul).init(.{ .value = first });
        defer tree.deinit(this.allocator);

        while (params_it.next()) |p| {
            try tree.add(
                try fmt.parseUnsigned(u64, p, 10),
                this.allocator,
            );
        }

        if (try tree.walk(target, tree.node.value)) sum += target;
    }

    return sum;
}

pub fn part2(this: *const @This()) !?u64 {
    const AddMulConcat = struct {
        const Operation = enum { add, mul, concat };
        const T = u64;

        value: T = 0,
        operation: Operation = .add,

        pub fn eval(t: *@This(), current: T) !T {
            return switch (t.operation) {
                .add => current + t.value,
                .mul => current * t.value,
                .concat => num: {
                    var n = t.value;
                    var mul: T = 1;
                    while (n >= 10) : (n /= 10) mul *= 10;
                    break :num current * (mul * 10) + t.value;
                },
            };
        }
    };

    var lines = mem.tokenizeScalar(u8, this.input, '\n');
    var sum: u64 = 0;
    while (lines.next()) |line| {
        var it = mem.tokenizeSequence(u8, line, ": ");

        const target = try fmt.parseUnsigned(u64, it.next().?, 10);
        const params = it.next().?;

        var params_it = mem.tokenizeScalar(u8, params, ' ');
        const first = try fmt.parseUnsigned(
            u64,
            params_it.next().?,
            10,
        );

        var tree = ExponentialOperationTree(AddMulConcat).init(.{ .value = first });
        defer tree.deinit(this.allocator);

        while (params_it.next()) |p| {
            try tree.add(
                try fmt.parseUnsigned(u64, p, 10),
                this.allocator,
            );
        }

        if (try tree.walk(target, tree.node.value)) sum += target;
    }

    return sum;
}

test "Example Input" {
    const allocator = std.testing.allocator;
    const input =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(3749, try problem.part1());
    try std.testing.expectEqual(11387, try problem.part2());
}
