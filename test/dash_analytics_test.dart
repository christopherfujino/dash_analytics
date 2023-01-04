import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

import 'package:dash_analytics/dash_analytics.dart';
import 'package:dash_analytics/src/config_handler.dart';

void main() {
  late FileSystem fs;
  late Directory home;
  late Directory dartToolDirectory;
  late Analytics analytics;
  late ConfigHandler configHandler;

  const String initialToolName = 'initialTool';
  const String secondTool = 'newTool';
  const String measurementId = 'measurementId';
  const String apiSecret = 'apiSecret';
  const int toolsMessageVersion = 1;
  const String toolsMessage = 'toolsMessage';
  const String branch = 'branch';
  const String flutterVersion = 'flutterVersion';
  const String dartVersion = 'dartVersion';

  setUp(() {
    // Setup the filesystem with the home directory
    fs = MemoryFileSystem();
    home = fs.directory('home');
    dartToolDirectory = home.childDirectory('.dart-tool');

    analytics = Analytics.test(
      tool: initialToolName,
      homeDirectory: home,
      measurementId: measurementId,
      apiSecret: apiSecret,
      toolsMessageVersion: toolsMessageVersion,
      toolsMessage: toolsMessage,
      branch: branch,
      flutterVersion: flutterVersion,
      dartVersion: dartVersion,
      fs: fs,
    );
  });

  test('Initializer properly sets up on first run', () {
    // The 3 files that should have been generated
    final File clientIdFile =
        home.childDirectory('.dart-tool').childFile('CLIENT_ID');
    final File sessionFile =
        home.childDirectory('.dart-tool').childFile('session.json');
    final File configFile = home
        .childDirectory('.dart-tool')
        .childFile('dart-flutter-telemetry.config');

    expect(clientIdFile.existsSync(), true,
        reason: 'The CLIENT_ID file was not found');
    expect(sessionFile.existsSync(), true,
        reason: 'The session.json file was not found');
    expect(configFile.existsSync(), true,
        reason: 'The dart-flutter-telemetry.config was not found');
    expect(dartToolDirectory.listSync().length, equals(3),
        reason: 'There should only be 3 files in the .dart-tool directory');
    expect(analytics.shouldShowMessage, true,
        reason: 'For the first run, analytics should default to being enabled');
  });

  test('New tool is successfully added to config file', () {
    // Create a new instance of the analytics class with the new tool
    final Analytics secondAnalytics = Analytics.test(
      tool: secondTool,
      homeDirectory: home,
      measurementId: 'measurementId',
      apiSecret: 'apiSecret',
      toolsMessageVersion: 1,
      toolsMessage: 'flutterToolsMessage',
      branch: 'ey-test-branch',
      flutterVersion: 'Flutter 3.6.0-7.0.pre.47',
      dartVersion: 'Dart 2.19.0',
      fs: fs,
    );

    // Access the config handler specifically to check adding a tool was
    // was successful, this class will not be available for importing however
    configHandler = ConfigHandler(fs: fs, homeDirectory: home);

    expect(configHandler.parsedTools.length, equals(2),
        reason: 'There should be only 2 tools that have '
            'been parsed into the config file');
    expect(configHandler.parsedTools.containsKey(initialToolName), true,
        reason: 'The first tool: $initialToolName should be in the map');
    expect(configHandler.parsedTools.containsKey(secondTool), true,
        reason: 'The second tool: $secondAnalytics should be in the map');
  });

  test('Toggling telemetry boolean through Analytics class api', () {
    expect(analytics.telemetryEnabled, true,
        reason: 'Telemetry should be enabled by default '
            'when initialized for the first time');

    // Use the API to disable analytics
    analytics.enableTelemetry(false);
    expect(analytics.telemetryEnabled, false,
        reason: 'Analytics telemetry should be disabled');

    // Toggle it back to being enabled
    analytics.enableTelemetry(true);
    expect(analytics.telemetryEnabled, true,
        reason: 'Analytics telemetry should be enabled');
  });

  test(
      'Telemetry has been disabled by one '
      'tool and second tool correctly shows telemetry is disabled', () {
    // Use the API to disable analytics
    analytics.enableTelemetry(false);
    expect(analytics.telemetryEnabled, false,
        reason: 'Analytics telemetry should be disabled');

    // Initialize a second analytics class, which simulates a second tool
    // Create a new instance of the analytics class with the new tool
    final Analytics secondAnalytics = Analytics.test(
      tool: secondTool,
      homeDirectory: home,
      measurementId: 'measurementId',
      apiSecret: 'apiSecret',
      toolsMessageVersion: 1,
      toolsMessage: 'flutterToolsMessage',
      branch: 'ey-test-branch',
      flutterVersion: 'Flutter 3.6.0-7.0.pre.47',
      dartVersion: 'Dart 2.19.0',
      fs: fs,
    );

    expect(secondAnalytics.telemetryEnabled, false,
        reason: 'Analytics telemetry should be disabled by the first class '
            'and the second class should show telemetry is disabled');
  });

  // TODO: add a test to check that the tool is correctly adding a new line
  //  character at the end of the config file if it was missing one
}
