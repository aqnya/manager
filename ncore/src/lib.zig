const std = @import("std");

export fn get_kernel_release(buf: [*]u8, len: usize) c_int {
    var uts: std.os.linux.utsname = undefined;
    const rc = std.os.linux.uname(&uts);
    if (rc != 0) return -1;

    const release = std.mem.sliceTo(&uts.release, 0);
    const n = @min(release.len, len - 1);
    @memcpy(buf[0..n], release[0..n]);
    buf[n] = 0;
    return @intCast(n);
}