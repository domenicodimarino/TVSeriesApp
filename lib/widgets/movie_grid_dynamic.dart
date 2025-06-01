import 'package:flutter/material.dart';
import '../series.dart';
import '../series_screen.dart';
import 'series_image.dart';

class MovieGridDynamic extends StatelessWidget {
  final List<Series> series;
  final VoidCallback onSeriesUpdated;

  const MovieGridDynamic({
    super.key,
    required this.series,
    required this.onSeriesUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = screenWidth < 400 ? 150.0 : (screenWidth < 600 ? 200.0 : 240.0);
    final imageHeight = screenWidth < 400 ? 220.0 : (screenWidth < 600 ? 300.0 : 360.0);

    return SizedBox(
      height: imageHeight + 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: series.length,
        itemBuilder: (context, index) {
          final s = series[index];
          return Container(
            width: imageWidth,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.pushNamed(
                  context,
                  SeriesScreen.routeName,
                  arguments: {
                    'series': s,
                    'onSeriesUpdated': onSeriesUpdated,
                  },
                );
                if (result == true) {
                  onSeriesUpdated();
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SeriesImage(
                    series: s,
                    width: imageWidth,
                    height: imageHeight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth < 400 ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}