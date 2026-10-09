-- Воспроизведение звуков по ключу из Config.Sounds

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)

local Sound = {}

local cache: { [string]: Sound } = {}

local function get(key: string): Sound?
	local def = Config.Sounds[key]
	if not def or def.id == "" then
		return nil
	end
	local s = cache[key]
	if not s then
		s = Instance.new("Sound")
		s.Name = "Sfx_" .. key
		s.SoundId = def.id
		s.Volume = def.volume
		s.Parent = SoundService
		cache[key] = s
	end
	return s
end

function Sound.play(key: string, pitchJitter: number?)
	local s = get(key)
	if not s then
		return
	end
	local def = Config.Sounds[key]
	s.PlaybackSpeed = def.pitch * (1 + (math.random() - 0.5) * (pitchJitter or 0))
	SoundService:PlayLocalSound(s)
end

-- Зацикленный 3D-звук на объекте (жарка, слайсер, гул трансформатора)
function Sound.attachLoop(key: string, part: BasePart): Sound?
	local def = Config.Sounds[key]
	if not def or def.id == "" then
		return nil
	end
	local s = Instance.new("Sound")
	s.Name = "Loop_" .. key
	s.SoundId = def.id
	s.Volume = def.volume
	s.PlaybackSpeed = def.pitch
	s.Looped = true
	s.RollOffMaxDistance = 45
	s.RollOffMinDistance = 6
	s.Parent = part
	s:Play()
	return s
end

return Sound
