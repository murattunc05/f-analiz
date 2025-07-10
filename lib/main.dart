// lib/main.dart
import 'package:flutter/rendering.dart'; // ScrollDirection için eklendi
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart'; // Gerekli paketi import ediyoruz
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'home_feed_screen.dart';
import 'matches_screen.dart';
import 'analysis_screen.dart'; 
import 'app_themes.dart';
import 'data_service.dart';
import 'utils/dialog_utils.dart';
import 'team_search_screen.dart';

// --- Sabitler ve Sınıflar (Değişiklik yok) ---
const String kBrightnessPreference = 'brightness_preference_v2';
const String kThemePalettePreferenceKey = 'theme_palette_preference';
const String kSeasonPreferenceKey = 'season_preference';
const String kShowAttigiGolKey = 'show_attigi_gol';
const String kShowYedigiGolKey = 'show_yedigi_gol';
const String kShowGalibiyetKey = 'show_galibiyet';
const String kShowBeraberlikKey = 'show_beraberlik';
const String kShowMaglubiyetKey = 'show_maglubiyet';
const String kShowMacBasiOrtGolKey = 'show_mac_basi_ort_gol';
const String kShowMaclardaOrtTplGolKey = 'show_maclarda_ort_tpl_gol';
const String kShowGol2UstuOlasilikKey = 'show_gol_2_ustu_olasilik';
const String kShowSon5MacDetaylariKey = 'show_son_5_mac_detaylari';
const String kShowOverallLast5StatsKey = 'show_overall_last_5_stats';
const String kShowGolFarkiKey = 'show_gol_farki';
const String kShowKgVarYokKey = 'show_kg_var_yok';
const String kShowComparisonKgVarKey = 'show_comparison_kg_var';
const String kShowCleanSheetKey = 'show_clean_sheet';
const String kShowAvgShotsKey = 'show_avg_shots';
const String kShowAvgShotsOnTargetKey = 'show_avg_shots_on_target';
const String kShowAvgFoulsKey = 'show_avg_fouls';
const String kShowAvgCornersKey = 'show_avg_corners';
const String kShowAvgYellowCardsKey = 'show_avg_yellow_cards';
const String kShowAvgRedCardsKey = 'show_avg_red_cards';
const String kShowIySonuclarKey = 'show_iy_sonuclar';
const String kShowIyGolOrtKey = 'show_iy_gol_ort';

class StatsDisplaySettings {
    bool showAttigiGol; bool showYedigiGol; bool showGalibiyet; bool showBeraberlik; bool showMaglubiyet; bool showMacBasiOrtGol;
    bool showMaclardaOrtTplGol; bool showGol2UstuOlasilik; bool showSon5MacDetaylari; bool showOverallLast5Stats; bool showGolFarki;
    bool showKgVarYok; bool showComparisonKgVar; bool showCleanSheet; bool showAvgShots; bool showAvgShotsOnTarget; bool showAvgFouls;
    bool showAvgCorners; bool showAvgYellowCards; bool showAvgRedCards; bool showIySonuclar; bool showIyGolOrt;

    StatsDisplaySettings({
        this.showAttigiGol = true, this.showYedigiGol = true, this.showGalibiyet = true, this.showBeraberlik = true, this.showMaglubiyet = true,
        this.showMacBasiOrtGol = true, this.showMaclardaOrtTplGol = true, this.showGol2UstuOlasilik = true, this.showSon5MacDetaylari = true,
        this.showOverallLast5Stats = true, this.showGolFarki = true, this.showKgVarYok = true, this.showComparisonKgVar = true,
        this.showCleanSheet = true, this.showAvgShots = true, this.showAvgShotsOnTarget = true, this.showAvgFouls = true,
        this.showAvgCorners = true, this.showAvgYellowCards = true, this.showAvgRedCards = true, this.showIySonuclar = true, this.showIyGolOrt = true,
    });

