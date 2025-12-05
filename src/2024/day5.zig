const std = @import("std");
const mem = std.mem;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const AutoArrayHashMap = std.AutoArrayHashMap;
const PriorityQueue = std.PriorityQueue;
const print = std.debug.print;
const fmt = std.fmt;
const sort = std.sort;
const math = std.math;
const Allocator = std.mem.Allocator;
const Io = std.Io;

const DirectedGraph = struct {
    allocator: Allocator,
    edges: AutoHashMap(u64, AutoHashMap(u64, void)),

    pub fn init(allocator: Allocator) !@This() {
        return .{
            .allocator = allocator,
            .edges = AutoHashMap(
                u64,
                AutoHashMap(
                    u64,
                    void,
                ),
            ).init(allocator),
        };
    }

    pub fn deinit(this: *@This()) void {
        defer this.edges.deinit();

        var it = this.edges.valueIterator();
        while (it.next()) |entry| entry.deinit();
    }

    pub fn add(this: *@This(), from: u64, to: u64) !void {
        // add from -> to
        var entry = try this.edges.getOrPut(from);
        if (!entry.found_existing) entry.value_ptr.* = AutoHashMap(u64, void).init(
            this.allocator,
        );
        try entry.value_ptr.put(to, {});

        // if to -> {...} does not exist, create it
        entry = try this.edges.getOrPut(to);
        if (!entry.found_existing) entry.value_ptr.* = AutoHashMap(u64, void).init(
            this.allocator,
        );
    }

    pub fn remove(this: *@This(), from: u64, to: u64) void {
        if (this.edges.getPtr(from)) |entry| {
            _ = entry.remove(to);
        }
    }

    pub fn hasEdge(this: *const @This(), from: u64, to: u64) bool {
        return this.edges.contains(from) and this.edges.get(from).?.contains(to);
    }

    pub fn hasVertex(this: *const @This(), vertex: u64) bool {
        return this.edges.contains(vertex);
    }

    // Probably should adapt the path fn to handle filtered edges,
    // but this works for now.
    pub fn getFilteredGraph(
        this: *const @This(),
        nums: *const AutoArrayHashMap(u64, void),
    ) !@This() {
        // Remove all vertices and are in the given set
        var newGraph = try DirectedGraph.init(this.allocator);
        var it = this.edges.iterator();
        while (it.next()) |entry| {
            const from = entry.key_ptr.*;
            const tos = entry.value_ptr;

            if (nums.contains(from)) {
                var tosIt = tos.keyIterator();
                while (tosIt.next()) |to|
                    if (nums.contains(to.*)) try newGraph.add(from, to.*);
            }
        }

        return newGraph;
    }

    // Breadth-first search
    pub fn path(this: *const @This(), from: u64, to: u64) !bool {
        var visited: AutoHashMap(u64, void) = .init(this.allocator);
        defer visited.deinit();

        var q: PriorityQueue(
            u64,
            void,
            @This().priority,
        ) = .init(this.allocator, {});
        defer q.deinit();

        try q.add(from);
        try visited.put(from, {});

        return search: while (q.removeOrNull()) |current| {
            if (this.edges.getPtr(current)) |entry| {
                var it = entry.keyIterator();
                while (it.next()) |v|
                    if (!visited.contains(v.*)) {
                        try visited.put(v.*, {});

                        if (v.* == to) break :search true;
                        try q.add(v.*);
                    };
            }
        } else false;
    }

    fn priority(_: void, _: u64, _: u64) math.Order {
        // No priority is needed for now
        return math.Order.eq;
    }
};

// Consider the rules:
// - 47|53
// And the list:
// - 47, 10, 53
// A ordering algorithm will compare every pair of pages in the list against the rules,
// which will come to 2 cases of a < b:
// - I can find a path in the graph from a to b, so a < b => true
// - I can't find a path in the graph from a to b, so a < b => false
fn pageLessThan(rules: *const DirectedGraph, lhs: u64, rhs: u64) bool {
    return rules.path(lhs, rhs) catch @panic("pageLessThan");
}

