-- Клиентское состояние: данные синхронизации с сервера и атрибуты игрока

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer

local State = {}

State.data = nil :: any
local changed = Instance.new("BindableEvent")
State.Changed = changed.Event

function State.attr(name: string): any
	return player:GetAttribute(name)
end

function State.num(name: string): number
	return player:GetAttribute(name) or 0
end

function State.owns(itemId: string): boolean
	return State.data ~= nil and State.data.owned[itemId] == true
end

function State.onAttr(names: { string }, fn: () -> ())
	for _, name in ipairs(names) do
		player:GetAttributeChangedSignal(name):Connect(fn)
	end
end

Remotes.get("Sync").OnClientEvent:Connect(function(data)
	State.data = data
	changed:Fire()
end)

return State
