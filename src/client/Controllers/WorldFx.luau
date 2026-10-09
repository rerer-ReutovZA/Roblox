-- Живой мир базы: цвет кнопок покупки, анимация постройки, «+$» над полями,
-- искры при перегрузке сети, фоновые звуки цехов, фильтр подсказок чужих баз

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Format = require(ReplicatedStorage.Shared.Format)

local Effects = require(script.Parent.Effects)
local Sound = require(script.Parent.Sound)
local State = require(script.Parent.Parent.State)

local player = Players.LocalPlayer

local WorldFx = {}

-- Открытие меню через ProximityPrompt (офис, лаборатория, терминал звёзд, шаттл)
WorldFx.openMenu = function(_name: string) end

local GREEN = Color3.fromRGB(60, 210, 90)
local RED = Color3.fromRGB(215, 60, 55)
local GREY = Color3.fromRGB(120, 120, 125)

local function myPlot(): Instance?
	local plots = workspace:FindFirstChild("Plots")
	if not plots then
		return nil
	end
	for _, plot in ipairs(plots:GetChildren()) do
		if plot:GetAttribute("OwnerUserId") == player.UserId then
			return plot
		end
	end
	return nil
end
WorldFx.myPlot = myPlot

local function plotOf(inst: Instance): Instance?
	local plots = workspace:FindFirstChild("Plots")
	local node = inst
	while node and node.Parent do
		if node.Parent == plots then
			return node
		end
		node = node.Parent
	end
	return nil
end

------------------------------------------------------------------
-- Кнопки покупки
------------------------------------------------------------------
local function paintButton(model: Instance)
	local pad = model:FindFirstChild("Pad", true) :: BasePart?
	if not pad then
		return
	end
	local info = pad:FindFirstChild("Info") :: BillboardGui?
	local mine = model:GetAttribute("Owner") == player.UserId
	if not mine then
		pad.Color = GREY
		if info then
			info.Enabled = false
		end
		return
	end
	local cost = model:GetAttribute("Cost") or 0
	local affordable = State.num("Cash") + 1e-6 >= cost
	pad.Color = if affordable then GREEN else RED
	if info then
		info.Enabled = true
		local price = info:FindFirstChild("Price") :: TextLabel?
		if price then
			price.TextColor3 = if affordable then GREEN else Color3.fromRGB(255, 120, 110)
			price.Text = if affordable then Format.money(cost) else "🔒 " .. Format.money(cost)
		end
	end
end

local function paintAll()
	for _, model in ipairs(CollectionService:GetTagged("BuyButton")) do
		paintButton(model)
	end
end

------------------------------------------------------------------
-- Подсказки ProximityPrompt только на своей базе
------------------------------------------------------------------
local function filterPrompt(prompt: ProximityPrompt)
	local plot = plotOf(prompt)
	if not plot then
		return
	end
	local function apply()
		if plot:GetAttribute("OwnerUserId") ~= player.UserId and prompt.Enabled then
			prompt.Enabled = false
		end
	end
	apply()
	prompt:GetPropertyChangedSignal("Enabled"):Connect(apply)
end

------------------------------------------------------------------
-- Анимация появления постройки (прозрачность 1 → исходная)
------------------------------------------------------------------
local function buildAnimation(model: Model)
	local builtAt = model:GetAttribute("BuiltAt")
	if not builtAt or workspace:GetServerTimeNow() - builtAt > 3 then
		return
	end
	local parts = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 1 then
			table.insert(parts, { part = d, transparency = d.Transparency })
			d.Transparency = 1
		end
	end
	local pivot = model:GetPivot().Position
	Effects.float(pivot + Vector3.new(0, 4, 0), "🔨", Color3.new(1, 1, 1), 1.2)
	for i, rec in ipairs(parts) do
		local delayTime = math.min(i * 0.012, 0.6)
		task.delay(delayTime, function()
			if rec.part.Parent then
				TweenService:Create(rec.part, TweenInfo.new(0.35), { Transparency = rec.transparency }):Play()
			end
		end)
	end
end

