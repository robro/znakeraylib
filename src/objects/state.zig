const std = @import("std");
const rl = @import("../raylib.zig");
const objects = @import("objects.zig");
const misc = @import("../misc.zig");
const scratch = @import("../scratch.zig");

const Timer = std.time.Timer;
const Allocator = std.mem.Allocator;
const Board = objects.board.Board;
const Snake = objects.snake.Snake;
const Food = objects.food.Food;
const rng = std.crypto.random;

pub const State = struct {
    board: *Board,
    snake: *Snake,
    food: Food,
    timer: Timer,
    rand_indices: []usize,
    start_fps: c_int,
    cur_fps: c_int,
    score: u32 = 0,
    hiscore: u32 = 0,
    color_idx: usize = 0,
    gameover: bool = false,
    gameover_wait: u64 = 1_000, // ms

    pub fn handleInput(self: *State, input: c_int) void {
        self.snake.handleInput(input);
    }

    pub fn update(self: *State) !void {
        if (self.gameover) {
            if (self.timer.read() < self.gameover_wait * std.time.ns_per_ms) return;
            try self.reset();
            return;
        }
        self.snake.update();

        // Handle snake going OOB
        if (self.snake.head.pos.x < 0 or self.snake.head.pos.x >= self.board.cols or
            self.snake.head.pos.y < 0 or self.snake.head.pos.y >= self.board.rows)
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
            self.food = try objects.food.spawnFood(misc.getChar(self.snake.len()), self.board);
            self.score += 1;
            if (self.score % 5 == 0) {
                self.cur_fps = @min(self.cur_fps + 1, 60);
                rl.SetTargetFPS(self.cur_fps);
            }
            self.hiscore = @max(self.hiscore, self.score);
        }
    }

    pub fn scoreString(self: *State) ![:0]u8 {
        const buf = try scratch.scratchBuf(32);
        return try std.fmt.bufPrintZ(
            buf,
            " zig:{d:>3}  ziggest:{d:>3}",
            .{ self.score, self.hiscore },
        );
    }

    pub fn draw(self: *State) void {
        if (self.gameover) return;
        self.board.clear();
        self.snake.draw(self.board);
        self.food.draw(self.board);
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

    pub fn reset(self: *State) !void {
        try self.snake.reset();
        self.food = try objects.food.spawnFood(misc.getChar(self.snake.len()), self.board);
        self.gameover = false;
        self.score = 0;
        self.nextRandIdx();
        if (self.cur_fps != self.start_fps) {
            rl.SetTargetFPS(self.start_fps);
            self.cur_fps = self.start_fps;
        }
    }

    pub fn free(self: *State, allocator: *const Allocator) void {
        allocator.free(self.rand_indices);
    }

    fn gameOver(self: *State) void {
        self.gameover = true;
        self.timer.reset();
    }
};

pub fn spawnState(board: *Board, snake: *Snake, fps: c_int, color_count: usize, allocator: *const Allocator) !State {
    rl.SetTargetFPS(fps);
    var rand_indices = try allocator.alloc(usize, color_count);
    for (rand_indices, 0..) |_, i| rand_indices[i] = i;
    rng.shuffle(usize, rand_indices);
    return State{
        .board = board,
        .snake = snake,
        .food = try objects.food.spawnFood(misc.getChar(snake.len()), board),
        .timer = try Timer.start(),
        .rand_indices = rand_indices,
        .start_fps = fps,
        .cur_fps = fps,
    };
}
