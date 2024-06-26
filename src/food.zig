const std = @import("std");
const types = @import("types.zig");
const Grid = @import("grid.zig").Grid;
const Position = types.Position;

pub const Food = struct {
    char: u8,
    pos: Position,

    pub fn create(rng: std.Random, grid: Grid) Food {
        return Food{ .char = 'o', .pos = Food.getRandPos(rng, grid) };
    }

    pub fn update(self: *Food) void {
        _ = self;
    }

    pub fn printToGrid(self: *Food, grid: *Grid) void {
        grid.array[@as(usize, @intCast(self.pos.y))][@as(usize, @intCast(self.pos.x))] = self.char;
    }

    pub fn reset(self: *Food, rng: std.Random, grid: Grid) void {
        self.pos = Food.getRandPos(rng, grid);
    }

    pub fn getRandPos(rng: std.Random, grid: Grid) Position {
        return Position{
            .x = rng.intRangeLessThan(i32, 0, @as(i32, @intCast(grid.width))),
            .y = rng.intRangeLessThan(i32, 0, @as(i32, @intCast(grid.height))),
        };
    }
};
