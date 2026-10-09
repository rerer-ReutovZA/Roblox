-- Rebirth (ГДД 2.1 и этап 5): запуск шаттла, сброс базы, множитель 3^N и Картофельные Звезды

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Sessions = require(script.Parent.Sessions)
local PlotService = require(script.Parent.PlotService)
local ManualFarm = require(script.Parent.ManualFarm)

type Session = Sessions.Session

local RebirthService = {}

RebirthService.onRebirth = function(_session: Session) end

local LAUNCH_SECONDS = 5

function RebirthService.request(player: Player)
	local session = Sessions.get(player)
	if not (session and session.plot) or session.rebirthing then
		return
	end
	local profile = session.profile
	if not profile.owned.shuttle then
		Sessions.notify(player, "Rebirth requires the Export Shuttle (sector 4)", "error")
		return
	end
	local cost = Economy.rebirthCost(profile.rebirths, Config)
	if profile.cash < cost then
		Sessions.notify(player, "Rebirth requires " .. Format.money(cost), "error")
		return
	end
	session.rebirthing = true

	-- старт шаттла видят все игроки на сервере
	Sessions.effectAll({ type = "Launch", plotIndex = session.plot.index })
	task.wait(LAUNCH_SECONDS)
	if player.Parent == nil or Sessions.get(player) ~= session then
		return
	end

	profile.rebirths += 1
	local stars = Economy.rebirthStars(profile.rebirths, Config)
	profile.stars += stars
	local startCash = (profile.starTech.start_cash or 0) * Config.StarTech.ById.start_cash.perLevel
	profile.cash = startCash
	profile.owned = {}
	profile.varieties = { wild = true }
	profile.activeVariety = nil
	profile.staff = {}
	profile.bag = 0
	Economy.applyPrebuilt(profile, Config)
	session.ripeAt = {}

	Sessions.recompute(session)
	PlotService.buildAll(session)
	ManualFarm.setupBeds(session)
	ManualFarm.giveShovel(session)
	Sessions.sync(session)
	PlotService.teleportHome(player)

	local mult = Economy.rebirthMultiplier(profile.rebirths, Config)
	Sessions.effect(player, { type = "Confetti", big = true })
	Sessions.notify(
		player,
		string.format("🚀 REBIRTH %d! Income x%s forever, +%d ⭐", profile.rebirths, Format.number(mult), stars),
		"stage"
	)
	Sessions.notifyAll(string.format("🚀 %s just did Rebirth #%d!", player.DisplayName, profile.rebirths), "event")
	session.rebirthing = false
	RebirthService.onRebirth(session)
end

function RebirthService.init()
	Remotes.get("Rebirth").OnServerEvent:Connect(function(player)
		RebirthService.request(player)
	end)
end

return RebirthService
