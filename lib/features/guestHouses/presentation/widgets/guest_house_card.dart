import 'package:derb/features/guestHouses/presentation/guest_house_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';
import '../../data/models/guest_house.dart';

class GuestHouseCard extends StatefulWidget {
  final GuestHouse guestHouse;
  final bool isMobile;
  final bool isTablet;

  const GuestHouseCard({
    super.key,
    required this.guestHouse,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<GuestHouseCard> createState() => _GuestHouseCardState();
}

class _GuestHouseCardState extends State<GuestHouseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  static final _cacheManager = DefaultCacheManager();

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = widget.isMobile
        ? screenWidth * 0.9
        : widget.isTablet
        ? screenWidth * 0.45
        : screenWidth * 0.3;
    final cardPadding = widget.isMobile
        ? 12.0
        : widget.isTablet
        ? 16.0
        : 20.0;
    final imageHeight = widget.isMobile
        ? screenWidth * 0.8
        : widget.isTablet
        ? screenWidth * 0.5
        : screenWidth * 0.4;
    final fontSizeTitle = widget.isMobile
        ? 30.0
        : widget.isTablet
        ? 32.0
        : 34.0;
    final fontSizeSubtitle = widget.isMobile
        ? 18.0
        : widget.isTablet
        ? 20.0
        : 22.0;
    final iconSize = widget.isMobile
        ? 16.0
        : widget.isTablet
        ? 18.0
        : 20.0;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _scaleController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _scaleController.reverse();
      },
      child: GestureDetector(
        onTapDown: (_) {
          _scaleController.forward();
        },
        onTapUp: (_) {
          _scaleController.reverse();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuestHouseDetailPage(
                guestHouse: widget.guestHouse,
                isMobile: widget.isMobile,
                isTablet: widget.isTablet,
              ),
            ),
          );
        },
        onTapCancel: () => _scaleController.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: cardWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isHovered ? 0.2 : 0.1),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _isHovered
                          ? const Color(0xFF1C9826).withOpacity(0.9)
                          : Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1C9826).withOpacity(0.85),
                            const Color(0xFF4CAF50).withOpacity(0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.all(cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildImageSection(imageHeight, iconSize),
                          SizedBox(height: cardPadding),
                          _buildTextSection(
                            fontSizeTitle,
                            fontSizeSubtitle,
                            cardPadding,
                          ),
                          SizedBox(height: cardPadding / 2),
                          _buildFooterSection(fontSizeSubtitle, iconSize),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(double imageHeight, double iconSize) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: imageHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                widget.guestHouse.pictureUrl != null &&
                    widget.guestHouse.pictureUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.guestHouse.pictureUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.grey[300]),
                    ),
                    errorWidget: (context, url, error) {
                      debugPrint('Failed to load image: $error');
                      return Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: iconSize * 2,
                          color: Colors.grey[500],
                        ),
                      );
                    },
                    fadeInDuration: const Duration(milliseconds: 300),
                    cacheManager: _cacheManager,
                  )
                : Center(
                    child: Icon(
                      Icons.home_outlined,
                      size: iconSize * 2,
                      color: Colors.grey[500],
                    ),
                  ),
          ),
        ),
        if (widget.guestHouse.rating != null)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.star, size: iconSize, color: Colors.amber[400]),
                  const SizedBox(width: 4),
                  Text(
                    widget.guestHouse.rating!.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontSize: iconSize - 2,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextSection(
    double fontSizeTitle,
    double fontSizeSubtitle,
    double cardPadding,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.guestHouse.guestHouseName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: fontSizeTitle,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: cardPadding / 2),
        Text(
          '${widget.guestHouse.city} - ${widget.guestHouse.subCity}',
          style: GoogleFonts.poppins(
            fontSize: fontSizeSubtitle,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: cardPadding / 2),
        Text(
          widget.guestHouse.description,
          style: GoogleFonts.poppins(
            fontSize: fontSizeSubtitle,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFooterSection(double fontSizeSubtitle, double iconSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Rooms: ${widget.guestHouse.numberOfRooms}',
            style: GoogleFonts.poppins(
              fontSize: fontSizeSubtitle,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
