# TaskFlow — Flutter Görev Takip Uygulaması

Flutter ve Dart ile geliştirilen, Android'de çevrimdışı çalışan görev yönetimi uygulaması. Bu depo, portföy için sıfırdan yeniden oluşturulan bir projedir; eski bir staj projesinin kaynak kodu değildir.

## Özellikler
- Başlık, açıklama ve öncelik (Düşük / Normal / Yüksek) ile görev ekleme ve düzenleme
- Görevleri tamamlama, silme ve tamamlanma oranını ilerleme çubuğunda görme
- Başlık ve açıklama içinde metin arama; Tümü / Aktif / Biten filtreleri
- Açık ve koyu tema; tema seçimini cihazda saklama
- SQLite ile çevrimdışı görev kaydı

## Teknik mimari
- **Arayüz:** Flutter Material 3; `TaskFlowApp` ve `TaskHome` adlı `StatefulWidget` bileşenleri
- **Durum yönetimi:** `setState()`; veritabanı işlemlerinden sonra `refresh()` ile görev listesi yeniden okunur
- **Veri modeli:** `Task`; `toMap()`, `fromMap()` ve `copyWith()` ile SQLite eşleme
- **Veri erişimi:** `TaskDatabase` singleton sınıfı, `sqflite` üzerinden ekleme/güncelleme/silme/listeleme
- **Tema tercihi:** `shared_preferences` ile `dark` anahtarı
- **CI:** GitHub Actions ile Flutter analiz/test kontrolü ve Android APK oluşturma

## SQLite veritabanı
Veritabanı dosyası: `taskflow.db`. Tablo: `tasks`.

| Alan | Tür | Açıklama |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | Benzersiz görev kimliği |
| `title` | TEXT NOT NULL | Görev başlığı |
| `description` | TEXT NOT NULL | Görev açıklaması |
| `priority` | INTEGER NOT NULL | 0 düşük, 1 normal, 2 yüksek |
| `completed` | INTEGER NOT NULL | 0 aktif, 1 tamamlandı |
| `created_at` | TEXT NOT NULL | ISO 8601 oluşturulma zamanı |

Görevler `completed ASC, priority DESC, created_at DESC` sırasıyla okunur. Güncelleme ve silme işlemleri `id` üzerinden parametreli sorgularla yapılır. Arama ve durum filtreleri, yüklenmiş görev listesine arayüz tarafında uygulanır.

## Doğrulanan işlevler
GitHub Actions Flutter kontrolleri başarılı oldu ve Android APK derlendi. Samsung Android telefondan paylaşılan ekran görüntülerinde uygulamanın açılması, tema değiştirme, görev ekleme, tamamlanma sayacı/çubuğu, metin araması ve Biten filtresi görüldü.

**Ek cihaz testleri (kullanıcı tarafından doğrulandı):** Uygulama tamamen kapatılıp yeniden açıldığında kayıtlı görevlerin korunması (SQLite kalıcılığı), mevcut görevi düzenleme ve görev silme işlemleri başarıyla denendi.

**Henüz ayrıca doğrulanması gerekenler:** Daha geniş cihaz uyumluluğu, uç durumlar ve uzun süreli kullanım testleri.

## APK oluşturma
GitHub'da **Actions → Build Android APK** iş akışının başarılı çalıştırmasını açın. **Artifacts** bölümündeki `TaskFlow-Android-APK` paketinden APK alınabilir. Bu, portföy/test amaçlı derlemedir; mağaza yayını değildir.

## Yerel çalıştırma
Flutter SDK ve Android araçları kurulu olmalıdır.

```bash
flutter create --platforms=android --project-name taskflow .
flutter pub get
flutter run
```

## Geliştirme durumu
Aktif geliştirme. Ekran görüntüleri ve ek cihaz testleri ilerleyen sürümlerde eklenecek.
