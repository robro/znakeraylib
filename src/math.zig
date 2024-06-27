pub const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn add(a: *const Vec2, b: Vec2) Vec2 {
        return Vec2{ .x = a.x + b.x, .y = a.y + b.y };
    }

    pub fn eql(a: *const Vec2, b: Vec2) bool {
        return a.x == b.x and a.y == b.y;
    }
};
