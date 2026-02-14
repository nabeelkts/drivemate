import 'dart:async';

class StreamUtils {
  /// Combines a list of streams into one that emits a list of the latest values
  /// from each of those streams whenever any of them emits a new value.
  ///
  /// This behaves like Rx.combineLatestList from rxdart.
  static Stream<List<T>> combineLatest<T>(List<Stream<T>> streams) {
    final controller = StreamController<List<T>>.broadcast();
    final latestValues = List<T?>.filled(streams.length, null);
    final hasEmitted = List<bool>.filled(streams.length, false);
    final subscriptions = <StreamSubscription<T>>[];

    void update() {
      if (hasEmitted.every((emitted) => emitted)) {
        controller.add(latestValues.cast<T>().toList());
      }
    }

    for (var i = 0; i < streams.length; i++) {
      final subscription = streams[i].listen(
        (value) {
          latestValues[i] = value;
          hasEmitted[i] = true;
          update();
        },
        onError: controller.addError,
        onDone: () {
          // You might want to close the controller if all streams are done
          // but for Firestore snapshots, they usually stay open.
        },
      );
      subscriptions.add(subscription);
    }

    controller.onCancel = () {
      for (var sub in subscriptions) {
        sub.cancel();
      }
    };

    return controller.stream;
  }
}
