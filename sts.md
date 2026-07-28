12:08:08.298	Cloning repository...
12:08:09.361	From https://github.com/Pgarut/ppi
12:08:09.362	 * branch            338f2114abc48511659974412d53975dd71079e7 -> FETCH_HEAD
12:08:09.362	
12:08:09.393	HEAD is now at 338f211 fix: use correct CLOUDFLARE_API_TOKEN env var for wrangler pages deploy
12:08:09.393	
12:08:09.439	
12:08:09.440	Using v2 root directory strategy
12:08:09.452	Success: Finished cloning repository files
12:08:10.868	Checking for configuration in a Wrangler configuration file (BETA)
12:08:10.869	
12:08:11.019	No Wrangler configuration file found. Continuing.
12:08:11.188	Detected the following tools from environment: 
12:08:11.189	Executing user command: git clone https://github.com/flutter/flutter.git --depth 1 -b stable && export PATH="$PATH:$PWD/flutter/bin" && flutter config --enable-web && cd frontend && flutter pub get && flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL
12:08:11.196	Cloning into 'flutter'...
12:08:14.200	Updating files:  85% (13416/15665)
Updating files:  86% (13472/15665)
Updating files:  87% (13629/15665)
Updating files:  88% (13786/15665)
Updating files:  89% (13942/15665)
Updating files:  90% (14099/15665)
Updating files:  91% (14256/15665)
Updating files:  92% (14412/15665)
Updating files:  93% (14569/15665)
Updating files:  94% (14726/15665)
Updating files:  95% (14882/15665)
Updating files:  96% (15039/15665)
Updating files:  97% (15196/15665)
Updating files:  98% (15352/15665)
Updating files:  99% (15509/15665)
Updating files: 100% (15665/15665)
Updating files: 100% (15665/15665), done.
12:08:14.270	Downloading Linux x64 Dart SDK from Flutter engine 0cd610717bde95fd88343c64f81c11ba4e5c0010...
12:08:14.283	  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
12:08:14.283	                                 Dload  Upload   Total   Spent    Left  Speed
12:08:18.230	
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
 17  222M   17 37.9M    0     0  46.8M      0  0:00:04 --:--:--  0:00:04 46.8M
 42  222M   42 95.3M    0     0  52.6M      0  0:00:04  0:00:01  0:00:03 52.6M
 69  222M   69  154M    0     0  55.0M      0  0:00:04  0:00:02  0:00:02 55.0M
 96  222M   96  214M    0     0  56.2M      0  0:00:03  0:00:03 --:--:-- 56.2M
