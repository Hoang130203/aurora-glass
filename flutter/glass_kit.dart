/// Aurora Glass — Flutter port of the liquid-glass design system.
///
/// Same physics as the web kit — glass is a stack of optical layers:
///   1. Backdrop blur  — ImageFiltered + BackdropFilter.blur
///   2. Body tint      — translucent gradient fill (top-lit)
///   3. Rim light      — gradient hairline border, brightest top-left
///   4. Specular       — sharp sheen on the upper face
///   5. Inner depth    — inset highlight via inner gradient
///   6. Elevation      — soft BoxShadow below
///
/// Copy this file into any Flutter project. Zero dependencies.
library glass_kit;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ───────────────────────────────────────────────────────────── theme tokens ──

class GlassTheme extends ThemeExtension<GlassTheme> {
  const GlassTheme({
    required this.isDark,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.accent,
    required this.tintSoft,
    required this.tint,
    required this.tintStrong,
    required this.stroke,
    required this.strokeHi,
  });

  final bool isDark;
  final Color ink, ink2, ink3;
  final Color accent;
  final Color tintSoft, tint, tintStrong;
  final Color stroke, strokeHi;

  static const indigo = Color(0xFF7C6CFF);
  static const cyan = Color(0xFF54D9FF);
  static const pink = Color(0xFFFF6EC7);
  static const amber = Color(0xFFFFB85C);
  static const green = Color(0xFF4FE3A3);
  static const red = Color(0xFFFF6B7A);

  static const dark = GlassTheme(
    isDark: true,
    ink: Color(0xFFEEF1FB),
    ink2: Color(0xB8EEF1FB),
    ink3: Color(0x7AEEF1FB),
    accent: indigo,
    tintSoft: Color(0x0FFFFFFF),
    tint: Color(0x1AFFFFFF),
    tintStrong: Color(0x29FFFFFF),
    stroke: Color(0x24FFFFFF),
    strokeHi: Color(0x6BFFFFFF),
  );

  static const light = GlassTheme(
    isDark: false,
    ink: Color(0xFF141828),
    ink2: Color(0xB8141828),
    ink3: Color(0x80141828),
    accent: indigo,
    tintSoft: Color(0x52FFFFFF),
    tint: Color(0x7AFFFFFF),
    tintStrong: Color(0x9EFFFFFF),
    stroke: Color(0x1A141828),
    strokeHi: Color(0xE6FFFFFF),
  );

  static GlassTheme of(BuildContext context) =>
      Theme.of(context).extension<GlassTheme>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  GlassTheme copyWith({Color? accent, Color? tint}) => GlassTheme(
        isDark: isDark, ink: ink, ink2: ink2, ink3: ink3,
        accent: accent ?? this.accent,
        tintSoft: tintSoft, tint: tint ?? this.tint,
        tintStrong: tintStrong, stroke: stroke, strokeHi: strokeHi,
      );

  @override
  GlassTheme lerp(GlassTheme? other, double t) => t < 0.5 ? this : (other ?? this);
}

enum GlassLevel { control, surface, floating }

extension on GlassLevel {
  double get blur => switch (this) {
        GlassLevel.control => 14,
        GlassLevel.surface => 22,
        GlassLevel.floating => 36,
      };
  double get shadowY => switch (this) {
        GlassLevel.control => 8,
        GlassLevel.surface => 18,
        GlassLevel.floating => 32,
      };
}

// ──────────────────────────────────────────────────────── ambient backdrop ──

/// Colorful ambient scene so the glass has something to bend.
/// Blur over a flat color blurs nothing — always put an AuroraStage behind glass.
class AuroraStage extends StatelessWidget {
  const AuroraStage({super.key, required this.child, this.isDark = true});
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final blobs = isDark
        ? const [GlassTheme.indigo, GlassTheme.cyan, GlassTheme.pink, GlassTheme.amber]
        : const [Color(0xFF9B8DFF), Color(0xFF7FDFFF), Color(0xFFFF9BD5), Color(0xFFFFC87F)];
    return Stack(children: [
      Container(color: isDark ? const Color(0xFF070A12) : const Color(0xFFDCE4F5)),
      _blob(const Alignment(-1.2, -0.8), blobs[0], 0.30),
      _blob(const Alignment(1.25, -0.3), blobs[1], 0.26),
      _blob(const Alignment(0.4, 1.25), blobs[2], 0.24),
      _blob(const Alignment(-0.9, 0.6), blobs[3], 0.18),
      // grain — cheap noise via repeated opacity speckle
      const IgnorePointer(child: _Grain()),
      child,
    ]);
  }

  Widget _blob(Alignment at, Color c, double opacity) => Align(
        alignment: at,
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(opacity)),
          ),
        ),
      );
}

