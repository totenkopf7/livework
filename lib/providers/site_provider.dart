// --------------------------------------------------
// UPDATED: lib/providers/site_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/site_model.dart';
import 'language_provider.dart';

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

      // Mock data with multilingual zone names
      _availableSites = [
        SiteModel(
          id: 'site_001',
          name: 'Karband Co.',
          address: 'IRQ-KRG-DHK-Kwashe',
          latitude: 29.7604,
          longitude: -95.3698,
          zones: [
            ZoneModel(
                id: 'Atmosphere Unit',
                name: {'en': 'Atmosphere Unit', 'ku': '  یەکا ئەتموسفیرێ'},
                color: 'red'),
            ZoneModel(
                id: 'Vacuum Unit',
                name: {'en': 'Vacuum Unit', 'ku': ' یەکا ڤاکیومێ'},
                color: 'blue'),
            ZoneModel(
                id: 'Tanks',
                name: {'en': 'Tanks', 'ku': 'ناڤ تانکا '},
                color: 'green'),
            ZoneModel(
                id: 'Main Office',
                name: {'en': 'Main Office', 'ku': 'ئوفیسا سەرەکی'},
                color: 'orange'),
            ZoneModel(
                id: 'Employee Building 1',
                name: {
                  'en': 'Employee Building 1',
                  'ku': 'ئاڤاهیێ کارمەندان ١'
                },
                color: 'orange'),
            ZoneModel(
                id: 'Employee Building 2',
                name: {
                  'en': 'Employee Building 2',
                  'ku': 'ئاڤاهیێ کارمەندان ٢'
                },
                color: 'orange'),
            ZoneModel(
                id: 'Control Room ',
                name: {'en': 'Control Room', 'ku': ' کونترول '},
                color: 'orange'),
            ZoneModel(
                id: 'Laboratory ',
                name: {'en': 'Laboratory', 'ku': ' مختبر '},
                color: 'orange'),
            ZoneModel(
                id: 'Merul Factory',
                name: {'en': 'Merul Factory', 'ku': ' کارگەها میرول '},
                color: 'orange'),
            ZoneModel(
                id: 'Loading/Unloading Area',
                name: {'en': 'Loading/Unloading Area', 'ku': 'شەمعە '},
                color: 'yellow'),
            ZoneModel(
                id: 'Pre Flash Tower',
                name: {'en': 'Pre Flash Tower', 'ku': 'یەکا پری فلاش'},
                color: 'orange'),
            ZoneModel(
                id: 'Adjacent Fabrication Yard',
                name: {'en': 'Adjacent Fabrication Yard', 'ku': 'ساحا تەصفیێ'},
                color: 'orange'),
            ZoneModel(
                id: 'Refinery 2',
                name: {'en': 'Refinery 2', 'ku': 'تەصفیا ٢'},
                color: 'orange'),
            ZoneModel(
                id: 'Site near Loading Area',
                name: {
                  'en': 'Site near Loading Area',
                  'ku': 'سایتێ  نێزیک  شەمعا'
                },
                color: 'orange'),
            ZoneModel(
                id: 'Site near Vacuum & Atmosphere',
                name: {
                  'en': 'Site near Vacuum & Atmosphere',
                  'ku': 'سایتێ  نێزیک یەکێن سەری '
                },
                color: 'orange'),
            ZoneModel(
                id: 'Water Unit',
                name: {'en': 'Water Unit', 'ku': 'یەکا ئاڤێ'},
                color: 'blue'),
            ZoneModel(
                id: 'Generators',
                name: {'en': 'Generators', 'ku': ' موەلیدە'},
                color: 'red'),
            ZoneModel(
                id: 'Gabban',
                name: {'en': 'Gabban', 'ku': 'گەبان'},
                color: 'orange'),
            ZoneModel(
                id: 'Security Cabin',
                name: {'en': 'Security Cabin', 'ku': 'کابینا سکیوریتی'},
                color: 'orange'),
            ZoneModel(
                id: 'Garden',
                name: {'en': 'Garden', 'ku': 'باخچە'},
                color: 'orange'),
            ZoneModel(
                id: 'Burners',
                name: {'en': 'Burners', 'ku': 'بویلەر'},
                color: 'orange'),
            ZoneModel(
                id: 'Steam Boilers',
                name: {'en': 'Steam Boilers', 'ku': 'ستیم بویلەر '},
                color: 'orange'),
            ZoneModel(
                id: 'Irani-Kurdish Workers Building',
                name: {
                  'en': 'Irani-Kurdish Workers Building',
                  'ku': 'ئاڤاهیێ کارمەندێن روژهەلاتێ '
                },
                color: 'orange'),
            ZoneModel(
                id: 'Flare Area ',
                name: {'en': 'Flare Area', 'ku': 'فلێر'},
                color: 'orange'),
            ZoneModel(
                id: 'Across the Site',
                name: {'en': 'Across the Site', 'ku': ' دەورو بەرێ سایتی '},
                color: 'orange'),
          ],
        ),
        SiteModel(
          id: 'site_002',
          name: 'Industrial Park',
          address: '456 Industrial Blvd, Houston, TX',
          latitude: 29.7605,
          longitude: -95.3699,
          zones: [
            ZoneModel(
                id: 'zone_d',
                name: {'en': 'Warehouse 1', 'ku': 'کۆگا ١'},
                color: 'orange'),
            ZoneModel(
                id: 'zone_e',
                name: {'en': 'Warehouse 2', 'ku': 'کۆگا ٢'},
                color: 'purple'),
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

  // Helper method to get zone name in current language
  String getZoneName(BuildContext context, String zoneId) {
    if (_currentSite == null) return zoneId;

    final zone = _currentSite!.zones.firstWhere(
      (zone) => zone.id == zoneId,
      orElse: () => ZoneModel(
          id: zoneId, name: {'en': zoneId, 'ku': zoneId}, color: 'gray'),
    );

    return zone.getName(context);
  }

  // Call this when language changes to update UI
  void updateOnLanguageChange() {
    notifyListeners();
  }
}
