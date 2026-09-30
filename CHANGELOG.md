# Changelog

## 0.3.0 — 2026-09-30

### Traverce

- Проект переехал в `levvs-one/traverce` и получил единый публичный бренд **Traverce**.
- Приложение, Windows metadata, installer, release artifacts, docs и support flow приведены к одному имени.
- Release artifacts теперь называются `Traverce-<version>-Setup.exe` и `Traverce-<version>-windows-x64.zip`.
- Dart package переименован в `traverce`; внутренние imports и tests синхронизированы.
- zapret2 остаётся DPI engine, а не названием пользовательского продукта.

### Upgrade from 0.2

- Сохранён installer AppId, поэтому 0.3 обновляет существующую установку.
- `%LOCALAPPDATA%\\Prosvet` переносится в `%LOCALAPPDATA%\\Traverce` при первом запуске; при невозможности переноса используется безопасный fallback без потери настроек.
- Legacy Task Scheduler entry `Prosvet` и NRPT rules с comment `Prosvet` распознаются и удаляются.
- Старый `prosvet.exe` удаляется installer'ом при обновлении.
- Lua strategy memory читает старые `prosvet-*.memo` и дальше пишет новые `traverce-*.memo`.

## 0.2.0 — 2026-09-30

- Пересобран главный экран и Material 3 design system.
- Добавлены строгий CI, release pipeline, deterministic UI snapshots, Windows installer smoke-test, Dependabot, CODEOWNERS и полноценная документация.
- zapret2, Smart DNS и Telegram proxy сведены в один управляемый Windows lifecycle.

## 0.1.0

Первая версия проекта под именем Prosvet.
