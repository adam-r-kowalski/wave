const std = @import("std");
const List = std.ArrayList;
const Allocator = std.mem.Allocator;

const substitution = @import("substitution.zig");
const Substitution = substitution.Substitution;
const MonoType = substitution.MonoType;
const Indent = @import("indent.zig").Indent;

pub const Equal = struct {
    left: MonoType,
    right: MonoType,

    fn solve(self: Equal, s: *Substitution) !void {
        const left_tag = std.meta.activeTag(self.left);
        const right_tag = std.meta.activeTag(self.right);
        if (left_tag == .typevar)
            return try s.set(self.left.typevar, self.right);
        if (right_tag == .typevar)
            return try s.set(self.right.typevar, self.left);
        if (left_tag == .function and right_tag == .function) {
            if (self.left.function.len != self.right.function.len)
                std.debug.panic("\nFunction arity mismatch: {} != {}\n", .{
                    self.left.function.len,
                    self.right.function.len,
                });
            for (self.left.function, 0..) |left, i| {
                const right = self.right.function[i];
                try (Equal{ .left = left, .right = right }).solve(s);
            }
        }
        if (left_tag == right_tag)
            return;
        std.debug.panic("\nUnsupported type in equal: {} {}\n", .{ self.left, self.right });
    }

    fn toString(self: Equal, writer: anytype) !void {
        try writer.print("equal = ", .{});
        try (Indent{ .value = 1 }).toString(writer);
        try writer.print("left = ", .{});
        try self.left.toString(writer);
        try (Indent{ .value = 1 }).toString(writer);
        try writer.print("right = ", .{});
        try self.right.toString(writer);
    }
};

pub const Constraints = struct {
    equal: List(Equal),

    pub fn init(allocator: Allocator) Constraints {
        return Constraints{
            .equal = List(Equal).init(allocator),
        };
    }

    pub fn solve(self: Constraints, allocator: Allocator) !Substitution {
        var s = Substitution.init(allocator);
        for (self.equal.items) |e| try e.solve(&s);
        var max_attemps: u64 = 3;
        while (s.simplify() > 0 and max_attemps != 0) : (max_attemps -= 1) {}
        return s;
    }

    fn toString(self: Constraints, writer: anytype) !void {
        try writer.writeAll("\n\n=== Constraints ===");
        for (self.equal.items) |e| {
            try writer.writeAll("\n");
            try e.toString(writer);
        }
    }
};
