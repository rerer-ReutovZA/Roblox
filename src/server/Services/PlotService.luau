-- Базы игроков: выдача базы, постройка моделей, напольные кнопки, визуал персонала

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Format = require(ReplicatedStorage.Shared.Format)

local WorldFolder = script.Parent.Parent.World
local World = require(WorldFolder.WorldBuilder)
local Library = require(WorldFolder.ModelLibrary)
local Kit = require(WorldFolder.ModelKit)
local Misc = require(WorldFolder.Models.Misc)
local Templates = require(WorldFolder.Templates)

local Sessions = require(script.Parent.Sessions)

type Session = Sessions.Session

local PlotService = {}

-- Обработчики задаются в Main: покупка по кнопке, VIP-кнопки, действия ProximityPrompt
PlotService.onBuy = function(_player: Player, _itemId: string) end
PlotService.onVip = function(_player: Player, _passKey: string) end
PlotService.promptHandlers = {} :: { [string]: (Session, Model, ProximityPrompt) -> () }

-- Места персонала на базе (x, z)
local STAFF_SPOTS: { [string]: { { number } } } = {
	robo_inspector = { { -4, 30 }, { 4, 21 } },
	robo_cleaner = { { -1.5, -8 }, { 1.5, -14 }, { -1.5, -19 } },
	agronomist = { { 3.8, 18 } },
	palletizer = { { 14.5, -16.5 }, { 21.5, -16.5 } },
	engineer = { { -3.8, -12 } },
	truck_driver = { { -3.8, 38.5 } },
	exchange_manager = { { 3.8, 6 } },
	technician = { { 3.8, 12.5 } },
	guard_dog = { { 4, 27 } },
	profit_counter = { { -3.8, 21 } },
	professor = { { -3.8, -29 } },
	holo_assistant = { { -3.8, -35 } },
	trade_agent = { { 3.8, -25 } },
	shuttle_pilot = { { 3.8, -37 } },
	vip_droid = { { 3.8, 30 } },
}

