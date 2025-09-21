// UPDATED: lib/helpers/localization_helper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livework_view/providers/language_provider.dart';

String translate(BuildContext context, String key) {
  return context.watch<LanguageProvider>().translate(key);
}
