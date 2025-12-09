const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoArrayHashMapUnmanaged = std.AutoArrayHashMapUnmanaged;

pub fn Graph(T: type) type {
    return struct {
        connections: AutoArrayHashMapUnmanaged(T, ArrayList(T)) = .empty,

        pub fn init(_: Allocator) @This() {
            return .{};
        }

        pub fn deinit(this: *@This(), allocator: Allocator) void {
            for (this.connections.values()) |*list| list.deinit(allocator);
            this.connections.deinit(allocator);
        }

        pub fn addEdge(this: *@This(), allocator: Allocator, from: T, to: T) !void {
            const gop = try this.connections.getOrPut(allocator, from);
            if (!gop.found_existing) gop.value_ptr.* = .empty;
            try gop.value_ptr.append(allocator, to);
        }

        pub fn addEdgeBidirectional(this: *@This(), allocator: Allocator, a: T, b: T) !void {
            try this.addEdge(allocator, a, b);
            try this.addEdge(allocator, b, a);
        }

        pub fn getNeighbors(this: *const @This(), node: T) ?[]const T {
            if (this.connections.get(node)) |list| return list.items;
            return null;
        }

        pub fn hasNode(this: *const @This(), node: T) bool {
            return this.connections.contains(node);
        }

        pub fn nodes(this: *const @This()) []const T {
            return this.connections.keys();
        }

        pub fn nodeCount(this: *const @This()) usize {
            return this.connections.count();
        }

        pub fn format(this: *const @This(), writer: *Io.Writer) !void {
            for (this.connections.keys(), this.connections.values()) |node, neighbors| {
                try writer.print("{any} -> ", .{node});
                for (neighbors.items, 0..) |neighbor, i| {
                    if (i > 0) try writer.writeAll(", ");
                    try writer.print("{any}", .{neighbor});
                }
                try writer.writeByte('\n');
            }
        }
    };
}
