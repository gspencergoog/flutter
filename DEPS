# The dependencies referenced by the Flutter Engine.
#
# This file is referenced by the .gclient file at the root of the checkout.
# To preview changes to the dependencies, update this file and run
# `gclient sync`.
#
# When adding a new dependency, please update the top-level .gitignore file
# to list the dependency's destination directory.

vars = {
  'chromium_git': 'https://chromium.googlesource.com',
  'swiftshader_git': 'https://swiftshader.googlesource.com',
  'dart_git': 'https://dart.googlesource.com',
  'flutter_git': 'https://flutter.googlesource.com',
  'skia_git': 'https://skia.googlesource.com',
  'llvm_git': 'https://llvm.googlesource.com',
  'skia_revision': '8673a5f663693f6913044bbf03f30363d20d421c',

  # WARNING: DO NOT EDIT canvaskit_cipd_instance MANUALLY
  # See `lib/web_ui/README.md` for how to roll CanvasKit to a new version.
  'canvaskit_cipd_instance': '61aeJQ9laGfEFF_Vlc_u0MCkqB6xb2hAYHRBxKH-Uw4C',

  # Do not download the Emscripten SDK by default.
  # This prevents us from downloading the Emscripten toolchain for builds
  # which do not build for the web. This toolchain is needed to build CanvasKit
  # for the web engine.
  'download_emsdk': False,

  # For experimental features some dependencies may only be avaialable in the master/main
  # channels. This variable is being set when CI is checking out the repository.
  'release_candidate': False,

  # As Dart does, we use Fuchsia's GN and Clang toolchain. These revision
  # should be kept up to date with the revisions pulled by Dart.
  #
  # The list of revisions for these tools comes from Fuchsia, here:
  # https://fuchsia.googlesource.com/integration/+/HEAD/toolchain
  # If there are problems with the toolchain, contact fuchsia-toolchain@.
  #
  # Note, if you are *manually* rolling clang (i.e. the auto-roll is disabled)
  # you'll need to run post-submits (i.e. for Clang Tidy) in order to test that
  # updates to Clang Tidy will not turn the tree red.
  #
  # See https://github.com/flutter/flutter/wiki/Engine-pre‐submits-and-post‐submits#post-submit
  'clang_version': 'git_revision:725656bdd885483c39f482a01ea25d67acf39c46',

  'reclient_version': 'git_revision:29a9d3cb597b6a7d67fa3e9aa8a7cab1c81232ee',

  'gcloud_version': 'version:2@444.0.0.chromium.3',

  'esbuild_version': '0.19.5',

  # When updating the Dart revision, ensure that all entries that are
  # dependencies of Dart are also updated to match the entries in the
  # Dart SDK's DEPS file for that revision of Dart. The DEPS file for
  # Dart is: https://github.com/dart-lang/sdk/blob/main/DEPS
  # You can use //tools/dart/create_updated_flutter_deps.py to produce
  # updated revision list of existing dependencies.
  'dart_revision': 'e28bf080514a2d520dfe0663d5a15b41a9c77186',

  # WARNING: DO NOT EDIT MANUALLY
  # The lines between blank lines above and below are generated by a script. See create_updated_flutter_deps.py
  'dart_binaryen_rev': 'b4bdcc33115b31758c56b83bb9de4642c411a042',
  'dart_boringssl_rev': 'c6292fa69a65ab116923993757eb2110db7799ba',
  'dart_core_rev': '61e677100b06d56a1b3731ab1178ebf9102ecb1f',
  'dart_devtools_rev': 'f10e8df8c517fb0412b9a66c626581867c9c267d',
  'dart_ecosystem_rev': '23172636e60c52384b40e6bd1240d12c8e860122',
  'dart_http_rev': '1b6e28d7e1c61f7b0f8561be7aee9c35b03de193',
  'dart_i18n_rev': 'd9cce0b6348b51872fb269e43ff8a43120fe191d',
  'dart_libprotobuf_rev': '24487dd1045c7f3d64a21f38a3f0c06cc4cf2edb',
  'dart_perfetto_rev': '13ce0c9e13b0940d2476cd0cff2301708a9a2e2b',
  'dart_protobuf_gn_rev': 'ca669f79945418f6229e4fef89b666b2a88cbb10',
  'dart_protobuf_rev': '0bab78d9538e49d50023bab36159b15ff3c369eb',
  'dart_pub_rev': '528f5103fb5e9a7d5f5bc4e365a3514927bd43db',
  'dart_sync_http_rev': 'dc54465f07d9652875deeade643256dafa2fbc6c',
  'dart_tools_rev': '62bc13bc086a66ce9a6a3e64865c82d17a1379b3',
  'dart_vector_math_rev': 'f08d7d2652e9ecf7d8f8605d9983335174511c95',
  'dart_web_rev': '5a39fdc396ae40344308975140343c23b6863261',
  'dart_webdev_rev': '302b6db6125901fd183390e339aff7490cdde3d0',
  'dart_webdriver_rev': 'f52afbf72895ae980bd4129d877305c2182d6cbc',
  'dart_webkit_inspection_protocol_rev': 'effa75205516757795683d527c3dea9546eb0c32',

  'ocmock_rev': 'c4ec0e3a7a9f56cfdbd0aa01f4f97bb4b75c5ef8', # v3.7.1

  # Download a prebuilt Dart SDK by default
  'download_dart_sdk': True,

  # Download a prebuilt esbuild by default
  'download_esbuild': True,

  # Checkout Android dependencies only on platforms where we build for Android targets.
  'download_android_deps': 'host_os == "mac" or (host_os == "linux" and host_cpu == "x64")',

  # Checkout Java dependencies only on platforms that do not have java installed on path.
  'download_jdk': True,

  # Checkout Windows dependencies only if we are building on Windows.
  'download_windows_deps' : 'host_os == "win"',

  # Checkout Linux dependencies only when building on Linux.
  'download_linux_deps': 'host_os == "linux"',

  # The minimum macOS SDK version. This must match the setting in
  # //flutter/tools/gn.
  'mac_sdk_min': '10.14',

  # Checkout Fuchsia dependencies only on Linux. This is the umbrella flag which
  # controls the behavior of all fuchsia related flags. I.e. any fuchsia related
  # logic or condition may not work if this flag is False.
  # TODO(zijiehe): Make this condition more strict to only download fuchsia
  # dependencies when necessary: b/40935282
  'download_fuchsia_deps': 'host_os == "linux"',
  # Downloads the fuchsia SDK as listed in fuchsia_sdk_path var. This variable
  # is currently only used for the Fuchsia LSC process and is not intended for
  # local development.
  'download_fuchsia_sdk': False,
  'fuchsia_sdk_path': '',
  # Whether to download and run the Fuchsia emulator locally to test Fuchsia
  # builds.
  'run_fuchsia_emu': False,

  # An LLVM backend needs LLVM binaries and headers. To avoid build time
  # increases we can use prebuilts. We don't want to download this on every
  # CQ/CI bot nor do we want the average Dart developer to incur that cost.
  # So by default we will not download prebuilts. This variable is needed in
  # the flutter engine to ensure that Dart gn has access to it as well.
  "checkout_llvm": False,

  # Setup Git hooks by default.
  'setup_githooks': True,

  # When this is true, the Flutter Engine's configuration files and scripts for
  # RBE will be downloaded from CIPD. This option is only usable by Googlers.
  'use_rbe': False,

  # This is not downloaded be default because it increases the
  # `gclient sync` time by between 1 and 3 minutes. This option is enabled
  # in flutter/ci/builders/mac_impeller_cmake_example.json, and is likely to
  # only be useful locally when reproducing issues found by the bot.
  'download_impeller_cmake_example': False,

  # Upstream URLs for third party dependencies, used in
  # determining common ancestor commit for vulnerability scanning
  # prefixed with 'upstream_' in order to be identified by parsing tool.
  # The vulnerability database being used in this scan can be browsed
  # using this UI https://osv.dev/list
  # If a new dependency needs to be added, the upstream (non-mirrored)
  # git URL for that dependency should be added to this list
  # with the key-value pair being:
  # 'upstream_[dep name from last slash and before .git in URL]':'[git URL]'
  # example:
  "upstream_abseil-cpp": "https://github.com/abseil/abseil-cpp.git",
  "upstream_angle": "https://github.com/google/angle.git",
  "upstream_archive": "https://github.com/brendan-duncan/archive.git",
  "upstream_benchmark": "https://github.com/google/benchmark.git",
  "upstream_boringssl": "https://github.com/openssl/openssl.git",
  "upstream_brotli": "https://github.com/google/brotli.git",
  "upstream_dart_style": "https://github.com/dart-lang/dart_style.git",
  "upstream_dartdoc": "https://github.com/dart-lang/dartdoc.git",
  "upstream_equatable": "https://github.com/felangel/equatable.git",
  "upstream_ffi": "https://github.com/dart-lang/ffi.git",
  "upstream_flatbuffers": "https://github.com/google/flatbuffers.git",
  "upstream_freetype2": "https://gitlab.freedesktop.org/freetype/freetype.git",
  "upstream_gcloud": "https://github.com/dart-lang/gcloud.git",
  "upstream_glfw": "https://github.com/glfw/glfw.git",
  "upstream_googleapis": "https://github.com/google/googleapis.dart.git",
  "upstream_googletest": "https://github.com/google/googletest.git",
  "upstream_gtest-parallel": "https://github.com/google/gtest-parallel.git",
  "upstream_harfbuzz": "https://github.com/harfbuzz/harfbuzz.git",
  "upstream_http": "https://github.com/dart-lang/http.git",
  "upstream_icu": "https://github.com/unicode-org/icu.git",
  "upstream_imgui": "https://github.com/ocornut/imgui.git",
  "upstream_inja": "https://github.com/pantor/inja.git",
  "upstream_json": "https://github.com/nlohmann/json.git",
  "upstream_libcxx": "https://github.com/llvm-mirror/libcxx.git",
  "upstream_libcxxabi": "https://github.com/llvm-mirror/libcxxabi.git",
  "upstream_libexpat": "https://github.com/libexpat/libexpat.git",
  "upstream_libjpeg-turbo": "https://github.com/libjpeg-turbo/libjpeg-turbo.git",
  "upstream_libpng": "https://github.com/glennrp/libpng.git",
  "upstream_libtess2": "https://github.com/memononen/libtess2.git",
  "upstream_libwebp": "https://chromium.googlesource.com/webm/libwebp.git",
  "upstream_leak_tracker": "https://github.com/dart-lang/leak_tracker.git",
  "upstream_mockito": "https://github.com/dart-lang/mockito.git",
  "upstream_ocmock": "https://github.com/erikdoe/ocmock.git",
  "upstream_packages": "https://github.com/flutter/packages.git",
  "upstream_process_runner": "https://github.com/google/process_runner.git",
  "upstream_process": "https://github.com/google/process.dart.git",
  "upstream_protobuf": "https://github.com/google/protobuf.dart.git",
  "upstream_pub_semver": "https://github.com/dart-lang/pub_semver.git",
  "upstream_pub": "https://github.com/dart-lang/pub.git",
  "upstream_pyyaml": "https://github.com/yaml/pyyaml.git",
  "upstream_quiver-dart": "https://github.com/google/quiver-dart.git",
  "upstream_rapidjson": "https://github.com/Tencent/rapidjson.git",
  "upstream_sdk": "https://github.com/dart-lang/sdk.git",
  "upstream_shaderc": "https://github.com/google/shaderc.git",
  "upstream_shelf": "https://github.com/dart-lang/shelf.git",
  "upstream_skia": "https://skia.googlesource.com/skia.git",
  "upstream_sqlite": "https://github.com/sqlite/sqlite.git",
  "upstream_SwiftShader": "https://swiftshader.googlesource.com/SwiftShader.git",
  "upstream_tar": "https://github.com/simolus3/tar.git",
  "upstream_test": "https://github.com/dart-lang/test.git",
  "upstream_usage": "https://github.com/dart-lang/usage.git",
  "upstream_vector_math": "https://github.com/google/vector_math.dart.git",
  "upstream_VulkanMemoryAllocator": "https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator.git",
  "upstream_webdev": "https://github.com/dart-lang/webdev.git",
  "upstream_webkit_inspection_protocol": "https://github.com/google/webkit_inspection_protocol.dart.git",
  "upstream_wuffs-mirror-release-c": "https://github.com/google/wuffs-mirror-release-c.git",
  "upstream_yapf": "https://github.com/google/yapf.git",
  "upstream_zlib": "https://github.com/madler/zlib.git",

  # The version / instance id of the cipd:chromium/fuchsia/test-scripts which
  # will be used altogether with fuchsia-sdk to setup the build / test
  # environment.
  'fuchsia_test_scripts_version': 'Odv8fZ_wqp4I5Nln7pvt_3n1fQKDz1hHAsbL_13WmzcC',

  # The version / instance id of the cipd:chromium/fuchsia/gn-sdk which will be
  # used altogether with fuchsia-sdk to generate gn based build rules.
  'fuchsia_gn_sdk_version': 'K_1kHDN1WfObPYHyad1M8zegaI4awe8GiPhafqb99Y0C',
}

