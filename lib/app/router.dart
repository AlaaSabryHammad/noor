import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/adhkar/adhkar_screen.dart';
import '../features/adhkar/hisn_screen.dart';
import '../features/audio/audio_home_screen.dart';
import '../features/audio/now_playing_screen.dart';
import '../features/audio/reciter_screen.dart';
import '../features/audio/video_screen.dart';
import '../features/auth/account_screen.dart';
import '../features/books/books_screens.dart';
import '../features/explore/explore_screen.dart';
import '../features/home/home_screen.dart';
import '../features/khutab/khutab_screens.dart';
import '../features/library/library_screen.dart';
import '../features/prayer/prayer_screen.dart';
import '../features/prayer/qibla_screen.dart';
import '../features/quran/quran_screen.dart';
import '../features/quran/reader_screen.dart';
import '../features/services/academy_screen.dart';
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
import '../features/search/search.dart';
import '../features/services/qada_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/spotlights/spotlights.dart';
import '../features/settings/privacy_screen.dart';
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
        GoRoute(path: '/hisn', builder: (_, _) => const HisnScreen()),
        GoRoute(path: '/duas', builder: (_, _) => const DuasScreen()),
        GoRoute(path: '/names', builder: (_, _) => const NamesScreen()),
        GoRoute(path: '/planner', builder: (_, _) => const PlannerScreen()),
        GoRoute(path: '/zakat', builder: (_, _) => const ZakatScreen()),
        GoRoute(
          path: '/audio',
          builder: (_, s) => AudioHomeScreen(initialTab: AudioTab.values.where((t) => t.name == s.uri.queryParameters['tab']).firstOrNull ?? AudioTab.reciters),
        ),
        GoRoute(path: '/audio/reciter/:id', builder: (_, s) => ReciterScreen(reciterId: int.tryParse(s.pathParameters['id'] ?? '') ?? 0, moshafId: int.tryParse(s.uri.queryParameters['moshaf'] ?? ''))),
        GoRoute(path: '/audio/video/:id', builder: (_, s) => VideoScreen(videoId: int.tryParse(s.pathParameters['id'] ?? '') ?? 0)),
        GoRoute(
          path: '/audio/player',
          pageBuilder: (_, s) => CustomTransitionPage(
            key: s.pageKey,
            child: const NowPlayingScreen(),
            transitionsBuilder: (context, a, _, child) => SlideTransition(position: Tween(begin: const Offset(0, 1), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)).animate(a), child: child),
          ),
        ),
        GoRoute(path: '/khutab', builder: (_, _) => const KhutabScreen()),
        GoRoute(path: '/spotlights', builder: (_, _) => const SpotlightsScreen()),
        GoRoute(path: '/spotlights/:id', builder: (_, s) => SpotlightScreen(id: s.pathParameters['id'] ?? '')),
        GoRoute(path: '/search', builder: (_, s) => SearchScreen(initialQuery: s.uri.queryParameters['q'] ?? '')),
        GoRoute(path: '/qada', builder: (_, _) => const QadaScreen()),
        GoRoute(path: '/khutab/:id', builder: (_, s) => KhutbaScreen(id: s.pathParameters['id'] ?? '')),
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
        GoRoute(path: '/privacy', builder: (_, _) => const PrivacyScreen()),
        GoRoute(path: '/soon/:service', builder: (_, s) => ComingSoonScreen(service: s.pathParameters['service'] ?? '')),
      ],
    );
