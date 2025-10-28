// lib/main.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_completion_screen.dart';
import 'services/onboarding_service.dart';
import 'services/auth_service.dart';
import 'services/user_profile_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';

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
const String kShowFormPuaniKey = 'show_form_puani';
const String kShowIyAttigiGolOrtKey = 'show_iy_attigi_gol_ort';
const String kShowIyYedigiGolOrtKey = 'show_iy_yedigi_gol_ort';
const String kShowIyGalibiyetYuzdesiKey = 'show_iy_galibiyet_yuzdesi';

class StatsDisplaySettings {
    bool showAttigiGol; bool showYedigiGol; bool showGalibiyet; bool showBeraberlik; bool showMaglubiyet; bool showMacBasiOrtGol;
    bool showMaclardaOrtTplGol; bool showGol2UstuOlasilik; bool showSon5MacDetaylari; bool showOverallLast5Stats; bool showGolFarki;
    bool showKgVarYok; bool showComparisonKgVar; bool showCleanSheet; bool showAvgShots; bool showAvgShotsOnTarget; bool showAvgFouls;
    bool showAvgCorners; bool showAvgYellowCards; bool showAvgRedCards; bool showIySonuclar; bool showIyGolOrt;
    bool showFormPuani; bool showIyAttigiGolOrt; bool showIyYedigiGolOrt; bool showIyGalibiyetYuzdesi;

    StatsDisplaySettings({
        this.showAttigiGol = true, this.showYedigiGol = true, this.showGalibiyet = true, this.showBeraberlik = true, this.showMaglubiyet = true,
        this.showMacBasiOrtGol = true, this.showMaclardaOrtTplGol = true, this.showGol2UstuOlasilik = true, this.showSon5MacDetaylari = true,
        this.showOverallLast5Stats = true, this.showGolFarki = true, this.showKgVarYok = true, this.showComparisonKgVar = true,
        this.showCleanSheet = true, this.showAvgShots = true, this.showAvgShotsOnTarget = true, this.showAvgFouls = true,
        this.showAvgCorners = true, this.showAvgYellowCards = true, this.showAvgRedCards = true, this.showIySonuclar = true, this.showIyGolOrt = true,
        this.showFormPuani = true, this.showIyAttigiGolOrt = true, this.showIyYedigiGolOrt = true, this.showIyGalibiyetYuzdesi = true,
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
            showFormPuani: prefs.getBool(kShowFormPuaniKey) ?? true, showIyAttigiGolOrt: prefs.getBool(kShowIyAttigiGolOrtKey) ?? true,
            showIyYedigiGolOrt: prefs.getBool(kShowIyYedigiGolOrtKey) ?? true, showIyGalibiyetYuzdesi: prefs.getBool(kShowIyGalibiyetYuzdesiKey) ?? true,
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
            case kShowFormPuaniKey: showFormPuani = value; break; case kShowIyAttigiGolOrtKey: showIyAttigiGolOrt = value; break;
            case kShowIyYedigiGolOrtKey: showIyYedigiGolOrt = value; break; case kShowIyGalibiyetYuzdesiKey: showIyGalibiyetYuzdesi = value; break;
        }
    }
}

