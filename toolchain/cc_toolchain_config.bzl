load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "tool_path",
)

all_link_actions = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]

all_compile_actions = [
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.clif_match,
    ACTION_NAMES.lto_backend,
]

def _impl(ctx):
  tool_paths = [
      tool_path(
          name = "gcc",
          path = "/usr/local/bin/clang",
      ),
      tool_path(
          name = "ld",
          path = ctx.attr.linker_path,
      ),
      tool_path(
          name = "ar",
          path = "/usr/bin/llvm-ar",
      ),
      tool_path(
          name = "compat-ld",
          path = ctx.attr.linker_path,
      ),
      tool_path(
          name = "cpp",
          path = "/bin/false",
      ),
      tool_path(
          name = "dwp",
          path = "/bin/false",
      ),
      tool_path(
          name = "gcov",
          path = "/bin/false",
      ),
      tool_path(
          name = "nm",
          path = "/bin/false",
      ),
      tool_path(
          name = "objcopy",
          path = "/bin/false",
      ),
      tool_path(
          name = "objdump",
          path = "/bin/false",
      ),
      tool_path(
          name = "strip",
          path = "/bin/false",
      ),
  ]

  linker_flags = feature(
      name = "default_linker_flags",
      enabled = True,
      flag_sets = [
          flag_set(
              actions = all_link_actions,
              flag_groups = [
                  flag_group(
                      flags = [
                          "-B" + ctx.attr.linker_path,
                          ctx.attr.cpp_flag,
                          "--target=" + ctx.attr.target_full_name,
                      ],
                  ),
              ],
          ),
      ],
  )

  sysroot_flags = feature(
      name = "sysroot_flags",
      #Only enable this if a sysroot was specified
      enabled = (ctx.attr.sysroot != ""),
      flag_sets = [
          flag_set(
              actions = all_link_actions,
              flag_groups = [
                  flag_group(
                      flags = [
                          "--sysroot",
                          ctx.attr.sysroot,
                      ],
                  ),
              ],
          ),
      ],
  )

  compiler_flags = feature(
      name = "default_compile_flags",
      enabled = True,
      flag_sets = [
          flag_set(
              actions = all_compile_actions,
              flag_groups = [
                  flag_group(
                      flags = [
                          ctx.attr.bit_flag,
                          "-Wall",
                          "-no-canonical-prefixes",
                          "--target=" + ctx.attr.target_full_name,
                          "-isystem",
                          ctx.attr.toolchain_dir,
                          "-fvisibility=hidden",
                      ] + ctx.attr.include_flag,
                  ),
              ],
          ),
      ],
  )

  return cc_common.create_cc_toolchain_config_info(
      abi_libc_version = ctx.attr.abi_version,
      abi_version = ctx.attr.abi_version,
      ctx = ctx,
      compiler = "clang",
      cxx_builtin_include_directories = [
          ctx.attr.toolchain_dir,
          "/usr/include",
          "/usr/local/include",
          "/usr/local/lib/clang",
      ],
      features = [linker_flags, compiler_flags, sysroot_flags],
      host_system_name = "local",
      target_cpu = ctx.attr.target_cpu,
      target_libc = ctx.attr.target_cpu,
      target_system_name = ctx.attr.target_full_name,
      toolchain_identifier = ctx.attr.toolchain_name,
      tool_paths = tool_paths,
  )

cc_toolchain_config = rule(
    implementation = _impl,
    attrs = {
        "abi_version": attr.string(default = "local"),
        "bit_flag": attr.string(mandatory = True, values = ["-m32", "-m64"]),
        "cpp_flag": attr.string(mandatory = True),
        "include_flag": attr.string_list(),
        "linker_path": attr.string(mandatory = True),
        "sysroot": attr.string(mandatory = False),
        "target_cpu": attr.string(mandatory = True, values = ["aarch64", "ppc64", "systemz", "x86_32", "x86_64"]),
        "target_full_name": attr.string(mandatory = True),
        "toolchain_dir": attr.string(mandatory = True),
        "toolchain_name": attr.string(mandatory = True),
    },
    provides = [CcToolchainConfigInfo],
)
