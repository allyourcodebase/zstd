const std = @import("std");

pub fn build(b: *std.Build) void {
    const upstream = b.dependency("zstd", .{});
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Link mode") orelse .static;
    const strip = b.option(bool, "strip", "Omit debug information");
    const pic = b.option(bool, "pie", "Produce Position Independent Code");

    const compression = b.option(bool, "compression", "build compression module") orelse true;
    const decompression = b.option(bool, "decompression", "build decompression module") orelse true;
    const dictbuilder = b.option(bool, "dictbuilder", "build dictbuilder module") orelse compression;
    const deprecated = b.option(bool, "deprecated", "build deprecated module") orelse false;

    const minify = b.option(bool, "minify", "Configures a bunch of other options to space-optimized defaults") orelse false;
    const legacy_support = b.option(usize, "legacy-support", "makes it possible to decompress legacy zstd formats") orelse @as(usize, if (minify) 0 else 5);
    // For example, `-Dlegacy-support=0` means: no support for legacy formats
    // For example, `-Dlegacy-support=2` means: support legacy formats >= v0.2.0
    std.debug.assert(legacy_support < 8);

    const multi_thread = b.option(bool, "multi-thread", "Enable multi-threading") orelse (target.result.os.tag != .wasi);
    const disable_assembly = b.option(bool, "disable-assembly", "Assembly support") orelse false;
    const huf_force_decompress_x1 = b.option(bool, "huf-force-decompress-x1", "") orelse minify;
    const huf_force_decompress_x2 = b.option(bool, "huf-force-decompress-x2", "") orelse false;
    const force_decompress_sequences_short = b.option(bool, "force-decompress-sequences-short", "") orelse minify;
    const force_decompress_sequences_long = b.option(bool, "force-decompress-sequences-long", "") orelse false;
    const no_inline = b.option(bool, "no-inline", "Disable Inlining") orelse minify;
    const strip_error_strings = b.option(bool, "strip-error-strings", "removes the error messages that are otherwise returned by `ZSTD_getErrorName` (implied by `-Dminify`)") orelse minify;
    const exclude_compressors_dfast_and_up = b.option(bool, "exclude-compressors-dfast-and-up", "") orelse false;
    const exclude_compressors_greedy_and_up = b.option(bool, "exclude-compressors-greedy-and-up", "") orelse false;

    const zstd = b.addLibrary(.{
        .linkage = linkage,
        .name = "zstd",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .strip = strip,
            .pic = pic,
            .link_libc = true,
        }),
    });
    b.installArtifact(zstd);
    zstd.root_module.addCSourceFiles(.{ .root = upstream.path("lib"), .files = common_sources });
    // zstd does not install into its own subdirectory. :(
    zstd.installHeader(upstream.path("lib/zstd.h"), "zstd.h");
    zstd.installHeader(upstream.path("lib/zdict.h"), "zdict.h");
    zstd.installHeader(upstream.path("lib/zstd_errors.h"), "zstd_errors.h");
    if (compression) zstd.root_module.addCSourceFiles(.{ .root = upstream.path("lib"), .files = compression_sources });
    if (decompression) zstd.root_module.addCSourceFiles(.{ .root = upstream.path("lib"), .files = decompress_sources });
    if (dictbuilder) zstd.root_module.addCSourceFiles(.{ .root = upstream.path("lib"), .files = dict_builder_sources });
    if (deprecated) zstd.root_module.addCSourceFiles(.{ .root = upstream.path("lib"), .files = deprecated_sources });
    if (legacy_support != 0) {
        for (legacy_support..8) |i| zstd.root_module.addCSourceFile(.{ .file = upstream.path(b.fmt("lib/legacy/zstd_v0{d}.c", .{i})) });
    }

    if (target.result.cpu.arch == .x86_64) {
        if (decompression) {
            zstd.root_module.addAssemblyFile(upstream.path("lib/decompress/huf_decompress_amd64.S"));
        }
    } else {
        zstd.root_module.addCMacro("ZSTD_DISABLE_ASM", "");
    }

    zstd.root_module.addCMacro("ZSTD_LEGACY_SUPPORT", b.fmt("{d}", .{legacy_support}));
    if (multi_thread) zstd.root_module.addCMacro("ZSTD_MULTITHREAD", "1");
    if (disable_assembly) zstd.root_module.addCMacro("ZSTD_DISABLE_ASM", "");
    if (huf_force_decompress_x1) zstd.root_module.addCMacro("HUF_FORCE_DECOMPRESS_X1", "");
    if (huf_force_decompress_x2) zstd.root_module.addCMacro("HUF_FORCE_DECOMPRESS_X2", "");
    if (force_decompress_sequences_short) zstd.root_module.addCMacro("ZSTD_FORCE_DECOMPRESS_SEQUENCES_SHORT", "");
    if (force_decompress_sequences_long) zstd.root_module.addCMacro("ZSTD_FORCE_DECOMPRESS_SEQUENCES_LONG", "");
    if (no_inline) zstd.root_module.addCMacro("ZSTD_NO_INLINE", "");
    if (strip_error_strings) zstd.root_module.addCMacro("ZSTD_STRIP_ERROR_STRINGS", "");
    if (exclude_compressors_dfast_and_up) {
        zstd.root_module.addCMacro("ZSTD_EXCLUDE_DFAST_BLOCK_COMPRESSOR", "");
        zstd.root_module.addCMacro("ZSTD_EXCLUDE_GREEDY_BLOCK_COMPRESSOR", "");
        zstd.root_module.addCMacro("ZSTD_EXCLUDE_LAZY2_BLOCK_COMPRESSOR", "");
        zstd.root_module.addCMacro("ZSTD_EXCLUDE_BTLAZY2_BLOCK_COMPRESSOR", "");
        zstd.root_module.addCMacro("ZSTD_EXCLUDE_BTOPT_BLOCK_COMPRESSOR", "");
        zstd.root_module.addCMacro("ZSTD_EXCLUDE_BTULTRA_BLOCK_COMPRESSOR", "");
    }
    if (exclude_compressors_greedy_and_up) {
        zstd.root_module.addCMacro("ZSTD_EXCLUDE_GREEDY_BLOCK_COMPRESSOR", "");
        zstd.root_module.addCMacro("ZSTD_EXCLUDE_LAZY2_BLOCK_COMPRESSOR", "");
        zstd.root_module.addCMacro("ZSTD_EXCLUDE_BTLAZY2_BLOCK_COMPRESSOR", "");
        zstd.root_module.addCMacro("ZSTD_EXCLUDE_BTOPT_BLOCK_COMPRESSOR", "");
        zstd.root_module.addCMacro("ZSTD_EXCLUDE_BTULTRA_BLOCK_COMPRESSOR", "");
    }

    {
        const examples: []const []const u8 = &.{
            "simple_compression",
            "simple_decompression",
            "multiple_simple_compression",
            "dictionary_compression",
            "dictionary_decompression",
            "streaming_compression",
            "streaming_decompression",
            "multiple_streaming_compression",
            "streaming_memory_usage",
        };

        for (examples) |name| {
            const exe = b.addExecutable(.{
                .name = name,
                .root_module = b.createModule(.{
                    .target = target,
                    .optimize = optimize,
                }),
            });
            exe.root_module.addCSourceFile(.{ .file = upstream.path(b.fmt("examples/{s}.c", .{name})) });
            exe.root_module.addIncludePath(upstream.path("examples/common.c"));
            exe.root_module.linkLibrary(zstd);
            b.getInstallStep().dependOn(&b.addInstallArtifact(exe, .{ .dest_dir = .{ .override = .{ .custom = "examples" } } }).step);
        }
    }
}

