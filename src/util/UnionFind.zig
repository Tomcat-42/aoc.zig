const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const MultiArrayList = std.MultiArrayList;

const Entry = struct { parent: usize, size: usize };
const Data = MultiArrayList(Entry);

data: Data = .empty,

const Self = @This();

pub fn init(allocator: Allocator, s: usize) !Self {
    var data: Data = .empty;
    errdefer data.deinit(allocator);

    try data.ensureTotalCapacity(allocator, s);
    for (0..s) |i| data.appendAssumeCapacity(.{ .parent = i, .size = 1 });

    return .{ .data = data };
}

pub fn deinit(this: *Self, allocator: Allocator) void {
    this.data.deinit(allocator);
}

pub fn @"union"(this: *Self, a: usize, b: usize) void {
    const rootA = this.find(a);
    const rootB = this.find(b);

    if (rootA == rootB) return;

    const parents = this.data.items(.parent);
    const sizes = this.data.items(.size);

    if (sizes[rootA] < sizes[rootB]) {
        parents[rootA] = rootB;
        sizes[rootB] += sizes[rootA];
    } else {
        parents[rootB] = rootA;
        sizes[rootA] += sizes[rootB];
    }
}

pub fn find(this: *Self, value: usize) usize {
    const parents = this.data.items(.parent);
    if (parents[value] != value)
        parents[value] = this.find(parents[value]);
    return parents[value];
}

pub fn set(this: *Self, allocator: Allocator) !usize {
    const id = this.data.len;
    try this.data.append(allocator, .{ .parent = id, .size = 1 });
    return id;
}

pub fn roots(this: *Self, allocator: Allocator) ![]const usize {
    var r: ArrayList(usize) = .empty;
    errdefer r.deinit(allocator);

    var seen: std.AutoArrayHashMapUnmanaged(usize, void) = .empty;
    defer seen.deinit(allocator);

    for (0..this.data.len) |i| {
        const root = this.find(i);
        const gop = try seen.getOrPut(allocator, root);
        if (!gop.found_existing) try r.append(allocator, root);
    }

    return r.toOwnedSlice(allocator);
}

pub fn size(this: *Self, value: usize) usize {
    const root = this.find(value);
    return this.data.items(.size)[root];
}

pub fn connected(this: *Self, a: usize, b: usize) bool {
    return this.find(a) == this.find(b);
}