    static Future<StatsDisplaySettings> load() async {
        final prefs = await SharedPreferences.getInstance();
        return StatsDisplaySettings(
            showAttigiGol: prefs.getBool(kShowAttigiGolKey) ?? true, showYedigiGol: prefs.getBool(kShowYedigiGolKey) ?? true,
            showGalibiyet: prefs.getBool(kShowGalibiyetKey) ?? true, showBeraberlik: prefs.getBool(kShowBeraberlikKey) ?? true,
            showMaglubiyet: prefs.getBool(kShowMaglubiyetKey) ?? true, showMacBasiOrtGol: prefs.getBool(kShowMacBasiOrtGolKey) ?? true,
            showMaclardaOrtTplGol: prefs.getBool(kShowMaclardaOrtTplGolKey) ?? true, showGol2UstuOlasilik: prefs.getBool(kShowGol2UstuOlasilikKey) ?? true,
            showSon5MacDetaylari: prefs.getBool(kShowSon5MacDetaylariKey) ?? true, showOverallLast5Stats: prefs.getBool(kShowOverallLast5StatsKey) ?? true,
            showGolFarki: prefs.getBool(kShowGolFarkiKey) ?? true, showKgVarYok: prefs.getBool(kShowKgVarYokKey) ?? true,
            showComparisonKgVar: prefs.getBool(kShowComparisonKgVarKey) ?? true, showCleanSheet: prefs.getBool(kShowCleanSheetKey) ?? true,
            showAvgShots: prefs.getBool(kShowAvgShotsKey) ?? true, showAvgShotsOnTarget: prefs.getBool(kShowAvgShotsOnTargetKey) ?? true,
            showAvgFouls: prefs.getBool(kShowAvgFoulsKey) ?? true, showAvgCorners: prefs.getBool(kShowAvgCornersKey) ?? true,
            showAvgYellowCards: prefs.getBool(kShowAvgYellowCardsKey) ?? true, showAvgRedCards: prefs.getBool(kShowAvgRedCardsKey) ?? true,
            showIySonuclar: prefs.getBool(kShowIySonuclarKey) ?? true, showIyGolOrt: prefs.getBool(kShowIyGolOrtKey) ?? true,
        );
    }

    Future<void> saveSetting(String key, bool value) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(key, value);
        switch (key) {
            case kShowAttigiGolKey: showAttigiGol = value; break; case kShowYedigiGolKey: showYedigiGol = value; break;
            case kShowGalibiyetKey: showGalibiyet = value; break; case kShowBeraberlikKey: showBeraberlik = value; break;
            case kShowMaglubiyetKey: showMaglubiyet = value; break; case kShowMacBasiOrtGolKey: showMacBasiOrtGol = value; break;
            case kShowMaclardaOrtTplGolKey: showMaclardaOrtTplGol = value; break; case kShowGol2UstuOlasilikKey: showGol2UstuOlasilik = value; break;
            case kShowSon5MacDetaylariKey: showSon5MacDetaylari = value; break; case kShowOverallLast5StatsKey: showOverallLast5Stats = value; break;
            case kShowGolFarkiKey: showGolFarki = value; break; case kShowKgVarYokKey: showKgVarYok = value; break;
            case kShowComparisonKgVarKey: showComparisonKgVar = value; break; case kShowCleanSheetKey: showCleanSheet = value; break;
            case kShowAvgShotsKey: showAvgShots = value; break; case kShowAvgShotsOnTargetKey: showAvgShotsOnTarget = value; break;
            case kShowAvgFoulsKey: showAvgFouls = value; break; case kShowAvgCornersKey: showAvgCorners = value; break;
            case kShowAvgYellowCardsKey: showAvgYellowCards = value; break; case kShowAvgRedCardsKey: showAvgRedCards = value; break;
            case kShowIySonuclarKey: showIySonuclar = value; break; case kShowIyGolOrtKey: showIyGolOrt = value; break;
        }
    }
}

enum BrightnessPreference { light, dark, system }
BrightnessPreference _getBrightnessPreferenceFromString(String? prefString) { if (prefString == 'light') return BrightnessPreference.light; if (prefString == 'dark') return BrightnessPreference.dark; return BrightnessPreference.system; }
String _getStringFromBrightnessPreference(BrightnessPreference preference) { switch (preference) { case BrightnessPreference.light: return 'light'; case BrightnessPreference.dark: return 'dark'; case BrightnessPreference.system: return 'system'; } }

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('tr_TR', null);
    final prefs = await SharedPreferences.getInstance();
    final String? savedBrightnessPrefString = prefs.getString(kBrightnessPreference);
    final BrightnessPreference initialBrightnessPreference = _getBrightnessPreferenceFromString(savedBrightnessPrefString);
    final String? savedPaletteString = prefs.getString(kThemePalettePreferenceKey);
    final AppThemePalette initialPalette = stringToAppThemePalette(savedPaletteString);
    final StatsDisplaySettings initialStatsSettings = await StatsDisplaySettings.load();
    final String? savedSeasonApiValue = prefs.getString(kSeasonPreferenceKey);
    final String initialSeasonApiValue = savedSeasonApiValue ?? DataService.AVAILABLE_SEASONS_API.first;
    
    runApp(
      ProviderScope(
        child: MyApp(
            initialBrightnessPreference: initialBrightnessPreference, initialPalette: initialPalette, 
            initialStatsSettings: initialStatsSettings, initialSeasonApiValue: initialSeasonApiValue, 
        ),
      )
    );
}

