-- Окна меню: исследования семян (ГДД 193), найм персонала и дронов (194), подтверждение Rebirth (195),
-- звёздные технологии, магазин геймпассов, разбор дохода и отчёт об офлайн-доходе

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)
local State = require(script.Parent.Parent.State)
local Sound = require(script.Parent.Parent.Controllers.Sound)

local C = Theme.Colors
local New = Theme.New

local player = Players.LocalPlayer
local GameState = ReplicatedStorage:WaitForChild("GameState")

local Windows = {}

type Def = { title: string, icon: string, render: (ScrollingFrame) -> (), signature: (() -> string)? }

local current: { name: string, frame: Frame, list: ScrollingFrame, signature: string? }? = nil
local defs: { [string]: Def } = {}

-- Профиль-«тень» для расчёта цен на клиенте (те же формулы, что на сервере)
local function shadowProfile()
	local d = State.data
	if not d then
		return nil
	end
	return {
		cash = State.num("Cash"),
		owned = d.owned,
		varieties = d.varieties,
		activeVariety = d.activeVariety,
		staff = d.staff,
		starTech = d.starTech,
		rebirths = d.rebirths,
		stars = State.num("Stars"),
	}
end

local function itemName(id: string): string
	local item = Config.Items.ById[id]
	return if item then item.name else id
end

------------------------------------------------------------------
-- Компоненты
------------------------------------------------------------------
local function header(list: Instance, text: string, order: number)
	Theme.label({
		Size = UDim2.new(1, -8, 0, 30),
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = C.Gold,
		LayoutOrder = order,
		Parent = list,
	})
end

local function card(
	list: Instance,
	order: number,
	opts: {
		icon: string,
		iconColor: Color3?,
		title: string,
		subtitle: string,
		button: string?,
		buttonColor: Color3?,
		onClick: (() -> ())?,
		height: number?,
	}
)
	local frame = New("Frame", {
		Size = UDim2.new(1, -8, 0, opts.height or 78),
		BackgroundColor3 = C.Card,
		LayoutOrder = order,
		Parent = list,
	}, { Theme.corner(10) })
	New("Frame", {
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(62, 62),
		BackgroundColor3 = opts.iconColor or C.PanelLight,
		Parent = frame,
	}, {
		Theme.corner(10),
		Theme.label({ Size = UDim2.fromScale(1, 1), Text = opts.icon }),
	})
	Theme.label({
		Position = UDim2.fromOffset(80, 8),
		Size = UDim2.new(1, -250, 0, 24),
		Text = opts.title,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	local sub = Theme.label({
		Position = UDim2.fromOffset(80, 34),
		Size = UDim2.new(1, -250, 0, 38),
		Text = opts.subtitle,
		Font = Theme.FontRegular,
		TextColor3 = C.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Parent = frame,
	})
	New("UITextSizeConstraint", { MaxTextSize = 15, Parent = sub })
	if opts.button then
		local enabled = opts.onClick ~= nil
		local button = Theme.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(158, 44),
			BackgroundColor3 = opts.buttonColor or (if enabled then C.Button else C.ButtonOff),
			AutoButtonColor = enabled,
			Text = opts.button,
			Parent = frame,
		}, function()
			if opts.onClick then
				Sound.play("Click")
				opts.onClick()
			end
		end)
		Theme.padding(6).Parent = button
	end
	return frame
end

