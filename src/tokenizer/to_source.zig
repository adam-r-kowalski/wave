const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;

const interner = @import("../interner.zig");
const Intern = interner.Intern;
const Interned = interner.Interned;
const Builtins = @import("../builtins.zig").Builtins;
const types = @import("types.zig");
const Span = types.Span;
const Pos = types.Pos;
const Token = types.Token;

fn span(writer: List(u8).Writer, s: Span, pos: *Pos) !void {
    const delta = s.begin.column - pos.column;
    var i: usize = 0;
    while (i < delta) : (i += 1) {
        try writer.writeAll(" ");
    }
    pos.* = s.end;
}

pub fn toSource(allocator: Allocator, intern: Intern, tokens: []const Token) ![]const u8 {
    var list = List(u8).init(allocator);
    const writer = list.writer();
    var pos = Pos{ .line = 1, .column = 1 };
    for (tokens) |token| {
        try span(writer, token.span, &pos);
        switch (token.kind) {
            .symbol => |s| try writer.writeAll(interner.lookup(intern, s)),
            .int => |i| try writer.writeAll(interner.lookup(intern, i)),
            .float => |f| try writer.writeAll(interner.lookup(intern, f)),
            .bool => |b| try writer.writeAll(if (b) "true" else "false"),
            .equal => try writer.writeAll("="),
            .dot => try writer.writeAll("."),
            .colon => try writer.writeAll(":"),
            .plus => try writer.writeAll("+"),
            .minus => try writer.writeAll("-"),
            .times => try writer.writeAll("*"),
            .caret => try writer.writeAll("^"),
            .greater => try writer.writeAll(">"),
            .less => try writer.writeAll("<"),
            .left_paren => try writer.writeAll("("),
            .right_paren => try writer.writeAll(")"),
            .left_brace => try writer.writeAll("{"),
            .right_brace => try writer.writeAll("}"),
            .if_ => try writer.writeAll("if"),
            .comma => try writer.writeAll(","),
            .fn_ => try writer.writeAll("fn"),
            .import => try writer.writeAll("import"),
            .export_ => try writer.writeAll("export"),
        }
    }
    return list.toOwnedSlice();
}
