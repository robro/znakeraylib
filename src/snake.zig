const Snake = @This();
const std = @import("std");
const rl = @import("raylib.zig");
const Grid = @import("grid.zig");
const utils = @import("utils.zig");
const Direction = utils.Direction;
const Position = utils.Position;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Part = struct {
    facing: Direction,
    pos: Position,
};

char: u8,
start_len: usize,
start_pos: Position,
body: ArrayList(Part),
head: Part,
tail: Part,
facing: Direction,

const start_facing: Direction = .RIGHT;

pub fn create(char: u8, start_len: usize, start_pos: Position, allocator: *const Allocator) !Snake {
    var body = ArrayList(Part).init(allocator.*);
    try body.resize(start_len);
    for (body.items, 0..) |*part, i| {
        part.facing = start_facing;
        part.pos.x = start_pos.x - @as(i32, @intCast(i));
        part.pos.y = start_pos.y;
    }
    return Snake{
        .char = char,
        .start_len = start_len,
        .start_pos = start_pos,
        .body = body,
        .head = body.items[0],
        .tail = body.items[body.items.len - 1],
        .facing = Snake.start_facing,
    };
}

pub fn free(self: *Snake) void {
    self.body.deinit();
}

pub fn grow(self: *Snake) void {
    self.body.append(self.tail) catch unreachable;
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
    var new_x = self.head.pos.x;
    var new_y = self.head.pos.y;

    switch (self.facing) {
        .UP => new_y -= 1,
        .DOWN => new_y += 1,
        .LEFT => new_x -= 1,
        .RIGHT => new_x += 1,
    }
    self.body.insert(0, .{ .facing = self.facing, .pos = .{ .x = new_x, .y = new_y } }) catch unreachable;
    self.head = self.body.items[0];
    self.tail = self.body.pop();
}

pub fn draw(self: *Snake, grid: *Grid) void {
    for (self.body.items, 0..) |part, i| {
        if (part.pos.x < 0 or part.pos.x >= grid.width or part.pos.y < 0 or part.pos.y >= grid.height) continue;
        grid.array[@as(usize, @intCast(part.pos.y))][@as(usize, @intCast(part.pos.x))] =
            if (i == 0) self.char else utils.getChar(i);
    }
}

pub fn len(self: *Snake) usize {
    return self.body.items.len;
}

pub fn reset(self: *Snake) void {
    self.body.shrinkAndFree(self.start_len);
    for (self.body.items, 0..) |*part, i| {
        part.facing = Snake.start_facing;
        part.pos.x = self.start_pos.x - @as(i32, @intCast(i));
        part.pos.y = self.start_pos.y;
    }
    self.head = self.body.items[0];
    self.facing = Snake.start_facing;
}
