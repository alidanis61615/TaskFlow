# Changelog

## 1.1.1 — 2026-10-14

- Klavye açıkken küçük ekranda taşan görev özeti kaydırılabilir görünümle düzeltildi.
- Küçük ekran regresyon testi eklendi; 12 birim/arayüz testi başarılı.
- Android emülatöründe görevler, arama, tamamlanan filtre ve kalıcı tema denendi.
- Üretim APK'sını kurma ve yeniden açılışta kayıtları koruma doğrulandı.
- Örnek görevlerle dolu ekranlar ve kısa video eklendi.

## 1.1.0 — 2026-10-14

- Model, SQLite repository, query logic, home screen and task editor are separate files.
- Empty task titles are rejected; load and save errors are shown to the user.
- Real SQLite CRUD and version 1 → 3 migration tests were added.
- Widget tests cover creation, search, completion, confirmed deletion and empty-title validation.
- All 11 automated tests and Flutter analysis passed in GitHub Actions.
- A permanent `TaskFlow-Android.apk` download is published in the v1.1.0 release.

## Source preparation — 2026-10-12

- SQLite task management, priorities, categories and due dates.
- Persistent theme preference, search and task filtering.
- Automated analysis, tests and Android build workflow.

The v1.1.0 APK was built successfully. Physical-device testing of this version remains a separate check.
