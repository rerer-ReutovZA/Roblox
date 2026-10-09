-- Геймпассы (ГДД, раздел 6): x2 Cash, Бесконечная Энергия, Авто-дрон Магната, VIP Фермер

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Sessions = require(script.Parent.Sessions)
local PlotService = require(script.Parent.PlotService)
local ManualFarm = require(script.Parent.ManualFarm)

type Session = Sessions.Session

local GameState = ReplicatedStorage:WaitForChild("GameState")

local PassService = {}

local byKey = {}
local byId = {}
for _, pass in ipairs(Config.GamePasses.List) do
	byKey[pass.key] = pass
	if pass.id > 0 then
		byId[pass.id] = pass
	end
end

function PassService.load(session: Session)
	local player = session.player
	for _, pass in ipairs(Config.GamePasses.List) do
		local owned = false
		if pass.id > 0 then
			local ok, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			owned = ok and result == true
		end
		if Config.GamePasses.GrantAllInStudio and RunService:IsStudio() then
			owned = true
		end
		session.passes[pass.key] = owned
	end
end

-- Золотое сияние VIP-фермера
function PassService.applyCharacter(session: Session, character: Model)
	if not session.passes.vip then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root and not root:FindFirstChild("VipSparkles") then
		local sparkles = Instance.new("Sparkles")
		sparkles.Name = "VipSparkles"
		sparkles.SparkleColor = Color3.fromRGB(255, 205, 50)
		sparkles.Parent = root
	end
end

function PassService.prompt(player: Player, key: string)
	local pass = byKey[key]
	if not pass then
		return
	end
	local session = Sessions.get(player)
	if session and session.passes[key] then
		Sessions.notify(player, "У тебя уже есть «" .. pass.name .. "»", "info")
		return
	end
	if pass.id <= 0 then
		Sessions.notify(
			player,
			"Геймпасс «"
				.. pass.name
				.. "» ещё не настроен (впишите ID в Config/GamePasses)",
			"error"
		)
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, pass.id)
end

local function granted(player: Player, pass)
	local session = Sessions.get(player)
	if not session then
		return
	end
	session.passes[pass.key] = true
	Sessions.recompute(session)
	Sessions.sync(session)
	PlotService.buildVipPads(session)
	if pass.key == "vip" then
		if player.Character then
			PassService.applyCharacter(session, player.Character)
		end
		ManualFarm.giveShovel(session)
	end
	Sessions.notify(player, pass.icon .. " Спасибо за покупку «" .. pass.name .. "»!", "gold")
	Sessions.effect(player, { type = "Confetti" })
end

function PassService.init()
	PlotService.onVip = PassService.prompt

	Remotes.get("BuyPass").OnServerEvent:Connect(function(player, key: unknown)
		if type(key) == "string" then
			PassService.prompt(player, key)
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local pass = byId[passId]
		if purchased and pass then
			granted(player, pass)
		end
	end)

	-- цены в Robux для витрины
	task.spawn(function()
		for _, pass in ipairs(Config.GamePasses.List) do
			if pass.id > 0 then
				local ok, info = pcall(function()
					return MarketplaceService:GetProductInfo(pass.id, Enum.InfoType.GamePass)
				end)
				if ok and info and info.PriceInRobux then
					GameState:SetAttribute("PassPrice_" .. pass.key, info.PriceInRobux)
				end
			end
		end
	end)
end

return PassService
