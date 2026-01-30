
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
            bool isAutoWon = tryCast<bool>(activeData) ?? false;

            return _NinjasTimebarContent(
              totalValue: totalValue,
              isAutoWon: isAutoWon,
            );
          },
        );
      },
    );
  }
}

class _NinjasTimebarContent extends StatefulWidget {
  final double totalValue;
  final bool isAutoWon;

  const _NinjasTimebarContent({
    required this.totalValue,
    required this.isAutoWon,
  });

  @override
  State<_NinjasTimebarContent> createState() => _NinjasTimebarContentState();
}

class _NinjasTimebarContentState extends State<_NinjasTimebarContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  // Segment definitions
  static const List<int> flexRatios = [20, 25, 25, 25, 25, 40];
  static const List<int> segmentStarts = [0, 20, 45, 70, 95, 120];
  static const List<int> segmentEnds = [20, 45, 70, 95, 120, 160];
  static const List<String> segmentLabels = [
    'Auto',
    'Seg 2',
    'Seg 3',
    'Seg 4',
    'Seg 5',
    'Endgame',
  ];
  static const double blinkThreshold = 3.0;
  static const double endGameBlinkThreshold = 10.0; // Start blinking 3 seconds before end
  static const Color autonColor = Colors.yellow;
  static const Color endgameColor = Colors.pinkAccent;
  static const Color activeColor = Colors.green;
  static const Color inactiveColor = Colors.grey;


  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  int _getCurrentSegmentIndex() {
    for (int i = 0; i < segmentEnds.length; i++) {
      if (widget.totalValue < segmentEnds[i]) {
        return i;
      }
    }
    return segmentEnds.length - 1; // Return last segment if at/past end
  }

  bool _shouldBlink(int segmentIndex) {
    int end = segmentEnds[segmentIndex];
    int start = segmentStarts[segmentIndex];
    
    // Only blink if we're in this segment and within 3 units of the end
    if (widget.totalValue >= start && widget.totalValue < end && segmentIndex != 5) {
      return (end - widget.totalValue) <= blinkThreshold;
    }
    else if (widget.totalValue >= start && widget.totalValue < end) {
      return (end - widget.totalValue) <= endGameBlinkThreshold;
    }
    
    return false;
  }

  Color _getSegmentColor(int index, bool isAutoWon) {
    // Segment 1 (index 0): Yellow
    if (index == 0) return autonColor;
    // Segment 6 (index 5): Magenta
    if (index == 5) return endgameColor;
    // Segments 2-5 (indices 1-4): Green if auto won, Gray if not
    if (isAutoWon) {
      return index % 2 == 0 ? activeColor : inactiveColor;
    } else {
      return index % 2 == 1 ? activeColor : inactiveColor;
    }
  }

  Color _getBackgroundColor(int index, bool isAutoWon) {
    // Use a darker version of the segment color as background
    if (index == 0) return autonColor.withValues(alpha: 0.3);
    if (index == 5) return endgameColor.withValues(alpha: 0.3);
    // Segments 2-5: green background if auto won, grey otherwise
    if (isAutoWon) {
      return index % 2 == 0
          ? activeColor.withValues(alpha: 0.3)
          : inactiveColor.withValues(alpha: 0.3);
    } else {
      return index % 2 == 1
          ? activeColor.withValues(alpha: 0.3)
          : inactiveColor.withValues(alpha: 0.3);
    }
  }
  double _getTimeRemainingInSegment(int segmentIndex) {
    if (segmentIndex < 0 || segmentIndex >= segmentEnds.length) return 0;
    return (segmentEnds[segmentIndex] - widget.totalValue).clamp(0.0, double.infinity);
  }


  Color _brightenColor(Color color, double amount) {
    int r = (color.red + (255 - color.red) * amount * 0.6).round().clamp(0, 255);
    int g = (color.green + (255 - color.green) * amount * 0.6).round().clamp(0, 255);
    int b = (color.blue + (255 - color.blue) * amount * 0.6).round().clamp(0, 255);
    return Color.fromARGB(color.alpha, r, g, b);
  }

  double _calculateSegmentProgress(double totalValue, int segmentIndex) {
    int start = segmentStarts[segmentIndex];
    int end = segmentEnds[segmentIndex];
    int segmentWidth = end - start;

    if (totalValue <= start) {
      return 0.0;
    } else if (totalValue >= end) {
      return 1.0;
    } else {
      return (totalValue - start) / segmentWidth;
    }
  }

  String _formatTime(double seconds) {
    int secs = seconds.ceil();
    if (secs >= 60) {
      int mins = secs ~/ 60;
      int remainingSecs = secs % 60;
      return '$mins:${remainingSecs.toString().padLeft(2, '0')}';
    }
    return '${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    int currentSegment = _getCurrentSegmentIndex();
    double timeRemaining = _getTimeRemainingInSegment(currentSegment);
    String currentLabel = segmentLabels[currentSegment];

    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) => Column(
          children: [
            // Progress bar row
            Expanded(
              flex: 3,
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(6, (index) {
                    double segmentProgress =
                        _calculateSegmentProgress(widget.totalValue, index);

                    Color baseColor = _getSegmentColor(index, widget.isAutoWon);
                    Color backgroundColor =
                        _getBackgroundColor(index, widget.isAutoWon);

                    Color activeColor;
                    if (_shouldBlink(index)) {
                      activeColor =
                          _brightenColor(baseColor, _blinkController.value);
                    } else {
                      activeColor = baseColor;
                    }

                    return Expanded(
                      flex: flexRatios[index],
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: LinearProgressIndicator(
                              value: segmentProgress,
                              backgroundColor: backgroundColor,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(activeColor),
                              minHeight: constraints.maxHeight,
                            ),
                          ),
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
              ),
            ),
            // Timer display row
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.black54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$currentLabel: ',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatTime(timeRemaining),
                      style: TextStyle(
                        color: timeRemaining <= blinkThreshold
                            ? (_blinkController.value > 0.5
                                ? Colors.red
                                : Colors.white)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Total: ${_formatTime((160 - widget.totalValue).clamp(0, 160))}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
