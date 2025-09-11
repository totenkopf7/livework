import 'package:flutter/foundation.dart';
import '../data/models/site_model.dart';
class SiteProvider with ChangeNotifier {
  SiteModel? _currentSite;
  List<SiteModel> _availableSites = [];
  bool _isLoading = false;
  String? _error;

  SiteModel? get currentSite => _currentSite;
  List<SiteModel> get availableSites => _availableSites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data for demonstration
      _availableSites = [
        SiteModel(
          id: 'site_001',
          name: 'Downtown Office Complex',
          address: '123 Main St, Houston, TX',
          latitude: 29.7604,
          longitude: -95.3698,
          zones: [
            ZoneModel(
                id: 'Atmosphere Unit', name: 'Atmosphere Unit', color: 'red'),
            ZoneModel(id: 'Vacuum Unit', name: 'Vacuum Unit', color: 'blue'),
            ZoneModel(id: 'Tanks', name: 'Tanks', color: 'green'),
            ZoneModel(
                id: 'Office Area', name: 'Office Area', color: 'office Area'),
            ZoneModel(
                id: 'Welding Workshop',
                name: 'Welding Workshop',
                color: 'orange'),
            ZoneModel(
                id: 'Loading Area', name: 'Loading Area', color: 'yellow'),
          ],
        ),
        SiteModel(
          id: 'site_002',
          name: 'Industrial Park',
          address: '456 Industrial Blvd, Houston, TX',
          latitude: 29.7605,
          longitude: -95.3699,
          zones: [
            ZoneModel(id: 'zone_d', name: 'Warehouse 1', color: 'orange'),
            ZoneModel(id: 'zone_e', name: 'Warehouse 2', color: 'purple'),
          ],
        ),
      ];

      // Set first site as current if none selected
      if (_currentSite == null && _availableSites.isNotEmpty) {
        _currentSite = _availableSites.first;
      }
    } catch (e) {
      _error = 'Failed to load sites: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCurrentSite(SiteModel site) async {
    try {
      _currentSite = site;
      notifyListeners();

      // TODO: Save to local storage or backend
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      _error = 'Failed to set current site: $e';
      notifyListeners();
    }
  }

  void addSite(SiteModel site) {
    _availableSites.add(site);
    notifyListeners();
  }

  void removeSite(String siteId) {
    _availableSites.removeWhere((site) => site.id == siteId);
    if (_currentSite?.id == siteId) {
      _currentSite = _availableSites.isNotEmpty ? _availableSites.first : null;
    }
    notifyListeners();
  }
}
