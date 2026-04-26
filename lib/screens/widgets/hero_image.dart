import 'package:flutter/material.dart';
import '../../data/hero_library.dart';

class HeroImage extends StatelessWidget {
  final HeroData hero;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;

  const HeroImage({
    super.key,
    required this.hero,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      hero.artPath,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (c, e, s) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[800],
          child: Center(child: Icon(Icons.person, size: 32, color: Colors.grey)),
        );
  }
}