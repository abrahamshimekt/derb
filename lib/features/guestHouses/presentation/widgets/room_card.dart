import 'package:cached_network_image/cached_network_image.dart';
import 'package:derb/features/bookings/presentation/add_booking_page.dart';
import 'package:derb/features/guestHouses/data/models/room.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final double padding;
  final double fontSizeSubtitle;

  const RoomCard({
    super.key,
    required this.room,
    required this.padding,
    required this.fontSizeSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final imageHeight = isMobile
        ? screenWidth * 0.8
        : isTablet
        ? screenWidth * 0.7
        : screenWidth * 0.5;
    final imageWidth = isMobile
        ? screenWidth * 0.4
        : isTablet
        ? screenWidth * 0.3
        : screenWidth * 0.25;
    final adjustedFontSize =
        fontSizeSubtitle *
        (isMobile
            ? 0.9
            : isTablet
            ? 1.0
            : 1.1);
    final pageController = PageController();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFF1C9826).withOpacity(0.05)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Images
              if (room.roomPictures != null && room.roomPictures!.isNotEmpty)
                Column(
                  children: [
                    SizedBox(
                      height: imageHeight,
                      child: PageView.builder(
                        controller: pageController,
                        itemCount: room.roomPictures!.length,
                        itemBuilder: (context, imageIndex) {
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(
                              context,
                              room.roomPictures!,
                              imageIndex,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: room.roomPictures![imageIndex],
                                  width: imageWidth,
                                  height: imageHeight,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(
                                          width: imageWidth,
                                          height: imageHeight,
                                          color: Colors.grey[300],
                                        ),
                                      ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        width: imageWidth,
                                        height: imageHeight,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.error_outline,
                                          color: Colors.redAccent,
                                          size: 30,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (room.roomPictures!.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Center(
                          child: SmoothPageIndicator(
                            controller: pageController,
                            count: room.roomPictures!.length,
                            effect: const WormEffect(
                              dotHeight: 8,
                              dotWidth: 8,
                              activeDotColor: Color(0xFF1C9826),
                              dotColor: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              else
                Container(
                  width: imageWidth,
                  height: imageHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 30,
                  ),
                ),
              const SizedBox(height: 12),
              // Room Details
              Text(
                'Room ${room.roomNumber}',
                style: GoogleFonts.poppins(
                  fontSize: adjustedFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Price: ${room.price.toStringAsFixed(2)} ETB',
                style: GoogleFonts.poppins(
                  fontSize: adjustedFontSize - 2,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Status: ${room.status}',
                style: GoogleFonts.poppins(
                  fontSize: adjustedFontSize - 2,
                  color: Colors.grey[600],
                ),
              ),
              if (room.facilities != null && room.facilities!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Facilities: ${room.facilities!.join(', ')}',
                    style: GoogleFonts.poppins(
                      fontSize: adjustedFontSize - 2,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              // Book Now Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: room.status =="available"
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewBookingPage(bedroom: room),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1C9826), Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 10 : 12,
                      ),
                      constraints: const BoxConstraints(minWidth: 120),
                      child: Text(
                        'Book Now',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: adjustedFontSize - 2,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final fullScreenController = PageController(initialPage: initialIndex);
        return Dialog(
          backgroundColor: Colors.black87,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.6,
                width: double.infinity,
                child: PageView.builder(
                  controller: fullScreenController,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: images[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.grey[300]),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
              if (images.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SmoothPageIndicator(
                    controller: fullScreenController,
                    count: images.length,
                    effect: const WormEffect(
                      dotHeight: 10,
                      dotWidth: 10,
                      activeDotColor: Color(0xFF4CAF50),
                      dotColor: Colors.white54,
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