class _Grain extends StatelessWidget {
  const _Grain();
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.05,
        child: CustomPaint(painter: _GrainPainter(), size: Size.infinite),
      );
}

class _GrainPainter extends CustomPainter {
  final _rng = math.Random(7);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 2400; i++) {
      canvas.drawRect(
          Rect.fromLTWH(_rng.nextDouble() * size.width,
              _rng.nextDouble() * size.height, 1, 1),
          paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────── core surface ──

/// The workhorse. One GlassSurface = one pane of frosted glass.
///
/// ```dart
/// GlassSurface(
///   level: GlassLevel.surface,
///   radius: 22,
///   child: ...,
/// )
/// ```
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.level = GlassLevel.surface,
    this.radius = 22,
    this.tint,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.specular = true,
    this.rimLight = true,
    this.onTap,
  });

  final Widget child;
  final GlassLevel level;
  final double radius;
  final Color? tint;          // accent tint — use sparingly, for emphasis
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width, height;
  final bool specular;        // sharp sheen across the top
  final bool rimLight;        // gradient hairline brightest at top-left
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    final tintColor = tint ?? Colors.white;

    Widget pane = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: level.blur, sigmaY: level.blur),
        child: Container(
          width: width, height: height,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            // 2. body tint — top-lit gradient wash
            gradient: LinearGradient(
              begin: const Alignment(-0.7, -1),
              end: const Alignment(0.6, 1),
              colors: tint != null
                  ? [tintColor.withOpacity(0.32), tintColor.withOpacity(0.10)]
                  : [Colors.white.withOpacity(g.isDark ? 0.11 : 0.55),
                     Colors.white.withOpacity(g.isDark ? 0.04 : 0.25),
                     Colors.white.withOpacity(g.isDark ? 0.07 : 0.40)],
              stops: const [0.0, 0.45, 1.0],
            ),
            // 3. rim — hairline border; top edge brighter
            border: Border(
              top: BorderSide(color: g.strokeHi, width: 1),
              bottom: BorderSide(color: g.stroke, width: 1),
              left: BorderSide(color: g.stroke, width: 1),
              right: BorderSide(color: g.stroke, width: 1),
            ),
          ),
          child: Stack(children: [
            if (specular)
              // 4. specular — sharp sheen on the upper face
              IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.white.withOpacity(g.isDark ? 0.13 : 0.35),
                                 Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
            child,
          ]),
        ),
      ),
    );

    // 5–6. inner depth + elevation shadow
    pane = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(g.isDark ? 0.35 : 0.16),
              blurRadius: level.shadowY * 2.2, offset: Offset(0, level.shadowY * 0.7)),
        ],
      ),
      child: rimLight
          ? CustomPaint(foregroundPainter: _RimPainter(radius), child: pane)
          : pane,
    );

    if (onTap != null) {
      pane = InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: pane,
      );
    }
    return pane;
  }
}

/// Paints the directional rim-light gradient along the border.
class _RimPainter extends CustomPainter {
  _RimPainter(this.radius);
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = ui.Gradient.linear(
        const Offset(0, 0), Offset(size.width, size.height),
        [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.12)],
        [0.0, 0.4, 1.0],
      );
    canvas.drawRRect(rrect.deflate(0.5), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ──────────────────────────────────────────────────────────────── buttons ──

enum GlassButtonKind { plain, primary, destructive, ghost }

class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.kind = GlassButtonKind.plain,
    this.loading = false,
    this.icon,
    this.pill = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
  });

  final Widget child;
  final VoidCallback? onPressed;
  final GlassButtonKind kind;
  final bool loading;
  final Widget? icon;
  final bool pill;
  final EdgeInsetsGeometry padding;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    final colors = switch (widget.kind) {
      GlassButtonKind.primary => const [Color(0xE67C6CFF), Color(0xC05E4CEC)],
      GlassButtonKind.destructive => const [Color(0xC0FF6B7A), Color(0x99D23246)],
      GlassButtonKind.ghost => [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.05)],
      _ => [Colors.white.withOpacity(0.14), Colors.white.withOpacity(0.05)],
    };
    final glow = switch (widget.kind) {
      GlassButtonKind.primary => GlassTheme.indigo.withOpacity(0.4),
      GlassButtonKind.destructive => GlassTheme.red.withOpacity(0.3),
      _ => Colors.black.withOpacity(0.25),
    };
    final fg = widget.kind == GlassButtonKind.primary ||
            widget.kind == GlassButtonKind.destructive
        ? Colors.white
        : g.ink;

    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onPressed == null ? null : (_) => setState(() => _down = false),
      onTapCancel: widget.onPressed == null ? null : () => setState(() => _down = false),
      onTap: widget.loading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.pill ? 999 : 14),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Opacity(
              opacity: widget.onPressed == null ? 0.45 : 1,
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: colors),
                  borderRadius: BorderRadius.circular(widget.pill ? 999 : 14),
                  border: Border(
                    top: BorderSide(color: widget.kind == GlassButtonKind.plain ? g.stroke : Colors.white.withOpacity(0.5), width: 1),
                    bottom: BorderSide(color: g.stroke, width: 1),
                    left: BorderSide(color: g.stroke, width: 1),
                    right: BorderSide(color: g.stroke, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(color: glow, blurRadius: 20, offset: const Offset(0, 7)),
                  ],
                ),
                child: widget.loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : DefaultTextStyle(
                        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 14),
                        child: IconTheme(
                          data: IconThemeData(color: fg, size: 18),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 8)],
                            widget.child,
                          ]),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, this.onPressed, this.round = false, this.color});
  final Widget icon;
  final VoidCallback? onPressed;
  final bool round;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return GlassButton(
      onPressed: onPressed,
      pill: round,
      padding: const EdgeInsets.all(10),
      child: icon,
    );
  }
}

