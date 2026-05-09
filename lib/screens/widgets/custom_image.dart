import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/app_assets.dart';

/// Renders a user-supplied custom image, falling back to the default
/// `add_token_button.png` artwork when:
/// - [path] is null (the user never supplied an image), or
/// - the file at [path] no longer exists / fails to decode.
///
/// Used everywhere a custom hero or custom token image is displayed so the
/// fallback art is consistent across the app.
class CustomImage extends StatelessWidget {
  final String? path;
  final BoxFit fit;
  final double? width;
  final double? height;

  const CustomImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (path != null) {
      return Image.file(
        File(path!),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _buildDefault(),
      );
    }
    return _buildDefault();
  }

  Widget _buildDefault() {
    return Image.asset(
      AppAssets.addTokenButton,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, _, _) => Container(
        width: width,
        height: height,
        color: Colors.grey[800],
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, color: Colors.white24),
      ),
    );
  }
}