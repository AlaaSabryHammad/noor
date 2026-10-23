import 'package:go_router/go_router.dart';

import '../features/adhkar/adhkar_screen.dart';
import '../features/auth/account_screen.dart';
import '../features/books/books_screens.dart';
import '../features/explore/explore_screen.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/prayer/prayer_screen.dart';
import '../features/prayer/qibla_screen.dart';
import '../features/quran/quran_screen.dart';
import '../features/quran/reader_screen.dart';
import '../features/services/academy_screen.dart';
import '../features/services/audio_screen.dart';
import '../features/services/calendar_screen.dart';
import '../features/services/duas_screen.dart';
import '../features/services/faq_screen.dart';
import '../features/services/hadith_screen.dart';
import '../features/services/hajj_screen.dart';
import '../features/services/kids_screen.dart';
import '../features/services/mosques_screen.dart';
import '../features/services/names_screen.dart';
import '../features/services/planner_screen.dart';
import '../features/services/ramadan_screen.dart';
import '../features/services/seerah_screen.dart';
import '../features/services/stories_screen.dart';
import '../features/services/zakat_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/tasbeeh/tasbeeh_screen.dart';
import 'shell.dart';

GoRouter buildRouter() => GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => NoorShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/quran', builder: (_, _) => const QuranScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/prayer', builder: (_, _) => const PrayerScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/adhkar', builder: (_, _) => const AdhkarScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/explore', builder: (_, _) => const ExploreScreen())]),
          ],
        ),
        GoRoute(
          path: '/quran/reader/:surah',
          builder: (_, s) => ReaderScreen(
            surah: (int.tryParse(s.pathParameters['surah'] ?? '') ?? 1).clamp(1, 114),
            ayah: int.tryParse(s.uri.queryParameters['ayah'] ?? ''),
            autoplay: s.uri.queryParameters['play'] == '1',
          ),
        ),
        GoRoute(path: '/adhkar/session/:category', builder: (_, s) => DhikrSessionScreen(category: s.pathParameters['category'] ?? 'morning')),
        GoRoute(path: '/qibla', builder: (_, _) => const QiblaScreen()),
        GoRoute(path: '/tasbeeh', builder: (_, _) => const TasbeehScreen()),
        GoRoute(path: '/duas', builder: (_, _) => const DuasScreen()),
        GoRoute(path: '/names', builder: (_, _) => const NamesScreen()),
        GoRoute(path: '/planner', builder: (_, _) => const PlannerScreen()),
        GoRoute(path: '/zakat', builder: (_, _) => const ZakatScreen()),
        GoRoute(path: '/audio', builder: (_, _) => const AudioScreen()),
        GoRoute(path: '/hadith', builder: (_, _) => const HadithScreen()),
        GoRoute(path: '/seerah', builder: (_, _) => const SeerahScreen()),
        GoRoute(path: '/academy', builder: (_, _) => const AcademyScreen()),
        GoRoute(path: '/academy/:id', builder: (_, s) => CourseScreen(courseId: s.pathParameters['id'] ?? '')),
        GoRoute(path: '/stories', builder: (_, _) => const StoriesScreen()),
        GoRoute(path: '/library', builder: (_, _) => const LibraryScreen()),
        GoRoute(path: '/books', builder: (_, _) => const BooksScreen()),
        GoRoute(path: '/books/:id', builder: (_, s) => BookScreen(bookId: s.pathParameters['id'] ?? '')),
        GoRoute(path: '/books/:id/:section', builder: (_, s) => SectionScreen(bookId: s.pathParameters['id'] ?? '', section: int.tryParse(s.pathParameters['section'] ?? '') ?? 1)),
        GoRoute(path: '/ask', builder: (_, _) => const FaqScreen()),
        GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen()),
        GoRoute(path: '/ramadan', builder: (_, _) => const RamadanScreen()),
        GoRoute(path: '/hajj', builder: (_, _) => const HajjScreen()),
        GoRoute(path: '/kids', builder: (_, _) => const KidsScreen()),
        GoRoute(path: '/mosques', builder: (_, _) => const MosquesScreen()),
        GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
        GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
        GoRoute(path: '/soon/:service', builder: (_, s) => ComingSoonScreen(service: s.pathParameters['service'] ?? '')),
      ],
    );