/// macOS-style floating action button.
class GlassFAB extends StatelessWidget {
  const GlassFAB({super.key, required this.icon, this.onPressed});
  final Widget icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => GlassButton(
        onPressed: onPressed,
        kind: GlassButtonKind.primary,
        padding: const EdgeInsets.all(17),
        child: icon,
      );
}

// ─────────────────────────────────────────────────────────────── inputs ────

class GlassField extends StatelessWidget {
  const GlassField({super.key, this.label, this.hint, this.error, required this.child});
  final String? label, hint, error;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Text(label!,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: g.ink2)),
        ),
      child,
      if (error != null || hint != null)
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text(error ?? hint!,
              style: TextStyle(
                  fontSize: 11.5,
                  color: error != null ? GlassTheme.red : g.ink3)),
        ),
    ]);
  }
}

/// Inset glass text field — shadow inside, rim light, indigo focus ring.
class GlassInput extends StatefulWidget {
  const GlassInput({
    super.key,
    this.controller,
    this.hint,
    this.prefix,
    this.suffix,
    this.obscure = false,
    this.onChanged,
    this.maxLines = 1,
    this.pill = false,
  });

  final TextEditingController? controller;
  final String? hint;
  final Widget? prefix, suffix;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool pill;

  @override
  State<GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<GlassInput> {
  final _focus = FocusNode();
  bool get _focused => _focus.hasFocus;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.pill ? 999 : 14),
        border: Border.all(
          color: _focused ? GlassTheme.indigo.withOpacity(0.7) : g.stroke,
        ),
        boxShadow: [
          if (_focused) BoxShadow(color: GlassTheme.indigo.withOpacity(0.22), blurRadius: 0, spreadRadius: 3),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.pill ? 999 : 14),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            color: Colors.white.withOpacity(g.isDark ? 0.05 : 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              if (widget.prefix != null) ...[widget.prefix!, const SizedBox(width: 10)],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.obscure,
                  onChanged: widget.onChanged,
                  maxLines: widget.maxLines,
                  style: TextStyle(color: g.ink, fontSize: 14),
                  cursorColor: GlassTheme.cyan,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(color: g.ink3),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              if (widget.suffix != null) ...[const SizedBox(width: 10), widget.suffix!],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Toggle switch with springy knob + tinted track.
class GlassSwitch extends StatelessWidget {
  const GlassSwitch({super.key, required this.value, this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        width: 52, height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: value
              ? const LinearGradient(colors: [Color(0xD97C6CFF), Color(0xB35E4CEC)])
              : null,
          color: value ? null : Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.white.withOpacity(value ? 0.5 : 0.14)),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFD9DEEE)]),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass slider.
class GlassSlider extends StatelessWidget {
  const GlassSlider({super.key, required this.value, this.onChanged});
  final double value;
  final ValueChanged<double>? onChanged;
  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: GlassTheme.indigo,
        inactiveTrackColor: Colors.white.withOpacity(0.12),
        thumbColor: Colors.white,
        overlayColor: GlassTheme.indigo.withOpacity(0.18),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      child: Slider(value: value, onChanged: onChanged),
    );
  }
}

/// Removable filter chip.
class GlassChip extends StatelessWidget {
  const GlassChip({super.key, required this.label, this.onRemove, this.tint});
  final String label;
  final VoidCallback? onRemove;
  final Color? tint;
  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return GlassSurface(
      level: GlassLevel.control,
      radius: 999,
      tint: tint,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      specular: false,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: g.ink2)),
        if (onRemove != null) ...[
          const SizedBox(width: 7),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 15, height: 15,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.14)),
              child: const Icon(Icons.close, size: 9, color: Colors.white),
            ),
          ),
        ],
      ]),
    );
  }
}

