-- Верхний HUD-бар (ГДД 192): баланс, прирост $/сек, энергия, звёзды, этап.
-- Плюс цель этапа, таймеры событий, мешок картошки (Этап 1) и боковое меню.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)
local State = require(script.Parent.Parent.State)
local Sound = require(script.Parent.Parent.Controllers.Sound)

local C = Theme.Colors
local New = Theme.New

local player = Players.LocalPlayer
local GameState = ReplicatedStorage:WaitForChild("GameState")

local Hud = {}

Hud.onMenu = function(_name: string) end

local function pill(parent: Instance, width: number, color: Color3, order: number): (Frame, TextLabel)
	local frame = New("Frame", {
		Size = UDim2.fromOffset(width, 46),
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.1,
		LayoutOrder = order,
		Parent = parent,
	}, { Theme.corner(12), Theme.stroke(color, 2, 0.35) })
	local label = Theme.label({
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -20, 1, -12),
		TextColor3 = color,
		Font = Theme.FontBlack,
		Parent = frame,
	})
	return frame, label
end

function Hud.init()
	local bar = New("Frame", {
		Name = "TopBar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(760, 46),
		BackgroundTransparency = 1,
		Parent = Root.gui,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
	})
	local _, cashLabel = pill(bar, 190, C.Cash, 1)
	local incomeFrame, incomeLabel = pill(bar, 150, C.Cash, 2)
	local energyFrame, energyLabel = pill(bar, 170, C.Energy, 3)
	local _, starsLabel = pill(bar, 100, C.Star, 4)
	local _, stageLabel = pill(bar, 110, C.Accent, 5)

	-- клик по доходу открывает разбор формулы
	local incomeButton = New("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		Parent = incomeFrame,
	})
	incomeButton.Activated:Connect(function()
		Hud.onMenu("Stats")
	end)

	local goal = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 60),
		Size = UDim2.fromOffset(700, 22),
		Font = Theme.Font,
		TextColor3 = Color3.fromRGB(255, 240, 200),
		TextStrokeTransparency = 0.4,
		Parent = Root.gui,
	})
	local eventLine = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 86),
		Size = UDim2.fromOffset(700, 26),
		Font = Theme.FontBlack,
		TextColor3 = C.Accent,
		TextStrokeTransparency = 0.3,
		Parent = Root.gui,
	})
	local timers = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 114),
		Size = UDim2.fromOffset(500, 18),
		Font = Theme.FontRegular,
		TextColor3 = C.Muted,
		TextStrokeTransparency = 0.5,
		Parent = Root.gui,
	})

	-- мешок картошки (Этап 1)
	local bag = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -96),
		Size = UDim2.fromOffset(340, 58),
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.1,
		Parent = Root.gui,
	}, { Theme.corner(12), Theme.stroke(C.Accent, 2, 0.4) })
	local bagFill = New("Frame", {
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(0, 0, 0, 22),
		BackgroundColor3 = Color3.fromRGB(190, 140, 70),
		Parent = bag,
	}, { Theme.corner(8) })
	local bagLabel = Theme.label({
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(1, -12, 0, 22),
		Font = Theme.FontBlack,
		ZIndex = 2,
		Parent = bag,
	})
	Theme.label({
		Position = UDim2.fromOffset(6, 32),
		Size = UDim2.new(1, -12, 0, 20),
		Font = Theme.FontRegular,
		TextColor3 = C.Muted,
		Text = "Click ripe bushes with the shovel and sell the harvest to the buyer",
		Parent = bag,
	})

	-- боковое меню
	local menu = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(76, 520),
		BackgroundTransparency = 1,
		Parent = Root.gui,
	}, {
		New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})
	local MENU = {
		{ "Research", "🧬", "Varieties" },
		{ "Staff", "🤖", "Staff" },
		{ "StarTech", "⭐", "Stars" },
		{ "Rebirth", "🚀", "Rebirth" },
		{ "Shop", "💎", "Shop" },
		{ "Stats", "📊", "Income" },
		{ "Home", "🏠", "Home" },
	}
	for i, entry in ipairs(MENU) do
		local button = Theme.button({
			Size = UDim2.fromOffset(76, 58),
			BackgroundColor3 = C.Panel,
			BackgroundTransparency = 0.1,
			LayoutOrder = i,
			Parent = menu,
		}, function()
			Hud.onMenu(entry[1])
		end)
		Theme.stroke(C.Stroke, 1.5, 0.8).Parent = button
		Theme.label({
			Size = UDim2.new(1, 0, 0.62, 0),
			Text = entry[2],
			Parent = button,
		})
		Theme.label({
			Position = UDim2.fromScale(0, 0.62),
			Size = UDim2.new(1, 0, 0.32, 0),
			Text = entry[3],
			Font = Theme.Font,
			TextColor3 = C.Muted,
			Parent = button,
		})
	end

	-- музыка вкл/выкл
	local musicButton
	musicButton = Theme.button({
		Size = UDim2.fromOffset(76, 44),
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.1,
		LayoutOrder = #MENU + 1,
		Text = "🎵 Music",
		TextScaled = false,
		TextSize = 15,
		Parent = menu,
	}, function()
		local on = not Sound.musicEnabled()
		Sound.play("Click")
		Sound.setMusic(on)
		musicButton.Text = if on then "🎵 Music" else "🔇 Music"
		musicButton.TextColor3 = if on then Color3.new(1, 1, 1) else C.Muted
	end)
	Theme.stroke(C.Stroke, 1.5, 0.8).Parent = musicButton

	local function refresh()
		local cash = State.num("Cash")
		cashLabel.Text = "💰 " .. Format.money(cash)
		local manual = State.attr("Manual") == true
		if manual then
			incomeLabel.Text = "🥔 manual harvest"
			incomeLabel.TextColor3 = C.Muted
		else
			incomeLabel.Text = "+" .. Format.money(State.num("Income")) .. "/s"
			incomeLabel.TextColor3 = C.Cash
		end
		local gen, use = State.num("EnergyGen"), State.num("EnergyUse")
		local over = State.attr("Overloaded") == true
		energyLabel.Text = string.format("⚡ %s/%s kW", Format.number(use), Format.number(gen))
		energyLabel.TextColor3 = if over then C.Danger else C.Energy
		local stroke = energyFrame:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = if over then C.Danger else C.Energy
		end
		starsLabel.Text = "⭐ " .. Format.number(State.num("Stars"))
		local stage = math.max(1, State.num("Stage"))
		stageLabel.Text = "Stage " .. stage

		local info = Config.Game.Stages[stage]
		local text = if info then "🎯 " .. info.goal else ""
		if over then
			text = "⚠ GRID OVERLOAD: income -50%! Buy a generator ⚡"
			goal.TextColor3 = C.Danger
		else
			goal.TextColor3 = Color3.fromRGB(255, 240, 200)
		end
		goal.Text = text

		bag.Visible = manual
		local capacity = math.max(1, State.num("BagCapacity"))
		local count = State.num("Bag")
		bagLabel.Text = string.format("🥔 Sack: %d / %d", count, capacity)
		bagFill.Size = UDim2.new(math.clamp(count / capacity, 0, 1), -12, 0, 22)
		bagFill.BackgroundColor3 = if count >= capacity then C.Danger else Color3.fromRGB(190, 140, 70)
	end

	State.onAttr(
		{ "Cash", "Income", "EnergyGen", "EnergyUse", "Overloaded", "Stars", "Stage", "Manual", "Bag", "BagCapacity" },
		refresh
	)
	refresh()

	-- таймеры событий
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then
			return
		end
		acc = 0
		local now = workspace:GetServerTimeNow()
		local bugsEnd = GameState:GetAttribute("BugsEndsAt") or 0
		local boomEnd = GameState:GetAttribute("BoomEndsAt") or 0
		local lines = {}
		if bugsEnd > now and player:GetAttribute("BugsCaught") ~= nil then
			table.insert(
				lines,
				string.format(
					"🪲 Beetles: %d / %d — %s",
					player:GetAttribute("BugsCaught") or 0,
					Config.Game.Events.Bugs.Goal,
					Format.time(bugsEnd - now)
				)
			)
		end
		if boomEnd > now then
			table.insert(lines, "📈 MARKET BOOM x3 — " .. Format.time(boomEnd - now))
		end
		eventLine.Text = table.concat(lines, "   ")
		local nextBugs = (GameState:GetAttribute("NextBugsAt") or 0) - now
		local nextBoom = (GameState:GetAttribute("NextBoomAt") or 0) - now
		local parts = {}
		if nextBugs > 0 and nextBugs < 7200 then
			table.insert(parts, "🪲 beetles in " .. Format.time(nextBugs))
		end
		if nextBoom > 0 and nextBoom < 7200 then
			table.insert(parts, "📈 boom in " .. Format.time(nextBoom))
		end
		timers.Text = table.concat(parts, "  ·  ")
	end)
end

return Hud
