const std = @import("std");

export fn get_kernel_release(buf: [*]u8, len: usize) c_int {
    var uts: std.os.linux.utsname = undefined;
    const rc = std.os.linux.uname(&uts);
    if (rc != 0) return -1;

    const full_release = std.mem.sliceTo(&uts.release, 0);

    const dash_idx = std.mem.indexOfScalar(u8, full_release, '-') orelse full_release.len;
    const kernel_part = full_release[0..dash_idx];
    var android_part: []const u8 = "";
    if (std.mem.indexOf(u8, full_release, "android")) |android_idx| {
        const after_android = full_release[android_idx..];
        var end_idx: usize = 0;
        while (end_idx < after_android.len and after_android[end_idx] != '-') : (end_idx += 1) {}
        android_part = after_android[0..end_idx];
    }

    if (android_part.len > 0) {
        return printToBuf(buf, len, "{s}-{s}", .{ kernel_part, android_part });
    } else {
        return printToBuf(buf, len, "{s}", .{kernel_part});
    }
}

fn printToBuf(buf: [*]u8, len: usize, comptime fmt: []const u8, args: anytype) c_int {
    const res = std.fmt.bufPrint(buf[0..len], fmt, args) catch return -1;
    if (res.len < len) {
        buf[res.len] = 0;
    }
    return @intCast(res.len);
}

export fn get_selinux_status() c_int {
    const fd = std.os.linux.open("/sys/fs/selinux/enforce", .{}, 0);
    if (fd < 0) return 1;
    defer _ = std.os.linux.close(@intCast(fd));

    var buf: [1]u8 = undefined;
    const n = std.os.linux.read(@intCast(fd), &buf, 1);
    if (n <= 0) return 1;

    return if (buf[0] == '0') 0 else 1;
}
