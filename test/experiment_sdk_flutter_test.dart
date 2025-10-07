import 'dart:io';

import 'package:experiment_sdk_flutter/local_storage.dart';
import 'package:experiment_sdk_flutter/types/experiment_config.dart';
import 'package:experiment_sdk_flutter/types/experiment_expose_tracking_context.dart';
import 'package:experiment_sdk_flutter/types/experiment_exposure_tracking_provider.dart';
import 'package:experiment_sdk_flutter/types/experiment_variant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:experiment_sdk_flutter/experiment_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomBindings extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

class MockedTracker implements ExperimentExposureTrackingProvider {
  late int result;

  @override
  Future<void> exposure(
      String flagkey, ExperimentVariant? variant, String instanceName) async {
    // ↓ mock an result to exposure to ensure that is called
    result = 0;
  }

  @override
  Future<ExposureTrackingContext> getContext(String instanceName) async {
    // TODO: implement getContext
    return ExposureTrackingContext();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // ↓ required to avoid HTTP error 400 mocked returns
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
  });

  test('Should throw error if called with wrong apikey', () {
    final experiment = Experiment.initialize(apiKey: '');

    expect(experiment.fetch(deviceId: 'testing'),
        throwsA(const TypeMatcher<Exception>()));
  });

  test('Should succesfull fetch with a valid apiKey', () async {
    final experiment = Experiment.initialize(
        apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ');

    await experiment.fetch(deviceId: 'testing');

    expect(experiment.fetch(deviceId: 'testing'), completion(null));
  });

  test('Should has one variant', () async {
    final experiment = Experiment.initialize(
        apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ');

    await experiment.fetch(deviceId: 'testing');

    expect(experiment.variant('flutter-sdk-demo')?.value, isNotNull);
  });

  test('Should successfuly call track method inside tracker', () async {
    final mocked = MockedTracker();

    final experiment = Experiment.initialize(
        apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ',
        config: ExperimentConfig(
            automaticExposureTracking: true, exposureTrackingProvider: mocked));

    await experiment.fetch(deviceId: 'testing');
    experiment.variant('flutter-sdk-demo');
    experiment.exposure('flutter-sdk-demo');

    expect(mocked.result, 0);
  });

  test('Should return a map with variant on all method', () async {
    final experiment = Experiment.initialize(
        apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ');

    await experiment.fetch(deviceId: 'testing');
    final all = experiment.all();

    expect(all['flutter-sdk-demo']!.value, isNotNull);
  });

  test('Should succesfully clear cache', () async {
    final experiment = Experiment.initialize(
        apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ');

    await experiment.fetch(deviceId: 'testing');
    var all = experiment.all();

    expect(all['flutter-sdk-demo']!.value, isNotNull);

    experiment.clear();
    all = experiment.all();

    expect(all, {});
  });

  group('LocalStorage Tests', () {
    test('Should handle basic put/get operations', () {
      final localStorage = LocalStorage(apiKey: 'test-api-key');
      final variant = ExperimentVariant(value: 'test-value');

      localStorage.put('test-key', variant);
      final retrieved = localStorage.get('test-key');

      expect(retrieved?.value, equals('test-value'));
    });

    test('Should isolate data between different API keys', () {
      final localStorage1 = LocalStorage(apiKey: 'key1');
      final localStorage2 = LocalStorage(apiKey: 'key2');

      final variant1 = ExperimentVariant(value: 'value1');
      final variant2 = ExperimentVariant(value: 'value2');

      localStorage1.put('same-key', variant1);
      localStorage2.put('same-key', variant2);

      expect(localStorage1.get('same-key')?.value, equals('value1'));
      expect(localStorage2.get('same-key')?.value, equals('value2'));
    });

    test('Should not interfere with existing SharedPreferences values',
        () async {
      // Set up some existing SharedPreferences values
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_preference', 'existing_value');
      await prefs.setString('app_setting', 'another_value');
      await prefs.setInt('counter', 42);

      // Create LocalStorage and add some data
      final localStorage = LocalStorage(apiKey: 'test-key');
      final variant = ExperimentVariant(value: 'experiment_value');
      localStorage.put('experiment-key', variant);
      await localStorage.save();

      // Verify existing values are still intact
      expect(prefs.getString('user_preference'), equals('existing_value'));
      expect(prefs.getString('app_setting'), equals('another_value'));
      expect(prefs.getInt('counter'), equals(42));

      // Verify our experiment data is stored with prefix
      final experimentKeys =
          prefs.getKeys().where((key) => key.startsWith('ampli-'));
      expect(experimentKeys.length, greaterThan(0));

      // Verify we can still retrieve our experiment data
      localStorage.clear();
      await localStorage.load();
      final retrieved = localStorage.get('experiment-key');
      expect(retrieved?.value, equals('experiment_value'));
    });
  });
}
