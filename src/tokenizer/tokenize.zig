const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;

const interner = @import("../interner.zig");
const Interned = interner.Interned;
const Intern = interner.Intern;
const Builtins = @import("../builtins.zig").Builtins;
const types = @import("types.zig");

const Cursor = struct {
    source: []const u8,
    pos: types.Pos,
};

fn trim(cursor: *Cursor) void {
    var i: u64 = 0;
    while (i < cursor.source.len) {
        switch (cursor.source[i]) {
            ' ', '\t' => i += 1,
            else => break,
        }
    }
    cursor.pos.column += i;
    cursor.source = cursor.source[i..];
}

fn reserved(c: u8) bool {
    return switch (c) {
        ' ', '\n', '(', ')', '.', ':', ',' => true,
        else => false,
    };
}

fn advance(cursor: *Cursor, n: u64) []const u8 {
    const value = cursor.source[0..n];
    cursor.source = cursor.source[n..];
    cursor.pos.column += n;
    return value;
}

fn number(intern: *Intern, cursor: *Cursor) !types.Token {
    const begin = cursor.pos;
    var i: u64 = 1;
    var decimals: u64 = if (cursor.source[0] == '.') 1 else 0;
    while (i < cursor.source.len) : (i += 1) {
        switch (cursor.source[i]) {
            '0'...'9' => {},
            '.' => decimals += 1,
            else => break,
        }
    }
    if (i >= 2 and cursor.source[i - 1] == '.') {
        i -= 1;
        decimals -= 1;
    }
    const contents = cursor.source[0..i];
    if (contents.len == 1) {
        switch (contents[0]) {
            '-' => return exact(cursor, .minus),
            '.' => {
                _ = advance(cursor, i);
                return .{ .dot = .{ .span = .{ .begin = begin, .end = cursor.pos } } };
            },
            else => {},
        }
    }
    _ = advance(cursor, i);
    const span = types.Span{ .begin = begin, .end = cursor.pos };
    const interned = try intern.store(contents);
    if (decimals == 0) return .{ .int = .{ .value = interned, .span = span } };
    return .{ .float = .{ .value = interned, .span = span } };
}

fn string(intern: *Intern, cursor: *Cursor) !types.Token {
    const begin = cursor.pos;
    var i: u64 = 1;
    while (i < cursor.source.len) : (i += 1) {
        if (cursor.source[i] == '"') {
            i += 1;
            break;
        }
    }
    const contents = cursor.source[0..i];
    _ = advance(cursor, i);
    const span = types.Span{ .begin = begin, .end = cursor.pos };
    const interned = try intern.store(contents);
    return .{ .string = .{ .value = interned, .span = span } };
}

const Tag = std.meta.Tag(types.Token);

fn exact(cursor: *Cursor, comptime tag: Tag) types.Token {
    const begin = cursor.pos;
    _ = advance(cursor, 1);
    const span = types.Span{ .begin = begin, .end = cursor.pos };
    return @unionInit(types.Token, @tagName(tag), .{ .span = span });
}

fn symbol(intern: *Intern, builtins: Builtins, cursor: *Cursor) !types.Token {
    const begin = cursor.pos;
    var i: u64 = 0;
    while (i < cursor.source.len and !reserved(cursor.source[i])) : (i += 1) {}
    const contents = advance(cursor, i);
    const end = cursor.pos;
    const span = types.Span{ .begin = begin, .end = end };
    const interned = try intern.store(contents);
    if (interned.eql(builtins.fn_)) return .{ .fn_ = .{ .span = span } };
    if (interned.eql(builtins.if_)) return .{ .if_ = .{ .span = span } };
    if (interned.eql(builtins.else_)) return .{ .else_ = .{ .span = span } };
    if (interned.eql(builtins.true_)) return .{ .bool = .{ .value = true, .span = span } };
    if (interned.eql(builtins.false_)) return .{ .bool = .{ .value = false, .span = span } };
    if (interned.eql(builtins.or_)) return .{ .or_ = .{ .span = span } };
    if (interned.eql(builtins.mut)) return .{ .mut = .{ .span = span } };
    if (interned.eql(builtins.undefined)) return .{ .undefined = .{ .span = span } };
    return .{ .symbol = .{ .value = interned, .span = span } };
}

fn newLine(cursor: *Cursor) types.Token {
    const begin = cursor.pos;
    var i: u64 = 0;
    while (i < cursor.source.len and cursor.source[i] == '\n') : (i += 1) {}
    cursor.pos.line += i;
    cursor.pos.column = 1;
    cursor.source = cursor.source[i..];
    return .{ .new_line = .{ .span = .{ .begin = begin, .end = cursor.pos } } };
}

fn either(cursor: *Cursor, comptime tag: Tag, comptime char: u8, comptime other: Tag) types.Token {
    const begin = cursor.pos;
    if (cursor.source.len > 1 and cursor.source[1] == char) {
        _ = advance(cursor, 2);
        const span = types.Span{ .begin = begin, .end = cursor.pos };
        return @unionInit(types.Token, @tagName(other), .{ .span = span });
    }
    _ = advance(cursor, 1);
    const span = types.Span{ .begin = begin, .end = cursor.pos };
    return @unionInit(types.Token, @tagName(tag), .{ .span = span });
}

fn nextToken(cursor: *Cursor, intern: *Intern, builtins: Builtins) !?types.Token {
    trim(cursor);
    if (cursor.source.len == 0) return null;
    return switch (cursor.source[0]) {
        '0'...'9', '-', '.' => try number(intern, cursor),
        '"' => try string(intern, cursor),
        '=' => either(cursor, .equal, '=', .equal_equal),
        ':' => exact(cursor, .colon),
        '+' => either(cursor, .plus, '=', .plus_equal),
        '*' => exact(cursor, .times),
        '/' => exact(cursor, .slash),
        '^' => exact(cursor, .caret),
        '>' => exact(cursor, .greater),
        '<' => exact(cursor, .less),
        '%' => exact(cursor, .percent),
        '(' => exact(cursor, .left_paren),
        ')' => exact(cursor, .right_paren),
        '{' => exact(cursor, .left_brace),
        '}' => exact(cursor, .right_brace),
        '[' => exact(cursor, .left_bracket),
        ']' => exact(cursor, .right_bracket),
        ',' => exact(cursor, .comma),
        '\n' => newLine(cursor),
        else => try symbol(intern, builtins, cursor),
    };
}

pub fn tokenize(allocator: Allocator, intern: *Intern, builtins: Builtins, source: []const u8) ![]types.Token {
    var cursor = Cursor{
        .source = source,
        .pos = .{ .line = 1, .column = 1 },
    };
    var tokens = List(types.Token).init(allocator);
    while (try nextToken(&cursor, intern, builtins)) |t| try tokens.append(t);
    return try tokens.toOwnedSlice();
}