local function line(list: Instance, order: number, left: string, right: string, color: Color3?)
	local frame = New("Frame", {
		Size = UDim2.new(1, -8, 0, 32),
		BackgroundColor3 = C.Card,
		LayoutOrder = order,
		Parent = list,
	}, { Theme.corner(8) })
	Theme.label({
		Position = UDim2.fromOffset(12, 4),
		Size = UDim2.new(0.62, -12, 1, -8),
		Text = left,
		Font = Theme.FontRegular,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	Theme.label({
		Position = UDim2.new(0.62, 0, 0, 4),
		Size = UDim2.new(0.38, -12, 1, -8),
		Text = right,
		TextColor3 = color or C.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = frame,
	})
end

------------------------------------------------------------------
-- Исследования семян
------------------------------------------------------------------
defs.Research = {
	title = "Seed Research",
	icon = "🧬",
	signature = function()
		local p = shadowProfile()
		if not p then
			return ""
		end
		local parts = {}
		for _, v in ipairs(Config.Varieties) do
			table.insert(parts, if p.cash >= Economy.varietyCost(v, p, Config) then "1" else "0")
		end
		return table.concat(parts)
	end,
	render = function(list)
		local p = shadowProfile()
		if not p then
			return
		end
		local active = Economy.activeVariety(p, Config)
		header(list, "Now growing: " .. active.name .. (if p.activeVariety then "" else " (auto: most profitable)"), 0)
		if p.activeVariety then
			card(list, 1, {
				icon = "⚙",
				title = "Auto-Select Variety",
				subtitle = "Always plant the most profitable unlocked variety",
				button = "Enable Auto",
				onClick = function()
					Remotes.get("SelectVariety"):FireServer(nil)
				end,
			})
		end
		local wild = Config.Varieties[1]
		for i, v in ipairs(Config.Varieties) do
			local color = Color3.fromRGB(v.color[1], v.color[2], v.color[3])
			local value = v.price * v.growth / (wild.price * wild.growth)
			local subtitle =
				string.format("Yield %s · Field income ×%s vs. wild", Format.percent(v.growth), Format.number(value))
			local opts: any = {
				icon = "🥔",
				iconColor = color,
				title = string.format("%s — $%s/kg", v.name, Format.number(v.price)),
				subtitle = subtitle,
			}
			if p.varieties[v.id] then
				if active.id == v.id then
					opts.button = "✓ Growing"
					opts.buttonColor = Color3.fromRGB(150, 110, 20)
				else
					opts.button = "Plant"
					opts.buttonColor = C.Energy
					opts.onClick = function()
						Remotes.get("SelectVariety"):FireServer(v.id)
					end
				end
			elseif v.requires and not p.owned[v.requires] then
				opts.subtitle = subtitle .. "\n🔒 Requires: " .. itemName(v.requires)
				opts.button = "🔒 Locked"
				opts.buttonColor = Color3.fromRGB(120, 50, 50)
			else
				local cost = Economy.varietyCost(v, p, Config)
				opts.button = "Research " .. Format.money(cost)
				if p.cash >= cost then
					opts.onClick = function()
						Remotes.get("BuyResearch"):FireServer(v.id)
					end
				end
			end
			card(list, i + 1, opts)
		end
	end,
}

------------------------------------------------------------------
-- Персонал и дроны
------------------------------------------------------------------
local VISUAL_ICON = { Drone = "🚁", Robot = "🤖", Npc = "👷" }

local function staffEffect(s): string
	local parts = {}
	if s.yieldBoost then
		table.insert(parts, "+" .. Format.percent(s.yieldBoost) .. " yield")
	end
	if s.factoryAdd then
		table.insert(parts, "+" .. s.factoryAdd .. " workshop multiplier")
	end
	if s.factoryBoost then
		table.insert(parts, "+" .. Format.percent(s.factoryBoost) .. " workshop multiplier")
	end
	if s.powerGen then
		table.insert(parts, "+" .. s.powerGen .. " kW")
	end
	if s.powerBoost then
		table.insert(parts, "+" .. Format.percent(s.powerBoost) .. " generation")
	end
	if s.incomeBoost then
		table.insert(parts, "+" .. Format.percent(s.incomeBoost) .. " income")
	end
	if s.priceBoost then
		table.insert(parts, "+" .. Format.percent(s.priceBoost) .. " potato price")
	end
	if s.bugBoost then
		table.insert(parts, "+" .. Format.percent(s.bugBoost) .. " beetle reward")
	end
	return table.concat(parts, ", ") .. " per unit"
end

defs.Staff = {
	title = "Hire Staff & Drones",
	icon = "🤖",
	signature = function()
		local p = shadowProfile()
		if not p then
			return ""
		end
		local parts = {}
		for _, st in ipairs(Config.Staff.List) do
			table.insert(parts, if p.cash >= Economy.staffCost(st, p, Config) then "1" else "0")
		end
		return table.concat(parts)
	end,
	render = function(list)
		local p = shadowProfile()
		if not p then
			return
		end
		local passes = State.data.passes or {}
		for i, s in ipairs(Config.Staff.List) do
			local count = p.staff[s.id] or 0
			local opts: any = {
				icon = VISUAL_ICON[s.visual] or "👷",
				title = string.format("%s  (%d/%d)", s.name, count, s.max),
				subtitle = staffEffect(s),
			}
			if count >= s.max then
				opts.button = "✓ Maxed"
				opts.buttonColor = Color3.fromRGB(150, 110, 20)
			elseif not p.owned[s.requires] then
				opts.subtitle ..= "\n🔒 Requires: " .. itemName(s.requires)
				opts.button = "🔒 Locked"
				opts.buttonColor = Color3.fromRGB(120, 50, 50)
			elseif s.requiresPass and not passes[s.requiresPass] then
				opts.subtitle ..= "\n👑 VIP Farmers only"
				opts.button = "👑 VIP"
				opts.buttonColor = Color3.fromRGB(150, 110, 20)
				opts.onClick = function()
					Remotes.get("BuyPass"):FireServer(s.requiresPass)
				end
			else
				local cost = Economy.staffCost(s, p, Config)
				opts.button = "Hire " .. Format.money(cost)
				if p.cash >= cost then
					opts.onClick = function()
						Remotes.get("HireStaff"):FireServer(s.id)
					end
				end
			end
			card(list, i, opts)
		end
	end,
}

------------------------------------------------------------------
-- Звёздные технологии
------------------------------------------------------------------
defs.StarTech = {
	title = "Star Tech Tree",
	icon = "⭐",
	signature = function()
		return tostring(State.num("Stars"))
	end,
	render = function(list)
		local p = shadowProfile()
		if not p then
			return
		end
		header(list, string.format("You have ⭐ %s Potato Stars (earned through Rebirth)", Format.number(p.stars)), 0)
		for i, t in ipairs(Config.StarTech.List) do
			local level = p.starTech[t.id] or 0
			local opts: any = {
				icon = "⭐",
				iconColor = Color3.fromRGB(110, 80, 20),
				title = string.format("%s  (lvl %d/%d)", t.name, level, t.max),
				subtitle = t.desc,
			}
			if level >= t.max then
				opts.button = "✓ MAX"
				opts.buttonColor = Color3.fromRGB(150, 110, 20)
			else
				local cost = Config.StarTech.CostOf(t, level)
				opts.button = "⭐ " .. Format.number(cost)
				if p.stars >= cost then
					opts.buttonColor = Color3.fromRGB(170, 120, 20)
					opts.onClick = function()
						Remotes.get("BuyStarTech"):FireServer(t.id)
					end
				end
			end
			card(list, i, opts)
		end
	end,
}

------------------------------------------------------------------
-- Rebirth
------------------------------------------------------------------
defs.Rebirth = {
	title = "Confirm Rebirth",
	icon = "🚀",
	signature = function()
		local d = State.data
		return if d and State.num("Cash") >= d.rebirthCost then "1" else "0"
	end,
	render = function(list)
		local d = State.data
		if not d then
			return
		end
		local cash = State.num("Cash")
		local hasShuttle = d.owned.shuttle == true
		local enough = cash >= d.rebirthCost
		header(list, string.format("Rebirth #%d", d.rebirths + 1), 0)
		line(
			list,
			1,
			"All-income multiplier",
			string.format("x%s → x%s", Format.number(State.num("RebirthMult")), Format.number(d.nextMult)),
			C.Gold
		)
		line(list, 2, "Potato Stars", "+" .. Format.number(d.nextStars) .. " ⭐", C.Star)
		line(list, 3, "Required savings", Format.money(d.rebirthCost), if enough then C.Cash else C.Danger)
		line(
			list,
			4,
			"“Galactic Potato” Export Shuttle",
			if hasShuttle then "✓ built" else "✗ not built",
			if hasShuttle then C.Cash else C.Danger
		)
		local warn = Theme.label({
			Size = UDim2.new(1, -8, 0, 54),
			Text = "Resets: cash, buildings, varieties and staff.\nKept: Stars, star tech and the Rebirth multiplier.",
			Font = Theme.FontRegular,
			TextColor3 = C.Muted,
			TextWrapped = true,
			LayoutOrder = 5,
			Parent = list,
		})
		New("UITextSizeConstraint", { MaxTextSize = 16, Parent = warn })
		local ready = hasShuttle and enough
		local button = Theme.button({
			Size = UDim2.new(1, -8, 0, 56),
			BackgroundColor3 = if ready then C.Purple else C.ButtonOff,
			AutoButtonColor = ready,
			Text = if ready then "🚀 LAUNCH REBIRTH" else "🔒 Requirements not met",
			LayoutOrder = 6,
			Parent = list,
		}, function()
			if ready then
				Remotes.get("Rebirth"):FireServer()
				Windows.close()
			end
		end)
		Theme.padding(10).Parent = button
	end,
}

------------------------------------------------------------------
-- Магазин геймпассов
------------------------------------------------------------------
defs.Shop = {
	title = "Shop",
	icon = "💎",
	signature = function()
		return ""
	end,
	render = function(list)
		local passes = (State.data and State.data.passes) or {}
		for i, pass in ipairs(Config.GamePasses.List) do
			local owned = passes[pass.key] == true
			local price = GameState:GetAttribute("PassPrice_" .. pass.key)
			card(list, i, {
				icon = pass.icon,
				iconColor = Color3.fromRGB(110, 80, 20),
				title = pass.name,
				subtitle = pass.desc,
				button = if owned then "✓ Owned" else (if price then "R$ " .. price else "Buy"),
				buttonColor = if owned then Color3.fromRGB(150, 110, 20) else Color3.fromRGB(0, 160, 90),
				onClick = if owned
					then nil
					else function()
						if pass.id > 0 then
							MarketplaceService:PromptGamePassPurchase(player, pass.id)
						else
							Remotes.get("BuyPass"):FireServer(pass.key)
						end
					end,
			})
		end
	end,
}

------------------------------------------------------------------
-- Разбор дохода по формуле ГДД 2.1
------------------------------------------------------------------
defs.Stats = {
	title = "Factory Income",
	icon = "📊",
	render = function(list)
		local d = State.data
		if not d then
			return
		end
		local variety
		for _, v in ipairs(Config.Varieties) do
			if v.id == State.attr("Variety") then
				variety = v
			end
		end
		local s = d.stats
		header(list, "Income = Yield × Price × Workshops × Energy × Rebirth × Bonuses", 0)
		line(
			list,
			1,
			string.format(
				"🌱 Yield (%d fields, bonus +%s, variety %s)",
				s.plots,
				Format.percent(s.yieldBoost),
				if variety then Format.percent(variety.growth) else "?"
			),
			Format.mass(State.num("YieldKg")) .. "/s"
		)
		line(
			list,
			2,
			"🥔 Price of “" .. (if variety then variety.name else "?") .. "”",
			Format.money(State.num("Price")) .. "/kg"
		)
		line(list, 3, "🏭 Total workshop multiplier", "x" .. Format.number(State.num("FactoryMult")))
		local over = State.attr("Overloaded") == true
		line(
			list,
			4,
			string.format(
				"⚡ Energy %s / %s kW",
				Format.number(State.num("EnergyUse")),
				Format.number(State.num("EnergyGen"))
			),
			if over then "x0.5 OVERLOAD" else "x1",
			if over then C.Danger else C.Energy
		)
		line(list, 5, "🚀 Rebirth multiplier", "x" .. Format.number(State.num("RebirthMult")), C.Gold)
		line(
			list,
			6,
			"🎁 Bonuses (buildings, staff, stars, game passes, boom)",
			"x" .. string.format("%.2f", State.num("BonusMult"))
		)
		line(list, 7, "💰 Total", "+" .. Format.money(State.num("Income")) .. "/s", C.Cash)
		header(list, "Statistics", 8)
		line(list, 9, "Total earned", Format.money(d.totalEarned or 0))
		line(list, 10, "Total potatoes harvested", Format.mass(State.num("TotalKg")))
		line(
			list,
			11,
			"Offline income",
			string.format("%s of income for up to %d h", Format.percent(s.offlineRate), s.offlineHours)
		)
		line(list, 12, "Rebirth", tostring(d.rebirths))
	end,
}

------------------------------------------------------------------
-- Каркас окна
------------------------------------------------------------------
function Windows.close()
	if current then
		current.frame:Destroy()
		current = nil
	end
end

function Windows.refresh()
	if not current then
		return
	end
	local signature = defs[current.name].signature
	current.signature = if signature then signature() else nil
	local list = current.list
	for _, child in ipairs(list:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
	defs[current.name].render(list)
end

function Windows.open(name: string)
	if current and current.name == name then
		Windows.close()
		return
	end
	Windows.close()
	local def = defs[name]
	if not def then
		return
	end
	local frame = New("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromOffset(700, 500),
		BackgroundColor3 = C.Panel,
		ZIndex = 20,
		Parent = Root.gui,
	}, { Theme.corner(16), Theme.stroke(C.Stroke, 2, 0.75) })
	Theme.label({
		Position = UDim2.fromOffset(18, 10),
		Size = UDim2.new(1, -90, 0, 38),
		Text = def.icon .. "  " .. def.title,
		Font = Theme.FontBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	Theme.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 10),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = C.Danger,
		Text = "✕",
		Parent = frame,
	}, Windows.close)
	local list = New("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 58),
		Size = UDim2.new(1, -24, 1, -70),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = frame,
	}, {
		New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
	})
	current = { name = name, frame = frame, list = list }
	local scale = New("UIScale", { Scale = 0.85, Parent = frame })
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
	Sound.play("Click")
	Windows.refresh()
