pub const SizeError = error{
    BufferTooSmall,
    NoFreePositions,
};

pub const Direction = enum {
    UP,
    DOWN,
    LEFT,
    RIGHT,
};

pub const Position = struct {
    x: i32,
    y: i32,
};

pub fn getChar(num: usize) u8 {
    switch (num % 3) {
        0 => return 'z',
        1 => return 'i',
        2 => return 'g',
        else => unreachable,
    }
}
