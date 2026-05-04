import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/card.dart';

/// Full-screen view of a card's image, centered with a black background.
///
/// Phase 2: shows the latest printing, pinch-to-zoom via InteractiveViewer.
/// Phase 3 will add the printing swiper.
class CardDetailView extends StatelessWidget {
  final CardData card;

  const CardDetailView({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final printing = _bestPrinting(card);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(card.name),
      ),
      body: SafeArea(
        child: Center(
          child: printing == null
              ? const Text(
                  'No printing available',
                  style: TextStyle(color: Colors.white70),
                )
              : InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: _CardImage(printing: printing),
                ),
        ),
      ),
    );
  }

  /// Returns a printing to display by default. Currently picks the last
  /// printing in the list (the schema lists them in chronological order, so
  /// last = most recent). Filters out empty image URLs.
  CardPrinting? _bestPrinting(CardData card) {
    final withImage = card.printings.where((p) => p.imageUrl.isNotEmpty);
    if (withImage.isEmpty) return null;
    return withImage.last;
  }
}

class _CardImage extends StatelessWidget {
  final CardPrinting printing;
  const _CardImage({required this.printing});

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: printing.imageUrl,
      fit: BoxFit.contain,
      placeholder: (_, _) => const SizedBox(
        width: 80,
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (_, _, _) => const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, size: 64, color: Colors.white54),
            SizedBox(height: 8),
            Text(
              'Image unavailable',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'You may be offline.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    if (printing.imageRotationDegrees != 0) {
      return Transform.rotate(
        angle: printing.imageRotationDegrees * 3.14159265 / 180,
        child: image,
      );
    }
    return image;
  }
}