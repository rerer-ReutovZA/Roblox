-- Potato Tycoon — точка входа клиента: интерфейс, эффекты, управление

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Client = script.Parent
require(Client.State)
local Toasts = require(Client.UI.Toasts)
local Hud = require(Client.UI.Hud)
local Windows = require(Client.UI.Windows)
local Effects = require(Client.Controllers.Effects)
local Animator = require(Client.Controllers.Animator)
local Beds = require(Client.Controllers.Beds)
local Click = require(Client.Controllers.Click)
local WorldFx = require(Client.Controllers.WorldFx)

Effects.init()
Animator.init()
Beds.init()
Click.init()
WorldFx.init()
Hud.init()
Windows.init()

local function openMenu(name: string)
	if name == "Home" then
		Remotes.get("GoHome"):FireServer()
		return
	end
	Windows.open(name)
end
Hud.onMenu = openMenu
WorldFx.openMenu = openMenu

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
		Windows.close()
	end
end)

-- Чат-тег [VIP] (геймпасс «VIP Фермер»)
TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local props = Instance.new("TextChatMessageProperties")
	local source = message.TextSource
	if source then
		local sender = Players:GetPlayerByUserId(source.UserId)
		if sender and sender:GetAttribute("VIP") then
			props.PrefixText = "<font color='#FFD232'>[VIP]</font> " .. message.PrefixText
		end
	end
	return props
end

Remotes.get("Ready"):FireServer()
Toasts.show(
	"🥔 Добро пожаловать в Potato Tycoon! Поговори с Дедом Матвеем у входа на базу.",
	"tip"
)
