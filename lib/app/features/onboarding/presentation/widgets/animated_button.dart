import 'package:flutter/material.dart';

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? pressedBackgroundColor;
  final List<BoxShadow> boxShadow;
  final Color? textColor;
  final Color? pressedTextColor;
  final bool isSelected;
  final bool enabled;
  final Color? selectedBackgroundColor;
  final Color? selectedTextColor;
  final Color? disabledBackgroundColor;
  final Color? disabledTextColor;
  final BoxConstraints constraints;
  final TextStyle textStyle;
  final double width;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.backgroundColor,
    this.pressedBackgroundColor,
    this.boxShadow = const [],
    this.textColor,
    this.pressedTextColor,
    this.isSelected = false,
    this.enabled = true,
    this.selectedBackgroundColor,
    this.selectedTextColor,
    this.disabledBackgroundColor,
    this.disabledTextColor,
    this.constraints = const BoxConstraints(minHeight: 56, maxHeight: 60),
    this.textStyle = const TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      fontSize: 16,
      letterSpacing: 0.15,
    ),
    this.width = double.infinity,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) {
      value = false;
    }
    if (_pressed != value) {
      setState(() {
        _pressed = value;
      });
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _pressed) {
      setState(() {
        _pressed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(100);
    final colorScheme = Theme.of(context).colorScheme;

    final Color backgroundColor =
        widget.backgroundColor ?? colorScheme.surfaceContainerHighest;
    final Color pressedBackgroundColor =
        widget.pressedBackgroundColor ??
        Color.alphaBlend(
          colorScheme.primary.withOpacity(0.15),
          backgroundColor,
        );
    final Color textColor = widget.textColor ?? colorScheme.onSurface;
    final Color pressedTextColor =
        widget.pressedTextColor ?? colorScheme.onSurface;
    final Color selectedBackgroundColor =
        widget.selectedBackgroundColor ?? colorScheme.primary;
    final Color selectedTextColor =
        widget.selectedTextColor ?? colorScheme.onPrimary;
    final Color disabledBackgroundColor =
        widget.disabledBackgroundColor ??
        colorScheme.surfaceContainerHighest.withOpacity(
          colorScheme.brightness == Brightness.dark ? 0.45 : 0.7,
        );
    final Color disabledTextColor =
        widget.disabledTextColor ??
        colorScheme.onSurfaceVariant.withOpacity(0.6);

    Color resolvedBackgroundColor;
    Color resolvedTextColor;

    if (!widget.enabled) {
      resolvedBackgroundColor = disabledBackgroundColor;
      resolvedTextColor = disabledTextColor;
    } else if (_pressed) {
      resolvedBackgroundColor = pressedBackgroundColor;
      resolvedTextColor = pressedTextColor;
    } else if (widget.isSelected) {
      resolvedBackgroundColor = selectedBackgroundColor;
      resolvedTextColor = selectedTextColor;
    } else {
      resolvedBackgroundColor = backgroundColor;
      resolvedTextColor = textColor;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: widget.width,
      constraints: widget.constraints,
      decoration: BoxDecoration(
        color: resolvedBackgroundColor,
        borderRadius: radius,
        boxShadow: widget.boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.enabled ? widget.onTap : null,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          onHighlightChanged: widget.enabled ? _setPressed : null,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            style: widget.textStyle.copyWith(color: resolvedTextColor),
            child: IconTheme(
              data: IconThemeData(color: resolvedTextColor),
              child: Padding(
                padding: widget.padding,
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
