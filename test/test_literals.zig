const std = @import("std");
const rocket = @import("rocket");

test "tokenize int literal followed by dot" {
    const allocator = std.testing.allocator;
    const source = "2.";
    const actual = try rocket.testing.tokenize(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(int 2)
        \\(operator .)
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "type infer int literal as i32" {
    const allocator = std.testing.allocator;
    const source = "f = () i32 { 42 }";
    const actual = try rocket.testing.typeInfer(allocator, source, "f");
    defer allocator.free(actual);
    const expected =
        \\define =
        \\    name = symbol{ value = f, type = () i32 }
        \\    type = void
        \\    mutable = false
        \\    value =
        \\        function =
        \\            return_type = i32
        \\            body =
        \\                int{ value = 42, type = i32 }
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "type infer bool literal true" {
    const allocator = std.testing.allocator;
    const source = "f = () bool { true }";
    const actual = try rocket.testing.typeInfer(allocator, source, "f");
    defer allocator.free(actual);
    const expected =
        \\define =
        \\    name = symbol{ value = f, type = () bool }
        \\    type = void
        \\    mutable = false
        \\    value =
        \\        function =
        \\            return_type = bool
        \\            body =
        \\                bool{ value = true, type = bool }
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "type infer bool literal false" {
    const allocator = std.testing.allocator;
    const source = "f = () bool { false }";
    const actual = try rocket.testing.typeInfer(allocator, source, "f");
    defer allocator.free(actual);
    const expected =
        \\define =
        \\    name = symbol{ value = f, type = () bool }
        \\    type = void
        \\    mutable = false
        \\    value =
        \\        function =
        \\            return_type = bool
        \\            body =
        \\                bool{ value = false, type = bool }
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "type infer int literal as f32" {
    const allocator = std.testing.allocator;
    const source = "f = () f32 { 42 }";
    const actual = try rocket.testing.typeInfer(allocator, source, "f");
    defer allocator.free(actual);
    const expected =
        \\define =
        \\    name = symbol{ value = f, type = () f32 }
        \\    type = void
        \\    mutable = false
        \\    value =
        \\        function =
        \\            return_type = f32
        \\            body =
        \\                int{ value = 42, type = f32 }
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "type infer float literal as f32" {
    const allocator = std.testing.allocator;
    const source = "f = () f32 { 42.3 }";
    const actual = try rocket.testing.typeInfer(allocator, source, "f");
    defer allocator.free(actual);
    const expected =
        \\define =
        \\    name = symbol{ value = f, type = () f32 }
        \\    type = void
        \\    mutable = false
        \\    value =
        \\        function =
        \\            return_type = f32
        \\            body =
        \\                float{ value = 42.3, type = f32 }
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "codegen i32 with int literal" {
    const allocator = std.testing.allocator;
    const source = "start = () i32 { 42 }";
    const actual = try rocket.testing.codegen(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(module
        \\
        \\    (memory 1)
        \\    (export "memory" (memory 0))
        \\
        \\    (func $start (result i32)
        \\        (i32.const 42))
        \\
        \\    (export "_start" (func $start)))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "codegen f32 with int literal" {
    const allocator = std.testing.allocator;
    const source = "start = () f32 { 42 }";
    const actual = try rocket.testing.codegen(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(module
        \\
        \\    (memory 1)
        \\    (export "memory" (memory 0))
        \\
        \\    (func $start (result f32)
        \\        (f32.const 4.2e+01))
        \\
        \\    (export "_start" (func $start)))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "codegen f32 with float literal" {
    const allocator = std.testing.allocator;
    const source = "start = () f32 { 42.5 }";
    const actual = try rocket.testing.codegen(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(module
        \\
        \\    (memory 1)
        \\    (export "memory" (memory 0))
        \\
        \\    (func $start (result f32)
        \\        (f32.const 4.25e+01))
        \\
        \\    (export "_start" (func $start)))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "codegen i32 global constant" {
    const allocator = std.testing.allocator;
    const source =
        \\i: i32 = 42
        \\
        \\start = () i32 { i }
    ;
    const actual = try rocket.testing.codegen(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(module
        \\
        \\    (memory 1)
        \\    (export "memory" (memory 0))
        \\
        \\    (global $i i32 (i32.const 42))
        \\
        \\    (func $start (result i32)
        \\        (global.get $i))
        \\
        \\    (export "_start" (func $start)))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "codegen str with string literal" {
    const allocator = std.testing.allocator;
    const source =
        \\start = () str { "hi" }
    ;
    const actual = try rocket.testing.codegen(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(module
        \\
        \\    (memory 1)
        \\    (export "memory" (memory 0))
        \\
        \\    (data (i32.const 0) "hi")
        \\
        \\    (global $core/arena (mut i32) (i32.const 2))
        \\
        \\    (func $core/alloc (param $size i32) (result i32)
        \\        (local $ptr i32)
        \\        (local.tee $ptr
        \\            (global.get $core/arena))
        \\        (global.set $core/arena
        \\            (i32.add
        \\                (local.get $ptr)
        \\                (local.get $size))))
        \\
        \\    (func $start (result i32)
        \\        (local $0 i32)
        \\        (local.set $0
        \\            (call $core/alloc
        \\                (i32.const 8)))
        \\        (block (result i32)
        \\            (i32.store
        \\                (local.get $0)
        \\                (i32.const 0))
        \\            (i32.store
        \\                (i32.add
        \\                    (local.get $0)
        \\                    (i32.const 4))
        \\                (i32.const 2))
        \\            (local.get $0)))
        \\
        \\    (export "_start" (func $start)))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}

test "codegen str with template literal" {
    const allocator = std.testing.allocator;
    const source =
        \\start = () str { `hi` }
    ;
    const actual = try rocket.testing.codegen(allocator, source);
    defer allocator.free(actual);
    const expected =
        \\(module
        \\
        \\    (memory 1)
        \\    (export "memory" (memory 0))
        \\
        \\    (data (i32.const 0) "hi")
        \\
        \\    (global $core/arena (mut i32) (i32.const 2))
        \\
        \\    (func $core/alloc (param $size i32) (result i32)
        \\        (local $ptr i32)
        \\        (local.tee $ptr
        \\            (global.get $core/arena))
        \\        (global.set $core/arena
        \\            (i32.add
        \\                (local.get $ptr)
        \\                (local.get $size))))
        \\
        \\    (func $start (result i32)
        \\        (local $0 i32)
        \\        (local.set $0
        \\            (call $core/alloc
        \\                (i32.const 8)))
        \\        (block (result i32)
        \\            (i32.store
        \\                (local.get $0)
        \\                (i32.const 0))
        \\            (i32.store
        \\                (i32.add
        \\                    (local.get $0)
        \\                    (i32.const 4))
        \\                (i32.const 2))
        \\            (local.get $0)))
        \\
        \\    (export "_start" (func $start)))
    ;
    try std.testing.expectEqualStrings(expected, actual);
}
