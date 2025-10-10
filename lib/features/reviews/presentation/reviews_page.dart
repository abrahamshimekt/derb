import 'package:derb/features/reviews/application/reviews_controller.dart';
import 'package:derb/features/reviews/data/model/review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewsPage extends ConsumerStatefulWidget {
  final String roomNumber;
  final String roomId;
  final bool isOwner;

  const ReviewsPage({
    super.key,
    required this.roomNumber,
    required this.roomId,
    required this.isOwner,
  });

  @override
  ConsumerState<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends ConsumerState<ReviewsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(
        reviewsControllerProvider(widget.roomId).notifier,
      );
      controller.fetchReviews(roomId: widget.roomId);
      controller.subscribe(roomId: widget.roomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewsState = ref.watch(reviewsControllerProvider(widget.roomId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reviews for Room ${widget.roomNumber}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white
      ),
      body: reviewsState.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (reviews, averageRating) =>
            _buildReviewsContent(reviews, averageRating),
        error: (message, isNetworkError, isAuthError) => Center(
          child: Text(
            message,
            style: GoogleFonts.poppins(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsContent(List<Review> reviews, double averageRating) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAverageRating(averageRating, reviews.length),
          const SizedBox(height: 16),
          if (!widget.isOwner) _buildAddReviewSection(),
          const SizedBox(height: 16),
          if (reviews.isEmpty)
            Center(
              child: Text(
                'No reviews yet. Be the first!',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return _buildReviewCard(review);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAverageRating(double averageRating, int reviewCount) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            RatingBarIndicator(
              rating: averageRating,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 24.0,
            ),
            const SizedBox(width: 8),
            Text(
              '${averageRating.toStringAsFixed(1)} / 5 ($reviewCount reviews)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddReviewSection() {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: ref
          .read(reviewsControllerProvider(widget.roomId).notifier)
          .canAddReview(roomId: widget.roomId, userId: userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData && snapshot.data == true) {
          return ElevatedButton.icon(
            onPressed: () => _showAddReviewBottomSheet(),
            icon: const Icon(Icons.add_comment),
            label: const Text('Add Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C9826),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showAddReviewBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddReviewForm(
        roomId: widget.roomId,
        onSubmit: () {
          // Refresh after submit (already handled by subscription, but force fetch if needed)
          ref
              .read(reviewsControllerProvider(widget.roomId).notifier)
              .fetchReviews(roomId: widget.roomId);
        },
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  review.userName ?? 'Anonymous',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${review.createdAt.month}/${review.createdAt.year}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            RatingBarIndicator(
              rating: review.rating,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 20.0,
            ),
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: GoogleFonts.poppins(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

class AddReviewForm extends StatefulWidget {
  final String roomId;
  final VoidCallback onSubmit;

  const AddReviewForm({
    super.key,
    required this.roomId,
    required this.onSubmit,
  });

  @override
  State<AddReviewForm> createState() => _AddReviewFormState();
}

class _AddReviewFormState extends State<AddReviewForm> {
  double _rating = 0.0;
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Your Review',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) =>
                const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) => setState(() => _rating = rating),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              labelText: 'Comment (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, child) {
              return ElevatedButton(
                onPressed: () async {
                  if (_rating > 0) {
                    final userId =
                        Supabase.instance.client.auth.currentUser?.id ?? '';
                    await ref
                        .read(reviewsControllerProvider(widget.roomId).notifier)
                        .addReview(
                          roomId: widget.roomId,
                          userId: userId,
                          rating: _rating,
                          comment: _commentController.text.trim(),
                        );
                    widget.onSubmit();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Review added successfully!'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a rating.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C9826),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Submit Review'),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