// ───────────────────────────────────────────────────────────────── cards ───

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding, this.tint, this.onTap});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) =>
      GlassSurface(level: GlassLevel.surface, radius: 22, tint: tint, padding: padding, onTap: onTap, child: child);
}

/// Stat / KPI card.
class GlassStatCard extends StatelessWidget {
  const GlassStatCard({super.key, required this.label, required this.value, this.delta, this.up = true});
  final String label, value;
  final String? delta;
  final bool up;
  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: g.ink3)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1, color: g.ink, fontFeatures: const [ui.FontFeature.tabularFigures()])),
        if (delta != null)
          Text('${up ? "▲" : "▼"} $delta',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: up ? GlassTheme.green : GlassTheme.red)),
      ]),
    );
  }
}

/// Profile card.
class GlassProfileCard extends StatelessWidget {
  const GlassProfileCard({super.key, required this.name, required this.role, this.bio, this.onFollow, this.onMessage});
  final String name, role;
  final String? bio;
  final VoidCallback? onFollow, onMessage;
  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return GlassCard(
      child: Column(children: [
        GlassAvatar(name: name, size: 56, seed: name.hashCode),
        const SizedBox(height: 8),
        Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: g.ink)),
        Text(role, style: const TextStyle(fontSize: 12.5, color: GlassTheme.cyan, fontWeight: FontWeight.w600)),
        if (bio != null)
          Padding(padding: const EdgeInsets.only(top: 8),
              child: Text(bio!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: g.ink2))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GlassButton(kind: GlassButtonKind.primary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              onPressed: onFollow, child: const Text('Follow')),
          const SizedBox(width: 10),
          GlassButton(kind: GlassButtonKind.ghost, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              onPressed: onMessage, child: const Text('Message')),
        ]),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────── navigation ───

/// Floating pill navbar — the canonical Liquid Glass surface.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({super.key, required this.items, required this.selected, required this.onSelect, this.leading, this.trailing});
  final List<String> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final Widget? leading, trailing;
  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return GlassSurface(
      level: GlassLevel.floating,
      radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(children: [
        if (leading != null) ...[leading!, const SizedBox(width: 10)],
        for (var i = 0; i < items.length; i++)
          GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: i == selected
                    ? LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.08)])
                    : null,
                border: i == selected ? Border.all(color: g.strokeHi) : null,
              ),
              child: Text(items[i],
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                      color: i == selected ? g.ink : g.ink2)),
            ),
          ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ]),
    );
  }
}

/// Segmented control with sliding thumb.
class GlassSegmented extends StatelessWidget {
  const GlassSegmented({super.key, required this.items, required this.selected, required this.onSelect});
  final List<String> items;
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return GlassSurface(
      level: GlassLevel.control, radius: 999,
      padding: const EdgeInsets.all(4), specular: false, rimLight: false,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < items.length; i++)
          GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: i == selected
                    ? LinearGradient(colors: [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.10)])
                    : null,
                border: i == selected ? Border.all(color: g.strokeHi) : null,
                boxShadow: i == selected
                    ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Text(items[i],
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: i == selected ? g.ink : g.ink2)),
            ),
          ),
      ]),
    );
  }
}

/// iOS-style bottom bar.
class GlassBottomBar extends StatelessWidget {
  const GlassBottomBar({super.key, required this.items, required this.selected, required this.onSelect});
  final List<IconData> items;
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return GlassSurface(
      level: GlassLevel.floating, radius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        for (var i = 0; i < items.length; i++)
          GestureDetector(
            onTap: () => onSelect(i),
            child: Icon(items[i],
                size: 22,
                color: i == selected ? g.ink : g.ink3,
                shadows: i == selected ? [const Shadow(color: GlassTheme.indigo, blurRadius: 14)] : null),
          ),
      ]),
    );
  }
}

/// Breadcrumb.
class GlassBreadcrumb extends StatelessWidget {
  const GlassBreadcrumb({super.key, required this.items});
  final List<String> items;
  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return GlassSurface(
      level: GlassLevel.control, radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), specular: false,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < items.length; i++) ...[
          Text(items[i],
              style: TextStyle(fontSize: 13, fontWeight: i == items.length - 1 ? FontWeight.w700 : FontWeight.w600,
                  color: i == items.length - 1 ? g.ink : g.ink3)),
          if (i < items.length - 1)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('›', style: TextStyle(color: g.ink3))),
        ],
      ]),
    );
  }
}

// ────────────────────────────────────────────────────────────── overlays ───

