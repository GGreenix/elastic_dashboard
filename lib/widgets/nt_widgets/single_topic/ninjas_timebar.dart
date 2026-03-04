import 'package:elastic_dashboard/services/nt4_client.dart';
import 'package:flutter/material.dart';
import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

class NinjasTimebarModel extends MultiTopicNTWidgetModel {
  @override
  String type = NinjasTimebarWidget.widgetType;

  double _startingTime = 0;
  double _endingTime = 160; // FRC 2026: 20 + 10 + 100 + 30 = 160s

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
    double endingTime = 160,
  })  : _startingTime = startingTime,
        _endingTime = endingTime,
        super();

  NinjasTimebarModel.fromJson({
    required super.ntConnection,
    required super.preferences,
    required Map<String, dynamic> jsonData,
  }) : super.fromJson(jsonData: jsonData) {
    _startingTime = tryCast(jsonData['start_angle']) ?? _startingTime;
    _endingTime = tryCast(jsonData['end_angle']) ?? 160;
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
        // Clamp to 160 for the 2026 match length
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

  // FRC 2026 REBUILT Segments
  static const List<int> flexRatios = [20, 10, 25, 25, 25, 25, 30];
  static const List<int> segmentStarts = [0, 20, 30, 55, 80, 105, 130];
  static const List<int> segmentEnds = [20, 30, 55, 80, 105, 130, 160];
  static const List<String> segmentLabels = [
    'Auto',
    'Transition',
    'Shift 1',
    'Shift 2',
    'Shift 3',
    'Shift 4',
    'Endgame',
  ];

  static const double blinkThreshold = 3.0;
  static const double endGameBlinkThreshold = 10.0; 

  static const Color autonColor = Colors.yellow;
  static const Color endgameColor = Colors.pinkAccent;
  static const Color activeColor = Colors.green;
  static const Color inactiveColor = Color(0xFF424242); // Darker Grey

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  int _getCurrentSegmentIndex() {
    for (int i = 0; i < segmentEnds.length; i++) {
      if (widget.totalValue < segmentEnds[i]) return i;
    }
    return segmentEnds.length - 1;
  }

  bool _shouldBlink(int segmentIndex) {
    int end = segmentEnds[segmentIndex];
    int start = segmentStarts[segmentIndex];
    
    if (widget.totalValue >= start && widget.totalValue < end) {
      double threshold = (segmentIndex == 6) ? endGameBlinkThreshold : blinkThreshold;
      return (end - widget.totalValue) <= threshold;
    }
    return false;
  }

  Color _getSegmentColor(int index, bool isAutoWon) {
    if (index == 0) return autonColor;
    if (index == 1) return Colors.blueGrey; // Transition period
    if (index == 6) return endgameColor;

    // Shift logic: Winner of Auto gets active HUB in Shifts 2 & 4 (indices 3 & 5)
    bool isShiftActive = isAutoWon ? (index % 2 == 1) : (index % 2 == 0);
    return isShiftActive ? activeColor : inactiveColor;
  }

  Color _getBackgroundColor(int index, bool isAutoWon) {
    return _getSegmentColor(index, isAutoWon).withOpacity(0.2);
  }

  double _calculateSegmentProgress(double totalValue, int segmentIndex) {
    int start = segmentStarts[segmentIndex];
    int end = segmentEnds[segmentIndex];
    return ((totalValue - start) / (end - start)).clamp(0.0, 1.0);
  }

  String _formatTime(double seconds) {
    int secs = seconds.ceil();
    if (secs >= 60) {
      return '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    }
    return '${secs}s';
  }

  Color _brightenColor(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount * 0.7) ?? color;
  }

  @override
  Widget build(BuildContext context) {
    int currentSegment = _getCurrentSegmentIndex();
    double timeRemaining = (segmentEnds[currentSegment] - widget.totalValue).clamp(0.0, 160.0);

    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) => Column(
        children: [
          Expanded(
            flex: 3,
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(7, (index) {
                  double segmentProgress = _calculateSegmentProgress(widget.totalValue, index);
                  Color baseColor = _getSegmentColor(index, widget.isAutoWon);
                  Color activeColor = _shouldBlink(index) 
                      ? _brightenColor(baseColor, _blinkController.value) 
                      : baseColor;

                  return Expanded(
                    flex: flexRatios[index],
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: LinearProgressIndicator(
                            value: segmentProgress,
                            backgroundColor: _getBackgroundColor(index, widget.isAutoWon),
                            valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                          ),
                        ),
                        Center(
                          child: Text(
                            segmentLabels[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${segmentLabels[currentSegment]}: ',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatTime(timeRemaining),
                    style: TextStyle(
                      color: _shouldBlink(currentSegment) ? Colors.redAccent : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    'Match: ${_formatTime((160 - widget.totalValue))}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
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