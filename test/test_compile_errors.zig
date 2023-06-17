const std = @import("std");
const mantis = @import("mantis");
const RED = mantis.error_reporter.pretty_print.RED;
const CLEAR = mantis.error_reporter.pretty_print.CLEAR;

test "use of undefined variable" {
    const allocator = std.testing.allocator;
    const source =
        \\start = fn() f32 {
        \\    fib(5)
        \\}
    ;
    const actual = try mantis.testing.compileErrors(allocator, source);
    defer allocator.free(actual);
    const expected = try std.fmt.allocPrint(allocator,
        \\---- {s}UNDEFINED VARIABLE{s} ---------------------------------------------------
        \\
        \\Cannot find variable `fib`.
        \\
        \\1 | start = fn() f32 {{
        \\2 |     {s}fib{s}(5)
        \\3 | }}
        \\
        \\Maybe you want one of the following?
        \\
        \\    start
        \\
    , .{ RED, CLEAR, RED, CLEAR });
    defer allocator.free(expected);
    try std.testing.expectEqualStrings(expected, actual);
}

test "type error of if" {
    const allocator = std.testing.allocator;
    const source =
        \\start = fn(x: i32, y: f64) f32 {
        \\    if x == y {
        \\        x
        \\    } else {
        \\        y
        \\    }
        \\}
    ;
    const actual = try mantis.testing.compileErrors(allocator, source);
    defer allocator.free(actual);
    const expected = try std.fmt.allocPrint(allocator,
        \\---- {s}TYPE MISMATCH{s} ---------------------------------------------------
        \\
        \\Here the inferred type is i32
        \\
        \\1 | start = fn(x: i32, y: f64) f32 {{
        \\2 |     if {s}x{s} == y {{
        \\3 |         x
        \\
        \\Here the inferred type is f64
        \\
        \\1 | start = fn(x: i32, y: f64) f32 {{
        \\2 |     if x == {s}y{s} {{
        \\3 |         x
        \\
        \\Expected these two types to be the same.
        \\
        \\
    , .{ RED, CLEAR, RED, CLEAR, RED, CLEAR });
    defer allocator.free(expected);
    try std.testing.expectEqualStrings(expected, actual);
}

test "type error of define" {
    const allocator = std.testing.allocator;
    const source =
        \\start = fn() f32 {
        \\    x: f64 = 5
        \\    x
        \\}
    ;
    const actual = try mantis.testing.compileErrors(allocator, source);
    defer allocator.free(actual);
    const expected = try std.fmt.allocPrint(allocator,
        \\---- {s}TYPE MISMATCH{s} ---------------------------------------------------
        \\
        \\Here the inferred type is f32
        \\
        \\1 | start = fn() {s}f32{s} {{
        \\2 |     x: f64 = 5
        \\
        \\Here the inferred type is f64
        \\
        \\1 | start = fn() f32 {s}{{
        \\{s}2 |{s}     x: f64 = 5
        \\{s}3 |{s}     x
        \\{s}4 |{s} }}{s}
        \\
        \\Expected these two types to be the same.
        \\
        \\
    , .{ RED, CLEAR, RED, CLEAR, RED, CLEAR, RED, CLEAR, RED, CLEAR, RED, CLEAR });
    defer allocator.free(expected);
    try std.testing.expectEqualStrings(expected, actual);
}
