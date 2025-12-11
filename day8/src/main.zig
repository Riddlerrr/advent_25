const std = @import("std");
const utils = @import("utils");

pub const Point = struct {
    x: i64,
    y: i64,
    z: i64,

    pub fn distSq(self: Point, other: Point) i64 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        const dz = self.z - other.z;
        return dx * dx + dy * dy + dz * dz;
    }
};

const Edge = struct {
    u: usize,
    v: usize,
    dist_sq: i64,

    pub fn lessThan(_: void, lhs: Edge, rhs: Edge) bool {
        return lhs.dist_sq < rhs.dist_sq;
    }
};

const DSU = struct {
    parent: []usize,
    size: []usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, n: usize) !DSU {
        const parent = try allocator.alloc(usize, n);
        const size = try allocator.alloc(usize, n);
        for (0..n) |i| {
            parent[i] = i;
            size[i] = 1;
        }
        return DSU{
            .parent = parent,
            .size = size,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *DSU) void {
        self.allocator.free(self.parent);
        self.allocator.free(self.size);
    }

    pub fn find(self: *DSU, i: usize) usize {
        var root = i;
        while (root != self.parent[root]) {
            root = self.parent[root];
        }

        // Path compression
        var curr = i;
        while (curr != root) {
            const next = self.parent[curr];
            self.parent[curr] = root;
            curr = next;
        }

        return root;
    }

    pub fn unionSets(self: *DSU, i: usize, j: usize) void {
        const root_i = self.find(i);
        const root_j = self.find(j);
        if (root_i != root_j) {
            // Union by size
            if (self.size[root_i] < self.size[root_j]) {
                self.parent[root_i] = root_j;
                self.size[root_j] += self.size[root_i];
            } else {
                self.parent[root_j] = root_i;
                self.size[root_i] += self.size[root_j];
            }
        }
    }
};

pub const Simulation = struct {
    points: std.ArrayList(Point),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, content: []const u8) !Simulation {
        var points: std.ArrayList(Point) = .empty;
        var iter = utils.file.lines(content);
        while (iter.next()) |line| {
            if (line.len == 0) continue;
            var parts = std.mem.splitScalar(u8, line, ',');

            const x_str = parts.next() orelse continue;
            const y_str = parts.next() orelse continue;
            const z_str = parts.next() orelse continue;

            const x = try std.fmt.parseInt(i64, std.mem.trim(u8, x_str, " \t\r"), 10);
            const y = try std.fmt.parseInt(i64, std.mem.trim(u8, y_str, " \t\r"), 10);
            const z = try std.fmt.parseInt(i64, std.mem.trim(u8, z_str, " \t\r"), 10);

            try points.append(allocator, Point{ .x = x, .y = y, .z = z });
        }
        return Simulation{
            .points = points,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Simulation) void {
        self.points.deinit(self.allocator);
    }

    fn getSortedEdges(self: *Simulation) !std.ArrayList(Edge) {
        const n = self.points.items.len;
        var edges: std.ArrayList(Edge) = .empty;
        errdefer edges.deinit(self.allocator);

        for (0..n) |i| {
            for ((i + 1)..n) |j| {
                const d = self.points.items[i].distSq(self.points.items[j]);
                try edges.append(self.allocator, Edge{ .u = i, .v = j, .dist_sq = d });
            }
        }

        std.mem.sort(Edge, edges.items, {}, Edge.lessThan);
        return edges;
    }

    pub fn solvePart1(self: *Simulation, connections: usize) !usize {
        const n = self.points.items.len;
        if (n == 0) return 0;

        var edges = try self.getSortedEdges();
        defer edges.deinit(self.allocator);

        var dsu = try DSU.init(self.allocator, n);
        defer dsu.deinit();

        const limit = @min(connections, edges.items.len);
        for (0..limit) |i| {
            const edge = edges.items[i];
            dsu.unionSets(edge.u, edge.v);
        }

        var component_sizes: std.ArrayList(usize) = .empty;
        defer component_sizes.deinit(self.allocator);

        // Collect sizes of roots
        for (0..n) |i| {
            if (dsu.parent[i] == i) {
                try component_sizes.append(self.allocator, dsu.size[i]);
            }
        }

        std.mem.sort(usize, component_sizes.items, {}, std.sort.desc(usize));

        var result: usize = 1;
        const count = @min(3, component_sizes.items.len);
        for (0..count) |i| {
            result *= component_sizes.items[i];
        }

        return result;
    }

    pub fn solvePart2(self: *Simulation) !i64 {
        const n = self.points.items.len;
        if (n < 2) return 0;

        var edges = try self.getSortedEdges();
        defer edges.deinit(self.allocator);

        var dsu = try DSU.init(self.allocator, n);
        defer dsu.deinit();

        var components = n;

        for (edges.items) |edge| {
            if (dsu.find(edge.u) != dsu.find(edge.v)) {
                dsu.unionSets(edge.u, edge.v);
                components -= 1;
                if (components == 1) {
                    return self.points.items[edge.u].x * self.points.items[edge.v].x;
                }
            }
        }
        return 0;
    }
};

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const content = try utils.file.readFileAlloc(allocator, "boxes.txt");
    defer allocator.free(content);

    var sim = try Simulation.init(allocator, content);
    defer sim.deinit();

    const part1 = try sim.solvePart1(1000);
    try utils.io.println("Part 1: {}", .{part1});

    const part2 = try sim.solvePart2();
    try utils.io.println("Part 2: {}", .{part2});
}

test "example" {
    const content =
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
    ;
    var sim = try Simulation.init(std.testing.allocator, content);
    defer sim.deinit();
    const part1 = try sim.solvePart1(10);
    try std.testing.expectEqual(@as(usize, 40), part1);

    const part2 = try sim.solvePart2();
    try std.testing.expectEqual(@as(i64, 25272), part2);
}
