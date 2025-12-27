[![CI](https://github.com/allyourcodebase/zstd/actions/workflows/ci.yaml/badge.svg)](https://github.com/allyourcodebase/zstd/actions)

# zstd

This is [zstd](https://github.com/facebook/zstd), packaged for [Zig](https://ziglang.org/).

Compatible with zig `0.14`-`0.16`

## Installation

First, update your `build.zig.zon`:

```
# Initialize a `zig build` project if you haven't already
zig init
zig fetch --save git+https://github.com/allyourcodebase/zstd.git#master
```

You can then import `zstd` in your `build.zig` with:

```zig
const zstd_dependency = b.dependency("zstd", .{
    .target = target,
    .optimize = optimize,
});
your_exe.linkLibrary(zstd_dependency.artifact("zstd"));
```

## Options

```
  -Dlinkage=[enum]             Link mode. Defaults to static
                                 Supported Values:
                                   static
                                   dynamic
  -Dstrip=[bool]               Omit debug information
  -Dpie=[bool]                 Produce Position Independent Code
  -Dcompression=[bool]         build compression module
  -Ddecompression=[bool]       build decompression module
  -Ddictbuilder=[bool]         build dictbuilder module
  -Ddeprecated=[bool]          build deprecated module
  -Dminify=[bool]              Configures a bunch of other options to space-optimized defaults
  -Dlegacy-support=[int]       makes it possible to decompress legacy zstd formats
  -Dmulti-thread=[bool]        Enable multi-threading
  -Ddisable-assembly=[bool]    Assembly support
  -Dhuf-force-decompress-x1=[bool]
  -Dhuf-force-decompress-x2=[bool]
  -Dforce-decompress-sequences-short=[bool]
  -Dforce-decompress-sequences-long=[bool]
  -Dno-inline=[bool]           Disable Inlining
  -Dstrip-error-strings=[bool] removes the error messages that are otherwise returned by `ZSTD_getErrorName` (implied by `-Dminify`)
  -Dexclude-compressors-dfast-and-up=[bool]
  -Dexclude-compressors-greedy-and-up=[bool]
```
