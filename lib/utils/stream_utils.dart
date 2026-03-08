import 'dart:async';
import 'package:flutter/foundation.dart';

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
    bool hasInitiallyEmitted = false; // Track initial emission
    int errorCount = 0; // Track errors

    void update({bool forceEmit = false}) {
      final allEmitted = hasEmitted.every((emitted) => emitted);

      // Emit when all streams have emitted OR after first partial data (to avoid infinite shimmer)
      if (allEmitted || forceEmit) {
        if (!hasInitiallyEmitted || !allEmitted) {
          hasInitiallyEmitted = true;
        }
        // Filter out null values before casting to avoid type cast errors
        final nonNullValues = latestValues.where((v) => v != null).cast<T>().toList();
        if (nonNullValues.isNotEmpty) {
          controller.add(nonNullValues);
        }
      }
    }

    for (var i = 0; i < streams.length; i++) {
      final subscription = streams[i].listen(
        (value) {
          latestValues[i] = value;
          hasEmitted[i] = true;
          // Force emit after first stream responds to avoid infinite shimmer
          update(forceEmit: i == 0 && !hasInitiallyEmitted);
        },
        onError: (error) {
          debugPrint('StreamUtils combineLatest error in stream $i: $error');
          errorCount++;
          // Mark as emitted but don't set null value (to avoid type cast issues)
          // Just keep the previous valid value or leave it unset
          hasEmitted[i] = true;
          
          // If all streams have errors, emit what we have
          if (errorCount == streams.length) {
            debugPrint('StreamUtils combineLatest: All streams failed, emitting empty list');
            controller.add([]);
          } else {
            update();
          }
        },
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

    // Timeout fallback: emit partial data after 2 seconds to avoid infinite shimmer
    Future.delayed(const Duration(seconds: 2), () {
      if (!hasInitiallyEmitted) {
        debugPrint('StreamUtils combineLatest timeout - emitting partial data');
        update(forceEmit: true);
      }
    });

    return controller.stream;
  }
}