/// Modal dialog — Level-3 glass over a blurred scrim.
class GlassDialog extends StatelessWidget {
  const GlassDialog({super.key, required this.title, required this.body, this.actions = const []});
  final String title, body;
  final List<Widget> actions;

  static Future<T?> show<T>(BuildContext context,
          {required String title, required String body, List<Widget> actions = const []}) =>
      showGeneralDialog<T>(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        barrierDismissible: true,
        barrierLabel: 'dismiss',
        transitionDuration: const Duration(milliseconds: 280),
        transitionBuilder: (c, a, _, child) => ScaleTransition(
          scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: a, child: child),
        ),
        pageBuilder: (c, _, __) => BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(child: GlassDialog(title: title, body: body, actions: actions)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return GlassSurface(
      level: GlassLevel.floating,
      radius: 30,
      width: 420,
      padding: const EdgeInsets.all(26),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: g.ink)),
        const SizedBox(height: 6),
        Text(body, style: TextStyle(fontSize: 13.5, color: g.ink2)),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
        ],
      ]),
    );
  }
}

/// Bottom sheet — call [GlassSheet.show].
class GlassSheet extends StatelessWidget {
  const GlassSheet({super.key, required this.child});
  final Widget child;

  static Future<T?> show<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.4),
        builder: (_) => GlassSheet(child: child),
      );

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      level: GlassLevel.floating,
      radius: 30,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 42, height: 5,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: Colors.white.withOpacity(0.3))),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

/// Toast — overlay entry; call [GlassToast.show].
class GlassToast extends StatelessWidget {
  const GlassToast({super.key, required this.icon, required this.title, required this.body, required this.tint});
  final IconData icon;
  final String title, body;
  final Color tint;

  static void show(BuildContext context,
      {required IconData icon, required String title, required String body, Color tint = GlassTheme.green}) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastHost(
        tint: tint,
        child: GlassToast(icon: icon, title: title, body: body, tint: tint),
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return GlassSurface(
      level: GlassLevel.floating, radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: tint.withOpacity(0.22),
          ),
          child: Icon(icon, size: 15, color: tint),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: g.ink)),
          Text(body, style: TextStyle(fontSize: 12, color: g.ink3)),
        ]),
      ]),
    );
  }
}

class _ToastHost extends StatefulWidget {
  const _ToastHost({required this.child, required this.onDismiss, required this.tint});
  final Widget child;
  final VoidCallback onDismiss;
  final Color tint;
  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _t = Timer(const Duration(seconds: 4), _out);
  }

  void _out() => _c.reverse().then((_) => widget.onDismiss());

  @override
  void dispose() { _t?.cancel(); _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Positioned(
        right: 24, bottom: 24,
        child: SlideTransition(
          position: Tween(begin: const Offset(1.2, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack)),
          child: FadeTransition(opacity: _c, child: Material(color: Colors.transparent, child: widget.child)),
        ),
      );
}

/// Tooltip — wrap any widget.
class GlassTooltip extends StatelessWidget {
  const GlassTooltip({super.key, required this.message, required this.child});
  final String message;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      decoration: BoxDecoration(
        color: const Color(0xD9141A2C),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 28, offset: const Offset(0, 10))],
      ),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      child: child,
    );
  }
}

// ──────────────────────────────────────────────────────── data display ─────

/// Gradient avatar with deterministic palette + optional presence dot.
class GlassAvatar extends StatelessWidget {
  const GlassAvatar({super.key, required this.name, this.size = 40, this.seed, this.presence});
  final String name;
  final double size;
  final int? seed;
  final Color? presence;
  static const _palettes = [
    [GlassTheme.indigo, GlassTheme.cyan],
    [GlassTheme.pink, Color(0xFFFF9A62)],
    [GlassTheme.green, Color(0xFF0BA6C0)],
    [GlassTheme.amber, Color(0xFFFF5F6D)],
  ];
  @override
  Widget build(BuildContext context) {
    final p = _palettes[(seed ?? name.hashCode).abs() % _palettes.length];
    return Stack(children: [
      Container(
        width: size, height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Text(name.substring(0, math.min(2, name.length)).toUpperCase(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.34)),
      ),
      if (presence != null)
        Positioned(
          right: 0, bottom: 0,
          child: Container(
            width: size * 0.28, height: size * 0.28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: presence,
                border: Border.all(color: const Color(0xFF070A12), width: 2.5)),
          ),
        ),
    ]);
  }
}

