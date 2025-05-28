import 'package:flutter/material.dart';
import 'dart:io';
import '../series.dart';

class SeriesImage extends StatelessWidget {
  final Series series;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const SeriesImage({
    super.key,
    required this.series,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (series.imageUrl.isEmpty) {
      imageWidget = _buildPlaceholder();
    } else if (series.isLocalImage) {
      imageWidget = _buildLocalImage();
    } else {
      imageWidget = _buildNetworkImage();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildLocalImage() {
    return FutureBuilder<String>(
      future: series.getLocalImagePath(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder();
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorPlaceholder();
        }

        return Image.file(
          File(snapshot.data!),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
        );
      },
    );
  }

  Widget _buildNetworkImage() {
    return Image.network(
      series.imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[800],
      child: const Icon(Icons.movie, color: Colors.white70),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[800],
      child: const Icon(Icons.broken_image, color: Colors.white70),
    );
  }
}