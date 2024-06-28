const std = @import("std");
const rl = @import("../raylib.zig");
const math = @import("../math.zig");
const enums = @import("../enums.zig");
const misc = @import("../misc.zig");
const objects = @import("objects.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Direction = enums.Direction;
const Position = math.Position;
const Grid = objects.grid.Grid;

const Part = struct {
    facing: Direction,
    pos: Position,
};

pub const Snake = struct {
    start_len: usize,
    start_pos: Position,
    start_facing: Direction,
    facing: Direction,
    body: ArrayList(Part),
    head: Part,
    tail: ?Part,

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
        var pos = self.head.pos;
        switch (self.facing) {
            .UP => pos.y -= 1,
            .DOWN => pos.y += 1,
            .LEFT => pos.x -= 1,
            .RIGHT => pos.x += 1,
        }
        self.body.insert(0, .{ .facing = self.facing, .pos = pos }) catch unreachable;
        self.head = self.body.items[0];
        self.tail = self.body.pop();
    }

    pub fn draw(self: *Snake, grid: *Grid) void {
        var char: u8 = undefined;
        for (self.body.items, 0..) |*part, i| {
            if (part.pos.x < 0 or part.pos.x >= grid.width or
                part.pos.y < 0 or part.pos.y >= grid.height) continue;
            char = misc.getChar(i);
            if (i == 0) char = std.ascii.toUpper(char);
            grid.array[@as(usize, @intCast(part.pos.y))][@as(usize, @intCast(part.pos.x))] = char;
        }
    }

    pub fn grow(self: *Snake) void {
        self.body.append(self.tail.?) catch unreachable;
    }

    pub fn len(self: *Snake) usize {
        return self.body.items.len;
    }

    pub fn reset(self: *Snake) !void {
        try self.body.resize(self.start_len);
        initBody(&self.body, self.start_pos, self.start_facing);
        self.facing = self.start_facing;
        self.head = self.body.items[0];
        self.tail = null;
    }

    pub fn free(self: *Snake) void {
        self.body.deinit();
    }
};

pub fn spawnSnake(length: usize, position: Position, facing: Direction, allocator: *const Allocator) !Snake {
    var body = ArrayList(Part).init(allocator.*);
    try body.resize(length);
    initBody(&body, position, facing);
    return Snake{
        .start_len = length,
        .start_pos = position,
        .start_facing = facing,
        .facing = facing,
        .body = body,
        .head = body.items[0],
        .tail = null,
    };
}

fn initBody(body: *ArrayList(Part), pos: Position, facing: Direction) void {
    var offset: i32 = undefined;
    for (body.items, 0..) |*part, i| {
        offset = @intCast(i);
        part.facing = facing;
        part.pos = pos;
        switch (facing) {
            .UP => part.pos.y += offset,
            .DOWN => part.pos.y -= offset,
            .LEFT => part.pos.x += offset,
            .RIGHT => part.pos.x -= offset,
        }
    }
}
