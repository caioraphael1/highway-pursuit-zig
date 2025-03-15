


pub fn tof32(int: anytype) f32 {
	return @as(f32, @floatFromInt(int));
}


pub fn toi32(float: anytype) i32 {
	return @as(i32, @intFromFloat(float));
}
