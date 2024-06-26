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

    pub fn draw(self: Object, grid: *Grid) void {
        switch (self) {
            inline else => |case| case.draw(grid),
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
objects: [2]Object,
timer: std.time.Timer,
score: u32 = 0,
hiscore: u32 = 0,
gameover: bool = false,

const gameover_wait: u64 = 1_000; // ms

pub fn create(grid: *Grid, snake: *Snake, food: *Food) !State {
    return State{
        .grid = grid,
        .snake = snake,
        .food = food,
        .objects = [2]Object{ .{ .snake = snake }, .{ .food = food } },
        .timer = try std.time.Timer.start(),
    };
}

pub fn handleInput(self: *State, input: c_int) void {
    self.snake.handleInput(input);
}

pub fn update(self: *State) void {
    if (self.gameover) {
        if (self.timer.read() < State.gameover_wait * std.time.ns_per_ms) return;
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

pub fn printHUD(self: *State, buffer: *const []u8) !void {
    _ = try std.fmt.bufPrintZ(
        buffer.*,
        "score: {d:<3} best: {d:<3}",
        .{ self.score, self.hiscore },
    );
}

pub fn printGrid(self: *State, buffer: *const []u8) !void {
    self.grid.empty();
    for (self.objects) |obj| obj.draw(self.grid);
    try self.grid.printToBuf(buffer);
}

fn gameOver(self: *State) void {
    self.gameover = true;
    self.timer.reset();
}

fn reset(self: *State) void {
    for (self.objects) |obj| obj.reset(self.grid);
    self.gameover = false;
    self.score = 0;
}
