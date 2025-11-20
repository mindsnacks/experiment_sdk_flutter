<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

Amplitude Experiment implementation for Flutter. This is a non official package provided by ProductMinds.

## Features

`fetch`: Fetch experiments assigned to user. You can use some properties as below:
<br />
`variant`: Fetch assigned variant for each experiment. Returns synchronously from cached data.
<br />
`all`: Get all experiments and variants assigned to this user. Returns synchronously from cached data.
<br />
`clear`: Clear all SDK cache (async operation)
<br />
`exposure`: Track exposure for assigned variant in assigned experiment (requires custom **exposureTrackingProvider**)

## Getting started

In order to start using this package you **must** have properly defined an Amplitude Account and Project as well Amplitude Experiment. When you have already setted your experiment, you should create a `deployment` and this api key is the artifact that this SDK uses.

### **Initialization**

`initialize`: This async function returns an ExperimentClient instance that you should use to start instrumentation. The initialization loads cached data from local storage.

```dart
final experiment = await Experiment.initialize(
  apiKey: 'your-api-key',
  config: ExperimentConfig(...)
);
```

#### **Config Object**

```dart
class ExperimentConfig {
  final bool? debug;
  final String? instanceName;
  final int? fetchTimeoutMillis;
  final bool? retryFetchOnFailure;
  final bool? automaticExposureTracking;
  final ExperimentExposureTrackingProvider? exposureTrackingProvider;

  ExperimentConfig({
    this.debug = false,
    this.instanceName = '\$default_instance',
    this.fetchTimeoutMillis,
    this.retryFetchOnFailure,
    this.automaticExposureTracking = false,
    this.exposureTrackingProvider,
  });
}
```

**Note**: `ExperimentExposureTrackingProvider` is an abstract class with no default implementation. You must implement both `exposure()` and `getContext()` methods if you want to use exposure tracking.

## Usage

### Initialize the SDK

```dart
final experiment = await Experiment.initialize(
  apiKey: 'your-api-key',
  config: ExperimentConfig(
    debug: true,
    automaticExposureTracking: true,
    exposureTrackingProvider: MyCustomExposureTrackingProvider(),
  ),
);
```

### Fetch experiments for user

```dart
await experiment.fetch(
  userId: 'user-123',
  deviceId: 'device-456',
  userProperties: {'plan': 'premium'},
);
```

### Get variant for specific experiment (synchronous)

```dart
final variant = experiment.variant('my-flag-key');
if (variant != null) {
  print('Variant value: ${variant.value}');
}
```

### Get all variants and experiments (synchronous)

```dart
final allVariants = experiment.all();
allVariants.forEach((key, variant) {
  print('$key: ${variant.value}');
});
```

### Clear all cache data (async)

```dart
await experiment.clear();
```

### Track exposure event (async)

```dart
await experiment.exposure('my-flag-key');
```

**Note**: Exposure tracking requires a custom `ExperimentExposureTrackingProvider` implementation. The provider must implement both `exposure()` and `getContext()` methods.

## Additional information
This package is basically an wrappper to [Experiment Evaluation API](https://www.docs.developers.amplitude.com/experiment/apis/evaluation-api/) maintened by Product Minds team. If you have any problem with this license or usage, please mail to antonny.santos@productminds.io.

