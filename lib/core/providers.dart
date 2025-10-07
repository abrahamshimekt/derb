
import 'package:flutter_riverpod/legacy.dart';

final refreshTriggerProvider = StateProvider.family<int, int>((ref, tabIndex) => 0);
final roomFilterProvider = StateProvider<Map<String, dynamic>>((ref) => {
      'minPrice': 200.0,
      'maxPrice': 3000.0, 
      'minRating': 0.0,
      'maxRating': 5.0,
    });