-- Этап 1: ручной огород. Лопата, созревание кустов, мешок, сдача скупщику, советы Деда Матвея.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Misc = require(script.Parent.Parent.World.Models.Misc)

local Sessions = require(script.Parent.Sessions)
local PlotService = require(script.Parent.PlotService)

type Session = Sessions.Session

local ManualFarm = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function isShovel(tool: Instance?): boolean
	return tool ~= nil and tool:IsA("Tool") and tool:GetAttribute("Shovel") == true
end

function ManualFarm.removeShovel(player: Player)
	for _, container in ipairs({
		player:FindFirstChild("Backpack"),
		player:FindFirstChild("StarterGear"),
		player.Character,
	}) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if isShovel(child) then
					child:Destroy()
				end
			end
		end
	end
end

function ManualFarm.giveShovel(session: Session)
	local player = session.player
	ManualFarm.removeShovel(player)
	if not Economy.isManual(session.profile) then
		return
	end
	local golden = session.passes.vip == true
	local gear = player:FindFirstChild("StarterGear")
	if gear then
		Misc.Shovel(golden).Parent = gear
	end
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		Misc.Shovel(golden).Parent = backpack
	end
end

-- Выставляет таймеры созревания на ручных грядках
function ManualFarm.setupBeds(session: Session)
	local info = session.plot
	if not info then
		return
	end
	local manual = Economy.isManual(session.profile)
	local stats = session.stats or Sessions.recompute(session)
	for _, item in ipairs(Config.Items.List) do
		if item.manualYield and session.profile.owned[item.id] then
			local model = info.items:FindFirstChild(item.id)
			if model then
				local ripeAt = session.ripeAt[item.id] or (now() + stats.ripenTime)
				session.ripeAt[item.id] = ripeAt
				model:SetAttribute("RipeAt", ripeAt)
				model:SetAttribute("RipenTime", stats.ripenTime)
				model:SetAttribute("Auto", not manual)
				local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
				if prompt then
					prompt.Enabled = manual
				end
			end
		end
	end
	local stand = info.items:FindFirstChild("stand")
	if stand then
		local prompt = stand:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt then
			prompt.Enabled = manual
		end
	end
end

function ManualFarm.dig(session: Session, itemId: string, requireShovel: boolean)
	local player = session.player
	local profile = session.profile
	if not Economy.isManual(profile) or not session.plot then
		return
	end
	local item = Config.Items.ById[itemId]
	if not (item and item.manualYield and profile.owned[itemId]) then
		return
	end
	local model = session.plot.items:FindFirstChild(itemId) :: Model?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (model and root) then
		return
	end
	if (root.Position - model:GetPivot().Position).Magnitude > Config.Game.Manual.DigDistance then
		Sessions.notify(player, "Get closer to the bed", "error")
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if requireShovel and not isShovel(tool) then
		return
	end
	-- защита от спама кликами
	local t = now()
	if t - session.lastDig < 0.12 then
		return
	end
	session.lastDig = t
	if t < (session.ripeAt[itemId] or 0) - 0.15 then
		return
	end
	local stats = session.stats
	local capacity = stats.bagCapacity
	if profile.bag >= capacity then
		Sessions.notify(player, "Your sack is full! Take the potatoes to the buyer 🧺", "error")
		Sessions.effect(player, { type = "Sound", sound = "Error" })
		return
	end
	local gained = math.min(item.manualYield, capacity - profile.bag)
	profile.bag += gained
	player:SetAttribute("Bag", profile.bag)
	session.ripeAt[itemId] = t + stats.ripenTime
	model:SetAttribute("RipeAt", session.ripeAt[itemId])
	model:SetAttribute("RipenTime", stats.ripenTime)

	-- анимация удара лопатой (стандартный Animate проигрывает "Slash")
	if isShovel(tool) then
		local anim = Instance.new("StringValue")
		anim.Name = "toolanim"
		anim.Value = "Slash"
		anim.Parent = tool
		task.delay(0.5, function()
			anim:Destroy()
		end)
	end
	Sessions.effect(player, {
		type = "Dig",
		position = model:GetPivot().Position,
		amount = gained,
	})

	-- золотой клубень
	local chance = Config.Game.Manual.GoldenChance
		* (if session.passes.magnateDrone then Config.Game.Golden.PassMultiplier else 1)
	if math.random() < chance then
		local bonus = Config.Game.Manual.GoldenValue * stats.manualPrice
		Sessions.addCash(session, bonus)
		Sessions.updateLeaderstats(session)
		Sessions.notify(player, "✨ Golden tuber! +" .. Format.money(bonus), "gold")
		Sessions.effect(player, { type = "Golden", target = model, amount = bonus })
	end
end

function ManualFarm.sell(session: Session)
	local profile = session.profile
	local player = session.player
	if profile.bag <= 0 then
		Sessions.notify(player, "Your sack is empty — dig up some potatoes with the shovel 🥔", "info")
		return
	end
	local amount = profile.bag * session.stats.manualPrice
	profile.totalKg += profile.bag
	profile.bag = 0
	player:SetAttribute("Bag", 0)
	Sessions.addCash(session, amount)
	Sessions.updateLeaderstats(session)
	local stand = PlotService.findItem(session, "stand")
	Sessions.effect(player, {
		type = "Sell",
		position = if stand then stand:GetPivot().Position else nil,
		amount = amount,
	})
end

-- Покупка Авто-вышки: ручной труд исчезает навсегда
function ManualFarm.onTower(session: Session)
	if session.profile.bag > 0 then
		ManualFarm.sell(session)
	end
	ManualFarm.removeShovel(session.player)
	ManualFarm.setupBeds(session)
end

local TIPS = {
	[1] = "Grab the shovel, dig up ripe bushes and sell the potatoes to the buyer. Save $1,500 for the Auto Harvest Tower — and the manual labor is over!",
	[2] = "Now the harvest sells itself. Build auto beds, watch your energy ⚡ and unlock new varieties in the 🧬 menu.",
	[3] = "Every workshop multiplies your revenue. Don't forget generators: an overload halves your income!",
	[4] = "Hire drones in the staff menu and unlock premium varieties. The DNA Lab is next!",
	[5] = "Build the shuttle and save up for Rebirth: x3 to all income forever, plus Potato Stars!",
}

function ManualFarm.talk(session: Session)
	local stage = session.stats.stage
	Sessions.notify(session.player, "👴 Grandpa Matvey: " .. (TIPS[stage] or TIPS[1]), "tip")
end

function ManualFarm.init()
	-- лопату раздаёт сервер, из StarterPack её убираем на всякий случай
	for _, child in ipairs(StarterPack:GetChildren()) do
		if isShovel(child) then
			child:Destroy()
		end
	end

	PlotService.promptHandlers.Dig = function(session, model)
		ManualFarm.dig(session, model.Name, false)
	end
	PlotService.promptHandlers.Sell = function(session)
		ManualFarm.sell(session)
	end
	PlotService.promptHandlers.Talk = function(session)
		ManualFarm.talk(session)
	end

	Remotes.get("Dig").OnServerEvent:Connect(function(player: Player, itemId: unknown)
		local session = Sessions.get(player)
		if session and type(itemId) == "string" then
			ManualFarm.dig(session, itemId, true)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		ManualFarm.removeShovel(player)
	end)
end

return ManualFarm
