// Run once after `flutter create`:  dart run tools/patch_android.dart
// Sets the app name (Ember Legion) and locks the main activity to landscape.
import 'dart:io';

void main() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    stderr.writeln(
      'android/app/src/main/AndroidManifest.xml not found. Run `flutter create` first.',
    );
    exit(1);
  }
  var xml = file.readAsStringSync();

  xml = xml.replaceFirst(
    RegExp(r'android:label="[^"]*"'),
    'android:label="Ember Legion"',
  );

  if (!xml.contains('android:screenOrientation')) {
    final activity = RegExp(r'android:name="\.MainActivity"');
    if (!activity.hasMatch(xml)) {
      stderr.writeln(
        'Could not find MainActivity in the manifest; add android:screenOrientation="sensorLandscape" manually.',
      );
      exit(2);
    }
    xml = xml.replaceFirst(
      activity,
      'android:name=".MainActivity"\n            android:screenOrientation="sensorLandscape"',
    );
  }
  file.writeAsStringSync(xml);
  stdout.writeln('AndroidManifest.xml patched (label + sensorLandscape).');
}
