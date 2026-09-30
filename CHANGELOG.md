# Changelog

## 0.3.1 — 2026-09-30

### Fixed

- Upgrade installer now retargets an enabled 0.2 autostart task to `traverce.exe --background` before removing the obsolete executable.
- If task migration fails, installer keeps the legacy executable instead of silently leaving a broken startup entry.
- Windows CI and release smoke-tests now simulate the 0.2 → 0.3 upgrade path and verify task retargeting, executable cleanup and uninstall cleanup.

## 0.3.0 — 2026-09-30

### Traverce

- Проект переехал в `levvs-one/traverce` и получил единый публичный бренд **Traverce**.
- Приложение, Windows metadata, installer, release artifacts, docs и support flow приведены к одному имени.
- Release artifacts теперь называются `Traverce-<version>-Setup.exe` и `Traverce-<version>-windows-x64.zip`.
- Dart package переименован в `traverce`; внутренние imports и tests синхронизированы.
- zapret2 остаётся DPI engine, а не названием пользовательского продукта.

### Upgrade from 0.2

- Сохранён installer AppId, поэтому 0.3 обновляет существующую установку.
- Локальное состояние 0.2 переносится в `%LOCALAPPDATA%\\Traverce` при первом запуске; при невозможности переноса используется безопасный fallback без потери настроек.
- Legacy Task Scheduler entry и NRPT rules версии 0.2 распознаются и очищаются.
- Устаревший бинарник версии 0.2 удаляется installer'ом только после безопасной миграции autostart.
- Lua strategy memory читает legacy memo-файлы и дальше пишет данные в namespace Traverce.

## 0.2.0 — 2026-09-30

- Пересобран главный экран и Material 3 design system.
- Добавлены строгий CI, release pipeline, deterministic UI snapshots, Windows installer smoke-test, Dependabot, CODEOWNERS и полноценная документация.
- zapret2, Smart DNS и Telegram proxy сведены в один управляемый Windows lifecycle.

## 0.1.0

Первая публичная версия проекта.
