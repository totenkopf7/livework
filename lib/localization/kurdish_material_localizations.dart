// NEW FILE: lib/localization/kurdish_material_localizations.dart
import 'package:flutter/material.dart';

class KurdishMaterialLocalizations extends DefaultMaterialLocalizations {
  KurdishMaterialLocalizations();

  @override
  String get backButtonTooltip => 'زڤرین';

  @override
  String get cancelButtonLabel => 'لێڤە بوون';

  @override
  String get closeButtonTooltip => 'گرتن';

  @override
  String get continueButtonLabel => 'درێژە پێدان';

  @override
  String get copyButtonLabel => 'کوپی کرن';

  @override
  String get cutButtonLabel => 'بڕین';

  @override
  String get deleteButtonTooltip => 'ژێ برن';

  @override
  String get dialogLabel => 'دیالۆگ';

  @override
  String get hideAccountsLabel => 'ڤەشارتنا هەژمارا';

  @override
  String get licensesPageTitle => 'مۆڵەتنامەکان';

  @override
  String get modalBarrierDismissLabel => 'ڕاکرن';

  @override
  String get nextMonthTooltip => 'مانگی داهاتوو';

  @override
  String get nextPageTooltip => 'پەڕەی داهاتوو';

  @override
  String get okButtonLabel => 'باشە';

  @override
  String get openAppDrawerTooltip => 'کردنەوەی لیستەی ئەپ';

  @override
  String get pageRowsInfoTitleRaw => r'$firstRow–$lastRow لە $rowCount';

  @override
  String get pageRowsInfoTitleApproximateRaw =>
      r'$firstRow–$lastRow لە نزیکەی $rowCount';

  @override
  String get pasteButtonLabel => 'لکاندن';

  @override
  String get popupMenuLabel => 'لیستەی پۆپ ئەپ';

  @override
  String get postMeridiemAbbreviation => 'پ.ن';

  @override
  String get previousMonthTooltip => 'مانگی پێشوو';

  @override
  String get previousPageTooltip => 'پەڕەی پێشوو';

  @override
  String get refreshIndicatorSemanticLabel => 'نوێکردنەوە';

  @override
  String get searchFieldLabel => 'گەران';

  @override
  String get selectAllButtonLabel => 'هەمووی هەڵبژێرە';

  @override
  String get showAccountsLabel => 'نیشاندانی هەژمارەکان';

  @override
  String get showMenuTooltip => 'نیشاندانی لیستە';

  @override
  String get aboutListTileTitleRaw => r'دەربارەی $applicationName';

  @override
  String get alertDialogLabel => 'ئاگەهداری';

  @override
  String get anteMeridiemAbbreviation => 'پ.ن';

  @override
  String get calendarModeButtonLabel => 'گۆڕین بۆ کالێندار';

  @override
  String get closeButtonLabel => 'گرتن';

  @override
  String get continueButtonTooltip => 'درێژە پێدان';

  @override
  String get firstPageTooltip => 'یەکەم پەڕە';

  @override
  String get lastPageTooltip => 'کۆتا پەڕە';

  @override
  String get menuBarMenuLabel => 'لیستەی بار';

  @override
  String get reorderItemDown => 'ڕاکێشان بۆ خوارەوە';

  @override
  String get reorderItemLeft => 'ڕاکێشان بۆ چەپ';

  @override
  String get reorderItemRight => 'ڕاکێشان بۆ ڕاست';

  @override
  String get reorderItemToEnd => 'ڕاکێشان بۆ کۆتایی';

  @override
  String get reorderItemToStart => 'ڕاکێشان بۆ سەرەتا';

  @override
  String get reorderItemUp => 'ڕاکێشان بۆ سەرەوە';

  @override
  String get rowsPerPageTitle => 'ڕیز لە هەر پەڕەیەک:';

  @override
  String get saveButtonLabel => 'پاشەکەوتکردن';

  @override
  String get scanTextButtonLabel => 'پشکنینی تێکست';

  @override
  String get scrimLabel => 'پەردە';

  @override
  String get scrimOnTapHintRaw => r'لابردنی $modalRouteContentName';

  @override
  String get searchFieldTooltip => 'گەران';

  @override
  String get selectYearSemanticsLabel => 'هەڵبژاردنی ساڵ';

  @override
  String get selectedRowCountTitleFew => r'$selectedRowCount ئایتم هەڵبژێردرا';

  @override
  String get selectedRowCountTitleMany => r'$selectedRowCount ئایتم هەڵبژێردرا';

  @override
  String get selectedRowCountTitleOne => '١ ئایتم هەڵبژێردرا';

  @override
  String get selectedRowCountTitleOther =>
      r'$selectedRowCount ئایتم هەڵبژێردرا';

  @override
  String get selectedRowCountTitleTwo => r'$selectedRowCount ئایتم هەڵبژێردرا';

  @override
  String get selectedRowCountTitleZero => '';

  @override
  String get timePickerHourModeAnnouncement => 'هەڵبژاردنی کاتژمێر';

  @override
  String get timePickerMinuteModeAnnouncement => 'هەڵبژاردنی خولەک';

  @override
  String get viewLicensesButtonLabel => 'بینینی مۆڵەتنامەکان';

  @override
  String get datePickerDateOrderString => 'mdy';

  @override
  String get datePickerDateSeparator => '/';

  @override
  String get datePickerDateTimeOrderString => 'date_time';

  @override
  String get datePickerDateTimeSeparator => ' ';

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _KurdishMaterialLocalizationsDelegate();
}

class _KurdishMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _KurdishMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return KurdishMaterialLocalizations();
  }

  @override
  bool shouldReload(_KurdishMaterialLocalizationsDelegate old) => false;
}
