
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
  static const double blinkThreshold = 3.0; // Start blinking 3 seconds before end
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
      duration: const Duration(milliseconds: 50), // Blink speed
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
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

    Color _brightenColor(Color color, double amount) {
    // Convert to HSL for better brightness control
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount * 0.5).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + amount * 0.2).clamp(0.0, 1.0))
        .toColor();
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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) => LayoutBuilder(
          builder: (context, constraints) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(6, (index) {
              double segmentProgress =
                  _calculateSegmentProgress(widget.totalValue, index);
              
              Color baseColor = _getSegmentColor(index, widget.isAutoWon);
              Color backgroundColor = _getBackgroundColor(index, widget.isAutoWon);
              
              // Apply blinking effect if within threshold
              Color activeColor;
              if (_shouldBlink(index)) {
                // Brighten based on animation value (0.0 to 1.0)
                activeColor = _brightenColor(baseColor, _blinkController.value * 0.5);
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
                        valueColor: AlwaysStoppedAnimation<Color>(activeColor),
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
    );
}
