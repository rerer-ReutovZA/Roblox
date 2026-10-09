-- Сетевые события. Сервер создаёт их, клиент ждёт.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	-- сервер → клиент
	"Sync", -- полное состояние игрока (постройки, сорта, персонал, технологии)
	"Notify", -- всплывающее сообщение
	"Effect", -- визуальные/звуковые эффекты
	"Offline", -- отчёт об офлайн-доходе
	-- клиент → сервер
	"Dig", -- копнуть грядку лопатой
	"ClickBug", -- клик по жуку
	"BuyResearch",
	"SelectVariety",
	"HireStaff",
	"BuyStarTech",
	"Rebirth",
	"GoHome",
	"BuyPass",
	"Ready", -- клиент загрузил интерфейс
}

local Remotes = {}

local folder: Folder
if RunService:IsServer() then
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		folder = existing :: Folder
	else
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in ipairs(EVENTS) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function Remotes.get(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
