import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:livework_view/pages/login_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'widgets/colors.dart';
import 'dashboard_page.dart';
import 'report_creation_page.dart';
import 'pages/map_page.dart';
import 'providers/report_provider.dart';
import 'providers/site_provider.dart';
import 'providers/auth_provider.dart' as livework_auth;
import 'pages/settings_page.dart';
import 'pages/completed_reports_page.dart';
import 'providers/language_provider.dart';
import 'helpers/localization_helper.dart';
import 'localization/kurdish_material_localizations.dart'; // ADDED
import 'localization/kurdish_cupertino_localizations.dart'; // ADDED

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LiveWorkViewApp());

}



class LiveWorkViewApp extends StatelessWidget {
  const LiveWorkViewApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => livework_auth.LiveWorkAuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final siteProvider = SiteProvider();
            siteProvider.loadSites();
            return siteProvider;
          },
        ),
        ChangeNotifierProxyProvider<livework_auth.LiveWorkAuthProvider,
            ReportProvider>(
          create: (context) => ReportProvider(),
          update: (context, authProvider, reportProvider) {
            if (reportProvider == null) {
              reportProvider = ReportProvider();
            }
            reportProvider.setCurrentUser(authProvider.user);
            return reportProvider;
          },
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'LiveWork View',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: const Color(0xFF2196F3),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2196F3),
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.secondary,
                elevation: 2,
                iconTheme: IconThemeData(color: Colors.white),
              ),
              iconTheme: const IconThemeData(color: Colors.black),
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.secondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: AppColors.background,
                selectedItemColor: AppColors.secondary,
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                showUnselectedLabels: true,
              ),
            ),
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
            locale: languageProvider.currentLocale,
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('ku', 'IQ'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              KurdishMaterialLocalizations.delegate, // ADDED
              KurdishCupertinoLocalizations.delegate, // ADDED
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale?.languageCode &&
                    supportedLocale.countryCode == locale?.countryCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<livework_auth.LiveWorkAuthProvider>(context);

    if (authProvider.isLoading) {
      return const SplashScreen();
    }

    if (authProvider.user == null) {
      return const LoginPage();
    }

    return const MainNavigationPage();
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.fastEaseInToSlowEaseOut,
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationPage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _bounceAnimation,
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                strokeWidth: 0.5),
            const SizedBox(height: 20),
            Text(
              translate(context, 'loading'),
              style: TextStyle(color: AppColors.secondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

// UPDATED: lib/main.dart (MainNavigationPage section)
class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      // ADDED: Listen to language changes
      builder: (context, languageProvider, child) {
        final authProvider =
            Provider.of<livework_auth.LiveWorkAuthProvider>(context);

        List<Widget> pages = [
          const DashboardPage(),
          const MapPage(),
        ];

        if (authProvider.isAdmin) {
          pages.add(const ReportCreationPage());
        } else {
          pages.add(Center(child: Text(translate(context, 'no_access'))));
        }

        pages.addAll([
          const CompletedReportsPage(),
          const SettingsPage(),
        ]);

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: Builder(
            builder: (context) {
              final authProvider =
                  Provider.of<livework_auth.LiveWorkAuthProvider>(context,
                      listen: true);
              final reportProvider =
                  Provider.of<ReportProvider>(context, listen: true);

              final completedCount = reportProvider.completedReports.length;

              List<BottomNavigationBarItem> items = [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard, size: 24),
                  label: translate(context, 'dashboard'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map, size: 24),
                  label: translate(context, 'map'),
                ),
              ];

              if (authProvider.isAdmin) {
                items.add(
                  BottomNavigationBarItem(
                    icon: Icon(Icons.add_circle_outline, size: 24),
                    label: translate(context, 'new_report'),
                  ),
                );
              } else {
                items.add(
                  BottomNavigationBarItem(
                    icon: Icon(Icons.block, size: 24),
                    label: translate(context, 'no_access'),
                  ),
                );
              }

              items.addAll([
                BottomNavigationBarItem(
                  icon: completedCount > 0
                      ? _buildBadgeIcon(completedCount)
                      : Icon(Icons.assignment_turned_in, size: 24),
                  label: translate(context, 'reports'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings, size: 24),
                  label: translate(context, 'settings'),
                ),
              ]);

              return BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                items: items,
                selectedItemColor: AppColors.secondary,
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                showUnselectedLabels: true,
              );
            },
          ),
        );
      },
    );
  }
  // ... rest of the code

  Widget _buildBadgeIcon(int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.assignment_turned_in, size: 24),
        Positioned(
          right: -8,
          top: -8,
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
