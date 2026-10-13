# TaskFlow — Görev Yönetimi

Flutter ve Dart ile geliştirilen Android uygulaması; görevleri öncelik, kategori ve son tarihe göre düzenlemeyi sağlar. Görevler SQLite ile cihazda, tema tercihi SharedPreferences ile saklanır.

[![Flutter checks](https://github.com/alidanis61615/TaskFlow/actions/workflows/flutter-checks.yml/badge.svg?branch=main)](https://github.com/alidanis61615/TaskFlow/actions/workflows/flutter-checks.yml)
[![Android build](https://github.com/alidanis61615/TaskFlow/actions/workflows/build-apk.yml/badge.svg?branch=main)](https://github.com/alidanis61615/TaskFlow/actions/workflows/build-apk.yml)

**[Ekranlar](#ekran-görüntüleri) · [Özellikler](#özellikler) · [Kurulum](#yerelde-çalıştırma) · [APK derlemeleri](https://github.com/alidanis61615/TaskFlow/actions/workflows/build-apk.yml)**

## Ekran görüntüleri

Gerçek Android cihazda çalışan uygulamadan alınan görüntüler.

| Açık tema | Koyu tema | Tamamlanan görev |
| --- | --- | --- |
| <a href="light-theme.jpg"><img src="light-theme.jpg" alt="TaskFlow açık tema" width="230"></a> | <a href="dark-theme.jpg"><img src="dark-theme.jpg" alt="TaskFlow koyu tema" width="230"></a> | <a href="completed-task.jpg"><img src="completed-task.jpg" alt="TaskFlow tamamlanan görev" width="230"></a> |

## Özellikler

- Başlık, açıklama ve düşük/normal/yüksek öncelik ile görev ekleme ve düzenleme.
- Genel, iş, okul, kişisel ve alışveriş kategorileri; kategoriye göre filtreleme.
- Son tarih seçme/kaldırma ve geciken görevleri vurgulama.
- Görev tamamlama, tamamlanma oranı ve silmeden önce onay.
- Başlık/açıklama içinde arama; tümü, aktif, biten ve önemli görev filtreleri.
- Varsayılan, en yeni ve son tarih sıralamaları.
- Açık/koyu tema; yeniden açılışta tema ve görev kayıtlarının korunması.

## Bir dakikalık demo

1. Bir görev ekleyin; öncelik, kategori ve son tarih belirleyin.
2. Arama ve kategori/durum filtreleriyle görevi bulun.
3. Görevi tamamlayın; istatistik ve ilerleme çubuğunu inceleyin.
4. Temayı değiştirin ve uygulamayı yeniden açarak kayıtları kontrol edin.

## Teknik yapı

| Katman | Uygulama |
| --- | --- |
| Arayüz | Flutter Material 3; `TaskFlowApp`, `TaskHome` |
| Durum yönetimi | `setState()` ve veri değişikliklerinden sonra `refresh()` |
| Model | `Task`; `toMap()`, `fromMap()`, `copyWith()` |
| Veritabanı | `TaskDatabase` singleton; `sqflite`, parametreli güncelleme/silme |
| Tercihler | SharedPreferences ile açık/koyu tema |
| Kontroller | Görev modeli testi; GitHub Actions ile analiz, test ve APK derlemesi |

### SQLite şeması

`taskflow.db` dosyasındaki `tasks` tablosu, veritabanı sürümü **3**:

| Alan | Tür | Kullanım |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | Görev kimliği |
| `title` | TEXT NOT NULL | Başlık |
| `description` | TEXT NOT NULL | Açıklama |
| `priority` | INTEGER NOT NULL | 0 düşük, 1 normal, 2 yüksek |
| `completed` | INTEGER NOT NULL | 0 aktif, 1 tamamlandı |
| `created_at` | TEXT NOT NULL | Oluşturulma zamanı |
| `due_date` | TEXT | İsteğe bağlı son tarih |
| `category` | TEXT NOT NULL | Varsayılan: Genel |

Sürüm geçişleri eski kayıtlara `due_date` ve `category` alanlarını ekler. Varsayılan sorgu sırası `completed ASC, priority DESC, created_at DESC` biçimindedir. Arama, filtreler ve alternatif sıralamalar arayüzde uygulanır.

## Yerelde çalıştırma

Flutter SDK, Android araçları ve bir cihaz/emülatör gerekir. Android proje dosyaları ilk kurulumda üretilir.

```bash
git clone https://github.com/alidanis61615/TaskFlow.git
cd TaskFlow
flutter create --platforms=android --project-name taskflow .
rm -f test/widget_test.dart
flutter pub get
flutter run
```

Oluşturulan örnek `widget_test.dart`, uygulamanın `TaskFlowApp` sınıfını kullanmadığı için kaldırılır; `task_model_test.dart` korunur. Windows PowerShell'de `Remove-Item test/widget_test.dart -ErrorAction SilentlyContinue` kullanılabilir.

## Analiz ve test

```bash
flutter analyze
flutter test
```

Model testi ve otomatik analiz, cihaz üzerindeki tüm etkileşimleri kapsamaz. Gerçek cihazda görev ekleme/düzenleme/silme, tamamlama, arama, tema değiştirme ve yeniden açılışta veri korunması kullanıcı tarafından denenmiştir.

## APK indirme

**[Actions → Build Android APK](https://github.com/alidanis61615/TaskFlow/actions/workflows/build-apk.yml)** altında başarılı bir çalışmayı açın. **Artifacts** bölümünden `TaskFlow-Android-APK` paketini indirin. İş akışı `app-release.apk` üretir ve artefaktı 14 gün saklar. Mağaza yayını için imzalama ve dağıtım ayrıca yapılandırılmalıdır.

## Proje hakkında

Portföy için yeniden oluşturulmuş bir görev yönetimi projesidir. Bu depo güncel bağımsız sürümü içerir; `index/projects/taskflow` klasöründeki öğrenme sürümü ayrı bir çalışmadır.

**Geliştirici:** [Ali Danış](https://github.com/alidanis61615) · Mobil Teknolojileri mezunu, Yazılım Geliştirici
