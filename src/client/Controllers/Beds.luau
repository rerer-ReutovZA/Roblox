-- Рост кустов на ручных грядках (Этап 1): сервер присылает время созревания, клиент анимирует

local RunService = game:GetService("RunService")

local Beds = {}

type BedInfo = {
	model: Model,
	parts: { { part: BasePart, size: Vector3, cframe: CFrame, bottom: number } },
	tubers: { BasePart },
	last: number,
}

local beds: { [Model]: BedInfo } = {}

-- Половина высоты детали по мировой оси Y (учитывает повёрнутые цилиндры-стебли)
local function halfHeight(cf: CFrame, size: Vector3): number
	return (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z)
		/ 2
end

local function track(model: Model)
	if beds[model] or not model:GetAttribute("ManualBed") then
		return
	end
	local bush = model:WaitForChild("Bush", 5)
	local tubers = model:WaitForChild("Tubers", 5)
	if not (bush and tubers) then
		return
	end
	local info: BedInfo = { model = model, parts = {}, tubers = {}, last = -1 }
	for _, p in ipairs(bush:GetDescendants()) do
		if p:IsA("BasePart") then
			table.insert(info.parts, {
				part = p,
				size = p.Size,
				cframe = p.CFrame,
				bottom = p.CFrame.Position.Y - halfHeight(p.CFrame, p.Size),
			})
		end
	end
	for _, p in ipairs(tubers:GetDescendants()) do
		if p:IsA("BasePart") then
			table.insert(info.tubers, p)
		end
	end
	beds[model] = info
	model.Destroying:Connect(function()
		beds[model] = nil
	end)
end

local function growth(model: Model): number
	if model:GetAttribute("Auto") then
		return 1
	end
	local ripeAt = model:GetAttribute("RipeAt")
	local ripen = model:GetAttribute("RipenTime") or 3
	if not ripeAt then
		return 1
	end
	return math.clamp(1 - (ripeAt - workspace:GetServerTimeNow()) / ripen, 0, 1)
end

function Beds.isRipe(model: Model): boolean
	return not model:GetAttribute("Auto") and growth(model) >= 0.97
end

local function update()
	for model, info in pairs(beds) do
		if not model.Parent then
			beds[model] = nil
			continue
		end
		local f = growth(model)
		local auto = model:GetAttribute("Auto") == true
		local key = math.floor(f * 30) + (if auto then 100 else 0)
		if key ~= info.last then
			info.last = key
			local k = 0.25 + 0.75 * f
			for _, rec in ipairs(info.parts) do
				local size = rec.size * k
				rec.part.Size = size
				local pos = rec.cframe.Position
				local half = halfHeight(rec.cframe, size)
				rec.part.CFrame = rec.cframe - pos + Vector3.new(pos.X, rec.bottom + half, pos.Z)
			end
			local ripe = f >= 0.97 and not auto
			for _, t in ipairs(info.tubers) do
				t.Transparency = if ripe then 0 else 1
			end
		end
	end
end

function Beds.init()
	local plots = workspace:WaitForChild("Plots")
	for _, d in ipairs(plots:GetDescendants()) do
		if d:IsA("Model") and d:GetAttribute("ManualBed") then
			task.spawn(track, d)
		end
	end
	plots.DescendantAdded:Connect(function(d)
		if d:IsA("Model") then
			task.defer(function()
				if d:GetAttribute("ManualBed") then
					track(d)
				end
			end)
		end
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.08 then
			acc = 0
			update()
		end
	end)
end

return Beds
