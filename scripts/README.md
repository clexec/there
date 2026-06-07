# THERE Music — Seeder

## Запуск

```bash
# Установить зависимости (только стандартная библиотека Python 3)
cd scripts

# Запустить — все 25 артистов, 50 треков каждый
python3 seed_music.py

# Только метаданные без загрузки превью
python3 seed_music.py --no-download

# Конкретные артисты
python3 seed_music.py --artists "Morgenshtern" "FACE" "Lil Peep"

# Больше треков
python3 seed_music.py --limit 100
```

## Что создаётся

```
scripts/data/
├── theremusic.db          # SQLite база
├── json/
│   ├── artists.json       # Все артисты
│   ├── albums.json        # Все альбомы
│   ├── tracks.json        # Все треки
│   └── seed.json          # Всё вместе (для iOS)
└── previews/
    └── *.m4a              # 30-секундные превью (бесплатно из iTunes)
```

## Добавить seed.json в iOS

1. `scripts/data/json/seed.json` → перетащить в Xcode в `Resources/`
2. В `THEREMusicApp.swift`:

```swift
.onFirstAppear {
    Task {
        await DatabaseSeeder.shared.seedIfNeeded(
            context: PersistenceController.shared.container.viewContext
        )
    }
}
```

## Источник данных

**iTunes Search API** — официальный бесплатный API Apple.
- Метаданные треков, альбомов, артистов: ✅ бесплатно
- Обложки в высоком качестве (600x600): ✅ бесплатно  
- 30-секундные превью (.m4a): ✅ бесплатно и официально

Ограничения: ~20 запросов/минуту, максимум 200 треков за запрос.
