-- Случайные события (ГДД, раздел 6):
--  * Нашествие жуков — каждые 20 мин: поймай 15 жуков за 45 сек → бонус = 10 минут дохода
--  * Картофельный бум на бирже — раз в 30 мин: 3 минуты чипсы и фри в цене, доход x3

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Kit = require(script.Parent.Parent.World.ModelKit)
local Misc = require(script.Parent.Parent.World.Models.Misc)
local World = require(script.Parent.Parent.World.WorldBuilder)
local Sessions = require(script.Parent.Sessions)

type Session = Sessions.Session

local GameState = ReplicatedStorage:WaitForChild("GameState")

local EventService = {}

local NEVER = 1e15
local bugsActive = false
local bugSerial = 0

local function now(): number
	return workspace:GetServerTimeNow()
end

local function spawnBug(session: Session, boss: boolean)
	local info = session.plot
	if not info then
		return
	end
	-- случайная точка в агро-блоке, не на центральной дорожке
	local x = math.random(5, 37) * (if math.random() < 0.5 then -1 else 1)
	local z = math.random(16, 38)
	local cf = World.localCFrame(info, x, z, math.random(0, 359))
	bugSerial += 1
	local b = Kit.new("Bug" .. bugSerial, cf)
	Misc.Bug(b, boss)
	local health = if boss then Config.Game.Events.Bugs.BossHealth else 1
	b.model:SetAttribute("Bug", true)
	b.model:SetAttribute("Boss", boss)
	b.model:SetAttribute("Health", health)
	b.model:SetAttribute("MaxHealth", health)
	b.model:SetAttribute("Owner", session.player.UserId)
	b:tag(b.model, "Bug")
	b:finish(info.bugs)
end

local function reward(session: Session)
	local E = Config.Game.Events.Bugs
	local stats = session.stats
	local base = if stats.manual then 0 else stats.incomeNoEvent * E.RewardSeconds
	local amount = math.max(base, E.MinReward * stats.rebirthMult) * (1 + (stats.bugBoost or 0))
	Sessions.addCash(session, amount)
	Sessions.updateLeaderstats(session)
	session.profile.bugEventsWon += 1
	Sessions.notify(session.player, "🪲 Жуки побеждены! Бонус " .. Format.money(amount), "gold")
	Sessions.effect(session.player, { type = "Confetti" })
	Sessions.effect(session.player, { type = "Sound", sound = "Cash" })
end

local function clearBugs(session: Session)
	if session.plot then
		session.plot.bugs:ClearAllChildren()
	end
end

function EventService.startBugs()
	local E = Config.Game.Events.Bugs
	bugsActive = true
	GameState:SetAttribute("BugsEndsAt", now() + E.Duration)
	GameState:SetAttribute("BugsGoal", E.Goal)
	for _, session in pairs(Sessions.all) do
		if session.loaded and session.plot then
			session.bugs = { count = 0, rewarded = false }
			session.player:SetAttribute("BugsCaught", 0)
			for _ = 1, E.Count do
				spawnBug(session, false)
			end
			spawnBug(session, true)
		end
	end
	Sessions.notifyAll(
		"🪲 НАШЕСТВИЕ ЖУКОВ! Кликай по жукам на своём поле: 15 за 45 сек = 10 минут дохода!",
		"event"
	)
	Sessions.effectAll({ type = "Sound", sound = "BugBuzz" })
	task.delay(E.Duration, function()
		bugsActive = false
		for _, session in pairs(Sessions.all) do
			if session.plot and #session.plot.bugs:GetChildren() > 0 and not session.bugs.rewarded then
				Sessions.notify(
					session.player,
					"Жуки улетели... Попробуй в следующий раз!",
					"info"
				)
			end
			clearBugs(session)
			session.player:SetAttribute("BugsCaught", nil)
		end
		GameState:SetAttribute("NextBugsAt", now() + E.Interval - E.Duration)
	end)
end

function EventService.clickBug(player: Player, bug: Instance)
	local session = Sessions.get(player)
	if not (bugsActive and session and session.plot) then
		return
	end
	if typeof(bug) ~= "Instance" or not bug:IsDescendantOf(session.plot.bugs) or not bug:GetAttribute("Bug") then
		return
	end
	local E = Config.Game.Events.Bugs
	local health = (bug:GetAttribute("Health") :: number) - 1
	bug:SetAttribute("Health", health)
	Sessions.effect(player, { type = "Squash", position = (bug :: Model):GetPivot().Position, dead = health <= 0 })
	if health > 0 then
		return
	end
	local value = if bug:GetAttribute("Boss") then E.BossValue else 1
	bug:Destroy()
	session.bugs.count += value
	player:SetAttribute("BugsCaught", session.bugs.count)
	if session.bugs.count >= E.Goal and not session.bugs.rewarded then
		session.bugs.rewarded = true
		reward(session)
		clearBugs(session)
	end
end

function EventService.startBoom()
	local B = Config.Game.Events.Boom
	GameState:SetAttribute("BoomEndsAt", now() + B.Duration)
	for _, session in pairs(Sessions.all) do
		Sessions.recompute(session)
	end
	Sessions.notifyAll(
		"📈 КАРТОФЕЛЬНЫЙ БУМ НА БИРЖЕ! Чипсы и фри в цене — доход x3 на 3 минуты!",
		"event"
	)
	Sessions.effectAll({ type = "Sound", sound = "Cash" })
	task.delay(B.Duration + 0.1, function()
		GameState:SetAttribute("NextBoomAt", now() + B.Interval - B.Duration)
		for _, session in pairs(Sessions.all) do
			Sessions.recompute(session)
		end
		Sessions.notifyAll(
			"Биржевой бум закончился. Следующий — через 27 минут.",
			"info"
		)
	end)
end

function EventService.init()
	local E = Config.Game.Events
	local fast = Config.Game.Debug.FastEvents and RunService:IsStudio()
	GameState:SetAttribute("NextBugsAt", now() + (if fast then 20 else E.Bugs.FirstDelay))
	GameState:SetAttribute("NextBoomAt", now() + (if fast then 60 else E.Boom.FirstDelay))

	Remotes.get("ClickBug").OnServerEvent:Connect(function(player, bug: unknown)
		if typeof(bug) == "Instance" then
			EventService.clickBug(player, bug :: Instance)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			local t = now()
			if not bugsActive and t >= (GameState:GetAttribute("NextBugsAt") or NEVER) then
				GameState:SetAttribute("NextBugsAt", NEVER)
				EventService.startBugs()
			end
			if t >= (GameState:GetAttribute("NextBoomAt") or NEVER) then
				GameState:SetAttribute("NextBoomAt", NEVER)
				EventService.startBoom()
			end
		end
	end)
end

return EventService
