import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class GuestHousesShimmer extends StatelessWidget {
  final double width;
  final bool isMobile;
  final bool isTablet;

  const GuestHousesShimmer({
    super.key,
    required this.width,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!.withOpacity(0.5),
          highlightColor: Colors.grey[100]!.withOpacity(0.3),
          period: const Duration(milliseconds: 800),
          child: Card(
            margin: EdgeInsets.only(bottom: isMobile ? 16 : 24),
            child: Container(
              height: isMobile ? 120 : isTablet ? 140 : 160,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(width: isMobile ? 80 : 100, height: isMobile ? 80 : 100, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: width * 0.6, height: 16, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: width * 0.8, height: 12, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: width * 0.4, height: 12, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        childCount: 5,
      ),
    );
  }
}