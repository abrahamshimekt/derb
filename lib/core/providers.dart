// lib/core/providers.dart

import 'package:flutter_riverpod/legacy.dart';

// Provider to trigger refresh for each tab
final refreshTriggerProvider = StateProvider.family<int, int>((ref, tabIndex) => 0);