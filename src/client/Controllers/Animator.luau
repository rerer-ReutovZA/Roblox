-- Локальные анимации объектов по тегам CollectionService (сервер их только помечает):
-- Spin, Slide, Bob, Sway, Pulse, Hover (дроны), Roam (роботы), Bug (жуки)

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Animator = {}

type Entry = {
	inst: Instance,
	tag: string,
	base: CFrame,
	current: CFrame,
	transparency: number?,
	seed: number,
	depth: number,
	parent: any?, -- ближайший анимируемый предок (лопасти дрона внутри летящего дрона)
	rel: CFrame?,
}

local entries: { [Instance]: { Entry } } = {}
local list: { Entry } = {}
local TAGS = { "Spin", "Slide", "Bob", "Sway", "Pulse", "Hover", "Roam", "Bug" }
local MOVERS = { Spin = true, Slide = true, Bob = true, Sway = true, Hover = true, Roam = true, Bug = true }
local CULL_DISTANCE = 220

local function pivotOf(inst: Instance): CFrame?
	if inst:IsA("Model") then
		return inst:GetPivot()
	elseif inst:IsA("BasePart") then
		return inst.CFrame
	end
	return nil
end

local function setPivot(inst: Instance, cf: CFrame)
	if inst:IsA("Model") then
		inst:PivotTo(cf)
	elseif inst:IsA("BasePart") then
		inst.CFrame = cf
	end
end

local function depthOf(inst: Instance): number
	local d = 0
	local node = inst.Parent
	while node do
		d += 1
		node = node.Parent
	end
	return d
end

local function rebuildList()
	table.clear(list)
	for _, group in pairs(entries) do
		for _, e in ipairs(group) do
			table.insert(list, e)
		end
	end
	for _, e in ipairs(list) do
		e.parent = nil
		e.rel = nil
		e.depth = depthOf(e.inst)
		if MOVERS[e.tag] then
			local node = e.inst.Parent
			while node and node ~= workspace and not e.parent do
				for _, pe in ipairs(entries[node] or {}) do
					if MOVERS[pe.tag] then
						e.parent = pe
						e.rel = pe.base:ToObjectSpace(e.base)
						break
					end
				end
				node = node.Parent
			end
		end
	end
	-- родители анимируются раньше детей
	table.sort(list, function(a, b)
		return a.depth < b.depth
	end)
end

local function add(inst: Instance, tag: string)
	local base = pivotOf(inst)
	if not base then
		return
	end
	local e: Entry = {
		inst = inst,
		tag = tag,
		base = base,
		current = base,
		transparency = if inst:IsA("BasePart") then inst.Transparency else nil,
		seed = math.random() * 100,
		depth = 0,
	}
	entries[inst] = entries[inst] or {}
	table.insert(entries[inst], e)
	rebuildList()
end

local function remove(inst: Instance)
	if entries[inst] then
		entries[inst] = nil
		rebuildList()
	end
end

local function axisRotation(axis: string?, angle: number): CFrame
	if axis == "X" then
		return CFrame.Angles(angle, 0, 0)
	elseif axis == "Z" then
		return CFrame.Angles(0, 0, angle)
	end
	return CFrame.Angles(0, angle, 0)
end

local function axisVector(axis: string?): Vector3
	if axis == "X" then
		return Vector3.xAxis
	elseif axis == "Y" then
		return Vector3.yAxis
	end
	return Vector3.zAxis
end

local function step()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local camPos = camera.CFrame.Position
	local t = os.clock()
	for _, e in ipairs(list) do
		local inst = e.inst
		local base = if e.parent and e.rel then e.parent.current * e.rel else e.base
		if (base.Position - camPos).Magnitude > CULL_DISTANCE then
			continue
		end
		local speed = inst:GetAttribute("Speed") or 1
		local tag = e.tag
		-- Phase (доля цикла) согласует детали одной модели, например лапы жука; иначе фаза случайная
		local phase = inst:GetAttribute("Phase")
		local offset = if tag ~= "Hover" and phase then phase * math.pi * 2 else e.seed
		local cf: CFrame? = nil
		if tag == "Spin" then
			local angle = math.rad(t * speed + e.seed * 10)
			cf = base * axisRotation(inst:GetAttribute("Axis"), angle)
		elseif tag == "Slide" then
			local shift = math.sin(t * speed * 2 + offset) * (inst:GetAttribute("Amplitude") or 1)
			cf = base * CFrame.new(axisVector(inst:GetAttribute("Axis")) * shift)
		elseif tag == "Bob" then
			local shift = math.sin(t * speed * 2 + offset) * (inst:GetAttribute("Amplitude") or 0.3)
			cf = base * CFrame.new(0, shift, 0)
		elseif tag == "Sway" then
			local angle = math.rad(math.sin(t * speed + offset) * (inst:GetAttribute("Amplitude") or 10))
			cf = base * axisRotation(inst:GetAttribute("Axis"), angle)
		elseif tag == "Pulse" then
			if inst:IsA("BasePart") then
				local baseT = e.transparency or 0
				inst.Transparency = baseT + (1 - baseT) * 0.6 * (0.5 + 0.5 * math.sin(t * speed * 3 + e.seed))
			end
		elseif tag == "Hover" then
			local r = inst:GetAttribute("Radius") or 3
			local hoverPhase = phase or 0
			local a = t * speed + hoverPhase
			local pos = Vector3.new(math.cos(a) * r, math.sin(t * 2 + hoverPhase) * 0.4, math.sin(a) * r)
			local facing = math.atan2(-math.cos(a), math.sin(a))
			cf = base * CFrame.new(pos) * CFrame.Angles(0, facing, math.sin(t * 3) * 0.08)
		elseif tag == "Roam" then
			local r = inst:GetAttribute("Radius") or 1.5
			local a = t * speed + e.seed
			local pos = Vector3.new(math.sin(a) * r, 0, math.sin(a * 0.5) * r)
			cf = base * CFrame.new(pos) * CFrame.Angles(0, math.sin(a) * 0.8, 0)
		elseif tag == "Bug" then
			local a = t * 0.9 + e.seed
			local pos = Vector3.new(math.sin(a) * 3, math.abs(math.sin(t * 9 + e.seed)) * 0.15, math.sin(a * 0.7) * 3)
			local dx = math.cos(a) * 3
			local dz = math.cos(a * 0.7) * 2.1
			cf = base * CFrame.new(pos) * CFrame.Angles(0, math.atan2(dx, dz), 0)
		end
		if cf then
			e.current = cf
			setPivot(inst, cf)
		end
	end
end

function Animator.init()
	for _, tag in ipairs(TAGS) do
		for _, inst in ipairs(CollectionService:GetTagged(tag)) do
			add(inst, tag)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
			-- ждём, пока модель полностью реплицируется
			task.defer(add, inst, tag)
		end)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(remove)
	end
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator >= 1 / 30 then
			accumulator = 0
			step()
		end
	end)
end

return Animator