class MyApp extends StatefulWidget {
    final BrightnessPreference initialBrightnessPreference;
    final AppThemePalette initialPalette;
    final StatsDisplaySettings initialStatsSettings;
    final String initialSeasonApiValue;
    const MyApp({super.key, required this.initialBrightnessPreference, required this.initialPalette, required this.initialStatsSettings, required this.initialSeasonApiValue});
    @override State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
    late BrightnessPreference _currentBrightnessPreference;
    late AppThemePalette _currentPalette;
    late StatsDisplaySettings _currentStatsSettings;
    late String _currentSeasonApiValue;
    PackageInfo _packageInfo = PackageInfo(appName: 'Bilinmiyor', packageName: 'Bilinmiyor', version: 'Bilinmiyor', buildNumber: 'Bilinmiyor');
    @override void initState() { super.initState(); _currentBrightnessPreference = widget.initialBrightnessPreference; _currentPalette = widget.initialPalette; _currentStatsSettings = widget.initialStatsSettings; _currentSeasonApiValue = widget.initialSeasonApiValue; _initPackageInfo(); }
    Future<void> _initPackageInfo() async { final PackageInfo info = await PackageInfo.fromPlatform(); if (mounted) setState(() => _packageInfo = info); }
    void _changeBrightnessPreference(BrightnessPreference preference) async { final prefs = await SharedPreferences.getInstance(); await prefs.setString(kBrightnessPreference, _getStringFromBrightnessPreference(preference)); if (mounted) setState(() => _currentBrightnessPreference = preference); }
    void _changePalette(AppThemePalette palette) async { final prefs = await SharedPreferences.getInstance(); await prefs.setString(kThemePalettePreferenceKey, appThemePaletteToString(palette)); if (mounted) setState(() => _currentPalette = palette); }
    void _changeStatsSetting(String key, bool value) async { await _currentStatsSettings.saveSetting(key, value); if (mounted) setState(() {}); }
    void _changeSeason(String seasonApiValue) async { final prefs = await SharedPreferences.getInstance(); await prefs.setString(kSeasonPreferenceKey, seasonApiValue); if (mounted) setState(() => _currentSeasonApiValue = seasonApiValue); }
    
    @override Widget build(BuildContext context) {
        final ThemeData currentLightTheme = AppThemes.getThemeData(_currentPalette, Brightness.light);
        final ThemeData currentDarkTheme = AppThemes.getThemeData(_currentPalette, Brightness.dark);
        ThemeMode currentThemeMode;
        switch (_currentBrightnessPreference) { case BrightnessPreference.light: currentThemeMode = ThemeMode.light; break; case BrightnessPreference.dark: currentThemeMode = ThemeMode.dark; break; case BrightnessPreference.system: currentThemeMode = ThemeMode.system; break; }
        return MaterialApp(
            title: 'GOALITYCS',
            theme: currentLightTheme,
            darkTheme: currentDarkTheme,
            themeMode: currentThemeMode,
            home: HomeScreen(onBrightnessPreferenceChanged: _changeBrightnessPreference, onPaletteChanged: _changePalette, currentBrightnessPreference: _currentBrightnessPreference, currentPalette: _currentPalette, currentStatsSettings: _currentStatsSettings, onStatsSettingChanged: _changeStatsSetting, currentSeasonApiValue: _currentSeasonApiValue, onSeasonChanged: _changeSeason, packageInfo: _packageInfo),
            debugShowCheckedModeBanner: false
        );
    }
}

class HomeScreen extends StatefulWidget {
  final Function(BrightnessPreference) onBrightnessPreferenceChanged;
  final Function(AppThemePalette) onPaletteChanged;
  final BrightnessPreference currentBrightnessPreference;
  final AppThemePalette currentPalette;
  final StatsDisplaySettings currentStatsSettings;
  final Function(String key, bool value) onStatsSettingChanged;
  final String currentSeasonApiValue;
  final Function(String seasonApiValue) onSeasonChanged;
  final PackageInfo packageInfo;
  
