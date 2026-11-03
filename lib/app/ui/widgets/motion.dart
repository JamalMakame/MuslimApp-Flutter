import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rive/rive.dart';

/// Plays `assets/rive/<name>.riv` (its `main` state machine, or its first
/// animation) when that file is bundled; otherwise shows [fallback]. A
/// designer's Rive file can replace any built-in animation without code
/// changes: see docs/ANIMATIONS.md.
class DeenRive extends StatefulWidget {
  const DeenRive(
    this.name, {
    super.key,
    required this.fallback,
    this.fit = BoxFit.contain,
  });

  final String name;
  final Widget fallback;
  final BoxFit fit;

  static final _files = <String, RiveFile?>{};

  /// The bundled Rive file for [name], or null; looked up once per name.
  static Future<RiveFile?> load(String name) async {
    if (_files.containsKey(name)) return _files[name];
    RiveFile? file;
    try {
      final data = await rootBundle.load('assets/rive/$name.riv');
      await RiveFile.initialize();
      file = RiveFile.import(data);
    } catch (_) {
      file = null;
    }
    return _files[name] = file;
  }

  @override
  State<DeenRive> createState() => _DeenRiveState();
}

class _DeenRiveState extends State<DeenRive> {
  RiveFile? _file;

  @override
  void initState() {
    super.initState();
    _file = DeenRive._files[widget.name];
    if (!DeenRive._files.containsKey(widget.name)) {
      DeenRive.load(widget.name).then((f) {
        if (mounted && f != null) setState(() => _file = f);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    if (file == null) return widget.fallback;
    final hasMain = file.mainArtboard.stateMachines.any(
      (s) => s.name == 'main',
    );
    return RiveAnimation.direct(
      file,
      key: ValueKey('rive-${widget.name}'),
      stateMachines: hasMain ? const ['main'] : const [],
      fit: widget.fit,
      placeHolder: widget.fallback,
    );
  }
}

/// Shrinks its child slightly while a finger is down, for tap feedback.
/// Purely visual: the child keeps its own tap handling.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.scale = 0.96});
  final Widget child;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// Fades and slides its child up into place once, [index] steps after the
/// first item of a list.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  static const step = 60;
  static const length = 380;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final int _delay = math.min(widget.index, 8) * FadeSlideIn.step;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _delay + FadeSlideIn.length),
  )..forward();
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      _delay / (_delay + FadeSlideIn.length),
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _t,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(_t),
      child: widget.child,
    ),
  );
}

/// [children], each fading in a little after the one before.
List<Widget> staggered(List<Widget> children) => [
  for (var i = 0; i < children.length; i++)
    FadeSlideIn(index: i, child: children[i]),
];

/// An icon that pops in with a bounce, for empty states.
class PopInIcon extends StatelessWidget {
  const PopInIcon(this.icon, {super.key, this.color, this.size = 56});
  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 700),
    curve: Curves.elasticOut,
    builder: (_, v, child) => Transform.scale(scale: v, child: child),
    child: Icon(icon, size: size, color: color),
  );
}