local function characterPlayer(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	while model do
		local player = Players:GetPlayerFromCharacter(model)
		if player then
			return player
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

function PlotService.assign(session: Session): boolean
	for _, info in ipairs(World.plots) do
		if not (info :: any).owner then
			(info :: any).owner = session.player
			session.plot = info
			info.folder:SetAttribute("OwnerUserId", session.player.UserId)
			info.sign.Text = "Base: " .. session.player.DisplayName
			session.player:SetAttribute("PlotIndex", info.index)
			return true
		end
	end
	return false
end

function PlotService.clear(session: Session)
	local info = session.plot
	if not info then
		return
	end
	info.items:ClearAllChildren()
	info.buttons:ClearAllChildren()
	info.staff:ClearAllChildren()
	info.bugs:ClearAllChildren()
	local vip = info.folder:FindFirstChild("Vip")
	if vip then
		vip:Destroy()
	end
end

function PlotService.release(session: Session)
	local info = session.plot
	if not info then
		return
	end
	PlotService.clear(session);
	(info :: any).owner = nil
	info.folder:SetAttribute("OwnerUserId", nil)
	info.sign.Text = "Free Base"
	session.plot = nil
end

function PlotService.itemCFrame(info, item): CFrame
	return World.localCFrame(info, item.pos[1], item.pos[2], item.rot, item.y)
end

function PlotService.findItem(session: Session, itemId: string): Model?
	local info = session.plot
	if not info then
		return nil
	end
	return info.items:FindFirstChild(itemId) :: Model?
end

function PlotService.bindPrompts(session: Session, model: Instance)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			local action = d:GetAttribute("Action")
			if action and action ~= "OpenMenu" then
				d.Triggered:Connect(function(player: Player)
					if player ~= session.player then
						return
					end
					local handler = PlotService.promptHandlers[action]
					if handler then
						handler(session, model :: Model, d)
					end
				end)
			end
		end
	end
end

function PlotService.buildItem(session: Session, item, animate: boolean): Model?
	local info = session.plot
	if not info then
		return nil
	end
	local old = info.items:FindFirstChild(item.id)
	if old then
		old:Destroy()
	end
	local model = Library.build(item, PlotService.itemCFrame(info, item), info.items)
	model:SetAttribute("Owner", session.player.UserId)
	if item.yield then
		model:SetAttribute("Yield", item.yield)
	end
	if animate then
		model:SetAttribute("BuiltAt", workspace:GetServerTimeNow())
	end
	PlotService.bindPrompts(session, model)
	return model
end

local lastWarn: { [Model]: number } = {}

function PlotService.createButton(session: Session, item)
	local info = session.plot
	local spot = item.button or item.pos
	local b = Kit.new("Button_" .. item.id, World.localCFrame(info, spot[1], spot[2]))
	local cost = Economy.itemCost(item, session.profile, Config)
	local pad = Misc.Button(b, item.name, Format.money(cost), "Item")
	b.model:SetAttribute("ItemId", item.id)
	b.model:SetAttribute("Cost", cost)
	b.model:SetAttribute("Owner", session.player.UserId)
	if item.desc then
		b.model:SetAttribute("Desc", item.desc)
	end
	b.model:AddTag("BuyButton")
	local model = b:finish(info.buttons)
	local busy = false
	pad.Touched:Connect(function(hit: BasePart)
		if busy or characterPlayer(hit) ~= session.player then
			return
		end
		busy = true
		if session.profile.cash + 1e-6 >= cost then
			PlotService.onBuy(session.player, item.id)
		elseif os.clock() - (lastWarn[model] or 0) > 3 then
			lastWarn[model] = os.clock()
			Sessions.notify(
				session.player,
				"Не хватает " .. Format.money(cost - session.profile.cash),
				"error"
			)
		end
		task.delay(0.5, function()
			busy = false
		end)
	end)
	model.Destroying:Connect(function()
		lastWarn[model] = nil
	end)
end

-- Показывает кнопки всех доступных к покупке построек
function PlotService.refreshButtons(session: Session)
	local info = session.plot
	if not info then
		return
	end
	local profile = session.profile
	local wanted = {}
	for _, item in ipairs(Config.Items.List) do
		if not item.prebuilt and not profile.owned[item.id] and Economy.requirementsMet(item, profile) then
			wanted[item.id] = item
		end
	end
	for _, child in ipairs(info.buttons:GetChildren()) do
		local id = child:GetAttribute("ItemId")
		if wanted[id] and child:GetAttribute("Cost") == Economy.itemCost(wanted[id], profile, Config) then
			wanted[id] = nil
		else
			child:Destroy()
		end
	end
	for _, item in ipairs(Config.Items.List) do
		if wanted[item.id] then
			PlotService.createButton(session, item)
		end
	end
end

function PlotService.buildVipPads(session: Session)
	local info = session.plot
	if not info then
		return
	end
	local old = info.folder:FindFirstChild("Vip")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Vip"
	folder.Parent = info.folder
	for i, pass in ipairs(Config.GamePasses.List) do
		local spot = Config.Game.VipPads[i]
		if spot then
			local b = Kit.new("Vip_" .. pass.key, World.localCFrame(info, spot[1], spot[2]))
			local owned = session.passes[pass.key] == true
			local pad =
				Misc.Button(b, pass.icon .. " " .. pass.name, if owned then "✓ Куплено" else "Robux", "Vip")
			b.model:SetAttribute("PassKey", pass.key)
			b:finish(folder)
			local busy = false
			pad.Touched:Connect(function(hit: BasePart)
				if busy or owned or characterPlayer(hit) ~= session.player then
					return
				end
				busy = true
				PlotService.onVip(session.player, pass.key)
				task.delay(4, function()
					busy = false
				end)
			end)
		end
	end
end

function PlotService.spawnStaff(session: Session, staff, n: number, animate: boolean?)
	local info = session.plot
	if not info then
		return
	end
	local color = Color3.fromRGB(staff.color[1], staff.color[2], staff.color[3])
	local b
	if staff.visual == "Drone" then
		-- дроны патрулируют над агро-блоком
		local k = staff.order * 5 + n
		local x = -32 + (k * 13) % 64
		local z = 18 + (k * 7) % 18
		b = Kit.new(staff.id .. "_" .. n, World.localCFrame(info, x, z, 0, 10 + (k % 3)))
		Misc.Drone(b, color, if staff.id == "drone_hexa" then 6 else 4)
		Templates.dress(b.model, "Drone", b.origin * CFrame.new(0, -1.6, 0), { tint = { White = color } })
		b:tag(b.model, "Hover", { Radius = 3 + (k % 4), Speed = 0.4 + (k % 5) * 0.08, Phase = k })
	else
		local spots = STAFF_SPOTS[staff.id] or { { 0, 0 } }
		local spot = spots[math.min(n, #spots)]
		local rot = if spot[1] < 0 then 90 else -90
		b = Kit.new(staff.id .. "_" .. n, World.localCFrame(info, spot[1], spot[2], rot))
		if staff.visual == "Robot" then
			Misc.Robot(b, color)
			Templates.dress(b.model, "Robot", b.origin, { tint = { Blue = color } })
			b:tag(b.model, "Roam", { Radius = 1.5, Speed = 0.5 + n * 0.1 })
		else
			Misc.StaffNpc(b, color, staff.name)
		end
	end
	b.model:SetAttribute("StaffId", staff.id)
	if animate then
		b.model:SetAttribute("BuiltAt", workspace:GetServerTimeNow())
	end
	b:finish(info.staff)
end

function PlotService.buildStaff(session: Session)
	local info = session.plot
	if not info then
		return
	end
	info.staff:ClearAllChildren()
	for _, staff in ipairs(Config.Staff.List) do
		for n = 1, session.profile.staff[staff.id] or 0 do
			PlotService.spawnStaff(session, staff, n, false)
		end
	end
end

-- Полная перестройка базы по профилю (вход в игру, Rebirth)
function PlotService.buildAll(session: Session)
	if not session.plot then
		return
	end
	PlotService.clear(session)
	for _, item in ipairs(Config.Items.List) do
		if session.profile.owned[item.id] then
			PlotService.buildItem(session, item, false)
		end
	end
	PlotService.buildStaff(session)
	PlotService.refreshButtons(session)
	PlotService.buildVipPads(session)
end

function PlotService.teleportHome(player: Player)
	local session = Sessions.get(player)
	local character = player.Character
	if not (session and session.plot and character) then
		return
	end
	character:PivotTo(session.plot.spawn)
end

return PlotService
