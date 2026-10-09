-- Сохранение прогресса в DataStore (с повторами). Если DataStore недоступен
-- (например, в Studio без «Enable Studio Access to API Services»), игра работает без сохранений.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)

local DataService = {}

local store: DataStore? = nil
local storeFailed = false

local function getStore(): DataStore?
	if store or storeFailed then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.Game.DataStoreName)
	end)
	if ok then
		store = result
	else
		storeFailed = true
		warn(
			"[DataService] DataStore недоступен, прогресс не будет сохраняться: "
				.. tostring(result)
		)
	end
	return store
end

local function key(player: Player): string
	return "u_" .. player.UserId
end

local function retry<T>(label: string, attempts: number, fn: () -> T): (boolean, T?)
	for attempt = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn(
			string.format(
				"[DataService] %s: попытка %d не удалась: %s",
				label,
				attempt,
				tostring(result)
			)
		)
		if attempt < attempts then
			task.wait(attempt * 1.5)
		end
	end
	return false, nil
end

-- Переносит сохранённые данные в свежий профиль, отбрасывая неизвестные ключи
local function reconcile(profile, data)
	local function num(v, default)
		return if type(v) == "number" and v == v then v else default
	end
	profile.cash = num(data.cash, profile.cash)
	profile.stars = num(data.stars, 0)
	profile.rebirths = math.floor(num(data.rebirths, 0))
	profile.bag = math.floor(num(data.bag, 0))
	profile.totalEarned = num(data.totalEarned, 0)
	profile.totalKg = num(data.totalKg, 0)
	profile.lastOnline = num(data.lastOnline, 0)
	profile.lastIncome = num(data.lastIncome, 0)
	profile.bugEventsWon = num(data.bugEventsWon, 0)

	if type(data.owned) == "table" then
		for id, v in pairs(data.owned) do
			if v == true and Config.Items.ById[id] then
				profile.owned[id] = true
			end
		end
	end
	if type(data.varieties) == "table" then
		for _, v in ipairs(Config.Varieties) do
			if data.varieties[v.id] == true then
				profile.varieties[v.id] = true
			end
		end
	end
	if type(data.activeVariety) == "string" and profile.varieties[data.activeVariety] then
		profile.activeVariety = data.activeVariety
	end
	if type(data.staff) == "table" then
		for _, s in ipairs(Config.Staff.List) do
			local count = data.staff[s.id]
			if type(count) == "number" then
				profile.staff[s.id] = math.clamp(math.floor(count), 0, s.max)
			end
		end
	end
	if type(data.starTech) == "table" then
		for _, t in ipairs(Config.StarTech.List) do
			local level = data.starTech[t.id]
			if type(level) == "number" then
				profile.starTech[t.id] = math.clamp(math.floor(level), 0, t.max)
			end
		end
	end
	Economy.applyPrebuilt(profile, Config)
end

local function serialize(profile)
	return {
		version = profile.version,
		cash = profile.cash,
		stars = profile.stars,
		rebirths = profile.rebirths,
		owned = profile.owned,
		varieties = profile.varieties,
		activeVariety = profile.activeVariety,
		staff = profile.staff,
		starTech = profile.starTech,
		bag = profile.bag,
		totalEarned = profile.totalEarned,
		totalKg = profile.totalKg,
		lastOnline = profile.lastOnline,
		lastIncome = profile.lastIncome,
		bugEventsWon = profile.bugEventsWon,
	}
end

-- Возвращает профиль и флаг persistent (можно ли его сохранять)
function DataService.load(player: Player)
	local profile = Economy.newProfile(Config)
	local s = getStore()
	if not s then
		return profile, false
	end
	-- в Studio без доступа к API не ждём повторов, сразу играем без сохранений
	local attempts = if RunService:IsStudio() then 1 else 3
	local ok, data = retry("загрузка " .. player.Name, attempts, function()
		return s:GetAsync(key(player))
	end)
	if not ok and RunService:IsStudio() then
		storeFailed = true
		store = nil
		warn(
			"[DataService] Включите Game Settings → Security → Enable Studio Access to API Services, чтобы проверить сохранения"
		)
	end
	if not ok then
		-- не перезаписываем сохранение, которое не смогли прочитать
		return profile, false
	end
	if type(data) == "table" then
		reconcile(profile, data)
	end
	return profile, true
end

function DataService.save(player: Player, profile, persistent: boolean): boolean
	if not persistent then
		return false
	end
	local s = getStore()
	if not s then
		return false
	end
	local payload = serialize(profile)
	local ok = retry("сохранение " .. player.Name, 3, function()
		return s:UpdateAsync(key(player), function()
			return payload
		end)
	end)
	return ok
end

return DataService
