// UPDATED: lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:livework_view/providers/site_provider.dart';
import 'package:livework_view/providers/auth_provider.dart' as livework_auth;
import 'package:livework_view/providers/language_provider.dart';
import 'package:livework_view/helpers/localization_helper.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Text(translate(context, 'settings'));
          },
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<SiteProvider>(
            builder: (context, siteProvider, child) {
              return Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                translate(context, 'select_language'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              if (languageProvider.isLoading)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    RadioListTile(
                                      title: Text(translate(
                                          context, 'language_english')),
                                      value: 'en',
                                      groupValue: languageProvider
                                          .currentLocale.languageCode,
                                      onChanged: (value) {
                                        if (value != null) {
                                          languageProvider
                                              .loadLanguage(Locale(value,
                                                  value == 'en' ? 'US' : 'IQ'))
                                              .then((_) {
                                            // Notify site provider to update zone names
                                            final siteProvider =
                                                Provider.of<SiteProvider>(
                                                    context,
                                                    listen: false);
                                            siteProvider
                                                .updateOnLanguageChange();
                                          });
                                        }
                                      },
                                    ),
                                    RadioListTile(
                                      title: Text(translate(
                                          context, 'language_kurdish')),
                                      value: 'ku',
                                      groupValue: languageProvider
                                          .currentLocale.languageCode,
                                      onChanged: (value) {
                                        if (value != null) {
                                          languageProvider
                                              .loadLanguage(Locale(value,
                                                  value == 'en' ? 'US' : 'IQ'))
                                              .then((_) {
                                            // Notify site provider to update zone names
                                            final siteProvider =
                                                Provider.of<SiteProvider>(
                                                    context,
                                                    listen: false);
                                            siteProvider
                                                .updateOnLanguageChange();
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                translate(context, 'site_configuration'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              if (siteProvider.currentSite != null) ...[
                                Text(
                                  '${translate(context, 'current_site')}: ${siteProvider.currentSite!.name}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '${translate(context, 'site_id')}: ${siteProvider.currentSite!.id}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  translate(context, 'no_site_configured'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  _showSiteSelectionDialog(context);
                                },
                                child: Text(translate(context, 'change_site')),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                translate(context, 'app_information'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'LiveWork View v1.0.0',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                translate(context, 'real_time_tracking'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                translate(context, 'account'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Consumer<livework_auth.LiveWorkAuthProvider>(
                                builder: (context, authProvider, child) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${translate(context, 'logged_in_as')}: ${authProvider.user?.email ?? 'Unknown'}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '${translate(context, 'role')}: ${authProvider.user?.role ?? 'Unknown'}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await authProvider.logout();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child:
                                            Text(translate(context, 'logout')),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSiteSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate(context, 'select_site')),
        content: Text(translate(context, 'site_selection_prompt')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translate(context, 'cancel')),
          ),
        ],
      ),
    );
  }
}
