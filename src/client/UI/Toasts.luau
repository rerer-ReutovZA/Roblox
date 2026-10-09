-- Всплывающие уведомления в правом нижнем углу

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)
local Sound = require(script.Parent.Parent.Controllers.Sound)

local C = Theme.Colors

local Toasts = {}

local KIND_COLORS = {
	info = C.PanelLight,
	success = Color3.fromRGB(45, 120, 60),
	error = Color3.fromRGB(150, 45, 45),
	gold = Color3.fromRGB(150, 110, 20),
	stage = Color3.fromRGB(110, 60, 170),
	event = Color3.fromRGB(190, 95, 20),
	tip = Color3.fromRGB(60, 95, 140),
}

local holder = Theme.New("Frame", {
	Name = "Toasts",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.fromOffset(360, 420),
	BackgroundTransparency = 1,
	Parent = Root.gui,
}, {
	Theme.New("UIListLayout", {
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	}),
})

local order = 0
local recent: { [string]: number } = {}

function Toasts.show(text: string, kind: string?)
	-- одинаковые сообщения не дублируем чаще раза в 2 секунды
	local key = text
	if recent[key] and os.clock() - recent[key] < 2 then
		return
	end
	recent[key] = os.clock()

	order += 1
	local long = #text > 70 or kind == "tip" or kind == "event"
	local toast = Theme.New("Frame", {
		BackgroundColor3 = KIND_COLORS[kind or "info"] or C.PanelLight,
		BackgroundTransparency = 0.08,
		Size = UDim2.fromOffset(360, if long then 74 else 46),
		LayoutOrder = order,
		Parent = holder,
	}, {
		Theme.corner(10),
		Theme.stroke(nil, 1.5, 0.8),
		Theme.padding(8),
		Theme.label({
			Size = UDim2.fromScale(1, 1),
			Text = text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			TextScaled = true,
		}),
	})
	local label = toast:FindFirstChildOfClass("TextLabel")
	if label then
		Theme.New("UITextSizeConstraint", { MaxTextSize = 17, Parent = label })
	end
	if kind == "error" then
		Sound.play("Error")
	end
	local children = holder:GetChildren()
	local frames = {}
	for _, c in ipairs(children) do
		if c:IsA("Frame") then
			table.insert(frames, c)
		end
	end
	if #frames > 6 then
		table.sort(frames, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		frames[1]:Destroy()
	end
	local life = if long then 6 else 3.5
	task.delay(life, function()
		if toast.Parent then
			local tween = TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
			tween:Play()
			for _, d in ipairs(toast:GetDescendants()) do
				if d:IsA("TextLabel") then
					TweenService:Create(d, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
				elseif d:IsA("UIStroke") then
					TweenService:Create(d, TweenInfo.new(0.4), { Transparency = 1 }):Play()
				end
			end
			tween.Completed:Wait()
			toast:Destroy()
		end
	end)
end

Remotes.get("Notify").OnClientEvent:Connect(function(text: string, kind: string)
	Toasts.show(text, kind)
end)

return Toasts
