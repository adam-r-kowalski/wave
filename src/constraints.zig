const std = @import("std");
const List = std.ArrayList;
const Allocator = std.mem.Allocator;

const substitution = @import("substitution.zig");
const Substitution = substitution.Substitution;
const MonoType = substitution.MonoType;
const TypeVar = substitution.TypeVar;
const Indent = @import("indent.zig").Indent;
const CompileErrors = @import("compile_errors.zig").CompileErrors;
const Span = @import("span.zig").Span;

pub const TypedSpan = struct {
    span: ?Span,
    type: MonoType,
};

pub const Equal = struct {
    left: TypedSpan,
    right: TypedSpan,

    fn solve(self: Equal, s: *Substitution) !void {
        const left_tag = std.meta.activeTag(self.left.type);
        const right_tag = std.meta.activeTag(self.right.type);
        if (left_tag == .typevar)
            return try s.set(self.left.type.typevar, self.right.type);
        if (right_tag == .typevar)
            return try s.set(self.right.type.typevar, self.left.type);
        if (left_tag == .function and right_tag == .function) {
            if (self.left.type.function.len != self.right.type.function.len)
                std.debug.panic("\nFunction arity mismatch: {} != {}\n", .{
                    self.left.type.function.len,
                    self.right.type.function.len,
                });
            for (self.left.type.function, 0..) |left, i| {
                const right = self.right.type.function[i];
                try (Equal{
                    .left = .{ .type = left, .span = null },
                    .right = .{ .type = right, .span = null },
                }).solve(s);
            }
        }
        if (left_tag == right_tag)
            return;
        std.debug.panic("\nUnsupported type in equal: {} {}\n", .{ self.left, self.right });
    }

    pub fn format(self: Equal, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.writeAll("equal = ");
        try (Indent{ .value = 1 }).toString(writer);
        try writer.writeAll("left = ");
        try self.left.toString(writer);
        try (Indent{ .value = 1 }).toString(writer);
        try writer.writeAll("right = ");
        try self.right.toString(writer);
    }
};

pub const Constraints = struct {
    equal: List(Equal),
    next_type_var: TypeVar,
    compile_errors: *CompileErrors,

    pub fn init(allocator: Allocator, compile_errors: *CompileErrors) Constraints {
        return Constraints{
            .equal = List(Equal).init(allocator),
            .next_type_var = TypeVar{ .value = 0 },
            .compile_errors = compile_errors,
        };
    }

    pub fn solve(self: Constraints, allocator: Allocator) !Substitution {
        var s = Substitution.init(allocator);
        for (self.equal.items) |e| try e.solve(&s);
        var max_attemps: u64 = 3;
        while (s.simplify() > 0 and max_attemps != 0) : (max_attemps -= 1) {}
        return s;
    }

    pub fn freshTypeVar(self: *Constraints) MonoType {
        const typevar = self.next_type_var;
        self.next_type_var = TypeVar{ .value = self.next_type_var.value + 1 };
        return .{ .typevar = typevar };
    }

    pub fn format(self: Constraints, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.writeAll("\n\n=== Constraints ===");
        for (self.equal.items) |e| try writer.print("\n{}", .{e});
    }
};