------------------------------------------------------------------
-- Всплывающие «+$» над полями (ГДД 205)
------------------------------------------------------------------
local function incomeFloats()
	local income = State.num("Income")
	if income <= 0 then
		return
	end
	local plot = myPlot()
	local items = plot and plot:FindFirstChild("Items")
	if not items then
		return
	end
	local sources, total = {}, 0
	for _, model in ipairs(items:GetChildren()) do
		local y = model:GetAttribute("Yield")
		if y then
			table.insert(sources, model)
			total += y
		end
	end
	if #sources == 0 then
		return
	end
	local model = sources[math.random(1, #sources)]
	local share = income * 2 * (model:GetAttribute("Yield") / total) * #sources / 3
	Effects.float(model:GetPivot().Position + Vector3.new(0, 3, 0), "+" .. Format.money(share))
end

------------------------------------------------------------------
-- Перегрузка сети: сирена и искры над генераторами (ГДД 202, 207)
------------------------------------------------------------------
local sparks: { Instance } = {}

local function setOverload(on: boolean)
	for _, s in ipairs(sparks) do
		s:Destroy()
	end
	table.clear(sparks)
	if not on then
		return
	end
	Sound.play("Alarm")
	task.delay(0.4, Sound.play, "Zap")
	local plot = myPlot()
	local items = plot and plot:FindFirstChild("Items")
	if not items then
		return
	end
	for _, model in ipairs(items:GetChildren()) do
		local id = model.Name
		if id == "substation" or string.find(id, "gen_") or string.find(id, "diesel") or id == "breaker" then
			local p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.Transparency = 1
			p.Size = Vector3.new(1, 1, 1)
			p.Position = (model :: Model):GetPivot().Position + Vector3.new(0, 3, 0)
			local e = Instance.new("ParticleEmitter")
			e.Color = ColorSequence.new(Color3.fromRGB(255, 240, 120), Color3.fromRGB(120, 200, 255))
			e.LightEmission = 1
			e.Size = NumberSequence.new(0.25, 0)
			e.Speed = NumberRange.new(8, 14)
			e.SpreadAngle = Vector2.new(180, 180)
			e.Lifetime = NumberRange.new(0.15, 0.35)
			e.Rate = 40
			e.Acceleration = Vector3.new(0, -30, 0)
			e.Parent = p
			p.Parent = workspace:FindFirstChild("ClientFx") or workspace
			table.insert(sparks, p)
		end
	end
end

------------------------------------------------------------------
-- Фоновые звуки цехов
------------------------------------------------------------------
local function ambient(model: Instance)
	local key = model:GetAttribute("Sound")
	if key and model:IsA("Model") then
		local part = model:FindFirstChildWhichIsA("BasePart", true)
		if part then
			-- источник звука — центр постройки, а не случайная деталь
			local emitter = Instance.new("Attachment")
			emitter.Name = "SoundEmitter"
			emitter.Parent = part
			emitter.WorldPosition = model:GetPivot().Position + Vector3.new(0, 2, 0)
			Sound.attachLoop(key, emitter)
		end
	end
end

function WorldFx.init()
	CollectionService:GetInstanceAddedSignal("BuyButton"):Connect(function(model)
		task.defer(paintButton, model)
	end)
	State.onAttr({ "Cash" }, paintAll)
	paintAll()

	local plots = workspace:WaitForChild("Plots")
	for _, d in ipairs(plots:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			filterPrompt(d)
		end
	end
	plots.DescendantAdded:Connect(function(d)
		if d:IsA("ProximityPrompt") then
			task.defer(filterPrompt, d)
		elseif d:IsA("Model") and d:GetAttribute("BuiltAt") then
			task.defer(buildAnimation, d)
		end
		if d:IsA("Model") then
			task.defer(ambient, d)
		end
	end)
	for _, plot in ipairs(plots:GetChildren()) do
		plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
			for _, d in ipairs(plot:GetDescendants()) do
				if d:IsA("ProximityPrompt") then
					filterPrompt(d)
				end
			end
			paintAll()
		end)
	end

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt:GetAttribute("Action") == "OpenMenu" then
			local plot = plotOf(prompt)
			if not plot or plot:GetAttribute("OwnerUserId") == player.UserId then
				WorldFx.openMenu(prompt:GetAttribute("Menu"))
			end
		end
	end)

	State.onAttr({ "Overloaded" }, function()
		setOverload(State.attr("Overloaded") == true)
	end)

	task.spawn(function()
		while true do
			task.wait(1.6)
			incomeFloats()
		end
	end)
end

return WorldFx
