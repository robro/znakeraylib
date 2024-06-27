const Grid = @This();
const std = @import("std");
const Position = @import("utils.zig").Position;

const SizeError = error{BufferTooSmall};

width: usize,
height: usize,
array: [][]u8,
empty_ps: []Position,

pub fn create(width: usize, height: usize, allocator: *const std.mem.Allocator) !Grid {
    const array = try allocator.alloc([]u8, height);
    for (array) |*row| {
        row.* = try allocator.alloc(u8, width);
    }
    return Grid{
        .width = width,
        .height = height,
        .array = array,
        .empty_ps = try allocator.alloc(Position, width * height),
    };
}

pub fn free(self: *Grid, allocator: *const std.mem.Allocator) void {
    for (self.array) |*row| {
        allocator.free(row.*);
    }
    allocator.free(self.array);
    allocator.free(self.empty_ps);
}

pub fn empty(self: *Grid) void {
    for (self.array) |*row| {
        for (row.*) |*item| {
            item.* = ' ';
        }
    }
}

pub fn getEmptyCount(self: *Grid) usize {
    var empty_count: usize = 0;
    for (self.array, 0..) |*row, y| {
        for (row.*, 0..) |char, x| {
            if (char != ' ') continue;
            self.empty_ps[empty_count] = .{ .x = @intCast(x), .y = @intCast(y) };
            empty_count += 1;
        }
    }
    return empty_count;
}

pub fn printToBuf(self: *Grid, buffer: *const []u8) !void {
    if (buffer.len < self.array[0].len * self.height) return SizeError.BufferTooSmall;
    for (self.array, 0..) |row, i| {
        std.mem.copyForwards(u8, buffer.*[row.len * i + i ..], row);
        std.mem.copyForwards(u8, buffer.*[row.len * i + i + row.len ..], "\n");
    }
}