end

-- Отчёт об офлайн-доходе
function Windows.offline(seconds: number, amount: number)
	local frame = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(460, 220),
		BackgroundColor3 = C.Panel,
		ZIndex = 30,
		Parent = Root.gui,
	}, { Theme.corner(16), Theme.stroke(C.Gold, 2, 0.4) })
	Theme.label({
		Position = UDim2.fromOffset(16, 14),
		Size = UDim2.new(1, -32, 0, 40),
		Text = "🌙 Welcome back, tycoon!",
		Font = Theme.FontBlack,
		TextColor3 = C.Gold,
		Parent = frame,
	})
	Theme.label({
		Position = UDim2.fromOffset(16, 62),
		Size = UDim2.new(1, -32, 0, 70),
		Text = string.format(
			"While you were away (%s), your farm earned\n%s",
			Format.time(seconds),
			Format.money(amount)
		),
		TextWrapped = true,
		Parent = frame,
	})
	Theme.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(200, 48),
		Text = "Collect",
		Parent = frame,
	}, function()
		Sound.play("Cash")
		frame:Destroy()
	end)
end

function Windows.init()
	local pending = false
	local function schedule(force: boolean)
		if pending or not current then
			return
		end
		-- при изменении денег перерисовываем, только если сменилась доступность кнопок
		local signature = defs[current.name].signature
		if not force and signature and signature() == current.signature then
			return
		end
		pending = true
		task.delay(0.25, function()
			pending = false
			Windows.refresh()
		end)
	end
	State.Changed:Connect(function()
		schedule(true)
	end)
	State.onAttr({ "Cash", "Stars", "Income", "Overloaded" }, function()
		schedule(false)
	end)
	Remotes.get("Offline").OnClientEvent:Connect(function(data)
		Windows.offline(data.seconds, data.amount)
	end)
end

return Windows