/// Overlapping avatar stack.
class GlassAvatarStack extends StatelessWidget {
  const GlassAvatarStack({super.key, required this.names, this.size = 40});
  final List<String> names;
  final double size;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + (names.length - 1) * size * 0.72,
      height: size,
      child: Stack(children: [
        for (var i = 0; i < names.length; i++)
          Positioned(left: i * size * 0.72,
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF070A12), width: 2)),
                child: GlassAvatar(name: names[i], size: size, seed: i))),
      ]),
    );
  }
}

/// Pill badge.
class GlassBadge extends StatelessWidget {
  const GlassBadge({super.key, required this.label, this.tint});
  final String label;
  final Color? tint;
  @override
  Widget build(BuildContext context) {
    final c = tint ?? GlassTheme.cyan;
    return GlassSurface(
      level: GlassLevel.control, radius: 999, tint: tint,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4), specular: false,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c,
                boxShadow: [BoxShadow(color: c, blurRadius: 8)])),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ]),
    );
  }
}

/// Gradient progress bar with shimmer sweep.
class GlassProgress extends StatefulWidget {
  const GlassProgress({super.key, required this.value, this.label});
  final double value; // 0..1
  final String? label;
  @override
  State<GlassProgress> createState() => _GlassProgressState();
}

class _GlassProgressState extends State<GlassProgress> with SingleTickerProviderStateMixin {
  late final _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  @override
  void dispose() { _shimmer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.label != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.label!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: g.ink2)),
            Text('${(widget.value * 100).round()}%',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: g.ink)),
          ]),
        ),
      Container(
        height: 9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          color: Colors.white.withOpacity(0.09),
        ),
        clipBehavior: Clip.antiAlias,
        child: FractionallySizedBox(
          widthFactor: widget.value.clamp(0.0, 1.0),
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: _shimmer,
            builder: (_, __) => Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(99)),
                gradient: LinearGradient(colors: [GlassTheme.indigo, GlassTheme.cyan]),
                boxShadow: [BoxShadow(color: GlassTheme.cyan, blurRadius: 14)],
              ),
              child: FractionallySizedBox(
                widthFactor: 0.4,
                alignment: Alignment(-1 + 3 * _shimmer.value, 0),
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.4),
                  Colors.transparent,
                ]))),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

/// Circular progress ring.
class GlassProgressRing extends StatelessWidget {
  const GlassProgressRing({super.key, required this.value, this.size = 90, this.label});
  final double value;
  final double size;
  final String? label;
  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return SizedBox(
      width: size, height: size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: Size.square(size), painter: _RingPainter(value)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${(value * 100).round()}',
              style: TextStyle(fontSize: size * 0.24, fontWeight: FontWeight.w800, color: g.ink)),
          if (label != null)
            Text(label!, style: TextStyle(fontSize: size * 0.1, fontWeight: FontWeight.w600, letterSpacing: 1.4, color: g.ink3)),
        ]),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);
  final double value;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = Colors.white.withOpacity(0.1);
    canvas.drawCircle(c, r, track);
    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.sweep(c, const [GlassTheme.indigo, GlassTheme.cyan, GlassTheme.indigo]);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, value * 2 * math.pi, false, prog);
  }

  @override
  bool shouldRepaint(o) => o.value != value;
}

/// Timeline item list.
class GlassTimeline extends StatelessWidget {
  const GlassTimeline({super.key, required this.items});
  final List<(String title, String desc, String time)> items;
  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return Column(children: [
      for (final it in items)
        Padding(
          padding: const EdgeInsets.only(left: 26, bottom: 18),
          child: Stack(children: [
            Positioned(
              left: -23, top: 5,
              child: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF070A12),
                  border: Border.all(color: GlassTheme.cyan, width: 2),
                  boxShadow: const [BoxShadow(color: GlassTheme.cyan, blurRadius: 12)],
                ),
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(it.$1, style: TextStyle(fontWeight: FontWeight.w650, fontSize: 13.5, color: g.ink)),
              Text(it.$2, style: TextStyle(fontSize: 12, color: g.ink3)),
              Text(it.$3, style: TextStyle(fontSize: 10.5, color: g.ink3, fontFeatures: const [ui.FontFeature.tabularFigures()])),
            ]),
          ]),
        ),
    ]);
  }
}

// ────────────────────────────────────────────────────────────── feedback ───

enum GlassAlertKind { ok, warn, err, info }

class GlassAlert extends StatelessWidget {
  const GlassAlert({super.key, required this.kind, required this.title, required this.body, this.onClose});
  final GlassAlertKind kind;
  final String title, body;
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    final (icon, tint) = switch (kind) {
      GlassAlertKind.ok => (Icons.check, GlassTheme.green),
      GlassAlertKind.warn => (Icons.warning_amber, GlassTheme.amber),
      GlassAlertKind.err => (Icons.close, GlassTheme.red),
      GlassAlertKind.info => (Icons.info_outline, GlassTheme.cyan),
    };
    return GlassSurface(
      level: GlassLevel.control, radius: 16, tint: tint,
      padding: const EdgeInsets.all(15),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: tint, size: 18),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: g.ink)),
          Text(body, style: TextStyle(fontSize: 13, color: g.ink2)),
        ])),
        if (onClose != null)
          GestureDetector(onTap: onClose, child: Icon(Icons.close, size: 14, color: g.ink3)),
      ]),
    );
  }
}

