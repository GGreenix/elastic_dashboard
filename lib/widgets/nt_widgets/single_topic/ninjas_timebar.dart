import 'package:elastic_dashboard/services/nt4_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_color_picker.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_text_input.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

class NinjasTimebarModel extends MultiTopicNTWidgetModel {
  @override
  String type = NinjasTimebarWidget.widgetType;

  double _startingTime = 0;
  double _endingTime = 160; // FRC 2026: 20 + 10 + 100 + 30 = 160s

  Color _autoColor = Colors.yellow;
  Color _transitionColor = Colors.teal;
  Color _activeShiftColor = Colors.green;
  Color _inactiveShiftColor = const Color(0xFF424242);
  Color _endgameColor = Colors.pinkAccent;
  double _textSize = 10.0;

  String get activeTopicName => '$topic/active';
  String get timeTopicName => '$topic/time';
  String get activeFlashTimeTopicName => '$topic/active_flash_time';
  String get inactiveFlashTimeTopicName => '$topic/inactive_flash_time';
  String get endgameFlashTimeTopicName => '$topic/endgame_flash_time';

  double get startingTime => _startingTime;

  late NT4Subscription activeSubscription;
  late NT4Subscription timeSubscription;
  late NT4Subscription activeFlashTimeSubscription;
  late NT4Subscription inactiveFlashTimeSubscription;
  late NT4Subscription endgameFlashTimeSubscription;

