import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String gradle;
  late String manifest;
  late String mainActivity;
  late String dartService;
  late String nativeSources;

  setUpAll(() {
    gradle = File('android/app/build.gradle.kts').readAsStringSync();
    manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    mainActivity = File(
      'android/app/src/main/kotlin/org/safemyanmar/mobile/MainActivity.kt',
    ).readAsStringSync();
    dartService = File(
      'lib/core/ai/native_ai_platform_service.dart',
    ).readAsStringSync();
    nativeSources =
        Directory('android/app/src/main/kotlin/org/safemyanmar/mobile/ai')
            .listSync()
            .whereType<File>()
            .map((file) => file.readAsStringSync())
            .join();
  });

  test('pins both native runtimes without floating selectors', () {
    expect(
      gradle,
      contains('com.microsoft.onnxruntime:onnxruntime-android:1.27.0'),
    );
    expect(
      gradle,
      contains('com.google.ai.edge.litertlm:litertlm-android:0.14.0'),
    );
    expect(gradle, isNot(contains('latest.')));
    expect(gradle, isNot(contains(':+')));
  });

  test('declares accelerator libraries as optional', () {
    expect(
      manifest,
      contains(
        '<uses-native-library android:name="libvndksupport.so" '
        'android:required="false"/>',
      ),
    );
    expect(
      manifest,
      contains(
        '<uses-native-library android:name="libOpenCL.so" '
        'android:required="false"/>',
      ),
    );
  });

  test('uses one fixed channel and the required narrow operations', () {
    const channel = 'org.safemyanmar.mobile/ai';
    expect(mainActivity, contains('NativeAiBridge.CHANNEL_NAME'));
    expect(nativeSources, contains('CHANNEL_NAME = "$channel"'));
    expect(dartService, contains("channelName = '$channel'"));
    for (final operation in [
      'capabilities',
      'classifyIntent',
      'initializeGemma',
      'rewriteVerifiedContent',
      'cancel',
      'dispose',
    ]) {
      expect(nativeSources, contains('"$operation"'));
    }
    expect(nativeSources, isNot(contains('EventChannel')));
  });

  test('contains no network client, credentials, or content logging', () {
    expect(nativeSources, isNot(contains('java.net')));
    expect(nativeSources, isNot(contains('http://')));
    expect(nativeSources, isNot(contains('https://')));
    expect(nativeSources.toLowerCase(), isNot(contains('api_key')));
    expect(nativeSources.toLowerCase(), isNot(contains('secret=')));
    expect(nativeSources, isNot(contains('Log.')));
    expect(nativeSources, isNot(contains('println(')));
    expect(nativeSources, isNot(contains('printStackTrace')));
  });

  test('native shutdown is asynchronous and activity teardown never waits', () {
    expect(nativeSources, isNot(contains('runBlocking')));
    expect(mainActivity, contains('aiBridge?.shutdownAsync()'));
    expect(mainActivity, isNot(contains('aiBridge?.close()')));
    expect(nativeSources, contains('fun shutdownAsync(): Job'));
    expect(
      nativeSources,
      contains('activeOperation.getAndSet(null)?.cancel()'),
    );
  });

  test('Gemma creates and closes a fresh conversation for every rewrite', () {
    expect(nativeSources, contains('activeEngine.createConversation'));
    expect(nativeSources, contains('closeConversation(conversation)'));
    expect(
      nativeSources,
      contains('activeConversation.compareAndSet(null, conversation)'),
    );
    expect(
      RegExp(
        r'private\s+var\s+conversation\s*:\s*Conversation',
      ).hasMatch(nativeSources),
      isFalse,
    );
  });

  test(
    'native Gemma defense blocks all critical English and Burmese terms',
    () {
      for (final term in [
        'trapped_person',
        'first_aid',
        'send_sos',
        'safe_route',
        'bleeding',
        'safer route',
        'ပိတ်မိ',
        'သွေးထွက်',
        'အရေးပေါ်စာ',
        'ဘေးကင်းတဲ့လမ်း',
      ]) {
        expect(nativeSources, contains('"$term"'), reason: term);
      }
    },
  );

  test('uses fixed private artifacts and validated metadata contracts', () {
    expect(nativeSources, contains('File(context.filesDir, "ai")'));
    expect(nativeSources, contains('"intent_classifier.onnx"'));
    expect(nativeSources, contains('"intent_classifier.json"'));
    expect(nativeSources, contains('"gemma3-1b-it-int4.litertlm"'));
    expect(nativeSources, contains('"gemma3-1b-it-int4.json"'));
    expect(nativeSources, contains('"normalized_bag_of_words_v1"'));
    expect(nativeSources, contains('"probabilities_v1"'));
    expect(nativeSources, contains('MessageDigest.getInstance("SHA-256")'));
    expect(nativeSources, contains('json.getInt("schemaVersion") != 1'));
  });

  test('does not bundle model artifacts or add download permissions', () {
    final sourceRoots = [Directory('lib'), Directory('android/app/src')];
    final modelFiles = sourceRoots
        .expand((root) => root.listSync(recursive: true))
        .whereType<File>()
        .where(
          (file) => RegExp(
            r'\.(onnx|ort|litertlm|tflite)$',
            caseSensitive: false,
          ).hasMatch(file.path),
        );
    expect(modelFiles, isEmpty);
    expect(manifest, isNot(contains('REQUEST_INSTALL_PACKAGES')));
    expect(manifest, isNot(contains('WRITE_EXTERNAL_STORAGE')));
    expect(manifest, isNot(contains('MANAGE_EXTERNAL_STORAGE')));
  });
}
