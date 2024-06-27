const std = @import("std");
const math = @import("../math.zig");

const Allocator = std.mem.Allocator;
const Vec2 = math.Vec2;

pub const Grid = struct {
    width: usize,
    height: usize,
    array: [][]u8,
    empty_ps: []Vec2,

    pub fn create(width: usize, height: usize, allocator: *const Allocator) !Grid {
        const array = try allocator.alloc([]u8, height);
        for (array) |*row| {
            row.* = try allocator.alloc(u8, width);
        }
        return Grid{
            .width = width,
            .height = height,
            .array = array,
            .empty_ps = try allocator.alloc(Vec2, width * height),
        };
    }

    pub fn free(self: *Grid, allocator: *const Allocator) void {
        for (self.array) |*row| {
            allocator.free(row.*);
        }
        allocator.free(self.array);
        allocator.free(self.empty_ps);
    }

    pub fn clear(self: *Grid) void {
        for (self.array) |*row| {
            for (row.*) |*item| {
                item.* = ' ';
            }
        }
    }

    pub fn printToBuf(self: *Grid, buffer: *const []u8) !void {
        if (buffer.len < self.array[0].len * self.height) return error.BufferTooSmall;
        for (self.array, 0..) |row, i| {
            std.mem.copyForwards(u8, buffer.*[row.len * i + i ..], row);
            std.mem.copyForwards(u8, buffer.*[row.len * i + i + row.len ..], "\n");
        }
    }
};
