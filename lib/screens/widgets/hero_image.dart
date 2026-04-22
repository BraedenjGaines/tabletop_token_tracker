import 'package:flutter/material.dart';
import '../../data/hero_library.dart';

/// Crop rectangle for card scans only. Applied when falling back to the card
/// scan; bypassed when real character art is found.
class HeroArtCrop {
  static double left = 0.07;
  static double top = 0.09;
  static double right = 0.93;
  static double bottom = 0.48;

  static double get width => right - left;
  static double get height => bottom - top;
}

/// Displays a hero's image. If full character art exists (<id>.jpg) it is
/// shown untouched. If only the card scan is available it is cropped to the
/// card's art region.
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
    return FutureBuilder<String?>(
      future: resolveHeroImage(hero),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _placeholder();
        final path = snapshot.data;
        if (path == null) return _placeholder();

        // Only crop if we fell back to a card scan.
        final bool isCardScan = path.contains('_card.');

        if (!isCardScan) {
          // Full character art — show untouched.
          return Image.asset(
            path,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (c, e, s) => _placeholder(),
          );
        }

        // Card scan fallback — crop to art region.
        return SizedBox(
          width: width,
          height: height,
          child: ClipRect(
            child: _CroppedImage(path: path, fit: fit),
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[800],
          child: Center(
              child: Icon(Icons.person, size: 32, color: Colors.grey)),
        );
  }
}

class _CroppedImage extends StatelessWidget {
  final String path;
  final BoxFit fit;

  const _CroppedImage({required this.path, required this.fit});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double viewW = constraints.maxWidth;
        final double viewH = constraints.maxHeight;
        final double cropW = HeroArtCrop.width;
        final double cropH = HeroArtCrop.height;

        final double scaleByWidth = viewW / cropW;
        final double scaleByHeight = viewH / cropH;

        final double scale = (fit == BoxFit.cover)
            ? (scaleByWidth > scaleByHeight ? scaleByWidth : scaleByHeight)
            : (scaleByWidth < scaleByHeight ? scaleByWidth : scaleByHeight);

        final double imgW = scale;
        final double imgH = scale;
        final double artW = cropW * scale;
        final double artH = cropH * scale;
        final double offsetX = -HeroArtCrop.left * scale + (viewW - artW) / 2;
        final double offsetY = -HeroArtCrop.top * scale + (viewH - artH) / 2;

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: offsetX,
              top: offsetY,
              width: imgW,
              height: imgH,
              child: Image.asset(
                path,
                fit: BoxFit.fill,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}