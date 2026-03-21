import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../l10n/strings.dart';

/// A full-screen alert overlay shown when an active alert is in progress.
/// It displays the alert title, category, affected cities in columns,
/// and a live countdown before auto-dismissal.
class AlertBanner extends StatefulWidget {
  final Alert alert;
  final AppStrings strings;
  final bool isTV;
  final VoidCallback? onDismiss;

  const AlertBanner({
    super.key,
    required this.alert,
    required this.strings,
    required this.isTV,
    this.onDismiss,
  });

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner>
    with SingleTickerProviderStateMixin {
  static const _displayDuration = 20;

  late int _remaining;
  Timer? _countdown;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _remaining = _displayDuration;

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _slideController.forward();

    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        timer.cancel();
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTest = widget.alert.isTest;
    final accentColor = isTest ? Colors.orange : Colors.red;
    final bgColor = isTest
        ? const Color(0xFF1A1000)
        : const Color(0xFF1A0000);

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        color: bgColor,
        child: Column(
          children: [
            _buildHeader(accentColor, isTest),
            Expanded(child: _buildCityGrid()),
            _buildFooter(accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent, bool isTest) {
    final titleSize = widget.isTV ? 36.0 : 24.0;
    final subtitleSize = widget.isTV ? 18.0 : 14.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.9), accent.withOpacity(0.4)],
        ),
      ),
      child: Row(
        children: [
          // Pulsing icon
          _PulsingIcon(isTest: isTest, size: widget.isTV ? 48 : 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.alert.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
                ),
                Text(
                  widget.alert.desc,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: subtitleSize,
                  ),
                  textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_remaining',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.isTV ? 40 : 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.strings.get('seconds_remaining'),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: widget.isTV ? 14 : 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCityGrid() {
    final cities = List<String>.from(widget.alert.data)..sort();
    const maxPerColumn = 15;
    final columnCount = (cities.length + maxPerColumn - 1) ~/ maxPerColumn;

    final cityFontSize = widget.isTV ? 18.0 : 14.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
        children: List.generate(columnCount, (col) {
          final start = col * maxPerColumn;
          final end = (start + maxPerColumn).clamp(0, cities.length);
          final columnCities = cities.sublist(start, end);

          return Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: columnCities.map((city) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.7),
                        Colors.red.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    city,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: cityFontSize,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 1.5,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    textDirection:
                        _isRTL ? TextDirection.rtl : TextDirection.ltr,
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFooter(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${widget.strings.affectedAreas}: ${widget.alert.data.length}',
            style: TextStyle(
              color: Colors.white54,
              fontSize: widget.isTV ? 14 : 12,
            ),
          ),
          TextButton(
            onPressed: widget.onDismiss,
            style: TextButton.styleFrom(foregroundColor: accent),
            child: Text(
              widget.strings.dismiss,
              style: TextStyle(fontSize: widget.isTV ? 16 : 13),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isRTL =>
      widget.strings.languageCode == 'he' ||
      widget.strings.languageCode == 'ar';
}

class _PulsingIcon extends StatefulWidget {
  final bool isTest;
  final double size;

  const _PulsingIcon({required this.isTest, required this.size});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        widget.isTest ? Icons.science_outlined : Icons.warning_amber_rounded,
        color: Colors.white,
        size: widget.size,
      ),
    );
  }
}
