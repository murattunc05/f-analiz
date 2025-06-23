// widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_analiz_app/main.dart'; // main.dart dosyanızın doğru yolu
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences importu

void main() {
  // SharedPreferences için sahte (mock) başlangıç değerleri ayarla.
  // Bu, testler çalışırken "MissingPluginException" hatasını önler.
  // Testlerinizin SharedPreferences'tan belirli değerler okumasını bekliyorsanız,
  // buraya o değerleri ekleyebilirsiniz. Örneğin:
  // SharedPreferences.setMockInitialValues({'theme_preference': 'light'});
  // Şimdilik boş bir map yeterli olacaktır, çünkü main() içinde null kontrolü var.
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App loads and displays initial screen with default theme', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // MyApp'e gerekli initialThemeMode parametresini sağlıyoruz.
    // main.dart'taki SharedPreferences yüklemesi mock değerleri kullanacak.
    // Test ortamında main() doğrudan çalıştırılmadığı için,
    // MyApp'e doğrudan bir initialThemeMode vermek daha güvenilir olabilir
    // ya da main() içindeki SharedPreferences yükleme mantığının testte de çalışmasını sağlamak gerekir.
    // Şimdilik, main() fonksiyonunun testlerde SharedPreferences'ı doğru mock'ladığını varsayarak
    // ve MyApp'ın initialThemeMode'unu main() fonksiyonundan aldığını düşünerek
    // runApp(MyApp(...)) kısmını simüle etmeyeceğiz, direkt MyApp'i test edeceğiz.
    // Bu yüzden MyApp'e direkt bir değer vermek en temizi.
    await tester.pumpWidget(const MyApp(initialThemeMode: ThemeMode.dark));

    // Uygulamanızın ana ekranında görünmesini beklediğiniz bir widget'ı bulun.
    // HomeScreen widget'ının varlığını kontrol edelim.
    expect(find.byType(HomeScreen), findsOneWidget);

    // AppBar'daki Ayarlar ikonunu (leading) bulalım.
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    // BottomNavigationBar'daki "Karşılaştır" etiketini bulmayı deneyebilirsiniz.
    // Bu, HomeScreen'in içindeki BottomNavigationBar'ın render edildiğini doğrular.
    expect(find.text('Karşılaştır'), findsOneWidget);
  });

  testWidgets('Theme changes when theme toggle is tapped in drawer', (WidgetTester tester) async {
    // Uygulamamızı başlatıyoruz, başlangıç teması koyu olsun.
    await tester.pumpWidget(const MyApp(initialThemeMode: ThemeMode.dark));

    // Drawer'ı açmak için Ayarlar ikonuna tıkla.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle(); // Animasyonların bitmesini bekle (Drawer açılması)

    // Drawer içinde "Aydınlık Moda Geç" yazısını bul ve tıkla.
    expect(find.text('Aydınlık Moda Geç'), findsOneWidget);
    await tester.tap(find.text('Aydınlık Moda Geç'));
    await tester.pumpAndSettle(); // Tema değişikliği ve Drawer kapanması için bekle

    // Tema modunun değişip değişmediğini kontrol et.
    // MaterialApp widget'ını bulup themeMode özelliğini kontrol edebiliriz.
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.light);

    // Drawer'ı tekrar aç.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // Şimdi "Koyu Moda Geç" yazısını görmeliyiz.
    expect(find.text('Koyu Moda Geç'), findsOneWidget);
    await tester.tap(find.text('Koyu Moda Geç'));
    await tester.pumpAndSettle();

    // Tekrar tema modunu kontrol et.
    final materialAppAgain = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialAppAgain.themeMode, ThemeMode.dark);
  });
}
