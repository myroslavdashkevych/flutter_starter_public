import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Retries a failed download, because the demo image host answers 429 to a
/// burst of requests (`retry-after: 10`) and a visible image would otherwise
/// stay broken until it is rebuilt.
class ItemImage extends StatefulWidget {
  const ItemImage({required this.url, this.cacheManager, super.key});

  static const retryDelay = Duration(seconds: 10);
  static const maxRetries = 3;

  final String url;

  /// Replaces the default cache manager in tests.
  final BaseCacheManager? cacheManager;

  @override
  State<ItemImage> createState() => _ItemImageState();
}

class _ItemImageState extends State<ItemImage> {
  int _retries = 0;
  Timer? _retryTimer;

  void _scheduleRetry() {
    _retryTimer ??= Timer(ItemImage.retryDelay, () {
      setState(() {
        _retries++;
        _retryTimer = null;
      });
    });
  }

  @override
  void didUpdateWidget(ItemImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _retryTimer?.cancel();
      _retryTimer = null;
      _retries = 0;
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: CachedNetworkImage(
        // A new key starts a new download: a failed one is not kept in memory.
        key: ValueKey(_retries),
        imageUrl: widget.url,
        cacheManager: widget.cacheManager,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          if (_retries < ItemImage.maxRetries) {
            _scheduleRetry();
            return const SizedBox.shrink();
          }
          return Icon(Icons.broken_image_outlined, color: colorScheme.outline);
        },
      ),
    );
  }
}
