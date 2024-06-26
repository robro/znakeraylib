const Snake = @This();
const std = @import("std");
const rl = @import("raylib.zig");
const Grid = @import("grid.zig");
const types = @import("types.zig");
const Direction = types.Direction;
const Position = types.Position;

char: u8,
start_len: usize,
start_pos: Position,
body: std.ArrayList(Position),
head: Position,
facing: Direction,

const start_facing: Direction = .RIGHT;

pub fn create(
    char: u8,
    start_len: usize,
    start_pos: Position,
    allocator: *const std.mem.Allocator,
) !Snake {
    var body = std.ArrayList(Position).init(allocator.*);
    try body.resize(start_len);
    for (body.items, 0..) |*part, i| {
        part.x = start_pos.x - @as(i32, @intCast(i));
        part.y = start_pos.y;
    }
    return Snake{
        .char = char,
        .start_len = start_len,
        .start_pos = start_pos,
        .body = body,
        .head = body.items[0],
        .facing = Snake.start_facing,
    };
}

pub fn free(self: *Snake) void {
    self.body.deinit();
}

pub fn grow(self: *Snake) void {
    self.body.append(.{ .x = -1, .y = -1 }) catch unreachable;
}

pub fn handleInput(self: *Snake, input: c_int) void {
    switch (input) {
        rl.KEY_UP => self.facing = if (self.facing != .DOWN) .UP else .DOWN,
        rl.KEY_DOWN => self.facing = if (self.facing != .UP) .DOWN else .UP,
        rl.KEY_LEFT => self.facing = if (self.facing != .RIGHT) .LEFT else .RIGHT,
        rl.KEY_RIGHT => self.facing = if (self.facing != .LEFT) .RIGHT else .LEFT,
        else => {},
    }
}

pub fn update(self: *Snake) void {
    var new_x = self.head.x;
    var new_y = self.head.y;
    switch (self.facing) {
        .UP => new_y -= 1,
        .DOWN => new_y += 1,
        .LEFT => new_x -= 1,
        .RIGHT => new_x += 1,
    }
    self.body.insert(0, .{ .x = new_x, .y = new_y }) catch unreachable;
    self.head = self.body.items[0];
    _ = self.body.pop();
}

pub fn addToGrid(self: *Snake, grid: *Grid) void {
    for (self.body.items) |part| {
        if (part.x < 0 or part.x >= grid.width or part.y < 0 or part.y >= grid.height) continue;
        grid.array[@as(usize, @intCast(part.y))][@as(usize, @intCast(part.x))] = self.char;
    }
}

pub fn reset(self: *Snake, _: *Grid) void {
    self.body.shrinkAndFree(self.start_len);
    for (self.body.items, 0..) |*part, i| {
        part.x = self.start_pos.x - @as(i32, @intCast(i));
        part.y = self.start_pos.y;
    }
    self.head = self.body.items[0];
    self.facing = Snake.start_facing;
}
