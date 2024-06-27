const State = @This();
const std = @import("std");
const rl = @import("raylib.zig");
const Grid = @import("grid.zig");
const Snake = @import("snake.zig");
const Food = @import("food.zig");
const rng = std.crypto.random;
const Allocator = std.mem.Allocator;
const Timer = std.time.Timer;
const utils = @import("utils.zig");

grid: *Grid,
snake: *Snake,
food: *Food,
timer: Timer,
rand_indices: []usize,
start_fps: c_int,
cur_fps: c_int,
score: u32 = 0,
hiscore: u32 = 0,
color_idx: usize = 0,
gameover: bool = false,

const gameover_wait: u64 = 1_000; // ms

pub fn create(grid: *Grid, snake: *Snake, food: *Food, start_fps: c_int, color_count: usize, allocator: *const Allocator) !State {
    rl.SetTargetFPS(start_fps);
    var rand_indices = try allocator.alloc(usize, color_count);
    for (rand_indices, 0..) |_, i| {
        rand_indices[i] = i;
    }
    rng.shuffle(usize, rand_indices);
    return State{
        .grid = grid,
        .snake = snake,
        .food = food,
        .timer = try Timer.start(),
        .rand_indices = rand_indices,
        .start_fps = start_fps,
        .cur_fps = start_fps,
    };
}

pub fn free(self: *State, allocator: *const Allocator) void {
    allocator.free(self.rand_indices);
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
    self.snake.update();
    self.food.update();

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
        self.snake.grow();
        try self.food.reset(utils.getChar(self.snake.len()), self.grid);
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
        " zig:{d:>3}  ziggest:{d:>3}",
        .{ self.score, self.hiscore },
    );
}

pub fn printGrid(self: *State, buffer: *const []u8) !void {
    self.grid.clear();
    self.snake.draw(self.grid);
    self.food.draw(self.grid);
    try self.grid.printToBuf(buffer);
}

pub fn randIdx(self: *State) usize {
    return self.rand_indices[self.color_idx];
}

pub fn nextRandIdx(self: *State) void {
    const prev_idx = self.randIdx();
    self.color_idx += 1;
    if (self.color_idx == self.rand_indices.len) {
        self.color_idx = 0;
        rng.shuffle(usize, self.rand_indices);
        if (self.rand_indices[0] == prev_idx) {
            std.mem.swap(usize, &self.rand_indices[0], &self.rand_indices[1]);
        }
    }
}

fn gameOver(self: *State) void {
    self.gameover = true;
    self.timer.reset();
}

fn reset(self: *State) !void {
    self.snake.reset();
    try self.food.reset(utils.getChar(self.snake.len()), self.grid);
    self.gameover = false;
    self.score = 0;
    self.nextRandIdx();
    if (self.cur_fps != self.start_fps) {
        rl.SetTargetFPS(self.start_fps);
        self.cur_fps = self.start_fps;
    }
}
