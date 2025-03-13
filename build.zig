const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Modules.
    const exe_mod = b.createModule(.{
        // `root_source_file` is the Zig "entry point" of the module. If a module
        // only contains e.g. external object files, you can make this `null`.
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    // main raylib module
    const raylib = raylib_dep.module("raylib"); 
    // raygui module
    const raygui = raylib_dep.module("raygui"); 
    // raylib C library
    const raylib_artifact = raylib_dep.artifact("raylib"); 


    // InstallArtifact: exe.
    const exe = b.addExecutable(.{
        .name = "highway-pursuit-zig",
        .root_module = exe_mod,
    });
    
    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);

    b.installArtifact(exe);


    // RunArtifact: run_cmd -> install.
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // RunArtifact: exe_unit_tests.
    const exe_unit_tests = b.addTest(.{ .root_module = exe_mod });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);


    // Step: run_step -> run_cmd.
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Step: test_step -> run_exe_unit_tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
    // test_step.dependOn(&run_lib_unit_tests.step);



    // const lib_mod = b.createModule(.{
    //     // `root_source_file` is the Zig "entry point" of the module. If a module
    //     // only contains e.g. external object files, you can make this `null`.
    //     // In this case the main source file is merely a path, however, in more
    //     // complicated build scripts, this could be a generated file.
    //     .root_source_file = b.path("src/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    // exe_mod.addImport("zig_lib", lib_mod);

    // const lib = b.addLibrary(.{
    //     .linkage = .static,
    //     .name = "zig",
    //     .root_module = lib_mod,
    // });

    // b.installArtifact(lib);

    // const lib_unit_tests = b.addTest(.{
    //     .root_module = lib_mod,
    // });
    // const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
}