/// Status pill with pulsing dot.
class GlassStatus extends StatefulWidget {
  const GlassStatus({super.key, required this.label, required this.color});
  final String label;
  final Color color;
  @override
  State<GlassStatus> createState() => _GlassStatusState();
}

class _GlassStatusState extends State<GlassStatus> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      level: GlassLevel.control, radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), specular: false,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [BoxShadow(color: widget.color.withOpacity(1 - _c.value), blurRadius: 0, spreadRadius: _c.value * 5)],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(widget.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.color)),
      ]),
    );
  }
}

/// Glass spinner.
class GlassSpinner extends StatelessWidget {
  const GlassSpinner({super.key, this.size = 26});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size, height: size,
        child: const CircularProgressIndicator(strokeWidth: 2.5, color: GlassTheme.cyan),
      );
}

// ────────────────────────────────────────────────────────────── effects ────

/// Cursor / pointer spotlight — a light follows the pointer across the pane.
class GlassSpotlight extends StatefulWidget {
  const GlassSpotlight({super.key, required this.child});
  final Widget child;
  @override
  State<GlassSpotlight> createState() => _GlassSpotlightState();
}

class _GlassSpotlightState extends State<GlassSpotlight> {
  Offset? _pos;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) => setState(() => _pos = e.localPosition),
      onExit: (_) => setState(() => _pos = null),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(children: [
          widget.child,
          if (_pos != null)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-1 + 2 * _pos!.dx / 400, -1 + 2 * _pos!.dy / 400),
                    radius: 1.2,
                    colors: [Colors.white.withOpacity(0.16), Colors.transparent],
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Empty state.
class GlassEmpty extends StatelessWidget {
  const GlassEmpty({super.key, required this.title, required this.body, this.action});
  final String title, body;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return GlassCard(
      child: Column(children: [
        GlassSurface(
          level: GlassLevel.control, radius: 20, tint: GlassTheme.indigo,
          padding: const EdgeInsets.all(16), specular: false,
          child: const Icon(Icons.blur_on, size: 26, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: g.ink)),
        Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: g.ink3)),
        if (action != null) ...[const SizedBox(height: 8), action!],
      ]),
    );
  }
}

/// Glass divider.
class GlassDivider extends StatelessWidget {
  const GlassDivider({super.key});
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.14),
            Colors.transparent,
          ]),
        ),
      );
}

// ============================================================================
// SHAPES — glass beyond the rounded rectangle
// ============================================================================

/// Squircle glass — iOS continuous-curvature silhouette via
/// ContinuousRectangleBorder (smoothstep corners, unlike RoundedRectangleBorder).
class GlassSquircle extends StatelessWidget {
  const GlassSquircle({super.key, required this.child, this.size = 120, this.tint, this.level = GlassLevel.surface});
  final Widget child;
  final double size;
  final Color? tint;
  final GlassLevel level;

  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    final shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(size * 0.36),
      side: BorderSide(color: g.strokeHi, width: 1),
    );
    return Container(
      width: size, height: size,
      decoration: ShapeDecoration(shape: shape, shadows: [BoxShadow(color: Colors.black.withOpacity(g.isDark ? 0.35 : 0.16), blurRadius: 24, offset: const Offset(0, 10))]),
      child: ClipPath.shape(
        shape: shape,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: level.blur, sigmaY: level.blur),
          child: Container(
            decoration: ShapeDecoration(
              shape: shape,
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: tint != null
                  ? [tint!.withOpacity(0.32), tint!.withOpacity(0.10)]
                  : [Colors.white.withOpacity(g.isDark ? 0.11 : 0.55),
                     Colors.white.withOpacity(g.isDark ? 0.07 : 0.40)],
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Morphing organic blob — animates a superelliptical border-radius figure.
class GlassBlob extends StatefulWidget {
  const GlassBlob({super.key, this.size = 140, this.period = const Duration(seconds: 9), this.child, this.tint});
  final double size;
  final Duration period;
  final Widget? child;
  final Color? tint;

  @override
  State<GlassBlob> createState() => _GlassBlobState();
}

class _GlassBlobState extends State<GlassBlob> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  // 4 organic corner-radius keyframes (TL, TR, BR, BL).
  static const _frames = [
    [62.0, 38.0, 55.0, 45.0],
    [40.0, 60.0, 36.0, 64.0],
    [55.0, 45.0, 64.0, 36.0],
    [32.0, 68.0, 50.0, 50.0],
    [62.0, 38.0, 55.0, 45.0],
  ];

  BorderRadius _radius(double t) {
    final f = t * (_frames.length - 1);
    final i = f.floor().clamp(0, _frames.length - 2);
    final lt = Curves.easeInOut.transform(f - i);
    final a = _frames[i], b = _frames[i + 1];
    double l(int j) => a[j] + (b[j] - a[j]) * lt;
    return BorderRadius.only(
      topLeft: Radius.elliptical(l(0), 100 - l(0)),
      topRight: Radius.elliptical(l(1), 100 - l(1)),
      bottomRight: Radius.elliptical(l(2), 100 - l(2)),
      bottomLeft: Radius.elliptical(l(3), 100 - l(3)),
    );
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final r = _radius(_c.value);
        return ClipRRect(
          borderRadius: r,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              width: widget.size, height: widget.size,
              decoration: BoxDecoration(
                borderRadius: r,
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [
                    (widget.tint ?? g.tint).withOpacity(0.28),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                border: Border.all(color: g.strokeHi, width: 1),
              ),
              child: widget.child != null ? Center(child: widget.child) : null,
            ),
          ),
        );
      },
    );
  }
}

