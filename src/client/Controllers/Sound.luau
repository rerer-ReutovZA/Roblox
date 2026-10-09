-- Воспроизведение звуков по ключу из Config.Sounds: короткие эффекты, 3D-петли цехов и фоновая музыка.
-- Звуки разведены по группам (Effects, Ambient, Music), чтобы громкость каждой можно было менять целиком.

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local Sound = {}

local MAX_VOICES = 4 -- одновременных копий одного эффекта (частые «Cash» не складываются в шум)
local FADE = 0.25 -- затухание в конце обрезанного фрагмента, с

local groups: { [string]: SoundGroup } = {}
local voices: { [string]: number } = {}

local function group(name: string): SoundGroup
	local g = groups[name]
	if not g then
		g = Instance.new("SoundGroup")
		g.Name = name
		g.Volume = 1
		g.Parent = SoundService
		groups[name] = g
	end
	return g
end

-- Дубли звука: основной и variants. Вариант — id-строка или таблица { id, start?, length?, volume? },
-- недостающие поля берутся из основной записи
local function takes(def): { any }
	local list = { def }
	for _, v in ipairs(def.variants or {}) do
		local take = if type(v) == "string" then { id = v } else v
		table.insert(list, {
			id = take.id,
			volume = take.volume or def.volume,
			pitch = def.pitch,
			start = take.start or def.start,
			length = take.length or def.length,
		})
	end
	return list
end

-- Фрагмент файла: start — пропустить тишину в начале, length — сколько секунд играть (0 — до конца)
local function region(s: Sound, def)
	local start, length = def.start or 0, def.length or 0
	if start > 0 or length > 0 then
		s.PlaybackRegionsEnabled = true
		local stop = if length > 0 then start + length else 3600
		s.PlaybackRegion = NumberRange.new(start, stop)
		s.LoopRegion = NumberRange.new(start, stop)
	end
end

local function make(key: string, def, groupName: string): Sound
	local s = Instance.new("Sound")
	s.Name = key
	s.SoundId = def.id
	s.Volume = def.volume
	s.PlaybackSpeed = def.pitch or 1
	s.SoundGroup = group(groupName)
	region(s, def)
	return s
end

-- Короткий звук для этого игрока. pitchJitter — случайный разброс высоты (0.2 = ±10 %)
function Sound.play(key: string, pitchJitter: number?)
	local def = Config.Sounds[key]
	if not def or def.id == "" or (voices[key] or 0) >= MAX_VOICES then
		return
	end
	local list = takes(def)
	local take = list[math.random(1, #list)]
	local s = make(key, take, "Effects")
	local speed = (def.pitch or 1) * (1 + (math.random() - 0.5) * (pitchJitter or 0))
	s.PlaybackSpeed = speed
	s.Parent = SoundService
	voices[key] = (voices[key] or 0) + 1
	local done = false
	local function finish()
		if not done then
			done = true
			voices[key] = (voices[key] or 1) - 1
			s:Destroy()
		end
	end
	s.Ended:Connect(finish)
	local length = take.length or 0
	if length > 0 then
		local playTime = length / speed
		task.delay(math.max(0, playTime - FADE), function()
			if s.Parent then
				TweenService:Create(s, TweenInfo.new(FADE), { Volume = 0 }):Play()
			end
		end)
		task.delay(playTime + 0.05, finish)
	else
		task.delay(20, finish) -- страховка, если Ended не придёт
	end
	s:Play()
end

-- Зацикленный 3D-звук на объекте (жарка, слайсер, гул подстанции, двигатель, спринклер)
function Sound.attachLoop(key: string, parent: Instance): Sound?
	local def = Config.Sounds[key]
	if not def or def.id == "" then
		return nil
	end
	local s = make("Loop_" .. key, def, "Ambient")
	s.Looped = true
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMaxDistance = def.range or 45
	s.RollOffMinDistance = 6
	-- одинаковые петли рядом не должны звучать в унисон: старт со случайного места
	local start, length = def.start or 0, def.length or 0
	if length > 0 then
		s.TimePosition = start + math.random() * length
	end
	s.Parent = parent
	s:Play()
	return s
end

------------------------------------------------------------------
-- Фоновая музыка: ключи Music1, Music2… по кругу в случайном порядке
------------------------------------------------------------------
local musicOn = true
local musicStarted = false

local function playlist(): { string }
	local keys = {}
	for key, def in pairs(Config.Sounds) do
		if string.match(key, "^Music%d+$") and def.id ~= "" then
			table.insert(keys, key)
		end
	end
	table.sort(keys)
	for i = #keys, 2, -1 do
		local j = math.random(1, i)
		keys[i], keys[j] = keys[j], keys[i]
	end
	return keys
end

function Sound.startMusic()
	if musicStarted then
		return
	end
	musicStarted = true
	local keys = playlist()
	if #keys == 0 then
		return
	end
	task.spawn(function()
		local i = 0
		while true do
			i = i % #keys + 1
			local key = keys[i]
			local def = Config.Sounds[key]
			local s = make(key, def, "Music")
			s.Name = "Music"
			s.Parent = SoundService
			s:Play()
			-- ждём конца трека; если файл не загрузился за 15 с — следующий
			local waited = 0
			repeat
				task.wait(1)
				waited += 1
			until s.IsLoaded and not s.IsPlaying or not s.IsLoaded and waited > 15 or waited > 600
			s:Destroy()
			task.wait(3)
		end
	end)
end

function Sound.musicEnabled(): boolean
	return musicOn
end

function Sound.setMusic(on: boolean)
	musicOn = on
	TweenService:Create(group("Music"), TweenInfo.new(0.6), { Volume = if on then 1 else 0 }):Play()
end

function Sound.init()
	-- заранее подгружаем короткие эффекты, чтобы первый клик не был беззвучным
	local list = {}
	for key, def in pairs(Config.Sounds) do
		if not def.loop and not string.match(key, "^Music") then
			for _, take in ipairs(takes(def)) do
				if take.id ~= "" then
					table.insert(list, take.id)
				end
			end
		end
	end
	task.spawn(function()
		ContentProvider:PreloadAsync(list)
	end)
	Sound.startMusic()
end

return Sound
