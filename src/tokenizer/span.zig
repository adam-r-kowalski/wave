const types = @import("types.zig");
const Span = @import("../span.zig").Span;

pub fn token(t: types.Token) Span {
    return switch (t) {
        .symbol => |s| s.span,
        .int => |i| i.span,
        .float => |f| f.span,
        .string => |s| s.span,
        .bool => |b| b.span,
        .equal => |e| e.span,
        .equal_equal => |e| e.span,
        .dot => |d| d.span,
        .colon => |c| c.span,
        .plus => |p| p.span,
        .plus_equal => |p| p.span,
        .minus => |m| m.span,
        .times => |m| m.span,
        .slash => |s| s.span,
        .caret => |c| c.span,
        .greater => |g| g.span,
        .less => |l| l.span,
        .percent => |p| p.span,
        .left_paren => |l| l.span,
        .right_paren => |r| r.span,
        .left_brace => |l| l.span,
        .right_brace => |r| r.span,
        .left_bracket => |l| l.span,
        .right_bracket => |r| r.span,
        .if_ => |i| i.span,
        .else_ => |e| e.span,
        .or_ => |o| o.span,
        .comma => |c| c.span,
        .fn_ => |f| f.span,
        .mut => |m| m.span,
        .undefined => |u| u.span,
        .new_line => |n| n.span,
    };
}