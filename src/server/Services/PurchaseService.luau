-- Покупки: постройки (кнопки), исследования сортов, найм персонала, звёздные технологии

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Sessions = require(script.Parent.Sessions)
local PlotService = require(script.Parent.PlotService)
local ManualFarm = require(script.Parent.ManualFarm)

type Session = Sessions.Session

local PurchaseService = {}

local function afterChange(session: Session, oldStage: number?)
	local stats = Sessions.recompute(session)
	PlotService.refreshButtons(session)
	Sessions.sync(session)
	if oldStage and stats.stage > oldStage then
		local stage = Config.Game.Stages[stats.stage]
		Sessions.notify(session.player, string.format("🎉 ЭТАП %d: %s", stats.stage, stage.name), "stage")
		Sessions.effect(session.player, { type = "Stage", stage = stats.stage })
	end
	if stats.overloaded and not session.passes.infiniteEnergy then
		Sessions.notify(
			session.player,
			"⚠ Перегрузка сети! Доход -50%. Построй генератор.",
			"error"
		)
	end
end

function PurchaseService.buyItem(player: Player, itemId: string): boolean
	local session = Sessions.get(player)
	local item = Config.Items.ById[itemId]
	if not (session and session.plot and item) or item.prebuilt then
		return false
	end
	local profile = session.profile
	if profile.owned[itemId] or not Economy.requirementsMet(item, profile) then
		return false
	end
	local cost = Economy.itemCost(item, profile, Config)
	if not Sessions.trySpend(session, cost) then
		Sessions.notify(player, "Не хватает " .. Format.money(cost - profile.cash), "error")
		return false
	end
	local oldStage = Economy.stage(profile, Config)
	profile.owned[itemId] = true
	PlotService.buildItem(session, item, true)
	if item.manualYield then
		ManualFarm.setupBeds(session)
	end
	Sessions.effect(player, { type = "Purchase", itemId = itemId })
	Sessions.notify(player, "Построено: " .. item.name, "success")
	if Config.Items.HasFlag(item, "Tower") then
		Sessions.recompute(session)
		ManualFarm.onTower(session)
		Sessions.notify(
			player,
			"🤝 Контракт подписан! Урожай теперь собирается и продаётся сам.",
			"stage"
		)
	end
	afterChange(session, oldStage)
	return true
end

function PurchaseService.buyResearch(player: Player, varietyId: string)
	local session = Sessions.get(player)
	if not session then
		return
	end
	local profile = session.profile
	local variety
	for _, v in ipairs(Config.Varieties) do
		if v.id == varietyId then
			variety = v
		end
	end
	if not variety or profile.varieties[varietyId] then
		return
	end
	if variety.requires and not profile.owned[variety.requires] then
		local req = Config.Items.ById[variety.requires]
		Sessions.notify(
			player,
			"Сначала построй: " .. (if req then req.name else variety.requires),
			"error"
		)
		return
	end
	local cost = Economy.varietyCost(variety, profile, Config)
	if not Sessions.trySpend(session, cost) then
		Sessions.notify(player, "Не хватает " .. Format.money(cost - profile.cash), "error")
		return
	end
	profile.varieties[varietyId] = true
	Sessions.notify(player, "🧬 Открыт сорт «" .. variety.name .. "»", "success")
	Sessions.effect(player, { type = "Sound", sound = "Golden" })
	afterChange(session)
end

function PurchaseService.selectVariety(player: Player, varietyId: string?)
	local session = Sessions.get(player)
	if not session then
		return
	end
	if varietyId == nil or session.profile.varieties[varietyId] then
		session.profile.activeVariety = varietyId
		afterChange(session)
	end
end

function PurchaseService.hireStaff(player: Player, staffId: string)
	local session = Sessions.get(player)
	local staff = Config.Staff.ById[staffId]
	if not (session and staff) then
		return
	end
	local profile = session.profile
	local count = profile.staff[staffId] or 0
	if count >= staff.max then
		return
	end
	if not profile.owned[staff.requires] then
		local req = Config.Items.ById[staff.requires]
		Sessions.notify(
			player,
			"Сначала построй: " .. (if req then req.name else staff.requires),
			"error"
		)
		return
	end
	if staff.requiresPass and not session.passes[staff.requiresPass] then
		Sessions.notify(player, "Доступно только с геймпассом VIP Фермер 👑", "error")
		return
	end
	local cost = Economy.staffCost(staff, profile, Config)
	if not Sessions.trySpend(session, cost) then
		Sessions.notify(player, "Не хватает " .. Format.money(cost - profile.cash), "error")
		return
	end
	profile.staff[staffId] = count + 1
	PlotService.spawnStaff(session, staff, count + 1, true)
	Sessions.notify(player, "Нанят: " .. staff.name, "success")
	Sessions.effect(player, { type = "Sound", sound = "Cash" })
	afterChange(session)
end

function PurchaseService.buyStarTech(player: Player, techId: string)
	local session = Sessions.get(player)
	local tech = Config.StarTech.ById[techId]
	if not (session and tech) then
		return
	end
	local profile = session.profile
	local level = profile.starTech[techId] or 0
	if level >= tech.max then
		return
	end
	local cost = Config.StarTech.CostOf(tech, level)
	if profile.stars < cost then
		Sessions.notify(player, "Не хватает ⭐ " .. Format.number(cost - profile.stars), "error")
		return
	end
	profile.stars -= cost
	profile.starTech[techId] = level + 1
	Sessions.notify(player, string.format("⭐ %s: уровень %d", tech.name, level + 1), "success")
	Sessions.effect(player, { type = "Sound", sound = "Golden" })
	afterChange(session)
end

function PurchaseService.init()
	PlotService.onBuy = function(player, itemId)
		PurchaseService.buyItem(player, itemId)
	end
	Remotes.get("BuyResearch").OnServerEvent:Connect(function(player, id: unknown)
		if type(id) == "string" then
			PurchaseService.buyResearch(player, id)
		end
	end)
	Remotes.get("SelectVariety").OnServerEvent:Connect(function(player, id: unknown)
		if id == nil or type(id) == "string" then
			PurchaseService.selectVariety(player, id :: string?)
		end
	end)
	Remotes.get("HireStaff").OnServerEvent:Connect(function(player, id: unknown)
		if type(id) == "string" then
			PurchaseService.hireStaff(player, id)
		end
	end)
	Remotes.get("BuyStarTech").OnServerEvent:Connect(function(player, id: unknown)
		if type(id) == "string" then
			PurchaseService.buyStarTech(player, id)
		end
	end)
end

return PurchaseService
