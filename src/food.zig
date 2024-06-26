const Food = @This();
const std = @import("std");
const rng = std.crypto.random;
const Grid = @import("grid.zig");
const Position = @import("types.zig").Position;

char: u8,
pos: Position,

pub fn create(grid: *Grid) Food {
    return Food{ .char = 'o', .pos = Food.getRandPos(grid) };
}

pub fn update(self: *Food) void {
    _ = self;
}

pub fn draw(self: *Food, grid: *Grid) void {
    grid.array[@as(usize, @intCast(self.pos.y))][@as(usize, @intCast(self.pos.x))] = self.char;
}

pub fn reset(self: *Food, grid: *Grid) void {
    self.pos = Food.getRandPos(grid);
}

fn getRandPos(grid: *Grid) Position {
    return Position{
        .x = rng.intRangeLessThan(i32, 0, @as(i32, @intCast(grid.width))),
        .y = rng.intRangeLessThan(i32, 0, @as(i32, @intCast(grid.height))),
    };
}
