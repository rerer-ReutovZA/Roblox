-- Визуальные эффекты (ГДД, ассеты 205–210): всплывающие «+$», золотое сияние, искры перегрузки,
-- конфетти Rebirth, дым и пламя шаттла, лопание жуков, баннер нового этапа

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Root = require(script.Parent.Parent.UI.Root)
local Theme = require(script.Parent.Parent.UI.Theme)
local Sound = require(script.Parent.Sound)

local player = Players.LocalPlayer

local Effects = {}

local fxFolder = Instance.new("Folder")
fxFolder.Name = "ClientFx"
fxFolder.Parent = workspace

local function anchorPart(position: Vector3): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Position = position
	p.Parent = fxFolder
	return p
end

-- Всплывающий текст над точкой
function Effects.float(position: Vector3, text: string, color: Color3?, size: number?)
	local part = anchorPart(position)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160 * (size or 1), 40 * (size or 1))
	gui.StudsOffset = Vector3.new(0, 1, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color or Theme.Colors.Cash
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui
	local info = TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(gui, info, { StudsOffset = Vector3.new(0, 4.5, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(1.4, function()
		part:Destroy()
	end)
end

-- Подпрыгивающие клубни при копке
local function potatoPop(position: Vector3, count: number, color: Color3?)
	for _ = 1, math.min(count, 6) do
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(0.6, 0.6, 0.6)
		p.Color = color or Color3.fromRGB(190, 145, 85)
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Anchored = true
		p.Position = position + Vector3.new(0, 1.5, 0)
		p.Parent = fxFolder
		local target = p.Position
			+ Vector3.new(math.random(-20, 20) / 10, math.random(25, 40) / 10, math.random(-20, 20) / 10)
		TweenService
			:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = target })
			:Play()
		task.delay(0.35, function()
			TweenService:Create(p, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = target + Vector3.new(0, -3, 0),
				Transparency = 1,
			}):Play()
		end)
		task.delay(0.8, function()
			p:Destroy()
		end)
	end
end

-- Золотое сияние вокруг грядки
function Effects.glow(target: Instance?, seconds: number)
	if not (target and target:IsA("Model")) then
		return
	end
	local pivot = (target :: Model):GetPivot().Position
	local part = anchorPart(pivot + Vector3.new(0, 1.5, 0))
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Color3.fromRGB(255, 210, 60)
	sparkles.Parent = part
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 210, 80)
	light.Range = 14
	light.Brightness = 3
	light.Parent = part
	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(255, 210, 60)
	hl.FillTransparency = 0.6
	hl.OutlineColor = Color3.fromRGB(255, 240, 150)
	hl.Adornee = target
	hl.Parent = part
	task.delay(seconds, function()
		part:Destroy()
	end)
end