enum BrightnessPreference { light, dark, system }
BrightnessPreference _getBrightnessPreferenceFromString(String? prefString) { if (prefString == 'light') return BrightnessPreference.light; if (prefString == 'dark') return BrightnessPreference.dark; return BrightnessPreference.system; }
String _getStringFromBrightnessPreference(BrightnessPreference preference) { switch (preference) { case BrightnessPreference.light: return 'light'; case BrightnessPreference.dark: return 'dark'; case BrightnessPreference.system: return 'system'; } }

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Edge-to-edge display için
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    try {
      // Firebase'i başlat
      await Firebase.initializeApp();
      print('Firebase initialized successfully'); // Debug
    } catch (e) {
      print('Firebase initialization error: $e'); // Debug
    }
    
    await initializeDateFormatting('tr_TR', null);
    final prefs = await SharedPreferences.getInstance();
    final String? savedBrightnessPrefString = prefs.getString(kBrightnessPreference);
    final BrightnessPreference initialBrightnessPreference = _getBrightnessPreferenceFromString(savedBrightnessPrefString);
    final String? savedPaletteString = prefs.getString(kThemePalettePreferenceKey);
    final AppThemePalette initialPalette = stringToAppThemePalette(savedPaletteString);
    final StatsDisplaySettings initialStatsSettings = await StatsDisplaySettings.load();
    final String? savedSeasonApiValue = prefs.getString(kSeasonPreferenceKey);
    final String initialSeasonApiValue = savedSeasonApiValue ?? "2526"; // 2025-2026 sezonunu varsayılan yap
    
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
    bool _showOnboarding = false;
    bool _showAuth = false;
    bool _showProfileCompletion = false;
    bool _isLoading = true;
    Timer? _seasonCheckTimer;
    
    @override void initState() { 
        super.initState(); 
        _currentBrightnessPreference = widget.initialBrightnessPreference; 
        _currentPalette = widget.initialPalette; 
        _currentStatsSettings = widget.initialStatsSettings; 
        _currentSeasonApiValue = widget.initialSeasonApiValue; 
        _initPackageInfo();
        _checkOnboardingStatus();
        _startSeasonCheckTimer();
    }
    @override
    void dispose() {
        _seasonCheckTimer?.cancel();
        super.dispose();
    }

    Future<void> _initPackageInfo() async { final PackageInfo info = await PackageInfo.fromPlatform(); if (mounted) setState(() => _packageInfo = info); }
    
    void _startSeasonCheckTimer() {
        _seasonCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
            try {
                final prefs = await SharedPreferences.getInstance();
                final savedSeasonApiValue = prefs.getString(kSeasonPreferenceKey);
                final newSeasonApiValue = savedSeasonApiValue ?? "2526";
                
                if (newSeasonApiValue != _currentSeasonApiValue && mounted) {
                    setState(() {
                        _currentSeasonApiValue = newSeasonApiValue;
                    });
                }
            } catch (e) {
                print('Sezon kontrol hatası: $e');
            }
        });
    }
    
    Future<void> _checkOnboardingStatus() async {
        final isOnboardingCompleted = await OnboardingService.isOnboardingCompleted();
        final isUserSignedIn = AuthService.isSignedIn;
        
        if (!isOnboardingCompleted) {
            // Onboarding henüz tamamlanmamış
            setState(() {
                _showOnboarding = true;
                _isLoading = false;
            });
        } else if (!isUserSignedIn) {
            // Onboarding tamamlanmış ama kullanıcı giriş yapmamış
            setState(() {
                _showAuth = true;
                _isLoading = false;
            });
        } else {
            // Kullanıcı giriş yapmış, profil durumunu kontrol et
            final userProfileService = UserProfileService();
            final hasProfile = await userProfileService.hasUserProfile();
            final profile = await userProfileService.loadUserProfile();
            
            // Profil yoksa oluştur ama profil tamamlama sayfasını gösterme
            if (!hasProfile) {
                await userProfileService.createProfileFromCurrentUser();
            }
            
            setState(() {
                _showProfileCompletion = false; // Artık otomatik profil tamamlama yok
                _isLoading = false;
            });
        }
    }
    
    void _onOnboardingCompleted() {
        if (mounted) {
            setState(() {
                _showOnboarding = false;
                _showAuth = true;
            });
        }
    }
    
    void _onAuthCompleted() {
        if (mounted) {
            setState(() {
                _showAuth = false;
                _showProfileCompletion = false; // Direkt ana sayfaya git
            });
        }
    }
    
    void _onAuthSkipped() {
        if (mounted) {
            setState(() {
                _showAuth = false;
                _showProfileCompletion = false;
            });
        }
    }
    
    void _onProfileCompletionCompleted() {
        if (mounted) {
            setState(() {
                _showProfileCompletion = false;
            });
        }
    }
    void _changeBrightnessPreference(BrightnessPreference preference) async { 
      final prefs = await SharedPreferences.getInstance(); 
      await prefs.setString(kBrightnessPreference, _getStringFromBrightnessPreference(preference)); 
      if (mounted) {
        setState(() => _currentBrightnessPreference = preference);
        // Sistem UI artık builder'da otomatik güncelleniyor
      }
    }
    

    void _changePalette(AppThemePalette palette) async { 
      final prefs = await SharedPreferences.getInstance(); 
      await prefs.setString(kThemePalettePreferenceKey, appThemePaletteToString(palette)); 
      if (mounted) {
        setState(() => _currentPalette = palette);
        // Sistem UI artık builder'da otomatik güncelleniyor
      }
    }
    void _changeStatsSetting(String key, bool value) async { await _currentStatsSettings.saveSetting(key, value); if (mounted) setState(() {}); }
    void _changeSeason(String seasonApiValue) async { final prefs = await SharedPreferences.getInstance(); await prefs.setString(kSeasonPreferenceKey, seasonApiValue); if (mounted) setState(() => _currentSeasonApiValue = seasonApiValue); }
    
    void _updateSystemUIForTheme(ThemeMode themeMode, ThemeData lightTheme, ThemeData darkTheme, BuildContext context) {
      // Mevcut tema moduna göre hangi tema kullanılacağını belirle
      final brightness = MediaQuery.platformBrightnessOf(context);
      final isLight = themeMode == ThemeMode.light || 
                     (themeMode == ThemeMode.system && brightness == Brightness.light);
      
      final currentTheme = isLight ? lightTheme : darkTheme;
      final scaffoldColor = currentTheme.scaffoldBackgroundColor;
      
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
        statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: scaffoldColor,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      ));
    }
    
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
            builder: (context, child) {
              // Tema değişikliklerinde sistem UI ayarlarını güncelle
              _updateSystemUIForTheme(currentThemeMode, currentLightTheme, currentDarkTheme, context);
              return child!;
            },
            home: _isLoading 
                ? const Scaffold(
                    body: Center(
                        child: CircularProgressIndicator(),
                    ),
                )
                : _showOnboarding 
                    ? OnboardingScreen(onCompleted: _onOnboardingCompleted)
                    : _showAuth
                        ? AuthScreen(
                            onAuthSuccess: _onAuthCompleted,
                            onSkip: _onAuthSkipped,
                          )
                        : _showProfileCompletion
                            ? ProfileCompletionScreen(
                                onCompleted: _onProfileCompletionCompleted,
                              )
                            : HomeScreen(
                                onBrightnessPreferenceChanged: _changeBrightnessPreference, 
                                onPaletteChanged: _changePalette, 
                                currentBrightnessPreference: _currentBrightnessPreference, 
                                currentPalette: _currentPalette, 
                                currentStatsSettings: _currentStatsSettings, 
                                onStatsSettingChanged: _changeStatsSetting, 
                                currentSeasonApiValue: _currentSeasonApiValue, 
                                onSeasonChanged: _changeSeason, 
                                packageInfo: _packageInfo
                            ),
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
  Timer? _homeSeasonCheckTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _scrollControllers = List.generate(4, (_) => ScrollController());
    _updateWidgetOptions();
    _addSampleActivities();
    _startHomeSeasonCheckTimer();
  }

  void _changeBrightnessFromString(String brightnessString) {
    BrightnessPreference preference;
    switch (brightnessString) {
      case 'light':
        preference = BrightnessPreference.light;
        break;
      case 'dark':
        preference = BrightnessPreference.dark;
        break;
      case 'system':
      default:
        preference = BrightnessPreference.system;
        break;
    }
    widget.onBrightnessPreferenceChanged(preference);
  }

  String _getCurrentBrightnessString() {
    return _getStringFromBrightnessPreference(widget.currentBrightnessPreference);
  }

  // Örnek aktiviteler ekle (sadece ilk çalıştırmada)
  Future<void> _addSampleActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAddedSamples = prefs.getBool('has_added_sample_activities') ?? false;
      
      if (!hasAddedSamples) {
        // Doğrudan import kullan
        await Future.delayed(const Duration(seconds: 1)); // UI yüklendikten sonra
        
        // Örnek aktiviteler ekle
        await _addSampleActivity('Manchester United (İngiltere - Premier Lig) takımı analiz edildi');
        await _addSampleActivity('Arsenal vs Chelsea (İngiltere - Premier Lig) karşılaştırıldı');
        await _addSampleActivity('Liverpool (İngiltere - Premier Lig) favorilere eklendi');
        await _addSampleActivity('Barcelona (İspanya - La Liga) takımı analiz edildi');
        await _addSampleActivity('İngiltere - Premier Lig favori lig olarak seçildi');
        
        // Flag'i ayarla ki bir daha eklemesin
        await prefs.setBool('has_added_sample_activities', true);
      }
    } catch (e) {
      print('Örnek aktiviteler eklenirken hata: $e');
    }
  }

  Future<void> _addSampleActivity(String activity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activities = prefs.getStringList('last_activity') ?? [];
      
      activities.insert(0, '${DateTime.now().toIso8601String()}|$activity');
      
      // Son 10 aktiviteyi sakla
      if (activities.length > 10) {
        activities.removeRange(10, activities.length);
      }
      
      await prefs.setStringList('last_activity', activities);
      
      // İstatistikleri güncelle
      if (activity.contains('analiz edildi')) {
        final current = prefs.getInt('total_analysis') ?? 0;
        await prefs.setInt('total_analysis', current + 1);
      } else if (activity.contains('karşılaştırıldı')) {
        final current = prefs.getInt('total_comparisons') ?? 0;
        await prefs.setInt('total_comparisons', current + 1);
      }
      
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('Aktivite eklenirken hata: $e');
    }
  }

  @override
  void dispose() {
    _homeSeasonCheckTimer?.cancel();
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

  void _startHomeSeasonCheckTimer() {
    _homeSeasonCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedSeasonApiValue = prefs.getString(kSeasonPreferenceKey);
        final newSeasonApiValue = savedSeasonApiValue ?? "2526";
        
        if (newSeasonApiValue != widget.currentSeasonApiValue && mounted) {
          // Ana widget'a sezon değişikliğini bildir
          widget.onSeasonChanged(newSeasonApiValue);
        }
      } catch (e) {
        print('HomeScreen sezon kontrol hatası: $e');
      }
    });
  }

  void _updateWidgetOptions() {
    _widgetOptions = <Widget>[
      HomeFeedScreen(
        key: ValueKey('homeFeedScreen_${widget.currentSeasonApiValue}'),
        currentSeasonApiValue: widget.currentSeasonApiValue,
        scrollController: _scrollControllers[0],
        scaffoldKey: _scaffoldKey,
        onSearchTap: _openSearchScreen,
        onThemeSettingsTap: () => _showThemePaletteSelectionDialog(context),
        onStatsSettingsTap: () => _showModernStatsDialog(context),
        onAboutTap: () => _showAboutDialog(context),
        onBrightnessChanged: _changeBrightnessFromString,
        currentBrightness: _getCurrentBrightnessString(),
      ),
      MatchesScreen(
        key: ValueKey('matchesScreen_${widget.currentSeasonApiValue}'),
        scrollController: _scrollControllers[1],
        scaffoldKey: _scaffoldKey,
        onSearchTap: _openSearchScreen,
        onThemeSettingsTap: () => _showThemePaletteSelectionDialog(context),
        onStatsSettingsTap: () => _showModernStatsDialog(context),
        onAboutTap: () => _showAboutDialog(context),
        onBrightnessChanged: _changeBrightnessFromString,
        currentBrightness: _getCurrentBrightnessString(),
      ),
      AnalysisScreen(
        key: ValueKey('analysisScreen_${widget.currentSeasonApiValue}'),
        statsSettings: widget.currentStatsSettings,
        currentSeasonApiValue: widget.currentSeasonApiValue,
        scrollController: _scrollControllers[2],
        scaffoldKey: _scaffoldKey, 
        onSearchTap: _openSearchScreen,
        onThemeSettingsTap: () => _showThemePaletteSelectionDialog(context),
        onStatsSettingsTap: () => _showModernStatsDialog(context),
        onAboutTap: () => _showAboutDialog(context),
        onBrightnessChanged: _changeBrightnessFromString,
        currentBrightness: _getCurrentBrightnessString(),
      ),
      ProfileScreen(
        key: ValueKey('profileScreen_${widget.currentSeasonApiValue}'),
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
        case AppThemePalette.modernPremium: return "Modern Premium ⭐";
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

  void _showModernStatsDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'İstatistikler ve Sezon Ayarları',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'Analiz ekranlarında gösterilecek istatistikleri ve aktif sezonu yönetin',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sezon Seçimi Bölümü
                          _buildSeasonSelectionSection(context, isDark, setModalState),
                          
                          const SizedBox(height: 20),
                          
                          _buildModernStatsSection(
                            context,
                            'Ana İstatistikler',
                            Icons.sports_soccer,
                            const Color(0xFF2196F3),
                            [
                              _buildModernStatItem('Tüm Son Maç İstatistikleri', 'Bu başlık ve altındaki tüm istatistikler', widget.currentStatsSettings.showOverallLast5Stats, (value) {
                                widget.onStatsSettingChanged(kShowOverallLast5StatsKey, value);
                                setModalState(() {});
                              }),
                            ],
                          ),
                          
                          if (widget.currentStatsSettings.showOverallLast5Stats) ...[
                            _buildModernStatsSection(
                              context,
                              'Temel Maç İstatistikleri',
                              Icons.bar_chart,
                              const Color(0xFF4CAF50),
                              [
                                _buildModernStatItem('Attığı Gol', '', widget.currentStatsSettings.showAttigiGol, (value) {
                                  widget.onStatsSettingChanged(kShowAttigiGolKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('Yediği Gol', '', widget.currentStatsSettings.showYedigiGol, (value) {
                                  widget.onStatsSettingChanged(kShowYedigiGolKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('Gol Farkı (+/-)', '', widget.currentStatsSettings.showGolFarki, (value) {
                                  widget.onStatsSettingChanged(kShowGolFarkiKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('Galibiyet', '', widget.currentStatsSettings.showGalibiyet, (value) {
                                  widget.onStatsSettingChanged(kShowGalibiyetKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('Beraberlik', '', widget.currentStatsSettings.showBeraberlik, (value) {
                                  widget.onStatsSettingChanged(kShowBeraberlikKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('Mağlubiyet', '', widget.currentStatsSettings.showMaglubiyet, (value) {
                                  widget.onStatsSettingChanged(kShowMaglubiyetKey, value);
                                  setModalState(() {});
                                }),
                              ],
                            ),
                            
                            _buildModernStatsSection(
                              context,
                              'Detaylı İstatistikler',
                              Icons.analytics,
                              const Color(0xFF9C27B0),
                              [
                                _buildModernStatItem('Maç Başına Ort. Gol', '', widget.currentStatsSettings.showMacBasiOrtGol, (value) {
                                  widget.onStatsSettingChanged(kShowMacBasiOrtGolKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('Maçlarda Ort. Toplam Gol', '', widget.currentStatsSettings.showMaclardaOrtTplGol, (value) {
                                  widget.onStatsSettingChanged(kShowMaclardaOrtTplGolKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('KG Var/Yok Yüzdesi', '', widget.currentStatsSettings.showKgVarYok, (value) {
                                  widget.onStatsSettingChanged(kShowKgVarYokKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('Clean Sheet (Gol Yememe)', '', widget.currentStatsSettings.showCleanSheet, (value) {
                                  widget.onStatsSettingChanged(kShowCleanSheetKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('2+ Gol Olasılığı', '', widget.currentStatsSettings.showGol2UstuOlasilik, (value) {
                                  widget.onStatsSettingChanged(kShowGol2UstuOlasilikKey, value);
                                  setModalState(() {});
                                }),
                              ],
                            ),
                            
                            // Yeni Detaylı Maç Ortalamaları Bölümü
                            _buildModernStatsSection(
                              context,
                              'Detaylı Maç Ortalamaları',
                              Icons.bar_chart,
                              const Color(0xFFFF5722),
                              [
                                _buildModernStatItem('Ortalama Şut', '', widget.currentStatsSettings.showAvgShots, (value) {
                                  widget.onStatsSettingChanged(kShowAvgShotsKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('Ortalama İsabetli Şut', '', widget.currentStatsSettings.showAvgShotsOnTarget, (value) {
                                  widget.onStatsSettingChanged(kShowAvgShotsOnTargetKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('Ortalama Faul', '', widget.currentStatsSettings.showAvgFouls, (value) {
                                  widget.onStatsSettingChanged(kShowAvgFoulsKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('Ortalama Korner', '', widget.currentStatsSettings.showAvgCorners, (value) {
                                  widget.onStatsSettingChanged(kShowAvgCornersKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('Ortalama Sarı Kart', '', widget.currentStatsSettings.showAvgYellowCards, (value) {
                                  widget.onStatsSettingChanged(kShowAvgYellowCardsKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('Ortalama Kırmızı Kart', '', widget.currentStatsSettings.showAvgRedCards, (value) {
                                  widget.onStatsSettingChanged(kShowAvgRedCardsKey, value);
                                  setModalState(() {});
                                }),
                              ],
                            ),
                            
                            // Form ve İlk Yarı İstatistikleri Bölümü
                            _buildModernStatsSection(
                              context,
                              'Form ve İlk Yarı İstatistikleri',
                              Icons.trending_up,
                              const Color(0xFF607D8B),
                              [
                                _buildModernStatItem('Form Puanı', '', widget.currentStatsSettings.showFormPuani, (value) {
                                  widget.onStatsSettingChanged(kShowFormPuaniKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('İY Attığı Gol Ortalaması', '', widget.currentStatsSettings.showIyAttigiGolOrt, (value) {
                                  widget.onStatsSettingChanged(kShowIyAttigiGolOrtKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('İY Yediği Gol Ortalaması', '', widget.currentStatsSettings.showIyYedigiGolOrt, (value) {
                                  widget.onStatsSettingChanged(kShowIyYedigiGolOrtKey, value);
                                  setModalState(() {});
                                }),
                                _buildModernStatItem('İY Galibiyet Yüzdesi', '', widget.currentStatsSettings.showIyGalibiyetYuzdesi, (value) {
                                  widget.onStatsSettingChanged(kShowIyGalibiyetYuzdesiKey, value);
                                  setModalState(() {});
                                }),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSeasonSelectionSection(BuildContext context, bool isDark, StateSetter setModalState) {
    final currentSeasonDisplay = DataService.getDisplaySeasonFromApiValue(widget.currentSeasonApiValue);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF9800).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFFFF9800),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Geçerli Sezon',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: InkWell(
              onTap: () => _showSeasonSelectionDialog(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3A3A3A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seçili Sezon',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentSeasonDisplay,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF9800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatsSection(BuildContext context, String title, IconData icon, Color color, List<Widget> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildModernStatItem(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: value 
                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                  : (isDark ? const Color(0xFF333333) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value 
                    ? const Color(0xFF4CAF50).withOpacity(0.3)
                    : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Custom switch indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 28,
                  decoration: BoxDecoration(
                    color: value 
                        ? const Color(0xFF4CAF50)
                        : (isDark ? Colors.grey[600] : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: value 
                              ? const Color(0xFF4CAF50)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Status indicator
                if (value)
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFF4CAF50),
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStatsDisplaySettingsDialog(BuildContext context) {
    _showModernStatsDialog(context);
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

  void _openProfileScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const ProfileScreen(),
    ));
  }

  Widget _buildDrawer(BuildContext context, ThemeData theme) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Drawer Header
          Container(
            height: 120,
            padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 8.0),
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'GOALITYCS',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const Divider(),
          
          // Theme Mode
          ListTile(
            leading: Icon(
              widget.currentBrightnessPreference == BrightnessPreference.light
                  ? Icons.light_mode_outlined
                  : widget.currentBrightnessPreference == BrightnessPreference.dark
                      ? Icons.dark_mode_outlined
                      : Icons.brightness_auto_outlined,
            ),
            title: Text(
              widget.currentBrightnessPreference == BrightnessPreference.light
                  ? 'Mod: Aydınlık'
                  : widget.currentBrightnessPreference == BrightnessPreference.dark
                      ? 'Mod: Koyu'
                      : 'Mod: Sistem Varsayılanı',
            ),
            onTap: () {
              BrightnessPreference nextPreference;
              if (widget.currentBrightnessPreference == BrightnessPreference.light) {
                nextPreference = BrightnessPreference.dark;
              } else if (widget.currentBrightnessPreference == BrightnessPreference.dark) {
                nextPreference = BrightnessPreference.system;
              } else {
                nextPreference = BrightnessPreference.light;
              }
              widget.onBrightnessPreferenceChanged(nextPreference);
            },
          ),
          
          // Themes
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Temalar'),
            subtitle: Text('Mevcut: ${_getPaletteDisplayName(widget.currentPalette)}'),
            onTap: () {
              Navigator.pop(context);
              _showThemePaletteSelectionDialog(context);
            },
          ),
          
          // Season
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Sezon'),
            subtitle: Text('Geçerli: ${_getDisplaySeason(widget.currentSeasonApiValue)}'),
            onTap: () {
              Navigator.pop(context);
              _showSeasonSelectionDialog(context);
            },
          ),
          
          const Divider(),
          
          // Stats Display Settings
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: const Text('Görüntülenecek İstatistikler'),
            onTap: () {
              Navigator.pop(context);
              _showStatsDisplaySettingsDialog(context);
            },
          ),
          
          // About
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Hakkında'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: false,
      drawer: _buildDrawer(context, theme),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), 
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: (isDarkMode 
              ? theme.colorScheme.surface 
              : Colors.white).withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: isDarkMode 
              ? Colors.grey[400] 
              : Colors.grey[600],
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.space_dashboard_outlined),
            activeIcon: Icon(Icons.space_dashboard),
            label: 'Akış',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer_outlined),
            activeIcon: Icon(Icons.sports_soccer),
            label: 'Maçlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Analiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        ),
      ),
    );
  }
}