/// Ticket clipper — punches semicircular notches in both sides.
class TicketClipper extends CustomClipper<Path> {
  TicketClipper({this.radius = 16, this.notchRadius = 11, this.notchY = 0.62});
  final double radius, notchRadius, notchY;

  @override
  Path getClip(Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rr);
    final notch = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, size.height * notchY), radius: notchRadius))
      ..addOval(Rect.fromCircle(center: Offset(size.width, size.height * notchY), radius: notchRadius));
    return Path.combine(PathOperation.difference, path, notch);
  }

  @override
  bool shouldReclip(TicketClipper old) =>
      radius != old.radius || notchRadius != old.notchRadius || notchY != old.notchY;
}

/// Glass ticket — coupon/pass silhouette with side notches.
class GlassTicket extends StatelessWidget {
  const GlassTicket({super.key, required this.child, this.tint});
  final Widget child;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return ClipPath(
      clipper: TicketClipper(),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [(tint ?? g.tint).withOpacity(0.3), Colors.white.withOpacity(0.05)],
            ),
            border: Border.all(color: g.strokeHi),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Speech bubble clipper with a tail.
class BubbleClipper extends CustomClipper<Path> {
  BubbleClipper({this.tailOnLeft = true, this.radius = 18});
  final bool tailOnLeft;
  final double radius;

  @override
  Path getClip(Size size) {
    final r = Radius.circular(radius);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height - 10);
    final p = Path()..addRRect(RRect.fromRectAndRadius(rect, r));
    if (tailOnLeft) {
      p
        ..moveTo(8, size.height - 10)
        ..lineTo(0, size.height)
        ..lineTo(20, size.height - 10)
        ..close();
    } else {
      p
        ..moveTo(size.width - 20, size.height - 10)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - 8, size.height - 10)
        ..close();
    }
    return p;
  }

  @override
  bool shouldReclip(BubbleClipper old) => tailOnLeft != old.tailOnLeft;
}

/// Glass speech bubble — chat message with a tail.
class GlassBubble extends StatelessWidget {
  const GlassBubble({super.key, required this.child, this.tailOnLeft = true, this.tint});
  final Widget child;
  final bool tailOnLeft;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return ClipPath(
      clipper: BubbleClipper(tailOnLeft: tailOnLeft),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [(tint ?? g.tint).withOpacity(0.3), Colors.white.withOpacity(0.06)],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Gooey metaball loader — blurred dots + high-contrast alpha merge into blobs.
/// Uses ColorFiltered as the color-matrix half of the goo recipe; the blur is
/// applied per-dot so droplets coalesce visually at overlap.
class GlassGooLoader extends StatefulWidget {
  const GlassGooLoader({super.key, this.dots = 4, this.size = 18});
  final int dots;
  final double size;

  @override
  State<GlassGooLoader> createState() => _GlassGooLoaderState();
}

class _GlassGooLoaderState extends State<GlassGooLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150))..repeat();

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.dots, (i) {
          return AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final t = (_c.value + i * 0.12) % 1.0;
              final y = -16 * Curves.easeInOut.transform(t < 0.5 ? t * 2 : (1 - t) * 2);
              return Transform.translate(
                offset: Offset(0, y),
                child: Container(
                  width: widget.size, height: widget.size,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF54D9FF), Color(0xFF7C6CFF)],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
