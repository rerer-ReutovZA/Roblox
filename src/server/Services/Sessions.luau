-- Состояние игроков на сервере: профиль, расчёт статистики, синхронизация с клиентом

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local GameState = ReplicatedStorage:WaitForChild("GameState")

local Sessions = {}

export type Session = {
	player: Player,
	profile: any,
	persistent: boolean,
	plot: any?,
	stats: any,
	passes: { [string]: boolean },
	ripeAt: { [string]: number },
	bugs: { count: number, rewarded: boolean },
	clientReady: boolean,
	pendingOffline: { seconds: number, amount: number }?,
	lastDig: number,
	loaded: boolean,
	rebirthing: boolean,
}

Sessions.all = {} :: { [Player]: Session }

local syncRemote = Remotes.get("Sync")
local notifyRemote = Remotes.get("Notify")
local effectRemote = Remotes.get("Effect")

function Sessions.create(player: Player, profile, persistent: boolean): Session
	local session: Session = {
		player = player,
		profile = profile,
		persistent = persistent,
		plot = nil,
		stats = nil,
		passes = {},
		ripeAt = {},
		bugs = { count = 0, rewarded = false },
		clientReady = false,
		pendingOffline = nil,
		lastDig = 0,
		loaded = false,
		rebirthing = false,
	}
	Sessions.all[player] = session
	return session
end

function Sessions.get(player: Player): Session?
	return Sessions.all[player]
end

function Sessions.remove(player: Player)
	Sessions.all[player] = nil
end

function Sessions.boomActive(): boolean
	return (GameState:GetAttribute("BoomEndsAt") or 0) > workspace:GetServerTimeNow()
end

function Sessions.context(session: Session)
	return { passes = session.passes, boom = Sessions.boomActive() }
end

-- Пересчитывает доход/энергию и публикует атрибуты игрока для HUD
function Sessions.recompute(session: Session)
	local profile = session.profile
	local stats = Economy.compute(profile, Sessions.context(session), Config)
	session.stats = stats
	local p = session.player
	p:SetAttribute("Cash", profile.cash)
	p:SetAttribute("Income", if stats.manual then 0 else stats.incomePerSec)
	p:SetAttribute("Stars", profile.stars)
	p:SetAttribute("Rebirths", profile.rebirths)
	p:SetAttribute("Stage", stats.stage)
	p:SetAttribute("Manual", stats.manual)
	p:SetAttribute("EnergyGen", stats.energyGen)
	p:SetAttribute("EnergyUse", stats.energyUse)
	p:SetAttribute("Overloaded", stats.overloaded)
	p:SetAttribute("Bag", profile.bag)
	p:SetAttribute("BagCapacity", stats.bagCapacity)
	p:SetAttribute("YieldKg", stats.yieldKg)
	p:SetAttribute("Price", stats.price)
	p:SetAttribute("FactoryMult", stats.factoryMult)
	p:SetAttribute("RebirthMult", stats.rebirthMult)
	p:SetAttribute("BonusMult", stats.bonusMult)
	p:SetAttribute("Variety", stats.variety.id)
	p:SetAttribute("ManualPrice", stats.manualPrice)
	p:SetAttribute("TotalKg", profile.totalKg)
	p:SetAttribute("VIP", session.passes.vip == true)
	Sessions.updateLeaderstats(session)
	return stats
end

function Sessions.updateLeaderstats(session: Session)
	local stats = session.player:FindFirstChild("leaderstats")
	if not stats then
		return
	end
	local cash = stats:FindFirstChild("Cash") :: StringValue?
	if cash then
		cash.Value = Format.money(session.profile.cash)
	end
	local rebirths = stats:FindFirstChild("Rebirth") :: IntValue?
	if rebirths then
		rebirths.Value = session.profile.rebirths
	end
end

-- Полное состояние для меню клиента
function Sessions.sync(session: Session)
	if not session.clientReady then
		return
	end
	local profile = session.profile
	local stats = session.stats or Sessions.recompute(session)
	syncRemote:FireClient(session.player, {
		owned = profile.owned,
		varieties = profile.varieties,
		activeVariety = profile.activeVariety,
		staff = profile.staff,
		starTech = profile.starTech,
		passes = session.passes,
		rebirths = profile.rebirths,
		stars = profile.stars,
		totalEarned = profile.totalEarned,
		rebirthCost = Economy.rebirthCost(profile.rebirths, Config),
		nextStars = Economy.rebirthStars(profile.rebirths + 1, Config),
		nextMult = Economy.rebirthMultiplier(profile.rebirths + 1, Config),
		plotIndex = session.plot and session.plot.index,
		stats = {
			baseYield = stats.baseYield,
			yieldBoost = stats.yieldBoost,
			plots = stats.plots,
			bugBoost = stats.bugBoost,
			offlineRate = stats.offlineRate,
			offlineHours = stats.offlineHours,
			ripenTime = stats.ripenTime,
		},
	})
end

function Sessions.setCash(session: Session, value: number)
	session.profile.cash = value
	session.player:SetAttribute("Cash", value)
	Sessions.updateLeaderstats(session)
end

function Sessions.addCash(session: Session, amount: number)
	if amount ~= amount or amount <= 0 then
		return
	end
	session.profile.cash += amount
	session.profile.totalEarned += amount
	session.player:SetAttribute("Cash", session.profile.cash)
end

function Sessions.trySpend(session: Session, amount: number): boolean
	if session.profile.cash + 1e-6 < amount then
		return false
	end
	Sessions.setCash(session, math.max(0, session.profile.cash - amount))
	return true
end

function Sessions.notify(player: Player, text: string, kind: string?)
	notifyRemote:FireClient(player, text, kind or "info")
end

function Sessions.notifyAll(text: string, kind: string?)
	notifyRemote:FireAllClients(text, kind or "info")
end

function Sessions.effect(player: Player, data)
	effectRemote:FireClient(player, data)
end

function Sessions.effectAll(data)
	effectRemote:FireAllClients(data)
end

function Sessions.ofUserId(userId: number): Session?
	local player = Players:GetPlayerByUserId(userId)
	return player and Sessions.all[player]
end

return Sessions