  const HomeScreen({super.key, required this.onBrightnessPreferenceChanged, required this.onPaletteChanged, required this.currentBrightnessPreference, required this.currentPalette, required this.currentStatsSettings, required this.onStatsSettingChanged, required this.currentSeasonApiValue, required this.onSeasonChanged, required this.packageInfo });
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late List<ScrollController> _scrollControllers;
  final ValueNotifier<bool> _isNavBarVisible = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _scrollControllers = List.generate(3, (_) => ScrollController());
    _updateWidgetOptions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    _isNavBarVisible.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStatsSettings != oldWidget.currentStatsSettings ||
        widget.currentPalette != oldWidget.currentPalette ||
        widget.currentBrightnessPreference != oldWidget.currentBrightnessPreference ||
        widget.currentSeasonApiValue != oldWidget.currentSeasonApiValue) {
      if (mounted) {
        setState(() {
          _updateWidgetOptions();
        });
      }
    }
  }

  void _updateWidgetOptions() {
    _widgetOptions = <Widget>[
      HomeFeedScreen(
        key: const ValueKey('homeFeedScreen'),
        currentSeasonApiValue: widget.currentSeasonApiValue,
        scrollController: _scrollControllers[0],
        scaffoldKey: _scaffoldKey,
        onSearchTap: _openSearchScreen,
      ),
      MatchesScreen(
        key: const ValueKey('matchesScreen'),
        scrollController: _scrollControllers[1],
        scaffoldKey: _scaffoldKey,
        onSearchTap: _openSearchScreen,
      ),
      AnalysisScreen(
        key: const ValueKey('analysisScreen'),
        statsSettings: widget.currentStatsSettings,
        currentSeasonApiValue: widget.currentSeasonApiValue,
        scrollController: _scrollControllers[2],
        scaffoldKey: _scaffoldKey, 
        onSearchTap: _openSearchScreen,
      ),
    ];
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      if (_scrollControllers[index].hasClients) {
        _scrollControllers[index].animateTo(0.0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    } else {
      if (mounted) {
        setState(() => _selectedIndex = index);
        _pageController.jumpToPage(index);
      }
    }
  }

  String _getPaletteDisplayName(AppThemePalette palette) {
    switch (palette) {
        case AppThemePalette.defaultOrange: return "Varsayılan (Turuncu)";
        case AppThemePalette.material3Dynamic: return "Material You (Dinamik)";
        case AppThemePalette.oceanBlue: return "Okyanus Mavisi";
        case AppThemePalette.forestGreen: return "Orman Yeşili";
        case AppThemePalette.sunsetGlow: return "Gün Batımı Işıltısı";
        case AppThemePalette.mintyFresh: return "Ferah Nane";
        case AppThemePalette.lavenderDream: return "Lavanta Rüyası";
        case AppThemePalette.graphiteNight: return "Grafit Gecesi";
        case AppThemePalette.aiStudio: return "AI Stüdyosu";
    }
  }

  void _showThemePaletteSelectionDialog(BuildContext context) {
    showAnimatedDialog( context: context, titleWidget: const Text('Tema Paleti Seçin', textAlign: TextAlign.center),
      contentWidget: ListView( shrinkWrap: true,
        children: AppThemePalette.values.map((palette) => RadioListTile<AppThemePalette>( title: Text(_getPaletteDisplayName(palette)), value: palette, groupValue: widget.currentPalette,
          onChanged: (AppThemePalette? newValue) {
            if (newValue != null) { widget.onPaletteChanged(newValue); Navigator.of(context).pop(); }
          }
        )).toList(),
      ),
      actionsWidget: [ TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop()) ], maxHeightFactor: 0.7,
    );
  }

  String _getDisplaySeason(String apiValue) { return DataService.getDisplaySeasonFromApiValue(apiValue); }

  void _showSeasonSelectionDialog(BuildContext context) {
     showAnimatedDialog( context: context, titleWidget: const Text('Sezon Seçin', textAlign: TextAlign.center),
      contentWidget: SizedBox(
        child: ListView( shrinkWrap: true,
          children: DataService.AVAILABLE_SEASONS_DISPLAY.entries.map((entry) {
            return RadioListTile<String>( title: Text(entry.key), value: entry.value, groupValue: widget.currentSeasonApiValue,
              onChanged: (String? newValue) {
                if (newValue != null) { widget.onSeasonChanged(newValue); Navigator.of(context).pop(); }
              });
          }).toList(),
        ),
      ),
      actionsWidget: [ TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop()) ], maxHeightFactor: 0.6,
    );
  }

  void _showStatsDisplaySettingsDialog(BuildContext context) {
    final theme = Theme.of(context);
    showAnimatedDialog(
      context: context, titleWidget: const Text('Görüntülenecek İstatistikler', textAlign: TextAlign.center),
      contentWidget: StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter setDialogState) {
          final settings = widget.currentStatsSettings;
          return ListView( shrinkWrap: true, children: <Widget>[
            SwitchListTile(title: const Text('Tüm Son Maç İstatistikleri'), subtitle: const Text('Bu başlık ve altındaki tüm istatistikler'), value: settings.showOverallLast5Stats, onChanged: (bool value) { widget.onStatsSettingChanged(kShowOverallLast5StatsKey, value); setDialogState(() {}); }),
            const Divider(),
            Padding( padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), child: Text("Temel Maç İstatistikleri", style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary))),
            IgnorePointer( ignoring: !settings.showOverallLast5Stats, child: Opacity( opacity: settings.showOverallLast5Stats ? 1.0 : 0.5,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SwitchListTile(title: const Text('Attığı Gol'), value: settings.showAttigiGol, onChanged: (bool value) { widget.onStatsSettingChanged(kShowAttigiGolKey, value); setDialogState(() {}); }),
                  SwitchListTile(title: const Text('Yediği Gol'), value: settings.showYedigiGol, onChanged: (bool value) { widget.onStatsSettingChanged(kShowYedigiGolKey, value); setDialogState(() {}); }),
                  SwitchListTile(title: const Text('Gol Farkı (+/-)'), value: settings.showGolFarki, onChanged: (bool value) { widget.onStatsSettingChanged(kShowGolFarkiKey, value); setDialogState(() {}); }),
                  SwitchListTile(title: const Text('Galibiyet'), value: settings.showGalibiyet, onChanged: (bool value) { widget.onStatsSettingChanged(kShowGalibiyetKey, value); setDialogState(() {}); }),
                  SwitchListTile(title: const Text('Beraberlik'), value: settings.showBeraberlik, onChanged: (bool value) { widget.onStatsSettingChanged(kShowBeraberlikKey, value); setDialogState(() {}); }),
                  SwitchListTile(title: const Text('Mağlubiyet'), value: settings.showMaglubiyet, onChanged: (bool value) { widget.onStatsSettingChanged(kShowMaglubiyetKey, value); setDialogState(() {}); }),
                  SwitchListTile(title: const Text('Maç Başına Ort. Gol'), value: settings.showMacBasiOrtGol, onChanged: (bool value) { widget.onStatsSettingChanged(kShowMacBasiOrtGolKey, value); setDialogState(() {}); }),
                  SwitchListTile(title: const Text('Maçlarda Ort. Toplam Gol'), value: settings.showMaclardaOrtTplGol, onChanged: (bool value) { widget.onStatsSettingChanged(kShowMaclardaOrtTplGolKey, value); setDialogState(() {}); }),
                  SwitchListTile(title: const Text('KG Var/Yok Yüzdesi'), value: settings.showKgVarYok, onChanged: (bool value) { widget.onStatsSettingChanged(kShowKgVarYokKey, value); setDialogState(() {}); }),
                  SwitchListTile(title: const Text('Clean Sheet (Gol Yememe)'), value: settings.showCleanSheet, onChanged: (bool value) { widget.onStatsSettingChanged(kShowCleanSheetKey, value); setDialogState(() {}); }),
                  SwitchListTile(title: const Text('2+ Gol Olasılığı'), value: settings.showGol2UstuOlasilik, onChanged: (bool value) { widget.onStatsSettingChanged(kShowGol2UstuOlasilikKey, value); setDialogState(() {}); }),
                  SwitchListTile(title: const Text('Karşılaştırma KG VAR İhtimali'), value: settings.showComparisonKgVar, onChanged: (bool value) { widget.onStatsSettingChanged(kShowComparisonKgVarKey, value); setDialogState(() {}); }),
                ])
              )),
            const Divider(),
            Padding( padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), child: Text("İlk Yarı İstatistikleri", style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary))),
            IgnorePointer( ignoring: !settings.showOverallLast5Stats, child: Opacity( opacity: settings.showOverallLast5Stats ? 1.0 : 0.5,
                child: Column( mainAxisSize: MainAxisSize.min,children: [
                    SwitchListTile(title: const Text('İY Sonuçları (G/B/M)'), value: settings.showIySonuclar, onChanged: (bool value) { widget.onStatsSettingChanged(kShowIySonuclarKey, value); setDialogState(() {}); }),
                    SwitchListTile(title: const Text('İY Gol Ortalamaları'), value: settings.showIyGolOrt, onChanged: (bool value) { widget.onStatsSettingChanged(kShowIyGolOrtKey, value); setDialogState(() {}); }),
                  ]))),
            const Divider(),
            Padding( padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), child: Text("Detaylı Maç Ortalamaları", style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary))),
             IgnorePointer( ignoring: !settings.showOverallLast5Stats, child: Opacity( opacity: settings.showOverallLast5Stats ? 1.0 : 0.5,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SwitchListTile(title: const Text('Ortalama Şut'), value: settings.showAvgShots, onChanged: (bool value) { widget.onStatsSettingChanged(kShowAvgShotsKey, value); setDialogState(() {}); }),
                    SwitchListTile(title: const Text('Ort. İsabetli Şut'), value: settings.showAvgShotsOnTarget, onChanged: (bool value) { widget.onStatsSettingChanged(kShowAvgShotsOnTargetKey, value); setDialogState(() {}); }),
                    SwitchListTile(title: const Text('Ortalama Faul'), value: settings.showAvgFouls, onChanged: (bool value) { widget.onStatsSettingChanged(kShowAvgFoulsKey, value); setDialogState(() {}); }),
                    SwitchListTile(title: const Text('Ortalama Korner'), value: settings.showAvgCorners, onChanged: (bool value) { widget.onStatsSettingChanged(kShowAvgCornersKey, value); setDialogState(() {}); }),
                    SwitchListTile(title: const Text('Ortalama Sarı Kart'), value: settings.showAvgYellowCards, onChanged: (bool value) { widget.onStatsSettingChanged(kShowAvgYellowCardsKey, value); setDialogState(() {}); }),
                    SwitchListTile(title: const Text('Ortalama Kırmızı Kart'), value: settings.showAvgRedCards, onChanged: (bool value) { widget.onStatsSettingChanged(kShowAvgRedCardsKey, value); setDialogState(() {}); }),
                  ]))),
            const Divider(),
            IgnorePointer(ignoring: !settings.showOverallLast5Stats,
              child: Opacity( opacity: settings.showOverallLast5Stats ? 1.0 : 0.5,
                child: SwitchListTile( title: const Text('Son Maç Detayları'), value: settings.showSon5MacDetaylari,
                    onChanged: (bool value) { widget.onStatsSettingChanged(kShowSon5MacDetaylariKey, value); setDialogState(() {}); })))
          ]);
        }),
      actionsWidget: [ TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop()) ], maxHeightFactor: 0.8);
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showAnimatedDialog( context: context, titleWidget: const Text('GOALITYCS Hakkında', textAlign: TextAlign.center), dialogPadding: const EdgeInsets.all(20.0),
      contentWidget: Column( mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text('Uygulama Adı: ${widget.packageInfo.appName}', style: theme.textTheme.bodyMedium), const SizedBox(height: 4), Text('Sürüm: ${widget.packageInfo.version}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16), Text('Bu uygulama, futbol maçlarına dair istatistiksel analizler sunmak amacıyla geliştirilmiştir.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text( 'Goalitycs, asla bahis oynamaya veya yasa dışı kumar faaliyetlerine teşvik etmez. Sunulan veriler ve analizler yalnızca bilgilendirme ve eğlence amaçlıdır.', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant.withAlpha(204)),),
          const SizedBox(height: 16), RichText( text: TextSpan( style: theme.textTheme.bodyMedium, children: <TextSpan>[
                const TextSpan(text: 'Goalitycs, '), TextSpan(text: 'Ezgim\'in desteğiyle', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                const TextSpan(text: ' özenle hazırlandı.')
              ]))
        ],
      ),
      actionsWidget: [ TextButton(child: const Text('Tamam'), onPressed: () => Navigator.of(context).pop()) ], maxHeightFactor: 0.6,
    );
  }
  
  void _openSearchScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const TeamSearchScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: Drawer(child: ListView(padding: EdgeInsets.zero,children: <Widget>[Container(height: 120, padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 8.0), decoration: BoxDecoration(color: theme.colorScheme.primary), child: Align(alignment: Alignment.centerLeft, child: Text('Ayarlar', style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onPrimary)))), ListTile(leading: Icon( widget.currentBrightnessPreference == BrightnessPreference.light ? Icons.light_mode_outlined : widget.currentBrightnessPreference == BrightnessPreference.dark ? Icons.dark_mode_outlined : Icons.brightness_auto_outlined ), title: Text( widget.currentBrightnessPreference == BrightnessPreference.light ? 'Mod: Aydınlık' : widget.currentBrightnessPreference == BrightnessPreference.dark ? 'Mod: Koyu' : 'Mod: Sistem Varsayılanı' ), onTap: () { BrightnessPreference nextPreference; if (widget.currentBrightnessPreference == BrightnessPreference.light) { nextPreference = BrightnessPreference.dark; } else if (widget.currentBrightnessPreference == BrightnessPreference.dark) nextPreference = BrightnessPreference.system; else nextPreference = BrightnessPreference.light; widget.onBrightnessPreferenceChanged(nextPreference); }), ListTile(leading: const Icon(Icons.palette_outlined), title: const Text('Temalar'), subtitle: Text('Mevcut: ${_getPaletteDisplayName(widget.currentPalette)}'), onTap: () { Navigator.pop(context); _showThemePaletteSelectionDialog(context); }), ListTile(leading: const Icon(Icons.calendar_today_outlined), title: const Text('Sezon'), subtitle: Text('Geçerli: ${_getDisplaySeason(widget.currentSeasonApiValue)}'), onTap: () { Navigator.pop(context); _showSeasonSelectionDialog(context); }), const Divider(), ListTile(leading: const Icon(Icons.visibility_outlined), title: const Text('Görüntülenecek İstatistikler'), onTap: () { Navigator.pop(context); _showStatsDisplaySettingsDialog(context); }), ListTile(leading: const Icon(Icons.info_outline), title: const Text('Hakkında'), onTap: () { Navigator.pop(context); _showAboutDialog(context); })])),
      // DEĞİŞİKLİK: Scaffold'un body'si artık Stack
      body: Stack(
        children: [
          // Ana içerik (PageView)
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              final ScrollDirection direction = notification.direction;
              if (direction == ScrollDirection.reverse && _isNavBarVisible.value) {
                _isNavBarVisible.value = false;
              } else if (direction == ScrollDirection.forward && !_isNavBarVisible.value) {
                _isNavBarVisible.value = true;
              }
              return true;
            },
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), 
              children: _widgetOptions,
            ),
          ),
          // Navigasyon Barı (Üst katman)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isNavBarVisible,
              builder: (context, isVisible, child) {
                return AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  offset: isVisible ? Offset.zero : const Offset(0, 2),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              child: Container(
                color: Colors.transparent,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 72, right: 72, top: 8, bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF2D303E) : Colors.white, 
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 25,
                            color: isDarkMode ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: GNav(
                        rippleColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        haptic: true,
                        tabBorderRadius: 25,
                        tabBorder: Border.all(color: Colors.transparent),
                        tabActiveBorder: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 1),
                        tabShadow: const [],
                        tabBackgroundColor: Colors.transparent,
                        tabMargin: const EdgeInsets.symmetric(horizontal: 0),
                        color: isDarkMode ? Colors.white.withOpacity(0.6) : Colors.grey[600]!.withOpacity(0.6),
                        activeColor: isDarkMode ? Colors.white : theme.colorScheme.primary,
                        tabBackgroundGradient: null,
                        curve: Curves.easeOutQuad,
                        duration: const Duration(milliseconds: 300),
                        gap: 5,
                        iconSize: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        selectedIndex: _selectedIndex,
                        onTabChange: _onItemTapped,
                        tabs: const [
                          GButton(
                            icon: Icons.space_dashboard_outlined,
                            text: 'Akış',
                            textStyle: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          GButton(
                            icon: Icons.sports_soccer_outlined,
                            text: 'Maçlar',
                            textStyle: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          GButton(
                            icon: Icons.insights_outlined,
                            text: 'Analiz',
                            textStyle: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
