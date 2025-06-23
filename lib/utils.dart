// lib/utils.dart

/// Verilen metindeki her kelimenin ilk harfini büyük, geri kalanını küçük yapar.
/// 2-3 harfli ve tamamı büyük olan kısaltmaları (örn: PSG, FB) olduğu gibi bırakır.
String capitalizeFirstLetterOfWordsUtils(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    // Kelimenin tamamı büyük harfse ve 2-3 karakter uzunluğundaysa (kısaltma varsayımı)
    // olduğu gibi bırak.
    if (word == word.toUpperCase() && word.length > 1 && word.length <= 3) {
      return word;
    }
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

// Gelecekte buraya başka genel yardımcı fonksiyonlar eklenebilir.
// Örneğin:
//
// DateTime? parseDateString(String dateString) {
//   // Tarih ayrıştırma mantığı...
// }
//
// String formatNumber(double number, {int decimalPlaces = 2}) {
//   // Sayı formatlama mantığı...
// }