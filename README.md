[![CI](https://github.com/allyourcodebase/zstd/actions/workflows/ci.yaml/badge.svg)](https://github.com/allyourcodebase/zstd/actions)

# zstd

This is [zstd](https://github.com/facebook/zstd), packaged for [Zig](https://ziglang.org/).

## Installation

First, update your `build.zig.zon`:

```
# Initialize a `zig build` project if you haven't already
zig init
zig fetch --save git+https://github.com/allyourcodebase/zstd.git#1.5.7-1
```

You can then import `zstd` in your `build.zig` with:

```zig
const zstd_dependency = b.dependency("zstd", .{
    .target = target,
    .optimize = optimize,
});
your_exe.linkLibrary(zstd_dependency.artifact("zstd"));
```
