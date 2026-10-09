# Перенос игры в Roblox Studio — пошагово

Всё делается в Roblox Studio на компьютере. Звуки и музыка ничего не требуют: это бесплатные звуки
из каталога Roblox, они подключены по id и заиграют сами.

## 0. Скачать проект

GitHub → **Code → Download ZIP**, распаковать. Понадобятся:

- `PotatoTycoon.rbxlx` — сама игра (код, мир, интерфейс);
- папка `art/export/fbx/` — 95 моделей из Blender.

## 1. Открыть и опубликовать

1. Roblox Studio → **File → Open from File…** → `PotatoTycoon.rbxlx`.
2. **File → Publish to Roblox** → «Create new experience»: название, описание → **Create**.
   Новая игра сначала приватная — её видите только вы.

Опубликовать нужно **до** импорта моделей: тогда меши сразу закрепляются за этой игрой.

## 2. Импортировать модели

1. **File → Import** (или `Ctrl+M`) → выберите сначала **один** файл `art/export/fbx/Drone.fbx`.
2. В настройках импорта:
   - **Import Only As Model** — вкл (по умолчанию);
   - **Merge Meshes** — выкл (по умолчанию);
   - **Anchored** — вкл (по умолчанию выключено);
   - **Add to Workspace** — вкл (по умолчанию);
   - Scale Unit — Studs, World Forward — Front, World Up — Top (по умолчанию).

   Масштаб и поворот можно не подбирать: игра сама находит их по трём маркерам
   `Origin__Pivot`, `Origin__AxisX`, `Origin__AxisZ`.
3. **Import**. Проверьте в **Explorer**: модель `Drone`, внутри детали вида `DroneBody/Prop0__MetalDark`
   и три маркера `Origin__…`. Если имена такие — всё работает.
4. Остальные файлы — пачками по 10–20 штук: **File → Import**, выделить несколько `.fbx`,
   в очереди импорта правый клик → **Apply settings to all** → **Import**.
   Большие пачки на слабом компьютере иногда дают пустые детали — тогда импортируйте этот файл заново.

Опция **Upload to Roblox** (вкл по умолчанию) дополнительно кладёт каждую модель в ваш Toolbox;
выключите её, если не хотите 95 моделей в инвентаре.

## 3. Сложить модели в ServerStorage.Assets

1. **Explorer → ServerStorage → «+» (Insert Object) → Folder**, переименуйте в **`Assets`**.
2. Выделите в Workspace все импортированные модели (`BedWood`, `Drone`, `Bug`…) и перетащите их в `Assets`.
   Имя модели должно совпадать с именем файла — Studio так и называет её.
3. **Play**: постройки, грядки, дрон, жуки и шаттл теперь из Blender. Если для какой-то модели шаблона нет,
   она остаётся простой процедурной — игра работает в любом случае.
4. **File → Publish to Roblox** — сохранить.

Совет: правый клик по `Assets` → **Save to File…** (`Assets.rbxm`) — резервная копия импортированных моделей.

## 4. Настройки игры

- **Сохранения в Studio:** **File → Experience Settings → Security → Enable Studio Access to API Services**.
  Studio тогда работает с теми же сохранениями, что и живая игра, — для экспериментов лучше отдельная копия игры.
- **6 игроков на сервере** (на карте 6 баз): Creator Hub → игра → **Configure → Places →** место →
  **Access → Maximum Visitor Count = 6**.
- **Перевод:** Creator Hub → игра → **Audience → Localization**: Source Language = **English**,
  включить **Capture text from experience UI while users play** и **Use Translated Content**,
  на вкладке Languages включить нужные языки (русский и др.). Надписи на моделях и весь интерфейс переводятся
  автоматически; названия геймпассов — вручную во вкладке Products.

## 5. Геймпассы

1. Creator Hub → игра → **Monetization → Passes → Create pass**: иконка, название, описание → Create.
2. Откройте пасс → **Sales**: включить продажу, указать цену в Robux.
3. Скопируйте id: на карточке пасса **⋯ → Copy Asset ID**.
4. Впишите id в `ReplicatedStorage → Shared → Config → GamePasses` (поле `id` у
   `x2cash`, `infiniteEnergy`, `magnateDrone`, `vip`) — прямо в Studio или в
   `src/shared/Config/GamePasses.luau`. Пока `id = 0`, кнопка покупки только показывает подсказку.

## 6. Открыть игру для всех

1. Creator Hub → игра → **Configure → Questionnaire** — анкета Maturity & Compliance.
2. Проверка возраста аккаунта (по лицу или документу) — Roblox попросит её при открытии игры.
3. **Configure → Settings → Audience → Public → Save**.

## Дальше: как обновлять код

Не открывайте заново свежесобранный `PotatoTycoon.rbxlx` поверх опубликованной игры — в нём нет
импортированных моделей. Варианты:

- **Rojo** (рекомендуется): установить [Rokit](https://github.com/rojo-rbx/rokit), в папке проекта
  `rokit install` и `rojo plugin install`, перезапустить Studio, затем `rojo serve` и в Studio плагин
  **Rojo → Connect** — код из `src/` синхронизируется в открытую опубликованную игру, модели в
  `ServerStorage.Assets` не трогаются. Потом **Publish to Roblox**.
- Или правьте скрипты прямо в Studio.

Модели после изменений в Blender: заново `art/blender/build.py`, проверка `python3 tools/check_fbx.py`,
удалить старую модель из `Assets` и импортировать новый FBX (подробности — [ART_PIPELINE.md](ART_PIPELINE.md)).
