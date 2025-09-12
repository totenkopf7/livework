import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import your existing files
import 'dashboard_page.dart';
import 'report_creation_page.dart';
import 'pages/map_page.dart';
import 'providers/report_provider.dart';
import 'providers/site_provider.dart';
import 'widgets/report_card_widget.dart';
import 'data/models/report_model.dart';

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
          create: (_) {
            final reportProvider = ReportProvider();
            reportProvider.loadReports();
            return reportProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final siteProvider = SiteProvider();
            siteProvider.loadSites();
            return siteProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'LiveWork View',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF2196F3),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2196F3),
            foregroundColor: Colors.white,
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
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF2196F3),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
          ),
        ),
        home: const MainNavigationPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const MapPage(),
    const ReportCreationPage(),
    const CompletedReportsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Consumer<ReportProvider>(
        builder: (context, reportProvider, child) {
          final completedCount = reportProvider.completedReports.length;
          
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard, size: 24),
                label: 'Dashboard',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.map, size: 24),
                label: 'Map',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline, size: 24),
                label: 'New Report',
              ),
              BottomNavigationBarItem(
                icon: completedCount > 0 ? _buildBadgeIcon(completedCount) : const Icon(Icons.assignment_turned_in, size: 24),
                label: 'Reports',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings, size: 24),
                label: 'Settings',
              ),
            ],
            selectedItemColor: const Color(0xFF2196F3),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
          );
        },
      ),
    );
  }

  Widget _buildBadgeIcon(int count) {
    return Stack(
      clipBehavior: Clip.none, // Allow the badge to overflow
      children: [
        const Icon(Icons.assignment_turned_in, size: 24),
        Positioned(
          right: -8,
          top: -8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
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

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Consumer<SiteProvider>(
        builder: (context, siteProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Site Configuration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (siteProvider.currentSite != null) ...[
                          Text(
                            'Current Site: ${siteProvider.currentSite!.name}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Site ID: ${siteProvider.currentSite!.id}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'No site configured',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _showSiteSelectionDialog(context);
                          },
                          child: const Text('Change Site'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'App Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'LiveWork View v1.0.0',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Real-time task and hazard tracking system',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSiteSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Site'),
        content: const Text(
            'Site selection functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class CompletedReportsPage extends StatelessWidget {
  const CompletedReportsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Reports'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, child) {
          final completedReports = reportProvider.reports
              .where((r) => r.status == ReportStatus.done)
              .toList();
          if (completedReports.isEmpty) {
            return const Center(child: Text('No completed reports.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: completedReports.length,
            itemBuilder: (context, index) {
              final report = completedReports[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReportCardWidget(
                  report: report,
                  onStatusChanged: (newStatus) {
                    Provider.of<ReportProvider>(context, listen: false)
                        .updateReportStatus(report.id, newStatus);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}