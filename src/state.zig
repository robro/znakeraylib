const State = @This();
const std = @import("std");
const Grid = @import("grid.zig");
const Snake = @import("snake.zig");
const Food = @import("food.zig");

const Object = union(enum) {
    snake: *Snake,
    food: *Food,

    pub fn update(self: Object) void {
        switch (self) {
            inline else => |case| case.update(),
        }
    }

    pub fn addToGrid(self: Object, grid: *Grid) void {
        switch (self) {
            inline else => |case| case.addToGrid(grid),
        }
    }

    pub fn reset(self: Object, grid: *Grid) void {
        switch (self) {
            inline else => |case| case.reset(grid),
        }
    }
};

grid: *Grid,
snake: *Snake,
food: *Food,
objects: []Object,
timer: std.time.Timer,
score: u32 = 0,
hiscore: u32 = 0,
gameover_wait: u64 = 1_000, // milliseconds
gameover: bool = false,

pub fn create(grid: *Grid, snake: *Snake, food: *Food, allocator: *const std.mem.Allocator) !State {
    const objects = try allocator.alloc(Object, 2);
    objects[0] = .{ .snake = snake };
    objects[1] = .{ .food = food };

    return State{
        .grid = grid,
        .snake = snake,
        .food = food,
        .objects = objects,
        .timer = try std.time.Timer.start(),
    };
}

pub fn free(self: *State, allocator: *const std.mem.Allocator) void {
    allocator.free(self.objects);
}

pub fn handleInput(self: *State, input: c_int) void {
    self.snake.handleInput(input);
}

pub fn update(self: *State) void {
    if (self.gameover) {
        if (self.timer.read() < self.gameover_wait * std.time.ns_per_ms) return;
        self.reset();
        return;
    }
    for (self.objects) |obj| obj.update();
    // Handle snake going OOB
    if (self.snake.head.x < 0 or self.snake.head.x >= self.grid.width or
        self.snake.head.y < 0 or self.snake.head.y >= self.grid.height)
    {
        self.gameOver();
        return;
    }
    // Handle snake self-collision
    for (self.snake.body.items[1..]) |part| {
        if (std.meta.eql(self.snake.head, part)) {
            self.gameOver();
            return;
        }
    }
    // Handle food eating
    if (std.meta.eql(self.snake.head, self.food.pos)) {
        self.food.reset(self.grid);
        self.snake.grow();
        self.score += 1;
        self.hiscore = @max(self.hiscore, self.score);
    }
}

pub fn printToBuf(self: *State, buffer: *const []u8) !void {
    self.grid.empty();
    for (self.objects) |obj| obj.addToGrid(self.grid);
    try self.grid.printToBuf(buffer);
}

pub fn gameOver(self: *State) void {
    self.gameover = true;
    self.timer.reset();
}

pub fn reset(self: *State) void {
    for (self.objects) |obj| obj.reset(self.grid);
    self.gameover = false;
    self.score = 0;
}