100  222M  100  222M    0     0  56.3M      0  0:00:03  0:00:03 --:--:-- 56.3M
12:08:24.024	Building flutter tool...
12:08:24.049	Resolving dependencies...
12:08:24.926	Downloading packages...
12:08:28.166	+ _fe_analyzer_shared 95.0.0 (105.0.0 available)
12:08:28.166	+ analyzer 10.1.0 (14.1.0 available)
12:08:28.167	+ archive 3.6.1 (4.0.9 available)
12:08:28.167	+ args 2.7.0
12:08:28.167	+ async 2.13.1
12:08:28.167	+ boolean_selector 2.1.2
12:08:28.167	+ browser_launcher 1.1.3
12:08:28.167	+ built_collection 5.1.1
12:08:28.167	+ built_value 8.12.5 (8.12.6 available)
12:08:28.167	+ checked_yaml 2.0.4
12:08:28.167	+ cli_config 0.2.0
12:08:28.167	+ clock 1.1.2
12:08:28.167	+ code_assets 1.0.0 (1.2.1 available)
12:08:28.167	+ code_builder 4.11.1
12:08:28.167	+ collection 1.19.1
12:08:28.168	+ completion 1.0.2
12:08:28.168	+ convert 3.1.2
12:08:28.168	+ coverage 1.15.0 (1.15.1 available)
12:08:28.168	+ crypto 3.0.7
12:08:28.168	+ csslib 1.0.2
12:08:28.168	+ dap 1.4.0
12:08:28.168	+ dart_service_protocol_shared 0.0.3
12:08:28.168	+ dart_style 3.1.7 (3.1.12 available)
12:08:28.168	+ data_assets 0.19.6 (0.20.0 available)
12:08:28.168	+ dds 5.3.0 (5.4.0 available)
12:08:28.168	+ dds_service_extensions 2.1.0
12:08:28.168	+ devtools_shared 12.1.0 (14.0.0 available)
12:08:28.168	+ dtd 4.0.0
12:08:28.169	+ dwds 26.2.5 (27.1.2 available)
12:08:28.170	+ extension_discovery 2.1.0
12:08:28.170	+ fake_async 1.3.3
12:08:28.170	+ ffi 2.2.0
12:08:28.170	+ file 7.0.1
12:08:28.170	+ file_testing 3.0.2
12:08:28.171	+ fixnum 1.1.1
12:08:28.171	+ flutter_template_images 5.0.0 (5.0.1 available)
12:08:28.171	+ frontend_server_client 4.0.0
12:08:28.171	+ glob 2.1.3
12:08:28.171	+ graphs 2.3.2
12:08:28.171	+ hooks 1.0.2 (2.1.0 available)
12:08:28.171	+ hooks_runner 1.1.1 (1.6.1 available)
12:08:28.171	+ html 0.15.6
12:08:28.172	+ http 1.6.0
12:08:28.172	+ http_multi_server 3.2.2
12:08:28.172	+ http_parser 4.1.2
12:08:28.172	+ intl 0.20.2 (0.20.3 available)
12:08:28.172	+ io 1.0.5
12:08:28.172	+ js 0.7.2 (discontinued)
12:08:28.172	+ json_annotation 4.11.0 (4.12.0 available)
12:08:28.172	+ json_rpc_2 4.1.0
12:08:28.173	+ logging 1.3.0
12:08:28.173	+ matcher 0.12.19 (0.12.20 available)
12:08:28.173	+ meta 1.18.0 (1.19.0 available)
12:08:28.173	+ mime 2.0.0
12:08:28.173	+ multicast_dns 0.3.3 (0.3.3+1 available)
12:08:28.173	+ mustache_template 2.0.4 (2.0.5 available)
12:08:28.173	+ native_stack_traces 0.6.1
12:08:28.174	+ node_preamble 2.0.2
12:08:28.174	+ package_config 2.2.0 (3.0.0 available)
12:08:28.174	+ path 1.9.1
12:08:28.175	+ petitparser 7.0.2
12:08:28.175	+ platform 3.1.6
12:08:28.175	+ pool 1.5.2
12:08:28.175	+ process 5.0.5
12:08:28.175	+ pub_semver 2.2.0
12:08:28.175	+ pubspec_parse 1.5.0
12:08:28.175	+ record_use 0.6.0 (1.0.0 available)
12:08:28.176	+ shelf 1.4.2
12:08:28.176	+ shelf_packages_handler 3.0.2
12:08:28.176	+ shelf_proxy 1.0.4 (1.0.5 available)
12:08:28.176	+ shelf_static 1.1.3
12:08:28.176	+ shelf_web_socket 3.0.0
12:08:28.176	+ source_map_stack_trace 2.1.2
12:08:28.176	+ source_maps 0.10.13
12:08:28.176	+ source_span 1.10.2
12:08:28.176	+ sprintf 7.0.0
12:08:28.176	+ sse 4.1.8 (4.2.0 available)
12:08:28.177	+ stack_trace 1.12.1
12:08:28.177	+ standard_message_codec 0.0.1+4 (0.0.1+5 available)
12:08:28.177	+ stream_channel 2.1.4
12:08:28.177	+ string_scanner 1.4.1
12:08:28.177	+ sync_http 0.3.1
12:08:28.177	+ term_glyph 1.2.2
12:08:28.177	+ test 1.31.0 (1.31.2 available)
12:08:28.177	+ test_api 0.7.11 (0.7.13 available)
12:08:28.177	+ test_core 0.6.17 (0.6.19 available)
12:08:28.177	+ typed_data 1.4.0
12:08:28.177	+ unified_analytics 8.0.14 (8.0.16 available)
12:08:28.177	+ usage 4.1.1 (discontinued)
12:08:28.177	+ uuid 4.5.3 (4.6.0 available)
12:08:28.177	+ vm_service 15.0.2 (15.2.0 available)
12:08:28.177	+ vm_service_interface 2.0.1
12:08:28.177	+ vm_snapshot_analysis 0.7.6
12:08:28.177	+ watcher 1.2.1
12:08:28.178	+ web 1.1.1
12:08:28.178	+ web_socket 1.0.1
12:08:28.178	+ web_socket_channel 3.0.3
12:08:28.178	+ webdriver 3.1.0
12:08:28.178	+ webkit_inspection_protocol 1.2.1
12:08:28.178	+ xml 6.6.1 (7.0.1 available)
12:08:28.178	+ yaml 3.1.3
12:08:28.178	+ yaml_edit 2.2.4
12:08:28.178	Changed 102 dependencies!
12:08:28.178	2 packages are discontinued.
12:08:28.178	32 packages have newer versions incompatible with dependency constraints.
12:08:28.178	Try `dart pub outdated` for more information.
12:08:52.200	Setting "enable-web" value to "true".
12:08:52.200	
12:08:52.201	You may need to restart any open editors for them to read new settings.
12:08:52.540	[1/10] Material Fonts                                              172ms
12:08:52.604	[2/10] Gradle Wrapper                                                9ms
12:08:52.626	[3/10] Flutter SDK
12:08:52.717	  ├─ [1/5] sky_engine                                               82ms
12:08:52.811	  ├─ [2/5] flutter_gpu                                               7ms
12:08:52.973	  ├─ [3/5] flutter_patched_sdk                                     146ms
12:08:53.221	  ├─ [4/5] flutter_patched_sdk_product                             151ms
12:08:54.290	  └─ [5/5] linux-x64                                               964ms
12:08:55.285	[10/10] linux-x64/font-subset                                      279ms
12:08:55.522	Resolving dependencies...
12:08:56.339	Downloading packages...
12:08:59.424	  async 2.13.0 (2.13.1 available)
12:08:59.425	> characters 1.4.1 (was 1.4.0)
12:08:59.425	  cross_file 0.3.5+2 (0.3.5+4 available)
12:08:59.425	  file_picker 8.3.7 (11.0.2 available)
12:08:59.425	  flutter_lints 5.0.0 (6.0.0 available)
12:08:59.425	  flutter_plugin_android_lifecycle 2.0.31 (2.0.35 available)
12:08:59.425	  google_fonts 6.3.2 (8.2.0 available)
12:08:59.425	  intl 0.19.0 (0.20.3 available)
12:08:59.425	> leak_tracker 11.0.2 (was 10.0.9)
12:08:59.426	> leak_tracker_flutter_testing 3.0.10 (was 3.0.9)
12:08:59.426	> leak_tracker_testing 3.0.2 (was 3.0.1)
12:08:59.426	  lints 5.1.1 (6.1.0 available)
12:08:59.426	> matcher 0.12.19 (was 0.12.17) (0.12.20 available)
12:08:59.426	> material_color_utilities 0.13.0 (was 0.11.1)
12:08:59.427	> meta 1.18.0 (was 1.16.0) (1.19.0 available)
12:08:59.427	  path_provider 2.1.5 (2.1.6 available)
12:08:59.427	  path_provider_android 2.2.19 (2.3.1 available)
12:08:59.427	  path_provider_foundation 2.4.2 (2.6.0 available)
12:08:59.427	  path_provider_linux 2.2.1 (2.2.2 available)
12:08:59.428	  path_provider_platform_interface 2.1.2 (2.1.3 available)
12:08:59.428	  shared_preferences 2.5.3 (2.5.5 available)
12:08:59.428	  shared_preferences_android 2.4.13 (2.4.27 available)
12:08:59.428	  shared_preferences_foundation 2.5.4 (2.5.6 available)
12:08:59.428	  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
12:08:59.428	  source_span 1.10.1 (1.10.2 available)
12:08:59.429	> test_api 0.7.11 (was 0.7.4) (0.7.13 available)
12:08:59.430	> vector_math 2.2.0 (was 2.1.4) (2.4.1 available)
12:08:59.430	  vm_service 15.0.0 (15.2.0 available)
12:08:59.430	  win32 5.15.0 (6.3.0 available)
12:08:59.430	Changed 9 dependencies!
12:08:59.431	24 packages have newer versions incompatible with dependency constraints.
12:08:59.431	Try `flutter pub outdated` for more information.
12:09:01.040	[1/1] Web SDK                                                    1,135ms
12:09:37.997	Compiling lib/main.dart for the Web...                          
12:09:37.999	Wasm dry run findings:
12:09:37.999	Found incompatibilities with WebAssembly.
12:09:37.999	
12:09:37.999	package:ppi_frontend/features/admin/master_data/master_data_page.dart 2:1 - dart:html unsupported (0)
12:09:38.000	package:ppi_frontend/features/admin/pengaturan/pengaturan_page.dart 2:1 - dart:html unsupported (0)
12:09:38.000	
12:09:38.000	Consider addressing these issues to enable wasm builds. See docs for more info: https://docs.flutter.dev/platform-integration/web/wasm
12:09:38.000	
12:09:38.004	Use --no-wasm-dry-run to disable these warnings.
12:09:38.010	Target dart2js failed: ProcessException: Process exited abnormally with exit code 1:
12:09:38.011	lib/core/theme/app_theme.dart:115:31:
12:09:38.011	Error: Method not found: 'CupertinoPageTransitionsBuilder'.
12:09:38.011	          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
12:09:38.011	                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
12:09:38.011	Error: Compilation failed.
12:09:38.011	  Command: /opt/buildhome/repo/flutter/bin/cache/dart-sdk/bin/dart compile js --platform-binaries=/opt/buildhome/repo/flutter/bin/cache/flutter_web_sdk/kernel --invoker=flutter_tool -Ddart.vm.product=true -DAPI_BASE_URL= -DFLUTTER_VERSION=3.44.8 -DFLUTTER_CHANNEL=stable -DFLUTTER_GIT_URL=https://github.com/flutter/flutter.git -DFLUTTER_FRAMEWORK_REVISION=058e0af2c2 -DFLUTTER_ENGINE_REVISION=0cd610717b -DFLUTTER_DART_VERSION=3.12.2 -DFLUTTER_WEB_USE_SKIA=true -DFLUTTER_WEB_USE_SKWASM=false -DFLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/0cd610717bde95fd88343c64f81c11ba4e5c0010/ --native-null-assertions --no-source-maps -O4 --minify -o /opt/buildhome/repo/frontend/.dart_tool/flutter_build/ab7d5e87594190d34e5c531e8b172922/app.dill --packages=/opt/buildhome/repo/frontend/.dart_tool/package_config.json --cfe-only /opt/buildhome/repo/frontend/.dart_tool/flutter_build/ab7d5e87594190d34e5c531e8b172922/main.dart
12:09:38.011	#0      RunResult.throwException (package:flutter_tools/src/base/process.dart:153:5)
12:09:38.011	#1      _DefaultProcessUtils.run (package:flutter_tools/src/base/process.dart:379:19)
12:09:38.011	<asynchronous suspension>
12:09:38.011	#2      Dart2JSTarget.build (package:flutter_tools/src/build_system/targets/web.dart:208:5)
12:09:38.011	<asynchronous suspension>
12:09:38.011	#3      _BuildInstance._invokeInternal (package:flutter_tools/src/build_system/build_system.dart:937:9)
12:09:38.011	<asynchronous suspension>
12:09:38.011	#4      Future.wait.<anonymous closure> (dart:async/future.dart:546:21)
12:09:38.012	<asynchronous suspension>
12:09:38.012	#5      _BuildInstance.invokeTarget (package:flutter_tools/src/build_system/build_system.dart:875:32)
12:09:38.012	<asynchronous suspension>
12:09:38.012	#6      Future.wait.<anonymous closure> (dart:async/future.dart:546:21)
12:09:38.012	<asynchronous suspension>
12:09:38.012	#7      _BuildInstance.invokeTarget (package:flutter_tools/src/build_system/build_system.dart:875:32)
12:09:38.012	<asynchronous suspension>
12:09:38.012	#8      FlutterBuildSystem.build (package:flutter_tools/src/build_system/build_system.dart:684:16)
12:09:38.012	<asynchronous suspension>
12:09:38.012	#9      WebBuilder.buildWeb (package:flutter_tools/src/web/compile.dart:107:34)
12:09:38.012	<asynchronous suspension>
12:09:38.012	#10     BuildWebCommand.runCommand (package:flutter_tools/src/commands/build_web.dart:293:5)
12:09:38.012	<asynchronous suspension>
12:09:38.012	#11     FlutterCommand.run.<anonymous closure> (package:flutter_tools/src/runner/flutter_command.dart:1630:27)
12:09:38.012	<asynchronous suspension>
12:09:38.012	#12     AppContext.run.<anonymous closure> (package:flutter_tools/src/base/context.dart:154:19)
12:09:38.012	<asynchronous suspension>
12:09:38.012	#13     CommandRunner.runCommand (package:args/command_runner.dart:212:13)
12:09:38.012	<asynchronous suspension>
12:09:38.013	#14     FlutterCommandRunner.runCommand.<anonymous closure> (package:flutter_tools/src/runner/flutter_command_runner.dart:496:9)
12:09:38.013	<asynchronous suspension>
12:09:38.013	#15     AppContext.run.<anonymous closure> (package:flutter_tools/src/base/context.dart:154:19)
12:09:38.013	<asynchronous suspension>
12:09:38.013	#16     FlutterCommandRunner.runCommand (package:flutter_tools/src/runner/flutter_command_runner.dart:431:5)
12:09:38.013	<asynchronous suspension>
12:09:38.013	#17     FlutterCommandRunner.run.<anonymous closure> (package:flutter_tools/src/runner/flutter_command_runner.dart:307:33)
12:09:38.013	<asynchronous suspension>
12:09:38.013	#18     run.<anonymous closure>.<anonymous closure> (package:flutter_tools/runner.dart:104:11)
12:09:38.013	<asynchronous suspension>
12:09:38.013	#19     AppContext.run.<anonymous closure> (package:flutter_tools/src/base/context.dart:154:19)
12:09:38.013	<asynchronous suspension>
12:09:38.013	#20     main (package:flutter_tools/executable.dart:103:3)
12:09:38.013	<asynchronous suspension>
12:09:38.013	
12:09:38.013	Compiling lib/main.dart for the Web...                             36.0s
12:09:38.022	Error: Failed to compile application for the Web.
12:09:38.034	Failed: Error while executing user command. Exited with error code: 1
12:09:38.040	Failed: build command exited with code: 1
12:09:38.685	Failed: error occurred while running build command