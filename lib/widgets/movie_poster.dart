import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// Robust movie poster widget with caching, placeholder, and optional Hero animation
class MoviePoster extends StatelessWidget {
  final String posterUrl;
  final String heroTag;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool useHero;
  final double borderRadius;

  const MoviePoster({
    super.key,
    required this.posterUrl,
    required this.heroTag,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.useHero = false,
    this.borderRadius = 0,
  });

  Widget _buildImage() {
    final hasValidPoster =
        posterUrl.isNotEmpty && posterUrl != 'N/A';

    if (!hasValidPoster) {
      return _buildFallback();
    }

    return CachedNetworkImage(
      imageUrl: posterUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: 300,
      maxWidthDiskCache: 600,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildFallback(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.secondarySurface,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.secondarySurface,
      child: const Center(
        child: Icon(
          Icons.movie,
          size: 50,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: _buildImage(),
    );

    if (useHero) {
      return Hero(
        tag: heroTag,
        child: image,
      );
    }

    return image;
  }
}
