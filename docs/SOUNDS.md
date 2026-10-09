# Звуки

Все звуки и музыка — из официальных библиотек каталога Roblox: **Pro Sound Effects**, **APM Music** и самого
**Roblox**. Они бесплатные и разрешены в любом опыте, ничего загружать не нужно — в игре они подключены по
`rbxassetid` в [`src/shared/Config/Sounds.luau`](../src/shared/Config/Sounds.luau).

| Ключ | Где звучит | Звук | Автор | id |
|---|---|---|---|---|
| `Click` | кнопки интерфейса, клик по незрелой грядке | Roblox_UI_Bright_Click | Roblox | [15675059323](https://create.roblox.com/store/asset/15675059323) |
| `Open` | открытие окна | Roblox_UI_Whoosh_04 | Roblox | [15675012262](https://create.roblox.com/store/asset/15675012262) |
| `Error` | ошибка / не хватает денег | Roblox GUI - Negative | Roblox | [17208353912](https://create.roblox.com/store/asset/17208353912) |
| `Cash` | продажа, покупка, офлайн-доход | Roblox GUI - Purchase | Roblox | [17208380755](https://create.roblox.com/store/asset/17208380755) |
| `Golden` | золотая картошка | Magical Meetup - Hit2 | APMOfficial | [9048764475](https://create.roblox.com/store/asset/9048764475) |
| `Dump` | картошка высыпается в ящик скупщика | Crate Of Rocks 10 | ProSoundEffects | [9113967337](https://create.roblox.com/store/asset/9113967337) |
| `Fanfare` | новый этап, Rebirth, победа в событии | Glamour Fanfare 4 | APMOfficial | [1844584807](https://create.roblox.com/store/asset/1844584807) |
| `Dig` | копание лопатой | Dirt Scoops 4 | ProSoundEffects | [9114116006](https://create.roblox.com/store/asset/9114116006) |
| `Squash` | раздавить жука | Fruit Vegetable Impacts 6 | ProSoundEffects | [9114540148](https://create.roblox.com/store/asset/9114540148) |
| `BugBuzz` | начало нашествия жуков | Bee Various Buzzing Actions 10 | ProSoundEffects | [9113414621](https://create.roblox.com/store/asset/9113414621) |
| `Build` | постройка куплена | Hammer Nail Into Wood 25 | ProSoundEffects | [9114756916](https://create.roblox.com/store/asset/9114756916) |
| `Alarm` | перегрузка сети | Sci- Fi Siren Constant Varied Alarms 1 | ProSoundEffects | [9118781307](https://create.roblox.com/store/asset/9118781307) |
| `Zap` | искры при перегрузке | Arc Zaps Phasey Short Bursts 1 | ProSoundEffects | [9113149296](https://create.roblox.com/store/asset/9113149296) |
| `Rocket` | старт шаттла | Tubular Whoosh Explosion Long Constant Roar | ProSoundEffects | [9126142721](https://create.roblox.com/store/asset/9126142721) |
| `Sizzle` | фритюр (петля) | Fry Or Sizzle 2 | ProSoundEffects | [9114542880](https://create.roblox.com/store/asset/9114542880) |
| `Blade` | слайсер (петля) | Conveyor Belt 3 | ProSoundEffects | [9113910518](https://create.roblox.com/store/asset/9113910518) |
| `Hum` | подстанция (петля) | Transformer Hum 1 | ProSoundEffects | [9112889082](https://create.roblox.com/store/asset/9112889082) |
| `Engine` | генераторы (петля) | Lawn Mower Motor 1 | ProSoundEffects | [9116244745](https://create.roblox.com/store/asset/9116244745) |
| `Water` | спринклер (петля) | Water Fountain 1 | ProSoundEffects | [9120557629](https://create.roblox.com/store/asset/9120557629) |
| `Music1` | фоновая музыка | Playful Things (a) | APMOfficial | [1842106837](https://create.roblox.com/store/asset/1842106837) |
| `Music2` | фоновая музыка | Wild West Uke | APMOfficial | [1843265603](https://create.roblox.com/store/asset/1843265603) |
| `Music3` | фоновая музыка | Happy Ways | APMOfficial | [1843278593](https://create.roblox.com/store/asset/1843278593) |

## Как устроено

- `Sound.play(key)` — короткий эффект для одного игрока (не больше 4 копий одного звука одновременно);
  `Dig` выбирает случайный из трёх дублей, а клик по незрелой грядке и копание — со случайной высотой.
- `start`/`length` — фрагмент файла: пропуск тишины в начале и обрезка длинного хвоста (последние 0,25 с затухают).
- Петли (`loop = true`) — 3D-звук на постройке, слышен в радиусе ~45 стадов: фритюр и слайсер (`Model:SetAttribute("Sound", …)`
  в `World/Models/Factory.luau`), генераторы и подстанция (`Energy.luau`), спринклер (`Agro.luau`).
  Каждая петля стартует со случайного места, чтобы одинаковые постройки рядом не звучали в унисон.
- Музыка `Music1..3` играет по кругу в случайном порядке; кнопка **🎵 Music** в боковом меню выключает её.
- Группы громкости `SoundService.Effects`, `Ambient`, `Music` (`SoundGroup`) — общий микшер.

## Громкость

Громкость выровнена по средней громкости звучащей части файла (RMS без тишины) с целевыми уровнями:
интерфейс −30 дБ, деньги и ферма −24, фанфары −22, ракета −20, петли −30 (дальше их глушит расстояние),
музыка −32. Поэтому `volume` у разных звуков сильно отличается: файлы в библиотеках записаны с разной громкостью
(гул трансформатора — очень тихая запись, отсюда `volume = 4.5`).

## Запасные варианты

Если звук не понравится в игре — замените `id` (и при необходимости `start`/`volume`) на запасной:

| Ключ | Запасные |
|---|---|
| `Click` | Suction Pop 4 — `9119669065`; Roblox GUI - Select — `17208396156` |
| `Open` | Roblox_UI_Whoosh_02 — `15675028888`; Pop Airy 1 — `9117841338` |
| `Error` | Roblox GUI - Call Decline — `17208214688`; Roblox_UI_Whistle_Low — `15675062723` |
| `Cash` | Roblox GUI - Pickup — `17208319162`; RBLX UI Purchase — `10066947742` |
| `Golden` | Magic Twirling Small High Pitch Spinning Chime — `9125644065`; Magical Exit Sparkling Pass Bys Clinking Chimes — `9125635442` |
| `Dump` | Crate Of Rocks 15 — `9113967569`; Rock Hitting Wood Crash Bangs Boards Movement — `9125870973` |
| `Fanfare` | Jam Happy (sting c) — `1841740935`; Cartoon Fanfare (c) — `1842335078` |
| `Dig` | Dirt Dig Dirt Throws From Shovel 12 — `9114083746`; Dirt Dig Dirt Throws From Shovel 10 — `9114083717` |
| `Squash` | Body Fall Gooshy Mud 1 — `9113469902`; Fruit Vegetable Impacts 15 — `9114542640` |
| `BugBuzz` | Bee Various Buzzing Actions 6 — `9113414362`; Central Core Hive Buzzing Insect Swarm 1 — `9113752989` |
| `Build` | Wood Impact 7 — `9120902589`; Wood Drop Wooden Log Fall 2 — `9120871244` |
| `Alarm` | Siren Variety 3 — `9119164114`; Submarine Alarm Klaxon 6 — `9119662934` |
| `Zap` | Powerline Zaps 1 — `9117877054`; Arc Zaps Phasey Short Bursts 2 — `9113148015` |
| `Rocket` | Tubular Whoosh Explosion Long Constant Roar — `9126142726`; Rocket whoosh 01.wav — `12222095` |
| `Sizzle` | Fry Or Sizzle 1 — `9114542867`; Acid Sizzle Adding Baking Soda To Vinegar 2 — `9113040658` |
| `Blade` | Conveyor Belt 1 — `9113910414`; Conveyor Belt 2 — `9113910422` |
| `Hum` | Transformer Hum 3 — `9112889325`; Buzzing Energy 1 — `9112754462` |
| `Engine` | Harbor Background Constant Machine Idle 1 — `9114776167`; Comic Engine Constant 2 — `9112760403` |
| `Water` | Water Fountain 1 — `9120557306`; Water Hose 1 — `9120560251` |
| `Music1` | Countryside Kitchen (Alt) — `1836023902`; Cheerful Mornings Main Underscore — `1835292265` |
| `Music2` | Cheerful Day — `1839530410`; Very Carefree — `1839737454` |
| `Music3` | Sunflower Song — `9038762524`; Johnny Banjo — `1839048785` |

## Подобрать другой звук

Поиск в Creator Store: **Creator Hub → Store → Audio**, фильтр по автору *Pro Sound Effects*, *APM Music*
или *Roblox*. id — число в адресе страницы звука. Звуки других авторов могут быть закрыты для чужих игр.
