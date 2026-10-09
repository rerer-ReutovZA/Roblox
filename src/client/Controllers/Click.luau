-- Клики по миру: копка грядок лопатой и ловля жуков

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Beds = require(script.Parent.Beds)
local Sound = require(script.Parent.Sound)

local player = Players.LocalPlayer

local Click = {}

local digRemote = Remotes.get("Dig")
local bugRemote = Remotes.get("ClickBug")

local function shovelEquipped(): boolean
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	return tool ~= nil and tool:GetAttribute("Shovel") == true
end

local function modelWith(part: Instance, attribute: string): Model?
	local node = part.Parent
	while node and node ~= workspace do
		if node:IsA("Model") and node:GetAttribute(attribute) then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function handle(screenPos: Vector2)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local ray = camera:ScreenPointToRay(screenPos.X, screenPos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { player.Character :: Instance, workspace:FindFirstChild("ClientFx") :: Instance }
	local result
	-- полупрозрачные детали (стекло теплиц) пропускаем, кроме хитбоксов жуков
	for _ = 1, 5 do
		params.FilterDescendantsInstances = ignore
		result = workspace:Raycast(ray.Origin, ray.Direction * 300, params)
		if not result or result.Instance.Transparency < 0.5 or modelWith(result.Instance, "Bug") then
			break
		end
		table.insert(ignore, result.Instance)
	end
	if not result then
		return
	end
	local bug = modelWith(result.Instance, "Bug")
	if bug then
		if bug:GetAttribute("Owner") == player.UserId then
			bugRemote:FireServer(bug)
		end
		return
	end
	local bed = modelWith(result.Instance, "ManualBed")
	if bed and bed:GetAttribute("Owner") == player.UserId and shovelEquipped() then
		if Beds.isRipe(bed) then
			digRemote:FireServer(bed.Name)
		else
			Sound.play("Click", 0.3)
		end
	end
end

function Click.init()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			handle(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
end

return Click