-- Конфетти на весь экран
function Effects.confetti(big: boolean?)
	local colors = {
		Color3.fromRGB(255, 205, 60),
		Color3.fromRGB(255, 90, 90),
		Color3.fromRGB(90, 200, 255),
		Color3.fromRGB(120, 230, 110),
		Color3.fromRGB(200, 120, 255),
	}
	local count = if big then 140 else 60
	for i = 1, count do
		local piece = Instance.new("Frame")
		piece.BorderSizePixel = 0
		piece.BackgroundColor3 = colors[(i % #colors) + 1]
		piece.Size = UDim2.fromOffset(math.random(8, 14), math.random(14, 22))
		piece.Position = UDim2.new(math.random(), 0, 0, -30)
		piece.Rotation = math.random(0, 360)
		piece.ZIndex = 60
		piece.Parent = Root.fx
		local duration = math.random(18, 34) / 10
		TweenService:Create(piece, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(piece.Position.X.Scale + (math.random() - 0.5) * 0.3, 0, 1.1, 0),
			Rotation = piece.Rotation + math.random(-540, 540),
		}):Play()
		task.delay(duration, function()
			piece:Destroy()
		end)
	end
end

-- Баннер посередине экрана
function Effects.banner(title: string, subtitle: string?, color: Color3?)
	local frame = Theme.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.32),
		Size = UDim2.fromOffset(620, 120),
		BackgroundTransparency = 1,
		ZIndex = 55,
		Parent = Root.fx,
	})
	local t = Theme.label({
		Size = UDim2.fromScale(1, 0.62),
		Text = title,
		Font = Theme.FontBlack,
		TextColor3 = color or Theme.Colors.Gold,
		TextStrokeTransparency = 0.1,
		ZIndex = 56,
		Parent = frame,
	})
	local s = Theme.label({
		Position = UDim2.fromScale(0, 0.64),
		Size = UDim2.fromScale(1, 0.32),
		Text = subtitle or "",
		TextStrokeTransparency = 0.2,
		ZIndex = 56,
		Parent = frame,
	})
	local scale = Theme.New("UIScale", { Scale = 0.4, Parent = frame })
	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
	task.delay(3, function()
		local info = TweenInfo.new(0.5)
		TweenService:Create(t, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		TweenService:Create(s, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.wait(0.55)
		frame:Destroy()
	end)
end

-- Брызги при лопании жука
local function splat(position: Vector3, dead: boolean)
	local part = anchorPart(position + Vector3.new(0, 0.6, 0))
	local p = Instance.new("ParticleEmitter")
	p.Color = ColorSequence.new(if dead then Color3.fromRGB(120, 220, 60) else Color3.fromRGB(255, 220, 120))
	p.Size = NumberSequence.new(0.5, 0)
	p.Speed = NumberRange.new(6, 12)
	p.SpreadAngle = Vector2.new(180, 180)
	p.Lifetime = NumberRange.new(0.3, 0.6)
	p.Rate = 0
	p.Parent = part
	p:Emit(if dead then 25 else 8)
	task.delay(1, function()
		part:Destroy()
	end)
end

-- Старт шаттла: огонь, дым и подъём (виден всем)
local function launch(plotIndex: number)
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot" .. plotIndex)
	local shuttle = plot and plot:FindFirstChild("Items") and plot.Items:FindFirstChild("shuttle")
	if not shuttle then
		return
	end
	local stack = shuttle:FindFirstChild("Stack") :: Model?
	if not stack then
		return
	end
	for _, d in ipairs(stack:GetDescendants()) do
		if d:IsA("Fire") or d:IsA("Smoke") then
			d.Enabled = true
		elseif d:IsA("BasePart") and d:GetAttribute("LaunchOnly") then
			d.Transparency = 0 -- пламя модели из Blender
		end
	end
	if plot:GetAttribute("OwnerUserId") == player.UserId then
		Sound.play("Rocket")
	end
	local base = stack:GetPivot()
	local started = os.clock()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local t = os.clock() - started
		if not stack.Parent or t > 5 then
			connection:Disconnect()
			return
		end
		local lift = if t < 1 then t * 0.3 else 0.3 + (t - 1) ^ 2 * 9
		local shake = if t < 1 then (math.random() - 0.5) * 0.2 else 0
		stack:PivotTo(base * CFrame.new(shake, lift, shake))
	end)
end

function Effects.handle(data)
	local kind = data.type
	if kind == "Float" then
		Effects.float(data.position, data.text, data.color)
	elseif kind == "Dig" then
		potatoPop(data.position, data.amount)
		Effects.float(
			data.position + Vector3.new(0, 2, 0),
			"+" .. data.amount .. " 🥔",
			Color3.fromRGB(255, 220, 150)
		)
		Sound.play("Dig", 0.2)
	elseif kind == "Sell" then
		if data.position then
			Effects.float(
				data.position + Vector3.new(0, 5, 0),
				"+" .. Format.money(data.amount),
				Theme.Colors.Cash,
				1.4
			)
		end
		Sound.play("Dump")
		Sound.play("Cash")
	elseif kind == "Golden" then
		local target = data.target
		local pos = if target and target:IsA("Model") then target:GetPivot().Position else nil
		if pos then
			Effects.float(pos + Vector3.new(0, 4, 0), "✨ +" .. Format.money(data.amount), Theme.Colors.Gold, 1.4)
			potatoPop(pos, 3, Color3.fromRGB(255, 205, 50))
		end
		Effects.glow(target, data.glow or 6)
		Sound.play("Golden")
	elseif kind == "Confetti" then
		Effects.confetti(data.big)
		Sound.play("Cash")
	elseif kind == "Launch" then
		launch(data.plotIndex)
	elseif kind == "Squash" then
		splat(data.position, data.dead)
		Sound.play("Squash", 0.3)
	elseif kind == "Purchase" then
		Sound.play("Build")
		Sound.play("Cash")
	elseif kind == "Stage" then
		local stage = Config.Game.Stages[data.stage]
		if stage then
			Effects.banner("ЭТАП " .. data.stage, stage.name)
			Effects.confetti(false)
		end
	elseif kind == "Sound" then
		Sound.play(data.sound)
	end
end

function Effects.init()
	Remotes.get("Effect").OnClientEvent:Connect(Effects.handle)
end

return Effects
