-- Корневой ScreenGui с автоматическим масштабом под размер экрана

local Players = game:GetService("Players")

local Theme = require(script.Parent.Theme)

local player = Players.LocalPlayer

local Root = {}

local gui = Theme.New("ScreenGui", {
	Name = "PotatoUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = false,
	Parent = player:WaitForChild("PlayerGui"),
})
Root.gui = gui

local scale = Theme.New("UIScale", { Parent = gui })

local function rescale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local size = camera.ViewportSize
	scale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 760), 0.55, 1.25)
end

rescale()
local function watchCamera()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end
	rescale()
end
watchCamera()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)

-- Слой для полноэкранных эффектов (конфетти, баннеры)
Root.fx = Theme.New("Frame", {
	Name = "Fx",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 50,
	Parent = gui,
})

return Root
