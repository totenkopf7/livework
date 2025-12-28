// --------------------------------------------------
// ENHANCED: lib/pages/archived_reports_page.dart WITH CHECKBOX FILTERS
import 'package:flutter/material.dart';
import 'package:livework_view/data/models/site_model.dart';
import 'package:livework_view/widgets/animated_drawer_icon.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:livework_view/widgets/safety_drawer_widget.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../providers/site_provider.dart';
import '../providers/auth_provider.dart' as livework_auth;
import '../data/models/report_model.dart';
import '../widgets/report_card_widget.dart';
import '../helpers/localization_helper.dart';

class ArchivedReportsPage extends StatefulWidget {
  const ArchivedReportsPage({Key? key}) : super(key: key);

  @override
  State<ArchivedReportsPage> createState() => _ArchivedReportsPageState();
}

class _ArchivedReportsPageState extends State<ArchivedReportsPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  // REAL LAZY LOADING: PAGINATION VARIABLES
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _hasLoadedInitialData = false;
  List<ReportModel> _loadedArchivedReports = [];
  Map<String, List<ReportModel>> _paginatedArchivedReportsByDate = {};
  bool _isInitialLoading = false;

  // SEARCH FUNCTIONALITY VARIABLES
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // MULTI-SELECT FILTER VARIABLES (using Sets for multiple selections)
  Set<ReportType> _selectedTypeFilters = {};
  Set<ReportStatus> _selectedStatusFilters = {};
  Set<String> _selectedZoneFilters = {};
  Set<String> _selectedPerformerFilters = {};
  DateTime? _selectedDateFilter;
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Debounce search to avoid too many rebuilds
    _searchController.addListener(() {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_searchController.text != _searchQuery) {
          setState(() {
            _searchQuery = _searchController.text;
            _applyFilters();
          });
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailableZones();
    });
  }

  void _loadAvailableZones() {
    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    if (siteProvider.currentSite != null) {
      setState(() {
        // Zones are loaded automatically from site provider
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_searchQuery.isEmpty &&
        _selectedTypeFilters.isEmpty &&
        _selectedStatusFilters.isEmpty &&
        _selectedZoneFilters.isEmpty &&
        _selectedPerformerFilters.isEmpty &&
        _selectedDateFilter == null &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    if (_hasLoadedInitialData) return;

    setState(() {
      _isInitialLoading = true;
    });

    _currentPage = 0;
    _hasMoreData = true;
    _loadedArchivedReports.clear();
    _paginatedArchivedReportsByDate.clear();

    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    if (siteProvider.currentSite != null) {
      try {
        await reportProvider.clearPaginationTracking();

        final firstPageReports =
            await reportProvider.loadArchivedReportsPaginated(
          siteId: siteProvider.currentSite!.id,
          page: _currentPage,
          pageSize: _pageSize,
        );

        setState(() {
          _loadedArchivedReports = firstPageReports;
          _paginatedArchivedReportsByDate =
              _groupReportsByDate(firstPageReports);
          _hasLoadedInitialData = true;
          _isInitialLoading = false;
          _hasMoreData = firstPageReports.length == _pageSize;
        });
      } catch (e) {
        print('Error loading initial archived reports: $e');
        setState(() {
          _isInitialLoading = false;
        });
      }
    } else {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    if (siteProvider.currentSite != null) {
      try {
        final nextPageReports =
            await reportProvider.loadArchivedReportsPaginated(
          siteId: siteProvider.currentSite!.id,
          page: _currentPage + 1,
          pageSize: _pageSize,
        );

        setState(() {
          _currentPage++;
          _loadedArchivedReports.addAll(nextPageReports);
          _paginatedArchivedReportsByDate =
              _groupReportsByDate(_loadedArchivedReports);
          _isLoadingMore = false;
          _hasMoreData = nextPageReports.length == _pageSize;
        });
      } catch (e) {
        print('Error loading more archived reports: $e');
        setState(() {
          _isLoadingMore = false;
        });
      }
    } else {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Map<String, List<ReportModel>> _groupReportsByDate(
      List<ReportModel> reports) {
    final Map<String, List<ReportModel>> grouped = {};

    for (final report in reports) {
      final dateKey = _formatDateKey(report.timestamp);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(report);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedMap = <String, List<ReportModel>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }

    return sortedMap;
  }

  Map<String, List<ReportModel>> _applyFilters() {
    if (_loadedArchivedReports.isEmpty) return {};

    List<ReportModel> filteredReports = List.from(_loadedArchivedReports);

    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      filteredReports = filteredReports.where((report) {
        final query = _searchQuery.toLowerCase();
        return report.description.toLowerCase().contains(query) ||
            report.zone.toLowerCase().contains(query) ||
            (report.reporterName?.toLowerCase().contains(query) ?? false) ||
            report.performedBy
                .any((performer) => performer.toLowerCase().contains(query));
      }).toList();
    }

    // Apply type filters (multiple selection)
    if (_selectedTypeFilters.isNotEmpty) {
      filteredReports = filteredReports
          .where((report) => _selectedTypeFilters.contains(report.type))
          .toList();
    }

    // Apply status filters (multiple selection)
    if (_selectedStatusFilters.isNotEmpty) {
      filteredReports = filteredReports
          .where((report) => _selectedStatusFilters.contains(report.status))
          .toList();
    }

    // Apply zone filters (multiple selection)
    if (_selectedZoneFilters.isNotEmpty) {
      filteredReports = filteredReports
          .where((report) => _selectedZoneFilters.contains(report.zone))
          .toList();
    }

    // Apply performer filters (multiple selection)
    if (_selectedPerformerFilters.isNotEmpty) {
      filteredReports = filteredReports
          .where((report) => report.performedBy.any(
                (performer) => _selectedPerformerFilters.contains(performer),
              ))
          .toList();
    }

    // Apply date filter (single selection)
    if (_selectedDateFilter != null) {
      filteredReports = filteredReports.where((report) {
        final reportDate = DateTime(
          report.timestamp.year,
          report.timestamp.month,
          report.timestamp.day,
        );
        final filterDate = DateTime(
          _selectedDateFilter!.year,
          _selectedDateFilter!.month,
          _selectedDateFilter!.day,
        );
        return reportDate == filterDate;
      }).toList();
    }

    return _groupReportsByDate(filteredReports);
  }

  List<String> _getUniquePerformers() {
    final performers = <String>{};
    for (final report in _loadedArchivedReports) {
      performers.addAll(report.performedBy);
    }
    return performers.toList()..sort();
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider =
        Provider.of<livework_auth.LiveWorkAuthProvider>(context);
    final isAdmin = authProvider.isAdmin;
    final siteProvider = Provider.of<SiteProvider>(context);

    return Scaffold(
      drawer: const SafetyDrawer(),
      backgroundColor: AppColors.archived,
      appBar: AppBar(
        leading: Builder(builder: (context) {
          return AnimatedDrawerIcon(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        }),
        title: Text(translate(context, 'archived_reports')),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
        actions: [
          // Clear filters button
          if (_searchQuery.isNotEmpty ||
              _selectedTypeFilters.isNotEmpty ||
              _selectedStatusFilters.isNotEmpty ||
              _selectedZoneFilters.isNotEmpty ||
              _selectedPerformerFilters.isNotEmpty ||
              _selectedDateFilter != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: _clearFilters,
              tooltip: translate(context, 'clear_filters'),
            ),
        ],
      ),
      body: Consumer2<ReportProvider, SiteProvider>(
        builder: (context, reportProvider, siteProvider, child) {
          if (siteProvider.currentSite == null) {
            return Center(
              child: Text(
                translate(context, 'no_site_selected'),
                style: const TextStyle(fontSize: 16),
              ),
            );
          }

          // SHOW LOAD BUTTON IF NO DATA LOADED YET
          if (!_hasLoadedInitialData && !_isInitialLoading) {
            return _buildLoadArchivedReportsButton();
          }

          if (_isInitialLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image(
                    image: AssetImage('assets/images/logo.png'),
                    width: 90,
                    height: 90,
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.background),
                      backgroundColor: Colors.black12,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }

          if (reportProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${translate(context, 'error')}: ${reportProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInitialData,
                    child: Text(translate(context, 'retry')),
                  ),
                ],
              ),
            );
          }

          final filteredReportsByDate = _applyFilters();
          final hasActiveFilters = _searchQuery.isNotEmpty ||
              _selectedTypeFilters.isNotEmpty ||
              _selectedStatusFilters.isNotEmpty ||
              _selectedZoneFilters.isNotEmpty ||
              _selectedPerformerFilters.isNotEmpty ||
              _selectedDateFilter != null;

          return Column(
            children: [
              // SEARCH AND FILTERS SECTION
              _buildSearchAndFiltersSection(siteProvider),

              // SHOW FILTER BADGES IF ANY FILTERS ARE ACTIVE
              if (hasActiveFilters) _buildActiveFiltersChips(),

              // RESULTS COUNT
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${translate(context, 'results')}: ${_getTotalFilteredReports(filteredReportsByDate)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    if (hasActiveFilters && filteredReportsByDate.isEmpty)
                      Text(
                        translate(context, 'no_results_found'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ),

              // REPORTS LIST
              Expanded(
                child: _buildArchivedReportsList(
                  filteredReportsByDate,
                  reportProvider,
                  isAdmin,
                  hasActiveFilters,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFiltersSection(SiteProvider siteProvider) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // SEARCH BAR
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: translate(context, 'search_reports'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 12),

            // FILTERS ROW
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Type Filter
                  _buildFilterChip(
                    label: translate(context, 'type'),
                    icon: Icons.category,
                    onTap: () => _showTypeFilterDialog(),
                    isActive: _selectedTypeFilters.isNotEmpty,
                    count: _selectedTypeFilters.length,
                  ),
                  const SizedBox(width: 8),

                  // Status Filter
                  _buildFilterChip(
                    label: translate(context, 'status'),
                    icon: Icons.stairs,
                    onTap: () => _showStatusFilterDialog(),
                    isActive: _selectedStatusFilters.isNotEmpty,
                    count: _selectedStatusFilters.length,
                  ),
                  const SizedBox(width: 8),

                  // Zone Filter
                  _buildFilterChip(
                    label: translate(context, 'zone'),
                    icon: Icons.location_on,
                    onTap: () => _showZoneFilterDialog(siteProvider),
                    isActive: _selectedZoneFilters.isNotEmpty,
                    count: _selectedZoneFilters.length,
                  ),
                  const SizedBox(width: 8),

                  // Performer Filter
                  _buildFilterChip(
                    label: translate(context, 'performer'),
                    icon: Icons.person,
                    onTap: () => _showPerformerFilterDialog(),
                    isActive: _selectedPerformerFilters.isNotEmpty,
                    count: _selectedPerformerFilters.length,
                  ),
                  const SizedBox(width: 8),

                  // Date Filter
                  _buildFilterChip(
                    label: translate(context, 'date'),
                    icon: Icons.date_range,
                    onTap: () => _showDateFilterDialog(),
                    isActive: _selectedDateFilter != null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
    int? count,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.blue : Colors.grey.shade700,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    final chips = <Widget>[];

    if (_searchQuery.isNotEmpty) {
      chips.add(_buildActiveFilterChip(
        label: 'Search: "$_searchQuery"',
        onRemove: () {
          _searchController.clear();
          setState(() {
            _searchQuery = '';
          });
        },
      ));
    }

    // Type filters
    for (final type in _selectedTypeFilters) {
      chips.add(_buildActiveFilterChip(
        label: 'Type: ${type.name}',
        onRemove: () {
          setState(() {
            _selectedTypeFilters.remove(type);
          });
        },
      ));
    }

    // Status filters
    for (final status in _selectedStatusFilters) {
      chips.add(_buildActiveFilterChip(
        label: 'Status: ${status.name}',
        onRemove: () {
          setState(() {
            _selectedStatusFilters.remove(status);
          });
        },
      ));
    }

    // Zone filters
    for (final zone in _selectedZoneFilters) {
      chips.add(_buildActiveFilterChip(
        label: 'Zone: $zone',
        onRemove: () {
          setState(() {
            _selectedZoneFilters.remove(zone);
          });
        },
      ));
    }

    // Performer filters
    for (final performer in _selectedPerformerFilters) {
      chips.add(_buildActiveFilterChip(
        label: 'Performer: $performer',
        onRemove: () {
          setState(() {
            _selectedPerformerFilters.remove(performer);
          });
        },
      ));
    }

    // Date filter
    if (_selectedDateFilter != null) {
      chips.add(_buildActiveFilterChip(
        label: 'Date: ${_formatDisplayDate(_selectedDateFilter!)}',
        onRemove: () {
          setState(() {
            _selectedDateFilter = null;
          });
        },
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: Colors.blue.shade50,
      deleteIconColor: Colors.blue,
    );
  }

  Widget _buildLoadArchivedReportsButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh),
            label: Text(translate(context, 'load_archived_reports')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedReportsList(
    Map<String, List<ReportModel>> archivedReportsByDate,
    ReportProvider reportProvider,
    bool isAdmin,
    bool hasActiveFilters,
  ) {
    if (archivedReportsByDate.isEmpty) {
      if (_loadedArchivedReports.isEmpty) {
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _hasLoadedInitialData = false;
            });
            await _loadInitialData();
          },
          child: Center(
            child: Text(
              translate(context, 'no_archived_reports'),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        );
      } else if (hasActiveFilters) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                translate(context, 'no_results_found'),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _clearFilters,
                child: Text(translate(context, 'clear_filters')),
              ),
            ],
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _hasLoadedInitialData = false;
        });
        await _loadInitialData();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: archivedReportsByDate.length +
            (!hasActiveFilters && (_hasMoreData || _isLoadingMore) ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == archivedReportsByDate.length && !hasActiveFilters) {
            if (_isLoadingMore) {
              return _buildLoadingIndicator();
            } else if (_hasMoreData) {
              return _buildLoadMoreTrigger();
            } else {
              return const SizedBox.shrink();
            }
          }

          final dateKey = archivedReportsByDate.keys.elementAt(index);
          final reports = archivedReportsByDate[dateKey]!;

          return _buildDateSection(dateKey, reports, reportProvider, isAdmin);
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
          child: SizedBox(
        width: 120,
        child: LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
          backgroundColor: Colors.black12,
          minHeight: 4,
        ),
      )),
    );
  }

  Widget _buildLoadMoreTrigger() {
    return GestureDetector(
      onTap: _loadMoreData,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.keyboard_arrow_down, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Text(
              translate(context, 'load_more_reports'),
              style: TextStyle(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection(String dateKey, List<ReportModel> reports,
      ReportProvider reportProvider, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateHeader(dateKey),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${reports.length} ${translate(context, 'tasks')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _showDeleteDateConfirmation(
                        dateKey, reports, reportProvider),
                    tooltip: translate(context, 'delete_all_reports_for_date'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: reports
                  .map((report) =>
                      _buildArchivedReportCard(report, reportProvider, isAdmin))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedReportCard(
      ReportModel report, ReportProvider reportProvider, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ReportCardWidget(
        report: report,
        onStatusChanged: (newStatus) {
          reportProvider.updateReportStatus(report.id, newStatus);
        },
        showDeleteButton: isAdmin,
        showUnarchiveButton: isAdmin,
        onDelete: () => _showDeleteConfirmation(report, reportProvider),
        onUnarchive: () => _showUnarchiveConfirmation(report, reportProvider),
      ),
    );
  }

  String _formatDateHeader(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final date = DateTime(year, month, day);

        final months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];

        return '${date.day} ${months[date.month - 1]} ${date.year}';
      }
    } catch (e) {
      print('Error formatting date: $e');
    }

    return dateKey;
  }

  String _formatDisplayDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _getTotalFilteredReports(Map<String, List<ReportModel>> groupedReports) {
    return groupedReports.values
        .fold(0, (sum, reports) => sum + reports.length);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedTypeFilters.clear();
      _selectedStatusFilters.clear();
      _selectedZoneFilters.clear();
      _selectedPerformerFilters.clear();
      _selectedDateFilter = null;
    });
  }

// REPLACE THESE FOUR FILTER DIALOG METHODS IN YOUR CODE:

// DIALOGS FOR FILTERS (with checkboxes) - FIXED VERSION
  Future<void> _showTypeFilterDialog() async {
    final tempSelectedTypes = Set<ReportType>.from(_selectedTypeFilters);

    final result = await showDialog<Set<ReportType>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(translate(context, 'filter_by_type')),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Select All / Clear All buttons
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            tempSelectedTypes.clear();
                            tempSelectedTypes.addAll(ReportType.values);
                          });
                        },
                        child: Text(translate(context, 'select_all')),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            tempSelectedTypes.clear();
                          });
                        },
                        child: Text(translate(context, 'clear_all')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Checkbox list
                  Column(
                    children: ReportType.values.map((type) {
                      return CheckboxListTile(
                        title: Text(
                          type == ReportType.work
                              ? translate(context, 'work')
                              : translate(context, 'hazard'),
                        ),
                        value: tempSelectedTypes.contains(type),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              tempSelectedTypes.add(type);
                            } else {
                              tempSelectedTypes.remove(type);
                            }
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(translate(context, 'cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                      context, Set<ReportType>.from(tempSelectedTypes));
                },
                child: Text(translate(context, 'apply')),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTypeFilters = result;
      });
    }
  }

  Future<void> _showStatusFilterDialog() async {
    final tempSelectedStatuses = Set<ReportStatus>.from(_selectedStatusFilters);

    final result = await showDialog<Set<ReportStatus>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(translate(context, 'filter_by_status')),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Select All / Clear All buttons
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            tempSelectedStatuses.clear();
                            tempSelectedStatuses.addAll(ReportStatus.values);
                          });
                        },
                        child: Text(translate(context, 'select_all')),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            tempSelectedStatuses.clear();
                          });
                        },
                        child: Text(translate(context, 'clear_all')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Checkbox list
                  Column(
                    children: ReportStatus.values.map((status) {
                      return CheckboxListTile(
                        title: Text(_getStatusText(status)),
                        value: tempSelectedStatuses.contains(status),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              tempSelectedStatuses.add(status);
                            } else {
                              tempSelectedStatuses.remove(status);
                            }
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(translate(context, 'cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                      context, Set<ReportStatus>.from(tempSelectedStatuses));
                },
                child: Text(translate(context, 'apply')),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        _selectedStatusFilters = result;
      });
    }
  }

  Future<void> _showZoneFilterDialog(SiteProvider siteProvider) async {
    final tempSelectedZones = Set<String>.from(_selectedZoneFilters);
    final availableZones = siteProvider.currentSite!.zones;

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Create a filtered list for searching
          List<ZoneModel> displayedZones = List.from(availableZones);

          return AlertDialog(
            title: Text(translate(context, 'filter_by_zone')),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Search for zones
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: translate(context, 'search_zones'),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty) {
                            displayedZones = List.from(availableZones);
                          } else {
                            displayedZones = availableZones.where((zone) {
                              final zoneName =
                                  zone.getName(context).toLowerCase();
                              return zoneName.contains(value.toLowerCase());
                            }).toList();
                          }
                        });
                      },
                    ),
                  ),

                  // Select All / Clear All buttons
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            tempSelectedZones.clear();
                            for (final zone in availableZones) {
                              tempSelectedZones.add(zone.id);
                            }
                          });
                        },
                        child: Text(translate(context, 'select_all')),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            tempSelectedZones.clear();
                          });
                        },
                        child: Text(translate(context, 'clear_all')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Checkbox list
                  Expanded(
                    child: ListView.builder(
                      itemCount: displayedZones.length,
                      itemBuilder: (context, index) {
                        final zone = displayedZones[index];
                        return CheckboxListTile(
                          title: Text(zone.getName(context)),
                          value: tempSelectedZones.contains(zone.id),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                tempSelectedZones.add(zone.id);
                              } else {
                                tempSelectedZones.remove(zone.id);
                              }
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(translate(context, 'cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, Set<String>.from(tempSelectedZones));
                },
                child: Text(translate(context, 'apply')),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        _selectedZoneFilters = result;
      });
    }
  }

  Future<void> _showPerformerFilterDialog() async {
    final tempSelectedPerformers = Set<String>.from(_selectedPerformerFilters);
    final performers = _getUniquePerformers();

    if (performers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translate(context, 'no_performers_found')),
        ),
      );
      return;
    }

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Create a filtered list for searching
          List<String> displayedPerformers = List.from(performers);

          return AlertDialog(
            title: Text(translate(context, 'filter_by_performer')),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Search for performers
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: translate(context, 'search_performers'),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty) {
                            displayedPerformers = List.from(performers);
                          } else {
                            displayedPerformers = performers.where((performer) {
                              return performer
                                  .toLowerCase()
                                  .contains(value.toLowerCase());
                            }).toList();
                          }
                        });
                      },
                    ),
                  ),

                  // Select All / Clear All buttons
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            tempSelectedPerformers.clear();
                            tempSelectedPerformers.addAll(performers);
                          });
                        },
                        child: Text(translate(context, 'select_all')),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            tempSelectedPerformers.clear();
                          });
                        },
                        child: Text(translate(context, 'clear_all')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Checkbox list
                  Expanded(
                    child: ListView.builder(
                      itemCount: displayedPerformers.length,
                      itemBuilder: (context, index) {
                        final performer = displayedPerformers[index];
                        return CheckboxListTile(
                          title: Text(performer),
                          value: tempSelectedPerformers.contains(performer),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                tempSelectedPerformers.add(performer);
                              } else {
                                tempSelectedPerformers.remove(performer);
                              }
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(translate(context, 'cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                      context, Set<String>.from(tempSelectedPerformers));
                },
                child: Text(translate(context, 'apply')),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        _selectedPerformerFilters = result;
      });
    }
  }

  Future<void> _showDateFilterDialog() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDateFilter = selectedDate;
      });
    }
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.inProgress:
        return translate(context, 'in_progress');
      case ReportStatus.done:
        return translate(context, 'completed');
      case ReportStatus.hazard:
        return translate(context, 'hazard');
    }
  }

  void _showDeleteDateConfirmation(String dateKey, List<ReportModel> reports,
      ReportProvider reportProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate(context, 'delete_all_reports')),
        content: Text(
            '${translate(context, 'delete_all_reports_confirmation')} ${_formatDateHeader(dateKey)}? '
            '${translate(context, 'this_action_cannot_be_undone')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translate(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteReportsByDate(dateKey, reports, reportProvider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(translate(context, 'delete_all')),
          ),
        ],
      ),
    );
  }

  void _deleteReportsByDate(String dateKey, List<ReportModel> reports,
      ReportProvider reportProvider) {
    reportProvider.deleteArchivedReportsByDate(dateKey);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${translate(context, 'reports_deleted_for_date')} ${_formatDateHeader(dateKey)}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showDeleteConfirmation(
      ReportModel report, ReportProvider reportProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate(context, 'delete_report')),
        content: Text(
            '${translate(context, 'delete_report_confirmation')} "${report.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translate(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteReport(report, reportProvider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(translate(context, 'delete')),
          ),
        ],
      ),
    );
  }

  void _showUnarchiveConfirmation(
      ReportModel report, ReportProvider reportProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate(context, 'unarchive_report')),
        content: Text(
            '${translate(context, 'unarchive_report_confirmation')} "${report.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translate(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _unarchiveReport(report, reportProvider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(translate(context, 'unarchive')),
          ),
        ],
      ),
    );
  }

  void _deleteReport(ReportModel report, ReportProvider reportProvider) {
    reportProvider.deleteArchivedReport(report.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${translate(context, 'report_deleted')} "${report.description}"'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _unarchiveReport(
      ReportModel report, ReportProvider reportProvider) async {
    try {
      await reportProvider.unarchiveReport(report.id);

      setState(() {
        _hasLoadedInitialData = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${translate(context, 'report_unarchived')} "${report.description}"'),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      _loadInitialData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unarchive report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
