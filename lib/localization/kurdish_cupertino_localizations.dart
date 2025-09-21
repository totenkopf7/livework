// NEW FILE: lib/localization/kurdish_cupertino_localizations.dart
import 'package:flutter/cupertino.dart';

class KurdishCupertinoLocalizations extends DefaultCupertinoLocalizations {
  KurdishCupertinoLocalizations();

  @override
  String get alertDialogLabel => 'ئاگاداری';

  @override
  String get anteMeridiemAbbreviation => 'پ.ن';

  @override
  String get postMeridiemAbbreviation => 'پ.ن';

  @override
  String get todayLabel => 'ئەمڕۆ';

  @override
  String timerPickerHourLabel(int hour) => 'کاتژمێر';

  @override
  String timerPickerMinuteLabel(int minute) => 'خولەک';

  @override
  String timerPickerSecondLabel(int second) => 'چرکە';

  @override
  String get modalBarrierDismissLabel => 'لابردن';

  @override
  String get searchTextFieldPlaceholderLabel => 'گەران';

  @override
  String get datePickerDateOrderString => 'mdy';

  @override
  String get datePickerDateTimeOrderString => 'date_time';

  @override
  String get datePickerDateSeparator => '/';

  @override
  String get datePickerDateTimeSeparator => ' ';

  @override
  String get pasteButtonLabel => 'لکاندن';

  @override
  String get copyButtonLabel => 'لەبەرگرتنەوە';

  @override
  String get cutButtonLabel => 'بڕین';

  @override
  String get selectAllButtonLabel => 'هەمووی هەڵبژێرە';

  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      _KurdishCupertinoLocalizationsDelegate();
}

class _KurdishCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _KurdishCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    return KurdishCupertinoLocalizations();
  }

  @override
  bool shouldReload(_KurdishCupertinoLocalizationsDelegate old) => false;
}