  @override
  List<NT4Subscription> get subscriptions => [
        timeSubscription,
        activeSubscription,
        activeFlashTimeSubscription,
        inactiveFlashTimeSubscription,
        endgameFlashTimeSubscription,
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

  Color get autoColor => _autoColor;

  set autoColor(Color value) {
    _autoColor = value;
    refresh();
  }

  Color get transitionColor => _transitionColor;

  set transitionColor(Color value) {
    _transitionColor = value;
    refresh();
  }

  Color get activeShiftColor => _activeShiftColor;

  set activeShiftColor(Color value) {
    _activeShiftColor = value;
    refresh();
  }

  Color get inactiveShiftColor => _inactiveShiftColor;

  set inactiveShiftColor(Color value) {
    _inactiveShiftColor = value;
    refresh();
  }

  Color get endgameColor => _endgameColor;

  set endgameColor(Color value) {
    _endgameColor = value;
    refresh();
  }

  double get textSize => _textSize;

  set textSize(double value) {
    _textSize = value;
    refresh();
  }

  NinjasTimebarModel({
    required super.ntConnection,
    required super.preferences,
    required super.topic,
    super.period,
    double startingTime = 0,
    double endingTime = 160,
    Color autoColor = Colors.yellow,
    Color transitionColor = Colors.teal,
    Color activeShiftColor = Colors.green,
    Color inactiveShiftColor = const Color(0xFF424242),
    Color endgameColor = Colors.pinkAccent,
    double textSize = 10.0,
  })  : _startingTime = startingTime,
        _endingTime = endingTime,
        _autoColor = autoColor,
        _transitionColor = transitionColor,
        _activeShiftColor = activeShiftColor,
        _inactiveShiftColor = inactiveShiftColor,
        _endgameColor = endgameColor,
        _textSize = textSize,
        super();

  NinjasTimebarModel.fromJson({
    required super.ntConnection,
    required super.preferences,
    required Map<String, dynamic> jsonData,
  }) : super.fromJson(jsonData: jsonData) {
    _startingTime = tryCast(jsonData['start_angle']) ?? _startingTime;
    _endingTime = tryCast(jsonData['end_angle']) ?? 160;

    int? autoColorValue = tryCast(jsonData['auto_color']);
    _autoColor = Color(autoColorValue ?? Colors.yellow.toARGB32());

    int? transColorValue = tryCast(jsonData['transition_color']);
    _transitionColor = Color(transColorValue ?? Colors.teal.toARGB32());

    int? activeShiftColorValue = tryCast(jsonData['active_shift_color']);
    _activeShiftColor = Color(activeShiftColorValue ?? Colors.green.toARGB32());

    int? inactiveShiftColorValue = tryCast(jsonData['inactive_shift_color']);
    _inactiveShiftColor =
        Color(inactiveShiftColorValue ?? const Color(0xFF424242).toARGB32());

    int? endgameColorValue = tryCast(jsonData['endgame_color']);
    _endgameColor = Color(endgameColorValue ?? Colors.pinkAccent.toARGB32());

    _textSize = tryCast<num>(jsonData['text_size'])?.toDouble() ?? 10.0;
  }

  @override
  void initializeSubscriptions() {
    timeSubscription = ntConnection.subscribe(timeTopicName, super.period);
    activeSubscription = ntConnection.subscribe(activeTopicName, super.period);
    activeFlashTimeSubscription =
        ntConnection.subscribe(activeFlashTimeTopicName, super.period);
    inactiveFlashTimeSubscription =
        ntConnection.subscribe(inactiveFlashTimeTopicName, super.period);
    endgameFlashTimeSubscription =
        ntConnection.subscribe(endgameFlashTimeTopicName, super.period);
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'start_angle': _startingTime,
        'end_angle': _endingTime,
        'auto_color': _autoColor.toARGB32(),
        'transition_color': _transitionColor.toARGB32(),
        'active_shift_color': _activeShiftColor.toARGB32(),
        'inactive_shift_color': _inactiveShiftColor.toARGB32(),
        'endgame_color': _endgameColor.toARGB32(),
        'text_size': _textSize,
      };

  @override
  List<Widget> getEditProperties(BuildContext context) => [
        Row(
          children: [
            Flexible(
              child: DialogColorPicker(
                onColorPicked: (Color color) {
                  autoColor = color;
                },
                label: 'Auto Color',
                initialColor: _autoColor,
                defaultColor: Colors.yellow,
              ),
            ),
            Flexible(
              child: DialogColorPicker(
                onColorPicked: (Color color) {
                  transitionColor = color;
                },
                label: 'Transition Color',
                initialColor: _transitionColor,
                defaultColor: Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: DialogColorPicker(
                onColorPicked: (Color color) {
                  activeShiftColor = color;
                },
                label: 'Active Shift Color',
                initialColor: _activeShiftColor,
                defaultColor: Colors.green,
              ),
            ),
            Expanded(
              child: DialogColorPicker(
                onColorPicked: (Color color) {
                  inactiveShiftColor = color;
                },
                label: 'Inactive Shift Color',
                initialColor: _inactiveShiftColor,
                defaultColor: const Color(0xFF424242),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Flexible(
              child: DialogColorPicker(
                onColorPicked: (Color color) {
                  endgameColor = color;
                },
                label: 'Endgame Color',
                initialColor: _endgameColor,
                defaultColor: Colors.pinkAccent,
              ),
            ),
            Flexible(
              child: Tooltip(
                message: 'Font size for segment labels',
                waitDuration: const Duration(milliseconds: 750),
                child: DialogTextInput(
                  label: 'Label Text Size',
                  initialText: _textSize.toStringAsFixed(1),
                  onSubmit: (value) {
                    double? parsed = double.tryParse(value);
                    if (parsed == null) return;
                    textSize = parsed;
                  },
                  formatter:
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ),
              ),
            ),
          ],
        ),
      ];
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

            return ValueListenableBuilder<Object?>(
              valueListenable: model.activeFlashTimeSubscription,
              builder: (context, activeFlashData, child) {
                double activeFlashTime =
                    tryCast<num>(activeFlashData)?.toDouble() ?? 3.0;

                return ValueListenableBuilder<Object?>(
                  valueListenable: model.inactiveFlashTimeSubscription,
                  builder: (context, inactiveFlashData, child) {
                    double inactiveFlashTime =
                        tryCast<num>(inactiveFlashData)?.toDouble() ?? 3.0;

                    return ValueListenableBuilder<Object?>(
                      valueListenable: model.endgameFlashTimeSubscription,
                      builder: (context, endgameFlashData, child) {
                        double endgameFlashTime =
                            tryCast<num>(endgameFlashData)?.toDouble() ?? 10.0;

                        return _NinjasTimebarContent(
                          totalValue: totalValue,
                          isAutoWon: isAutoWon,
                          activeShiftFlashTime: activeFlashTime,
                          inactiveShiftFlashTime: inactiveFlashTime,
                          endgameFlashTime: endgameFlashTime,
                          autoColor: model.autoColor,
                          transitionColor: model.transitionColor,
                          activeShiftColor: model.activeShiftColor,
                          inactiveShiftColor: model.inactiveShiftColor,
                          endgameColor: model.endgameColor,
                          textSize: model.textSize,
                        );
                      },
                    );
                  },
                );
              },
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
  final double activeShiftFlashTime;
  final double inactiveShiftFlashTime;
  final double endgameFlashTime;
  final Color autoColor;
  final Color transitionColor;
  final Color activeShiftColor;
  final Color inactiveShiftColor;
  final Color endgameColor;
  final double textSize;

  const _NinjasTimebarContent({
    required this.totalValue,
    required this.isAutoWon,
    required this.activeShiftFlashTime,
    required this.inactiveShiftFlashTime,
    required this.endgameFlashTime,
    required this.autoColor,
    required this.transitionColor,
    required this.activeShiftColor,
    required this.inactiveShiftColor,
    required this.endgameColor,
    required this.textSize,
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
      double threshold;
      if (segmentIndex == 6) {
        threshold = widget.endgameFlashTime;
      } else if (segmentIndex == 0 || segmentIndex == 1) {
        threshold = widget.activeShiftFlashTime;
      } else {
        bool isShiftActive = widget.isAutoWon
            ? (segmentIndex % 2 == 1)
            : (segmentIndex % 2 == 0);
        threshold = isShiftActive
            ? widget.activeShiftFlashTime
            : widget.inactiveShiftFlashTime;
      }
      return (end - widget.totalValue) <= threshold;
    }
    return false;
  }

  Color _getSegmentColor(int index, bool isAutoWon) {
    if (index == 0) return widget.autoColor;
    if (index == 1) return widget.transitionColor;
    if (index == 6) return widget.endgameColor;

    bool isShiftActive =
        isAutoWon ? (index % 2 == 1) : (index % 2 == 0);
    return isShiftActive ? widget.activeShiftColor : widget.inactiveShiftColor;
  }

  Color _getBackgroundColor(int index, bool isAutoWon) => _getSegmentColor(index, isAutoWon).withOpacity(0.2);

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

  Color _brightenColor(Color color, double amount) => Color.lerp(color, Colors.white, amount * 0.7) ?? color;

  @override
  Widget build(BuildContext context) {
    int currentSegment = _getCurrentSegmentIndex();
    double timeRemaining =
        (segmentEnds[currentSegment] - widget.totalValue).clamp(0.0, 160.0);

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
                  double segmentProgress =
                      _calculateSegmentProgress(widget.totalValue, index);
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
                            backgroundColor:
                                _getBackgroundColor(index, widget.isAutoWon),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(activeColor),
                          ),
                        ),
                        Center(
                          child: Text(
                            segmentLabels[index],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.textSize,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(blurRadius: 2, color: Colors.black)
                              ],
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
                    style: const TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatTime(timeRemaining),
                    style: TextStyle(
                      color: _shouldBlink(currentSegment)
                          ? Colors.redAccent
                          : Colors.white,
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
