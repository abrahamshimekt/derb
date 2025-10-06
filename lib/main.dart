import 'package:derb/features/bookings/presentation/bookings_page.dart';
import 'package:derb/features/guestHouses/presentation/guest_houses_page.dart';
import 'package:derb/features/profile/presentation/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase_client.dart';
import 'core/providers.dart'; 
import 'features/auth/application/auth_controller.dart';
import 'features/auth/presentation/auth_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await AppSupabase.init(dotenv.env['SUPABASE_URL']!, dotenv.env['SUPABASE_ANON_KEY']!);
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      if (_selectedIndex == index) {
        // Trigger refresh for the current tab
        ref.read(refreshTriggerProvider(index).notifier).state++;
      }
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter + Supabase Auth',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1C9826),
        scaffoldBackgroundColor: Colors.white,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF1C9826),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: Consumer(
        builder: (context, ref, child) {
          ref.listen(authControllerProvider, (previous, next) {
            if (next is AuthAuthenticated && (previous is! AuthAuthenticated)) {
              setState(() {
                _selectedIndex = 0;
              });
            }
          });

          final status = ref.watch(authControllerProvider);

          return status is AuthAuthenticated
              ? Scaffold(
                  body: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      GuestHousesPage(key: ValueKey(_selectedIndex == 0 ? ref.watch(refreshTriggerProvider(0)) : 0)),
                      BooksPage(key: ValueKey(_selectedIndex == 1 ? ref.watch(refreshTriggerProvider(1)) : 0)),
                      ProfilePage(key: ValueKey(_selectedIndex == 2 ? ref.watch(refreshTriggerProvider(2)) : 0)),
                    ],
                  ),
                  bottomNavigationBar: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: _onItemTapped,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_outlined),
                        activeIcon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.book_outlined),
                        activeIcon: Icon(Icons.event),
                        label: 'Bookings',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person_outlined),
                        activeIcon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ],
                  ),
                )
              : const AuthPage();
        },
      ),
    );
  }
}