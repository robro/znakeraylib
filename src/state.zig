const State = @This();
const std = @import("std");
const rl = @import("raylib.zig");
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

    pub fn reset(self: Object, grid: *Grid) !void {
        switch (self) {
            inline else => |case| try case.reset(grid),
        }
    }
};

grid: *Grid,
snake: *Snake,
food: *Food,
objects: [2]Object,
timer: std.time.Timer,
color_count: usize,
color_index: usize,
start_fps: c_int,
cur_fps: c_int,
score: u32 = 0,
hiscore: u32 = 0,
gameover: bool = false,

const gameover_wait: u64 = 1_000; // ms

pub fn create(grid: *Grid, snake: *Snake, food: *Food, start_fps: c_int, color_count: usize) !State {
    rl.SetTargetFPS(start_fps);
    return State{
        .grid = grid,
        .snake = snake,
        .food = food,
        .objects = [2]Object{ .{ .snake = snake }, .{ .food = food } },
        .timer = try std.time.Timer.start(),
        .color_count = color_count,
        .color_index = std.crypto.random.uintLessThan(usize, color_count),
        .start_fps = start_fps,
        .cur_fps = start_fps,
    };
}

pub fn handleInput(self: *State, input: c_int) void {
    self.snake.handleInput(input);
}

pub fn update(self: *State) !void {
    if (self.gameover) {
        if (self.timer.read() < State.gameover_wait * std.time.ns_per_ms) return;
        try self.reset();
        return;
    }
    for (self.objects) |obj| obj.update();
    // Handle snake going OOB
    if (self.snake.head.pos.x < 0 or self.snake.head.pos.x >= self.grid.width or
        self.snake.head.pos.y < 0 or self.snake.head.pos.y >= self.grid.height)
    {
        self.gameOver();
        return;
    }
    // Handle snake self-collision
    for (self.snake.body.items[1..]) |part| {
        if (std.meta.eql(self.snake.head.pos, part.pos)) {
            self.gameOver();
            return;
        }
    }
    // Handle food eating
    if (std.meta.eql(self.snake.head.pos, self.food.pos)) {
        try self.food.reset(self.grid);
        self.snake.grow();
        self.score += 1;
        if (self.score % 5 == 0) {
            self.cur_fps = @min(self.cur_fps + 1, 60);
            rl.SetTargetFPS(self.cur_fps);
        }
        self.hiscore = @max(self.hiscore, self.score);
    }
}

pub fn printHUD(self: *State, buffer: *const []u8) !void {
    _ = try std.fmt.bufPrintZ(
        buffer.*,
        " score:{d:>3}  best:{d:>3}",
        .{ self.score, self.hiscore },
    );
}

pub fn printGrid(self: *State, buffer: *const []u8) !void {
    self.grid.clear();
    for (self.objects) |obj| obj.draw(self.grid);
    try self.grid.printToBuf(buffer);
}

fn gameOver(self: *State) void {
    self.gameover = true;
    self.timer.reset();
}

fn reset(self: *State) !void {
    for (self.objects) |obj| try obj.reset(self.grid);
    self.gameover = false;
    self.score = 0;
    self.color_index = std.crypto.random.uintLessThan(usize, self.color_count);
    if (self.cur_fps != self.start_fps) {
        rl.SetTargetFPS(self.start_fps);
        self.cur_fps = self.start_fps;
    }
}