gclient_gn_args_file = 'engine/src/flutter/third_party/dart/build/config/gclient_args.gni'
gclient_gn_args = [
  'checkout_llvm'
]

# Only these hosts are allowed for dependencies in this DEPS file.
# If you need to add a new host, contact chrome infrastructure team.
allowed_hosts = [
  'boringssl.googlesource.com',
  'chrome-infra-packages.appspot.com',
  'chromium.googlesource.com',
  'dart.googlesource.com',
  'flutter.googlesource.com',
  'llvm.googlesource.com',
  'skia.googlesource.com',
  'swiftshader.googlesource.com',
]

deps = {
  'engine/src/flutter/third_party/depot_tools':
  Var('chromium_git') + '/chromium/tools/depot_tools.git' + '@' + '580b4ff3f5cd0dcaa2eacda28cefe0f45320e8f7',

  'engine/src/flutter/third_party/rapidjson':
   Var('flutter_git') + '/third_party/rapidjson' + '@' + 'ef3564c5c8824989393b87df25355baf35ff544b',

  'engine/src/flutter/third_party/harfbuzz':
   Var('flutter_git') + '/third_party/harfbuzz' + '@' + 'ea8f97c615f0ba17dc25013ef67dbd6bfaaa76f2',

  'engine/src/flutter/third_party/libcxx':
   Var('llvm_git') + '/llvm-project/libcxx' + '@' + 'bd557f6f764d1e40b62528a13b124ce740624f8f',

  'engine/src/flutter/third_party/libcxxabi':
   Var('llvm_git') + '/llvm-project/libcxxabi' + '@' + 'a4dda1589d37a7e4b4f7a81ebad01b1083f2e726',

  'engine/src/flutter/third_party/llvm_libc':
   Var('llvm_git') + '/llvm-project/libc' + '@' + '5af39a19a1ad51ce93972cdab206dcd3ff9b6afa',

  'engine/src/flutter/third_party/glfw':
   Var('flutter_git') + '/third_party/glfw' + '@' + 'dd8a678a66f1967372e5a5e3deac41ebf65ee127',

  'engine/src/flutter/third_party/shaderc':
   Var('chromium_git') + '/external/github.com/google/shaderc' + '@' + '37e25539ce199ecaf19fb7f7d27818716d36686d',

  'engine/src/flutter/third_party/vulkan-deps':
   Var('chromium_git') + '/vulkan-deps' + '@' + '938de304bdcb33049ec39ce45f16223eb6a960b6',

  'engine/src/flutter/third_party/flatbuffers':
   Var('chromium_git') + '/external/github.com/google/flatbuffers' + '@' + '0a80646371179f8a7a5c1f42c31ee1d44dcf6709',

  'engine/src/flutter/third_party/icu':
   Var('chromium_git') + '/chromium/deps/icu.git' + '@' + '4239b1559d11d4fa66c100543eda4161e060311e',

   'engine/src/flutter/third_party/gtest-parallel':
   Var('chromium_git') + '/external/github.com/google/gtest-parallel' + '@' + '38191e2733d7cbaeaef6a3f1a942ddeb38a2ad14',

  'engine/src/flutter/third_party/benchmark':
   Var('chromium_git') + '/external/github.com/google/benchmark' + '@' + '431abd149fd76a072f821913c0340137cc755f36',

  'engine/src/flutter/third_party/googletest':
   Var('chromium_git') + '/external/github.com/google/googletest' + '@' + '7f036c5563af7d0329f20e8bb42effb04629f0c0',

  'engine/src/flutter/third_party/brotli':
   Var('skia_git') + '/external/github.com/google/brotli.git' + '@' + '350100a5bb9d9671aca85213b2ec7a70a361b0cd',

  'engine/src/flutter/third_party/yapf':
  Var('flutter_git') + '/third_party/yapf' + '@' + '212c5b5ad8e172d2d914ae454c121c89cccbcb35',

  'engine/src/flutter/third_party/boringssl/src':
  'https://boringssl.googlesource.com/boringssl.git' + '@' + Var('dart_boringssl_rev'),

  'engine/src/flutter/third_party/perfetto':
   Var('flutter_git') + "/third_party/perfetto" + '@' + Var('dart_perfetto_rev'),

  'engine/src/flutter/third_party/protobuf':
   Var('flutter_git') + '/third_party/protobuf' + '@' + Var('dart_libprotobuf_rev'),

  # TODO(67373): These are temporarily checked in, but this dep can be restored
  # once the buildmoot is completed.
  # 'engine/src/flutter/build/secondary/third_party/protobuf':
  #  Var('flutter_git') + '/third_party/protobuf-gn' + '@' + Var('dart_protobuf_gn_rev'),

  'engine/src/flutter/third_party/dart':
   Var('dart_git') + '/sdk.git' + '@' + Var('dart_revision'),

  # WARNING: Unused Dart dependencies in the list below till "WARNING:" marker are removed automatically - see create_updated_flutter_deps.py.

  'engine/src/flutter/third_party/dart/third_party/binaryen/src':
   Var('chromium_git') + '/external/github.com/WebAssembly/binaryen.git@b4bdcc33115b31758c56b83bb9de4642c411a042',

  'engine/src/flutter/third_party/dart/third_party/devtools':
   {'dep_type': 'cipd', 'packages': [{'package': 'dart/third_party/flutter/devtools', 'version': 'git_revision:f10e8df8c517fb0412b9a66c626581867c9c267d'}]},

  'engine/src/flutter/third_party/dart/third_party/pkg/core':
   Var('dart_git') + '/core.git' + '@' + Var('dart_core_rev'),

  'engine/src/flutter/third_party/dart/third_party/pkg/dart_style':
   Var('dart_git') + '/dart_style.git@21de99ec0ff8ace4d946a746fb427fffd6afa535',

  'engine/src/flutter/third_party/dart/third_party/pkg/dartdoc':
   Var('dart_git') + '/dartdoc.git@d40067626b8c419e451897447e4dae74d25bcc37',

  'engine/src/flutter/third_party/dart/third_party/pkg/ecosystem':
   Var('dart_git') + '/ecosystem.git' + '@' + Var('dart_ecosystem_rev'),

  'engine/src/flutter/third_party/dart/third_party/pkg/http':
   Var('dart_git') + '/http.git' + '@' + Var('dart_http_rev'),

  'engine/src/flutter/third_party/dart/third_party/pkg/i18n':
   Var('dart_git') + '/i18n.git' + '@' + Var('dart_i18n_rev'),

  'engine/src/flutter/third_party/dart/third_party/pkg/leak_tracker':
   Var('dart_git') + '/leak_tracker.git@f5620600a5ce1c44f65ddaa02001e200b096e14c',

  'engine/src/flutter/third_party/dart/third_party/pkg/native':
   Var('dart_git') + '/native.git@f1fa5be4b0d7449fa8fe4077113ac0413d2b16bf',

  'engine/src/flutter/third_party/dart/third_party/pkg/protobuf':
   Var('dart_git') + '/protobuf.git' + '@' + Var('dart_protobuf_rev'),

  'engine/src/flutter/third_party/dart/third_party/pkg/pub':
   Var('dart_git') + '/pub.git' + '@' + Var('dart_pub_rev'),

  'engine/src/flutter/third_party/dart/third_party/pkg/shelf':
   Var('dart_git') + '/shelf.git@2af8529640d10a247ebfa4e17e629a2ff5273656',

  'engine/src/flutter/third_party/dart/third_party/pkg/sync_http':
   Var('dart_git') + '/sync_http.git' + '@' + Var('dart_sync_http_rev'),

  'engine/src/flutter/third_party/dart/third_party/pkg/tar':
   Var('dart_git') + '/external/github.com/simolus3/tar.git@5a1ea943e70cdf3fa5e1102cdbb9418bd9b4b81a',

  'engine/src/flutter/third_party/dart/third_party/pkg/test':
   Var('dart_git') + '/test.git@9e349d0e9f6c477584ea320f7ba2f49f761d84ac',

  'engine/src/flutter/third_party/dart/third_party/pkg/tools':
   Var('dart_git') + '/tools.git' + '@' + Var('dart_tools_rev'),

  'engine/src/flutter/third_party/dart/third_party/pkg/vector_math':
   Var('dart_git') + '/external/github.com/google/vector_math.dart.git' + '@' + Var('dart_vector_math_rev'),

  'engine/src/flutter/third_party/dart/third_party/pkg/web':
   Var('dart_git') + '/web.git' + '@' + Var('dart_web_rev'),

  'engine/src/flutter/third_party/dart/third_party/pkg/webdev':
   Var('dart_git') + '/webdev.git' + '@' + Var('dart_webdev_rev'),

  'engine/src/flutter/third_party/dart/third_party/pkg/webdriver':
   Var('dart_git') + '/external/github.com/google/webdriver.dart.git' + '@' + Var('dart_webdriver_rev'),

  'engine/src/flutter/third_party/dart/third_party/pkg/webkit_inspection_protocol':
   Var('dart_git') + '/external/github.com/google/webkit_inspection_protocol.dart.git' + '@' + Var('dart_webkit_inspection_protocol_rev'),

  'engine/src/flutter/third_party/dart/tools/sdks/dart-sdk':
   {'dep_type': 'cipd', 'packages': [{'package': 'dart/dart-sdk/${{platform}}', 'version': 'git_revision:2d5dfe32cf2e6b3c3d6b396885502a5402b4fc72'}]},

  # WARNING: end of dart dependencies list that is cleaned up automatically - see create_updated_flutter_deps.py.

  # Prebuilt Dart SDK of the same revision as the Dart SDK source checkout
  'engine/src/flutter/prebuilts/linux-x64/dart-sdk': {
    'packages': [
      {
        'package': 'flutter/dart-sdk/linux-amd64',
        'version': 'git_revision:'+Var('dart_revision')
      }
    ],
    'dep_type': 'cipd',
    'condition': 'host_os == "linux" and download_dart_sdk'
  },
  'engine/src/flutter/prebuilts/linux-arm64/dart-sdk': {
    'packages': [
      {
        'package': 'flutter/dart-sdk/linux-arm64',
        'version': 'git_revision:'+Var('dart_revision')
      }
    ],
    'dep_type': 'cipd',
    'condition': 'host_os == "linux" and download_dart_sdk'
  },
  'engine/src/flutter/prebuilts/macos-x64/dart-sdk': {
    'packages': [
      {
        'package': 'flutter/dart-sdk/mac-amd64',
        'version': 'git_revision:'+Var('dart_revision')
      }
    ],
    'dep_type': 'cipd',
    'condition': 'host_os == "mac" and download_dart_sdk'
  },
  'engine/src/flutter/prebuilts/macos-arm64/dart-sdk': {
    'packages': [
      {
        'package': 'flutter/dart-sdk/mac-arm64',
        'version': 'git_revision:'+Var('dart_revision')
      }
    ],
    'dep_type': 'cipd',
    'condition': 'host_os == "mac" and download_dart_sdk'
  },
  'engine/src/flutter/prebuilts/windows-x64/dart-sdk': {
    'packages': [
      {
        'package': 'flutter/dart-sdk/windows-amd64',
        'version': 'git_revision:'+Var('dart_revision')
      }
    ],
    'dep_type': 'cipd',
    'condition': 'host_os == "win" and download_dart_sdk'
  },
  'engine/src/flutter/prebuilts/windows-arm64/dart-sdk': {
    'packages': [
      {
        'package': 'flutter/dart-sdk/windows-arm64',
        'version': 'git_revision:'+Var('dart_revision')
      }
    ],
    'dep_type': 'cipd',
    'condition': 'host_os == "win" and download_dart_sdk'
  },

  # esbuild download
  'engine/src/flutter/prebuilts/linux-x64/esbuild': {
    'packages': [
      {
        'package': 'flutter/tools/esbuild/linux-amd64',
        'version': Var('esbuild_version')
      }
    ],
    'dep_type': 'cipd',
    'condition': 'host_os == "linux" and download_esbuild'
  },
  'engine/src/flutter/prebuilts/macos-x64/esbuild': {
    'packages': [
      {
        'package': 'flutter/tools/esbuild/mac-amd64',
        'version': Var('esbuild_version')
      }
    ],
    'dep_type': 'cipd',
    'condition': 'host_os == "mac" and download_esbuild'
  },
  'engine/src/flutter/prebuilts/macos-arm64/esbuild': {
    'packages': [
      {
        'package': 'flutter/tools/esbuild/mac-arm64',
        'version': Var('esbuild_version')
      }
    ],
    'dep_type': 'cipd',
    'condition': 'host_os == "mac" and download_esbuild'
  },
  'engine/src/flutter/prebuilts/windows-x64/esbuild': {
    'packages': [
      {
        'package': 'flutter/tools/esbuild/windows-amd64',
        'version': Var('esbuild_version')
      }
    ],
    'dep_type': 'cipd',
    'condition': 'host_os == "win" and download_esbuild'
  },

  'engine/src/flutter/third_party/expat':
   Var('chromium_git') + '/external/github.com/libexpat/libexpat.git' + '@' + '654d2de0da85662fcc7644a7acd7c2dd2cfb21f0',

  'engine/src/flutter/third_party/freetype2':
   Var('flutter_git') + '/third_party/freetype2' + '@' + 'bfc3453fdc85d87b45c896f68bf2e49ebdaeef0a',

  'engine/src/flutter/third_party/skia':
   Var('skia_git') + '/skia.git' + '@' +  Var('skia_revision'),

  'engine/src/flutter/third_party/ocmock':
   Var('flutter_git') + '/third_party/ocmock' + '@' +  Var('ocmock_rev'),

  'engine/src/flutter/third_party/libjpeg-turbo/src':
   Var('flutter_git') + '/third_party/libjpeg-turbo' + '@' + '0fb821f3b2e570b2783a94ccd9a2fb1f4916ae9f',

  'engine/src/flutter/third_party/libpng':
   Var('flutter_git') + '/third_party/libpng' + '@' + 'de36b892e921c684ef718fec24739ae9bb49c977',

  'engine/src/flutter/third_party/libwebp':
   Var('chromium_git') + '/webm/libwebp.git' + '@' + 'ca332209cb5567c9b249c86788cb2dbf8847e760', # 1.3.2

  'engine/src/flutter/third_party/wuffs':
   Var('skia_git') + '/external/github.com/google/wuffs-mirror-release-c.git' + '@' + '600cd96cf47788ee3a74b40a6028b035c9fd6a61',

  'engine/src/flutter/third_party/zlib':
   Var('chromium_git') + '/chromium/src/third_party/zlib.git' + '@' + '7d77fb7fd66d8a5640618ad32c71fdeb7d3e02df',

  'engine/src/flutter/third_party/cpu_features/src':
   Var('chromium_git') + '/external/github.com/google/cpu_features.git' + '@' + '936b9ab5515dead115606559502e3864958f7f6e',

  'engine/src/flutter/third_party/inja':
   Var('flutter_git') + '/third_party/inja' + '@' + '88bd6112575a80d004e551c98cf956f88ff4d445',

  'engine/src/flutter/third_party/libtess2':
   Var('flutter_git') + '/third_party/libtess2' + '@' + '725e5e08ec8751477565f1d603fd7eb9058c277c',

  'engine/src/flutter/third_party/sqlite':
   Var('flutter_git') + '/third_party/sqlite' + '@' + '0f61bd2023ba94423b4e4c8cfb1a23de1fe6a21c',

  'engine/src/flutter/third_party/pyyaml':
   Var('flutter_git') + '/third_party/pyyaml.git' + '@' + '03c67afd452cdff45b41bfe65e19a2fb5b80a0e8',

  'engine/src/flutter/third_party/swiftshader':
  Var('swiftshader_git') + '/SwiftShader.git' + '@' + 'd040a5bab638bf7c226235c95787ba6288bb6416',

  'engine/src/flutter/third_party/angle':
  Var('chromium_git') + '/angle/angle.git' + '@' + '6a09e41ce6ea8c93524faae1a925eb01562f53b1',

  'engine/src/flutter/third_party/vulkan_memory_allocator':
  Var('chromium_git') + '/external/github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator' + '@' + 'c788c52156f3ef7bc7ab769cb03c110a53ac8fcb',

  'engine/src/flutter/third_party/abseil-cpp':
  Var('flutter_git') + '/third_party/abseil-cpp.git' + '@' + 'ff6504dc527b25fef0f3c531e7dba0ed6b69c162',

   # Dart packages
  'engine/src/flutter/third_party/pkg/archive':
  Var('chromium_git') + '/external/github.com/brendan-duncan/archive.git' + '@' + 'f1d164f8f5d8aea0be620a9b1e8d300b75a29388', # 3.6.1

  'engine/src/flutter/third_party/pkg/coverage':
  Var('flutter_git') + '/third_party/coverage.git' + '@' + 'bb0ab721ee4ceef1abfa413d8d6fd46013b583b9', # 1.7.2

  'engine/src/flutter/third_party/pkg/equatable':
  Var('flutter_git') + '/third_party/equatable.git' + '@' + '2117551ff3054f8edb1a58f63ffe1832a8d25623', # 2.0.5

  'engine/src/flutter/third_party/pkg/flutter_packages':
  Var('flutter_git') + '/mirrors/packages' + '@' + '25454e63851fe7933f04d025606e68c1eac4fe0f', # various

  'engine/src/flutter/third_party/pkg/gcloud':
  Var('flutter_git') + '/third_party/gcloud.git' + '@' + 'a5276b85c4714378e84b1fb478b8feeeb686ac26', # 0.8.6-dev

  'engine/src/flutter/third_party/pkg/googleapis':
  Var('flutter_git') + '/third_party/googleapis.dart.git' + '@' + '526011f56d98eab183cc6075ee1392e8303e43e2', # various

  'engine/src/flutter/third_party/pkg/io':
  Var('flutter_git') + '/third_party/io.git' + '@' + '997a6243aad20af4238147d9ec00bf638b9169af', # 1.0.5-wip

  'engine/src/flutter/third_party/pkg/node_preamble':
  Var('flutter_git') + '/third_party/node_preamble.dart.git' + '@' + '47245865175929ec452d8058e563c267b64c3d64', # 2.0.2

  'engine/src/flutter/third_party/pkg/process':
  Var('dart_git') + '/process.dart' + '@' + '0c9aeac86dcc4e3a6cf760b76fed507107e244d5', # 4.2.1

  'engine/src/flutter/third_party/pkg/process_runner':
  Var('flutter_git') + '/third_party/process_runner.git' + '@' + 'f24c69efdcaf109168f23d381fa281453d2bc9b1', # 4.1.2

  'engine/src/flutter/third_party/pkg/vector_math':
  Var('dart_git') + '/external/github.com/google/vector_math.dart.git' + '@' + '0a5fd95449083d404df9768bc1b321b88a7d2eef', # 2.1.0

  'engine/src/flutter/third_party/imgui':
  Var('flutter_git') + '/third_party/imgui.git' + '@' + '3ea0fad204e994d669f79ed29dcaf61cd5cb571d',

  'engine/src/flutter/third_party/json':
  Var('flutter_git') + '/third_party/json.git' + '@' + '17d9eacd248f58b73f4d1be518ef649fe2295642',

  'engine/src/flutter/third_party/gradle': {
    'packages': [
      {
        # See tools/gradle/README.md for update instructions.
        # Version here means the CIPD tag.
        'version': 'version:8.9',
        'package': 'flutter/gradle'
      }
    ],
    'condition': 'download_android_deps',
    'dep_type': 'cipd'
  },

  'engine/src/flutter/third_party/android_tools/trace_to_text': {
    'packages': [
      {
        # 25.0 downloads for both mac-amd64 and mac-arm64
        # 26.1 is not found with either platform
        # 27.1 is the latest release of perfetto
        'version': 'git_tag:v25.0',
        'package': 'perfetto/trace_to_text/${{platform}}'
      }
    ],
    'condition': 'download_android_deps',
    'dep_type': 'cipd'
  },

   'engine/src/flutter/third_party/android_tools/google-java-format': {
     'packages': [
       {
        'package': 'flutter/android/google-java-format',
        'version': 'version:1.7-1'
       }
     ],
     # We want to be able to format these as part of CI, and the CI step that
     # checks formatting runs without downloading the rest of the Android build
     # tooling. Therefore unlike all the other Android-related tools, we want to
     # download this every time.
     'dep_type': 'cipd',
   },

  'engine/src/flutter/third_party/android_tools': {
     'packages': [
       {
        'package': 'flutter/android/sdk/all/${{platform}}',
        'version': 'version:35v1'
       }
     ],
     'condition': 'download_android_deps',
     'dep_type': 'cipd',
   },

  'engine/src/flutter/third_party/android_embedding_dependencies': {
     'packages': [
       {
        'package': 'flutter/android/embedding_bundle',
        'version': 'last_updated:2024-09-10T16:32:16-0700'
       }
     ],
     'condition': 'download_android_deps',
     'dep_type': 'cipd',
   },

  'engine/src/flutter/third_party/java/openjdk': {
     'packages': [
       {
        'package': 'flutter/java/openjdk/${{platform}}',
        'version': 'version:17'
       }
     ],
     # Always download the JDK since java is required for running the formatter.
     'dep_type': 'cipd',
   },

  'engine/src/flutter/third_party/gn': {
    'packages': [
      {
        'package': 'gn/gn/${{platform}}',
        'version': 'git_revision:7a8aa3a08a13521336853a28c46537ec04338a2d'
      },
    ],
    'dep_type': 'cipd',
  },
  'third_party/ninja': {
    'packages': [
      {
        'package': 'infra/3pp/tools/ninja/${{platform}}',
        'version': 'version:2@1.11.1.chromium.4',
      }
    ],
    'dep_type': 'cipd',
  },

  'engine/src/flutter/prebuilts/emsdk': {
   'url': Var('skia_git') + '/external/github.com/emscripten-core/emsdk.git' + '@' + '2514ec738de72cebbba7f4fdba0cf2fabcb779a5',
   'condition': 'download_emsdk',
  },

  # Clang on mac and linux are expected to typically be the same revision.
  # They are separated out so that the autoroller can more easily manage them.
  'engine/src/flutter/buildtools/mac-x64/clang': {
    'packages': [
      {
        'package': 'fuchsia/third_party/clang/mac-amd64',
        'version': Var('clang_version'),
      }
    ],
    'condition': 'host_os == "mac"', # On ARM64 Macs too because Goma doesn't support the host-arm64 toolchain.
    'dep_type': 'cipd',
  },

  'engine/src/flutter/buildtools/mac-arm64/clang': {
    'packages': [
      {
        'package': 'fuchsia/third_party/clang/mac-arm64',
        'version': Var('clang_version'),
      }
    ],
    'condition': 'host_os == "mac" and host_cpu == "arm64"',
    'dep_type': 'cipd',
  },

  'engine/src/flutter/buildtools/linux-x64/clang': {
    'packages': [
      {
        'package': 'fuchsia/third_party/clang/linux-amd64',
        'version': Var('clang_version'),
      }
    ],
    'condition': 'host_os == "linux" or host_os == "mac"',
    'dep_type': 'cipd',
  },

  'engine/src/flutter/buildtools/linux-arm64/clang': {
    'packages': [
      {
        'package': 'fuchsia/third_party/clang/linux-arm64',
        'version': Var('clang_version'),
      }
    ],
    'condition': 'host_os == "linux" and host_cpu == "arm64"',
    'dep_type': 'cipd',
  },

  'engine/src/flutter/buildtools/windows-x64/clang': {
    'packages': [
      {
        'package': 'fuchsia/third_party/clang/windows-amd64',
        'version': Var('clang_version'),
      }
    ],
    'condition': 'download_windows_deps',
    'dep_type': 'cipd',
  },

  # RBE binaries and configs.
  'engine/src/flutter/buildtools/linux-x64/reclient': {
    'packages': [
      {
        'package': 'infra/rbe/client/${{platform}}',
        'version': Var('reclient_version'),
      }
    ],
    'condition': 'use_rbe and host_os == "linux" and host_cpu == "x64"',
    'dep_type': 'cipd',
  },

  'engine/src/flutter/buildtools/mac-arm64/reclient': {
    'packages': [
      {
        'package': 'infra/rbe/client/${{platform}}',
        'version': Var('reclient_version'),
      }
    ],
    'condition': 'use_rbe and host_os == "mac" and host_cpu == "arm64"',
    'dep_type': 'cipd',
  },

  'engine/src/flutter/buildtools/mac-x64/reclient': {
    'packages': [
      {
        'package': 'infra/rbe/client/${{platform}}',
        'version': Var('reclient_version'),
      }
    ],
    'condition': 'use_rbe and host_os == "mac" and host_cpu == "x64"',
    'dep_type': 'cipd',
  },

  'engine/src/flutter/buildtools/windows-x64/reclient': {
    'packages': [
      {
        'package': 'infra/rbe/client/${{platform}}',
        'version': Var('reclient_version'),
      }
    ],
    'condition': 'use_rbe and download_windows_deps',
    'dep_type': 'cipd',
  },

  'engine/src/flutter/build/rbe': {
    'packages': [
      {
        'package': 'flutter_internal/rbe/reclient_cfgs',
        'version': 'XIomtC8MFuQrF9qI5xYcFfcfKXZTbcY6nL6NgF-pSRIC',
      }
    ],
    'condition': 'use_rbe',
    'dep_type': 'cipd',
  },

  # gcloud
  'engine/src/flutter/buildtools/linux-x64/gcloud': {
    'packages': [
      {
        'package': 'infra/3pp/tools/gcloud/${{platform}}',
        'version': Var('gcloud_version'),
      }
    ],
    'condition': 'use_rbe and host_os == "linux" and host_cpu == "x64"',
    'dep_type': 'cipd',
  },

  'engine/src/flutter/buildtools/mac-arm64/gcloud': {
    'packages': [
      {
        'package': 'infra/3pp/tools/gcloud/${{platform}}',
        'version': Var('gcloud_version'),
      }
    ],
    'condition': 'use_rbe and host_os == "mac" and host_cpu == "arm64"',
    'dep_type': 'cipd',
  },

  # Get the SDK from https://chrome-infra-packages.appspot.com/p/fuchsia/sdk/core at the 'latest' tag
  # Get the toolchain from https://chrome-infra-packages.appspot.com/p/fuchsia/clang at the 'goma' tag
  'engine/src/fuchsia/sdk/linux': {
     'packages': [
       {
        'package': 'fuchsia/sdk/core/linux-amd64',
        'version': 'Aewmpu7l_HniO7aKQldIrIe8ot5iXBrIwjj5NKF1uRwC'
       }
     ],
     'condition': 'download_fuchsia_deps and not download_fuchsia_sdk',
     'dep_type': 'cipd',
   },

  'engine/src/flutter/tools/fuchsia/test_scripts': {
     'packages': [
       {
        'package': 'chromium/fuchsia/test-scripts',
        'version': Var('fuchsia_test_scripts_version'),
       }
     ],
     'condition': 'download_fuchsia_deps',
     'dep_type': 'cipd',
   },

  'engine/src/flutter/tools/fuchsia/gn-sdk': {
     'packages': [
       {
        'package': 'chromium/fuchsia/gn-sdk',
        'version': Var('fuchsia_gn_sdk_version'),
       }
     ],
     'condition': 'download_fuchsia_deps',
     'dep_type': 'cipd',
   },

  'engine/src/flutter/third_party/impeller-cmake-example': {
     'url': Var('flutter_git') + '/third_party/impeller-cmake-example.git' + '@' + '9f8298ec31dcbebbf019bd487888166abf2f55e6',
     'condition': 'download_impeller_cmake_example',
  },

  # cmake is only used by impeller-cmake-example.
  'engine/src/flutter/buildtools/mac-x64/cmake': {
    'packages': [
      {
        'package': 'infra/3pp/tools/cmake/mac-amd64',
        'version': 'CGpMvZoP962wdEINR9d4OEvEW7ZOv0MPrHNKbBUBS0sC',
      }
    ],
    'condition': 'download_impeller_cmake_example and host_os == "mac"',
    'dep_type': 'cipd',
  },

  'engine/src/flutter/third_party/google_fonts_for_unit_tests': {
      'packages': [
        {
          'package': 'flutter/flutter_font_fallbacks',
          'version': '44bd38be0bc8c189a397ca6dd6f737746a9e0c6117b96a8f84f1edf6acd1206b'
        }
      ],
      'dep_type': 'cipd',
  }
}