const common_sources: []const []const u8 = &.{
    "common/zstd_common.c",
    "common/threading.c",
    "common/entropy_common.c",
    "common/fse_decompress.c",
    "common/xxhash.c",
    "common/error_private.c",
    "common/pool.c",
};

const compression_sources: []const []const u8 = &.{
    "compress/fse_compress.c",
    "compress/huf_compress.c",
    "compress/zstd_double_fast.c",
    "compress/zstd_compress_literals.c",
    "compress/zstdmt_compress.c",
    "compress/zstd_compress_superblock.c",
    "compress/zstd_opt.c",
    "compress/zstd_compress.c",
    "compress/zstd_compress_sequences.c",
    "compress/hist.c",
    "compress/zstd_ldm.c",
    "compress/zstd_lazy.c",
    "compress/zstd_preSplit.c",
    "compress/zstd_fast.c",
};

const decompress_sources: []const []const u8 = &.{
    "decompress/zstd_decompress.c",
    "decompress/huf_decompress.c",
    "decompress/zstd_decompress_block.c",
    "decompress/zstd_ddict.c",
};

const dict_builder_sources: []const []const u8 = &.{
    "dictBuilder/divsufsort.c",
    "dictBuilder/zdict.c",
    "dictBuilder/cover.c",
    "dictBuilder/fastcover.c",
};

const deprecated_sources: []const []const u8 = &.{
    "deprecated/zbuff_decompress.c",
    "deprecated/zbuff_common.c",
    "deprecated/zbuff_compress.c",
};

const legacy_sources: []const []const u8 = &.{
    "legacy/zstd_v01.c",
    "legacy/zstd_v02.c",
    "legacy/zstd_v03.c",
    "legacy/zstd_v04.c",
    "legacy/zstd_v05.c",
    "legacy/zstd_v06.c",
    "legacy/zstd_v07.c",
};
