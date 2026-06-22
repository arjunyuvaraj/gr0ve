import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/easter_eggs/hidden_fish/hidden_fish_service.dart';

enum HiddenFishTriggerGesture {
  tapSequence,
  doubleTap,
  longPress,
  horizontalSwipe,
  hover,
}

class HiddenFishTrigger extends StatefulWidget {
  const HiddenFishTrigger({
    super.key,
    required this.id,
    required this.child,
    required this.gesture,
    this.requiredTaps = 1,
  });

  final String id;
  final Widget child;
  final HiddenFishTriggerGesture gesture;
  final int requiredTaps;

  @override
  State<HiddenFishTrigger> createState() => _HiddenFishTriggerState();
}

class _HiddenFishTriggerState extends State<HiddenFishTrigger> {
  int _tapCount = 0;
  bool _dialogOpen = false;

  Future<void> _reveal() async {
    if (_dialogOpen) return;
    final definition = HiddenFishService.byId(widget.id);
    debugPrint(
      '[HiddenFish] Trigger accepted: ${definition.id} (${definition.name})',
    );

    final discovered = await HiddenFishService.discover(widget.id);
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    _dialogOpen = true;
    debugPrint(
      '[HiddenFish] Progress ${HiddenFishService.foundCount}/${HiddenFishService.fish.length}',
    );
    try {
      await HiddenFishService.showInfoDialog(
        context,
        definition,
        discovered: discovered,
      );
    } finally {
      _dialogOpen = false;
    }
  }

  void _handleTap() {
    if (widget.gesture != HiddenFishTriggerGesture.tapSequence) return;
    _tapCount++;
    debugPrint(
      '[HiddenFish] Tap sequence ${widget.id}: $_tapCount/${widget.requiredTaps}',
    );
    HapticFeedback.selectionClick();
    if (_tapCount >= widget.requiredTaps) _reveal();
  }

  void _handleHover(PointerEnterEvent event) {
    if (widget.gesture != HiddenFishTriggerGesture.hover) return;
    debugPrint('[HiddenFish] Hover trigger entered: ${widget.id}');
    _reveal();
  }

  @override
  Widget build(BuildContext context) {
    Widget interactiveChild = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.gesture == HiddenFishTriggerGesture.tapSequence
          ? _handleTap
          : null,
      onDoubleTap: widget.gesture == HiddenFishTriggerGesture.doubleTap
          ? () {
              debugPrint('[HiddenFish] Double tap trigger: ${widget.id}');
              _reveal();
            }
          : null,
      onLongPress:
          widget.gesture == HiddenFishTriggerGesture.longPress ||
              widget.gesture == HiddenFishTriggerGesture.hover
          ? () {
              debugPrint('[HiddenFish] Long press trigger: ${widget.id}');
              _reveal();
            }
          : null,
      onHorizontalDragEnd:
          widget.gesture == HiddenFishTriggerGesture.horizontalSwipe
          ? (_) {
              debugPrint('[HiddenFish] Horizontal swipe trigger: ${widget.id}');
              _reveal();
            }
          : null,
      child: widget.child,
    );

    if (widget.gesture == HiddenFishTriggerGesture.hover) {
      interactiveChild = MouseRegion(
        onEnter: _handleHover,
        child: interactiveChild,
      );
    }

    return interactiveChild;
  }
}
