import 'package:flutter_riverpod/legacy.dart';

// Room filter state with proper typing
class RoomFilter {
  final double minPrice;
  final double maxPrice;
  final double minRating;
  final double maxRating;

  const RoomFilter({
    this.minPrice = 200.0,
    this.maxPrice = 3000.0,
    this.minRating = 0.0,
    this.maxRating = 5.0,
  });

  RoomFilter copyWith({
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? maxRating,
  }) {
    return RoomFilter(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      maxRating: maxRating ?? this.maxRating,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minRating': minRating,
      'maxRating': maxRating,
    };
  }
}

// Immutable room filter provider
final roomFilterProvider = StateNotifierProvider<RoomFilterNotifier, RoomFilter>((ref) {
  return RoomFilterNotifier();
});

class RoomFilterNotifier extends StateNotifier<RoomFilter> {
  RoomFilterNotifier() : super(const RoomFilter());

  void updateFilter({
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? maxRating,
  }) {
    state = state.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
      minRating: minRating,
      maxRating: maxRating,
    );
  }

  void resetFilter() {
    state = const RoomFilter();
  }
}

// Tab refresh state management
class TabRefreshState {
  final Map<int, int> refreshCounters;

  const TabRefreshState({this.refreshCounters = const {}});

  TabRefreshState copyWith({Map<int, int>? refreshCounters}) {
    return TabRefreshState(
      refreshCounters: refreshCounters ?? this.refreshCounters,
    );
  }

  int getRefreshCount(int tabIndex) {
    return refreshCounters[tabIndex] ?? 0;
  }
}

final tabRefreshProvider = StateNotifierProvider<TabRefreshNotifier, TabRefreshState>((ref) {
  return TabRefreshNotifier();
});

class TabRefreshNotifier extends StateNotifier<TabRefreshState> {
  TabRefreshNotifier() : super(const TabRefreshState());

  void triggerRefresh(int tabIndex) {
    final currentCount = state.getRefreshCount(tabIndex);
    state = state.copyWith(
      refreshCounters: {
        ...state.refreshCounters,
        tabIndex: currentCount + 1,
      },
    );
  }

  void resetRefresh(int tabIndex) {
    final newCounters = Map<int, int>.from(state.refreshCounters);
    newCounters.remove(tabIndex);
    state = state.copyWith(refreshCounters: newCounters);
  }
}