recursedeps = [
  'engine/src/flutter/third_party/vulkan-deps',
]

hooks = [
  {
    # Generate the Dart SDK's .dart_tool/package_confg.json file.
    'name': 'Generate .dart_tool/package_confg.json',
    'pattern': '.',
    'action': ['python3', 'engine/src/flutter/third_party/dart/tools/generate_package_config.py'],
  },
  {
    # Generate the sdk/version file.
    'name': 'Generate sdk/version',
    'pattern': '.',
    'action': ['python3', 'engine/src/flutter/third_party/dart/tools/generate_sdk_version_file.py'],
  },
  {
    # Update the Windows toolchain if necessary.
    'name': 'win_toolchain',
    'condition': 'download_windows_deps',
    'pattern': '.',
    'action': ['python3', 'engine/src/build/vs_toolchain.py', 'update'],
  },
  {
    'name': 'dia_dll',
    'pattern': '.',
    'condition': 'download_windows_deps',
    'action': [
      'python3',
      'engine/src/flutter/tools/dia_dll.py',
    ],
  },
  {
    'name': 'linux_sysroot_x64',
    'pattern': '.',
    'condition': 'download_linux_deps',
    'action': [
      'python3',
      'engine/src/build/linux/sysroot_scripts/install-sysroot.py',
      '--arch=x64'],
  },
  {
    'name': 'linux_sysroot_arm64',
    'pattern': '.',
    'condition': 'download_linux_deps',
    'action': [
      'python3',
      'engine/src/build/linux/sysroot_scripts/install-sysroot.py',
      '--arch=arm64'],
  },
  {
    'name': 'pub get --offline',
    'pattern': '.',
    'action': [
      'python3',
      'engine/src/flutter/tools/pub_get_offline.py',
    ]
  },
  {
    'name': 'Download Fuchsia SDK',
    'pattern': '.',
    'condition': 'download_fuchsia_deps and download_fuchsia_sdk',
    'action': [
      'python3',
      'engine/src/flutter/tools/download_fuchsia_sdk.py',
      '--fail-loudly',
      '--verbose',
      '--host-os',
      Var('host_os'),
      '--fuchsia-sdk-path',
      Var('fuchsia_sdk_path'),
    ]
  },
  {
    'name': 'Activate Emscripten SDK',
    'pattern': '.',
    'condition': 'download_emsdk',
    'action': [
      'python3',
      'engine/src/flutter/tools/activate_emsdk.py',
    ]
  },
  {
    'name': 'Setup githooks',
    'pattern': '.',
    'condition': 'setup_githooks',
    'action': [
      'python3',
      'engine/src/flutter/tools/githooks/setup.py',
    ]
  },
  {
    'name': 'impeller-cmake-example submodules',
    'pattern': '.',
    'condition': 'download_impeller_cmake_example',
    'action': [
      'python3',
      'engine/src/flutter/ci/impeller_cmake_build_test.py',
      '--path',
      'flutter/third_party/impeller-cmake-example',
      '--setup',
    ]
  },
  {
    'name': 'Download Fuchsia system images',
    'pattern': '.',
    'condition': 'run_fuchsia_emu',
    'action': [
      'env',
      'DOWNLOAD_FUCHSIA_SDK={download_fuchsia_sdk}',
      'FUCHSIA_SDK_PATH={fuchsia_sdk_path}',
      'python3',
      'engine/src/flutter/tools/fuchsia/with_envs.py',
      'engine/src/flutter/tools/fuchsia/test_scripts/update_product_bundles.py',
      'terminal.x64,terminal.qemu-arm64',
    ]
  },
  # The following two scripts check if they are running in the LUCI
  # environment, and do nothing if so. This is because Xcode is not yet
  # installed in CI when these hooks are run.
  {
    'name': 'Find the iOS device SDKs',
    'pattern': '.',
    'condition': 'host_os == "mac"',
    'action': [
      'python3',
      'engine/src/build/config/ios/ios_sdk.py',
      # This cleans up entries under flutter/prebuilts for this script and the
      # following script.
      '--as-gclient-hook'
    ]
  },
  {
    'name': 'Find the macOS SDK',
    'pattern': '.',
    'condition': 'host_os == "mac"',
    'action': [
      'python3',
      'engine/src/build/mac/find_sdk.py',
      '--as-gclient-hook',
      Var('mac_sdk_min')
    ]
  },
  {
    'name': 'Generate Fuchsia GN build rules',
    'pattern': '.',
    'condition': 'download_fuchsia_deps',
    'action': [
      'python3',
      'engine/src/flutter/tools/fuchsia/with_envs.py',
      'engine/src/flutter/tools/fuchsia/test_scripts/gen_build_defs.py',
    ],
  },
]
