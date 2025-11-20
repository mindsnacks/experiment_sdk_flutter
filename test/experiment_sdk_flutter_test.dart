import 'dart:io';

import 'package:experiment_sdk_flutter/local_storage.dart';
import 'package:experiment_sdk_flutter/types/experiment_config.dart';
import 'package:experiment_sdk_flutter/types/experiment_expose_tracking_context.dart';
import 'package:experiment_sdk_flutter/types/experiment_exposure_tracking_provider.dart';
import 'package:experiment_sdk_flutter/types/experiment_variant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:experiment_sdk_flutter/experiment_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockedTracker implements ExperimentExposureTrackingProvider {
  late int result;

  @override
  Future<void> exposure(
      String flagkey, ExperimentVariant? variant, String instanceName) async {
    // ↓ mock a result to exposure to ensure that it is called
    result = 0;
  }

  @override
  Future<ExposureTrackingContext> getContext(String instanceName) async {
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

  group('ExperimentClient Initialization', () {
    test('Should initialize successfully with valid API key', () async {
      final experiment = await Experiment.initialize(
          apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ');

      expect(experiment, isNotNull);
    });
  });

  group('ExperimentClient Fetch', () {
    test('Should throw error if called with wrong apikey', () async {
      final experiment = await Experiment.initialize(apiKey: '');

      expect(
        experiment.fetch(deviceId: 'testing'),
        throwsA(isA<Exception>()),
      );
    });

    test('Should successfully fetch with a valid apiKey', () async {
      final experiment = await Experiment.initialize(
          apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ');

      await experiment.fetch(deviceId: 'testing');

      expect(experiment.fetch(deviceId: 'testing'), completion(null));
    });

    test('Should update variants on subsequent fetches', () async {
      final experiment = await Experiment.initialize(
          apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ');

      await experiment.fetch(deviceId: 'testing');
      final firstAll = experiment.all();
      expect(firstAll.isNotEmpty, isTrue);

      await experiment.fetch(deviceId: 'testing');
      final secondAll = experiment.all();
      expect(secondAll.length, equals(firstAll.length));
    });

    test('Should call getContext during fetch when provider is set', () async {
      var getContextCalled = false;
      final tracker = MockedTracker()..result = 0;

      final customTracker = _ContextTrackingProvider(
        onGetContext: () {
          getContextCalled = true;
        },
        baseTracker: tracker,
      );

      final experiment = await Experiment.initialize(
          apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ',
          config: ExperimentConfig(exposureTrackingProvider: customTracker));

      await experiment.fetch(deviceId: 'testing');

      expect(getContextCalled, isTrue);
    });
  });

  group('ExperimentClient Variant', () {
    test('Should return variant for existing flag', () async {
      final experiment = await Experiment.initialize(
          apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ');

      await experiment.fetch(deviceId: 'testing');

      final variant = experiment.variant('flutter-sdk-demo');
      expect(variant?.value, isNotNull);
    });

    test('Should return null variant for non-existent flag', () async {
      final experiment = await Experiment.initialize(
          apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ');

      await experiment.fetch(deviceId: 'testing');
      final variant = experiment.variant('non-existent-flag');

      expect(variant, isNull);
    });

    test('Should trigger automatic exposure when variant is called', () async {
      var exposureCalled = false;
      final tracker = _ExposureTrackingProvider(
        onExposure: () {
          exposureCalled = true;
        },
      );

      final experiment = await Experiment.initialize(
          apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ',
          config: ExperimentConfig(
              automaticExposureTracking: true,
              exposureTrackingProvider: tracker));

      await experiment.fetch(deviceId: 'testing');

      // Give a moment for the unawaited exposure to complete
      experiment.variant('flutter-sdk-demo');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(exposureCalled, isTrue);
    });
  });

  group('ExperimentClient Exposure', () {
    test('Should successfully call track method inside tracker', () async {
      final mocked = MockedTracker();

      final experiment = await Experiment.initialize(
          apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ',
          config: ExperimentConfig(
              automaticExposureTracking: true,
              exposureTrackingProvider: mocked));

      await experiment.fetch(deviceId: 'testing');
      experiment.variant(
          'flutter-sdk-demo'); // Sync call, triggers automatic exposure
      await experiment.exposure('flutter-sdk-demo');

      expect(mocked.result, 0);
    });

    test('Should not throw when exposure called without provider', () async {
      final experiment = await Experiment.initialize(
          apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ');

      await experiment.fetch(deviceId: 'testing');

      // Should not throw even without exposure tracking provider
      expect(() => experiment.exposure('flutter-sdk-demo'), returnsNormally);
      await experiment.exposure('non-existent-flag');
    });
  });

  group('ExperimentClient Storage Operations', () {
    test('Should return a map with variant on all method', () async {
      final experiment = await Experiment.initialize(
          apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ');

      await experiment.fetch(deviceId: 'testing');
      final all = experiment.all();

      expect(all['flutter-sdk-demo']!.value, isNotNull);
    });

    test('Should return empty map when no variants exist', () async {
      // Use a unique API key to ensure no cached data
      final experiment = await Experiment.initialize(
          apiKey: 'empty-test-key-${DateTime.now().millisecondsSinceEpoch}');

      // Don't fetch, just check all()
      final all = experiment.all();
      expect(all, isEmpty);
    });

    test('Should successfully clear cache', () async {
      final experiment = await Experiment.initialize(
          apiKey: 'client-TgXx6plnArNPL2ck4sKc6QtAJ8lbu8nQ');

      await experiment.fetch(deviceId: 'testing');
      var all = experiment.all();

      expect(all['flutter-sdk-demo']!.value, isNotNull);

      await experiment.clear();
      all = experiment.all();

      expect(all, {});
    });
  });

  group('LocalStorage Tests', () {
    test('Should handle basic replaceAll/get operations', () async {
      final localStorage = await LocalStorage.create(apiKey: 'test-api-key');
      final variant = ExperimentVariant(value: 'test-value');

      await localStorage.replaceAll({'test-key': variant});
      final retrieved = localStorage.get('test-key');

      expect(retrieved?.value, equals('test-value'));
    });

    test('Should isolate data between different API keys', () async {
      final localStorage1 = await LocalStorage.create(apiKey: 'key1');
      final localStorage2 = await LocalStorage.create(apiKey: 'key2');

      final variant1 = ExperimentVariant(value: 'value1');
      final variant2 = ExperimentVariant(value: 'value2');

      await localStorage1.replaceAll({'same-key': variant1});
      await localStorage2.replaceAll({'same-key': variant2});

      final retrieved1 = localStorage1.get('same-key');
      final retrieved2 = localStorage2.get('same-key');
      expect(retrieved1?.value, equals('value1'));
      expect(retrieved2?.value, equals('value2'));
    });

    test('Should not interfere with existing SharedPreferences values',
        () async {
      // Set up some existing SharedPreferences values
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_preference', 'existing_value');
      await prefs.setString('app_setting', 'another_value');
      await prefs.setInt('counter', 42);

      // Create LocalStorage and add some data
      final localStorage = await LocalStorage.create(apiKey: 'test-key');
      final variant = ExperimentVariant(value: 'experiment_value');
      await localStorage.replaceAll({'experiment-key': variant});

      // Verify existing values are still intact
      expect(prefs.getString('user_preference'), equals('existing_value'));
      expect(prefs.getString('app_setting'), equals('another_value'));
      expect(prefs.getInt('counter'), equals(42));

      // Verify our experiment data is stored with prefix
      final experimentKeys =
          prefs.getKeys().where((key) => key.startsWith('ampli-'));
      expect(experimentKeys.length, greaterThan(0));

      // Verify we can still retrieve our experiment data
      // Create a new instance to test loading from disk
      final localStorage2 = await LocalStorage.create(apiKey: 'test-key');
      final retrieved = localStorage2.get('experiment-key');
      expect(retrieved?.value, equals('experiment_value'));
    });

    test('Should persist data across LocalStorage instances', () async {
      final localStorage1 = await LocalStorage.create(apiKey: 'persist-key');
      final variant = ExperimentVariant(value: 'persisted-value');
      await localStorage1.replaceAll({'persist-key': variant});

      // Create a new instance with same API key
      final localStorage2 = await LocalStorage.create(apiKey: 'persist-key');
      final retrieved = localStorage2.get('persist-key');
      expect(retrieved?.value, equals('persisted-value'));
    });
  });
}

class _ContextTrackingProvider implements ExperimentExposureTrackingProvider {
  final void Function() onGetContext;
  final ExperimentExposureTrackingProvider baseTracker;

  _ContextTrackingProvider({
    required this.onGetContext,
    required this.baseTracker,
  });

  @override
  Future<void> exposure(
      String flagkey, ExperimentVariant? variant, String instanceName) async {
    return baseTracker.exposure(flagkey, variant, instanceName);
  }

  @override
  Future<ExposureTrackingContext> getContext(String instanceName) async {
    onGetContext();
    return baseTracker.getContext(instanceName);
  }
}

class _ExposureTrackingProvider implements ExperimentExposureTrackingProvider {
  final void Function() onExposure;

  _ExposureTrackingProvider({required this.onExposure});

  @override
  Future<void> exposure(
      String flagkey, ExperimentVariant? variant, String instanceName) async {
    onExposure();
  }

  @override
  Future<ExposureTrackingContext> getContext(String instanceName) async {
    return ExposureTrackingContext();
  }
}