pub fn part1(io: Io, allocator: Allocator, input: []const u8) !?u64 {
    _ = io;
    var ordering = try DirectedGraph.init(allocator);
    defer ordering.deinit();

    var inputIt = mem.tokenizeSequence(u8, input, "\n\n");
    const pageOrderingRules = inputIt.next().?;
    const pagesList = inputIt.next().?;

    // Parse page ordering rules.
    var rulesIt = mem.tokenizeScalar(u8, pageOrderingRules, '\n');
    while (rulesIt.next()) |line| {
        var fromTo = mem.tokenizeScalar(u8, line, '|');
        const from = try fmt.parseInt(u64, fromTo.next().?, 10);
        const to = try fmt.parseInt(u64, fromTo.next().?, 10);
        try ordering.add(from, to);
    }

    // Parse pages.
    var sum: u64 = 0;
    var pagesIt = mem.tokenizeScalar(u8, pagesList, '\n');
    while (pagesIt.next()) |line| {
        var pages = mem.tokenizeScalar(u8, line, ',');
        var pagesArray: AutoArrayHashMap(u64, void) = .init(allocator);
        defer pagesArray.deinit();

        while (pages.next()) |page|
            try pagesArray.put(try fmt.parseInt(u64, page, 10), {});

        var orderingFiltered = try ordering.getFilteredGraph(&pagesArray);
        defer orderingFiltered.deinit();

        if (sort.isSorted(
            u64,
            pagesArray.keys(),
            &orderingFiltered,
            pageLessThan,
        ))
            sum += pagesArray.keys()[pagesArray.keys().len / 2];
    }

    return sum;
}

pub fn part2(io: Io, allocator: Allocator, input: []const u8) !?u64 {
    _ = io;
    var ordering = try DirectedGraph.init(allocator);
    defer ordering.deinit();

    var inputIt = mem.tokenizeSequence(u8, input, "\n\n");
    const pageOrderingRules = inputIt.next().?;
    const pagesList = inputIt.next().?;

    // Parse page ordering rules.
    var rulesIt = mem.tokenizeScalar(u8, pageOrderingRules, '\n');
    while (rulesIt.next()) |line| {
        var fromTo = mem.tokenizeScalar(u8, line, '|');
        const from = try fmt.parseInt(u64, fromTo.next().?, 10);
        const to = try fmt.parseInt(u64, fromTo.next().?, 10);
        try ordering.add(from, to);
    }

    // Parse pages.
    var sum: u64 = 0;
    var pagesIt = mem.tokenizeScalar(u8, pagesList, '\n');
    while (pagesIt.next()) |line| {
        var pages = mem.tokenizeScalar(u8, line, ',');
        var pagesArray: AutoArrayHashMap(u64, void) = .init(allocator);
        defer pagesArray.deinit();

        while (pages.next()) |page|
            try pagesArray.put(try fmt.parseInt(u64, page, 10), {});

        var orderingFiltered = try ordering.getFilteredGraph(&pagesArray);
        defer orderingFiltered.deinit();

        if (!sort.isSorted(
            u64,
            pagesArray.keys(),
            &orderingFiltered,
            pageLessThan,
        )) {
            mem.sort(
                u64,
                pagesArray.keys(),
                &orderingFiltered,
                pageLessThan,
            );
            sum += pagesArray.keys()[pagesArray.keys().len / 2];
        }
    }

    return sum;
}

test "DirectedGraph" {
    const expectEqual = std.testing.expectEqual;
    const allocator = std.testing.allocator;

    var graph = try DirectedGraph.init(allocator);
    defer graph.deinit();

    //     ┌───────────────┐
    //     ↓               ↑
    //     1 → 2 → 3 → 4 → 5
    //     ↑       ↓
    //     └───────┘
    try graph.add(1, 2);
    try graph.add(2, 3);
    try graph.add(3, 4);
    try graph.add(3, 1);
    try graph.add(4, 5);
    try graph.add(5, 1);

    try expectEqual(true, graph.hasEdge(1, 2));
    try expectEqual(true, graph.hasEdge(2, 3));
    try expectEqual(true, graph.hasEdge(3, 4));
    try expectEqual(true, graph.hasEdge(3, 1));
    try expectEqual(true, graph.hasEdge(4, 5));
    try expectEqual(true, graph.hasEdge(5, 1));

    try expectEqual(true, graph.path(1, 5));

    graph.remove(1, 2);
    try expectEqual(false, graph.hasEdge(1, 2));

    graph.remove(1, 3);
    try expectEqual(false, graph.hasEdge(1, 3));
}

test "Example Input" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;
    const input =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
    ;

    try std.testing.expectEqual(143, try part1(io, allocator, input));
    try std.testing.expectEqual(null, try part2(io, allocator, input));
}
