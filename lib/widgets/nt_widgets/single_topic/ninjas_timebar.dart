
import 'package:elastic_dashboard/services/nt4_client.dart';
import 'package:flutter/material.dart';

import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';

import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

class NinjasTimebarModel extends MultiTopicNTWidgetModel {
  @override
  String type = NinjasTimebarWidget.widgetType;

  double _startingTime = 0;
  double _endingTime = 240;
  String get activeTopicName => '$topic/active';
  String get timeTopicName => '$topic/time';

  double get startingTime => _startingTime;

  late NT4Subscription activeSubscription;
  late NT4Subscription timeSubscription;

  @override
  List<NT4Subscription> get subscriptions => [
        timeSubscription,
        activeSubscription,
      ];

  set startingTime(double value) {
    _startingTime = value;
    refresh();
  }

  double get endingTime => _endingTime;

  set endingTime(double value) {
    _endingTime = value;
    refresh();
  }

  NinjasTimebarModel({
    required super.ntConnection,
    required super.preferences,
    required super.topic,
    super.period,
    double startingTime = 0,
    double endingTime = 240,
  })  : _startingTime = startingTime,
        _endingTime = endingTime,
        super();

  NinjasTimebarModel.fromJson({
    required super.ntConnection,
    required super.preferences,
    required Map<String, dynamic> jsonData,
  }) : super.fromJson(jsonData: jsonData) {
    _startingTime = tryCast(jsonData['start_angle']) ?? _startingTime;
    _endingTime = tryCast(jsonData['end_angle']) ?? _endingTime;
  }

  @override
  void initializeSubscriptions() {
    timeSubscription = ntConnection.subscribe(timeTopicName, super.period);
    activeSubscription = ntConnection.subscribe(activeTopicName, super.period);
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'start_angle': _startingTime,
        'end_angle': _endingTime,
      };
}

class NinjasTimebarWidget extends NTWidget {
  static const String widgetType = 'Game Ninjas Timebar';

  const NinjasTimebarWidget({super.key});

  // Segment definitions
  static const List<int> _flexRatios = [20, 25, 25, 25, 25, 40];
  static const List<int> _segmentStarts = [0, 20, 45, 70, 95, 120];
  static const List<int> _segmentEnds = [20, 45, 70, 95, 120, 160];

  Color _getSegmentColor(int index, bool isAutoWon) {
    // Segment 1 (index 0): Yellow
    if (index == 0) return Colors.yellow;
    // Segment 6 (index 5): Magenta
    if (index == 5) return Colors.pinkAccent;
    // Segments 2-5 (indices 1-4): Green if auto won, Gray if not
    return isAutoWon ? Colors.green : Colors.grey;
  }

  Color _getBackgroundColor(int index, bool isAutoWon) {
    // Use a darker version of the segment color as background
    if (index == 0) return Colors.yellow.withValues(alpha: 0.3);
    if (index == 5) return Colors.pinkAccent.withValues(alpha: 0.3);
    // Segments 2-5: green background if auto won, grey otherwise
    return isAutoWon
        ? Colors.green.withValues(alpha: 0.3)
        : Colors.grey.withValues(alpha: 0.3);
  }

  double _calculateSegmentProgress(double totalValue, int segmentIndex) {
    int start = _segmentStarts[segmentIndex];
    int end = _segmentEnds[segmentIndex];
    int segmentWidth = end - start;

    if (totalValue <= start) {
      return 0.0; // Segment is empty
    } else if (totalValue >= end) {
      return 1.0; // Segment is full
    } else {
      return (totalValue - start) / segmentWidth; // Partial fill
    }
  }

  @override
  Widget build(BuildContext context) {
    NinjasTimebarModel model = cast(context.watch<NTWidgetModel>());

    return ValueListenableBuilder<Object?>(
      valueListenable: model.timeSubscription,
      builder: (context, timeData, child) {
        double totalValue =
            (tryCast<num>(timeData)?.toDouble() ?? 0.0).clamp(0.0, 160.0);

        return ValueListenableBuilder<Object?>(
          valueListenable: model.activeSubscription,
          builder: (context, activeData, child) {
            // Cast the boolean properly - defaults to false if null
            bool isAutoWon = tryCast<bool>(activeData) ?? false;

            return LayoutBuilder(
              builder: (context, constraints) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(6, (index) {
                  double segmentProgress =
                      _calculateSegmentProgress(totalValue, index);
                  Color activeColor = _getSegmentColor(index, isAutoWon);
                  Color backgroundColor = _getBackgroundColor(index, isAutoWon);

                  return Expanded(
                    flex: _flexRatios[index],
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress bar
                        Positioned.fill(
                          child: LinearProgressIndicator(
                            value: segmentProgress,
                            backgroundColor: backgroundColor,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(activeColor),
                            minHeight: constraints.maxHeight,
                          ),
                        ),
                        // Label for first segment (Autonomous)
                        if (index == 0)
                          const Center(
                            child: Text(
                              'Autonomous',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }
}
