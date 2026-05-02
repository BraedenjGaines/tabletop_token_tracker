import 'package:flutter/material.dart';

/// The four corner chrome buttons on the match screen: Home (top-left), Reset
/// (top-right), Log (bottom-left), Settings (bottom-right).
///
/// Each button is positioned absolutely. Callers should render this widget as
/// a child of a Stack that fills the screen.
class MatchChromeButtons extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onReset;
  final VoidCallback onSettings;
  final VoidCallback onShowLog;

  const MatchChromeButtons({
    super.key,
    required this.onHome,
    required this.onReset,
    required this.onSettings,
    required this.onShowLog,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 40,
          left: 16,
          child: _CircleIconButton(icon: Icons.home, onPressed: onHome),
        ),
        Positioned(
          top: 40,
          right: 16,
          child: _CircleIconButton(icon: Icons.refresh, onPressed: onReset),
        ),
        Positioned(
          bottom: 24,
          left: 16,
          child: _CircleIconButton(icon: Icons.list_alt, onPressed: onShowLog),
        ),
        Positioned(
          bottom: 24,
          right: 16,
          child: _CircleIconButton(icon: Icons.settings, onPressed: onSettings),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}