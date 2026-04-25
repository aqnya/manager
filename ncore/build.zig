const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ndk_sysroot = b.option(
        []const u8,
        "ndk-sysroot",
        "Path to NDK sysroot (.../toolchains/llvm/prebuilt/linux-x86_64/sysroot)",
    );
    const ndk_api = b.option(
        []const u8,
        "ndk-api",
        "Android API level (default: 30)",
    ) orelse "30";

    const lib = b.addLibrary(.{
        .name = "ncore",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/lib.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    if (optimize != .Debug) {
        lib.root_module.strip = true;
        lib.lto = .full;
    }

    if (target.result.abi == .android) {
        const sysroot = ndk_sysroot orelse {
            std.debug.print("error: -Dndk-sysroot=<path> is required for Android targets\n", .{});
            return error.MissingNdkSysroot;
        };

        const arch_name = @tagName(target.result.cpu.arch);
        const triple = b.fmt("{s}-linux-android", .{arch_name});
        const include = b.pathJoin(&.{ sysroot, "usr/include" });
        const arch_include = b.pathJoin(&.{ include, triple });
        const libpath = b.pathJoin(&.{ sysroot, "usr/lib", triple, ndk_api });

        const libc_content = b.fmt(
            \\include_dir={s}
            \\sys_include_dir={s}
            \\crt_dir={s}
            \\msvc_lib_dir=
            \\kernel32_lib_dir=
            \\gcc_dir=
        , .{ include, include, libpath });
        const libc_path = b.addWriteFiles().add("libc.txt", libc_content);

        lib.root_module.addIncludePath(.{ .cwd_relative = include });
        lib.root_module.addIncludePath(.{ .cwd_relative = arch_include });
        lib.root_module.addLibraryPath(.{ .cwd_relative = libpath });
        lib.root_module.linkSystemLibrary("log", .{});
        lib.root_module.linkSystemLibrary("c", .{});
        lib.setLibCFile(libc_path);
    }

    b.installArtifact(lib);
}
