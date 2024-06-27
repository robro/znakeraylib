const std = @import("std");
const rl = @import("../raylib.zig");
const math = @import("../math.zig");
const enums = @import("../enums.zig");
const misc = @import("../misc.zig");
const objects = @import("objects.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Direction = enums.Direction;
const Vec2 = math.Vec2;
const Grid = objects.grid.Grid;

const Part = struct {
    facing: Direction,
    pos: Vec2,
};

pub const Snake = struct {
    char: u8,
    start_len: usize,
    start_pos: Vec2,
    start_facing: Direction,
    facing: Direction,
    body: ArrayList(Part),
    head: Part,
    tail: Part,

    pub fn create(char: u8, start_len: usize, start_pos: Vec2, start_facing: Direction, allocator: *const Allocator) !Snake {
        var body = ArrayList(Part).init(allocator.*);
        try body.resize(start_len);
        initBody(&body, start_pos, start_facing);
        return Snake{
            .char = char,
            .start_len = start_len,
            .start_pos = start_pos,
            .start_facing = start_facing,
            .facing = start_facing,
            .body = body,
            .head = body.items[0],
            .tail = body.items[body.items.len - 1],
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
        for (self.body.items, 0..) |part, i| {
            if (part.pos.x < 0 or part.pos.x >= grid.width or part.pos.y < 0 or part.pos.y >= grid.height) continue;
            grid.array[@as(usize, @intCast(part.pos.y))][@as(usize, @intCast(part.pos.x))] =
                if (i == 0) self.char else misc.getChar(i);
        }
    }

    pub fn len(self: *Snake) usize {
        return self.body.items.len;
    }

    pub fn reset(self: *Snake) !void {
        try self.body.resize(self.start_len);
        initBody(&self.body, self.start_pos, self.start_facing);
        self.head = self.body.items[0];
        self.tail = self.body.items[self.body.items.len - 1];
        self.facing = self.start_facing;
    }

    fn initBody(body: *ArrayList(Part), pos: Vec2, facing: Direction) void {
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
};
