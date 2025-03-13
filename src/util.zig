


pub fn i2f32(int: anytype) f32 {
	return @as(f32, @floatFromInt(int));
}


pub fn f2i32(float: anytype) i32 {
	return @as(i32, @intFromFloat(float));
}
