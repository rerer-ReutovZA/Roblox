-- Конструктор моделей из деталей (Part). Все координаты — в локальной системе модели:
-- начало координат = центр пятна застройки на уровне пола, +Z смотрит к входу на базу.

local Kit = {}
Kit.__index = Kit

export type Opts = {
	rot: Vector3?, -- градусы (X, Y, Z)
	transparency: number?,
	collide: boolean?,
	name: string?,
	reflectance: number?,
	shadow: boolean?,
	parent: Instance?,
}

export type Builder = typeof(setmetatable(
	{} :: {
		model: Model,
		origin: CFrame,
		target: Instance,
	},
	Kit
))

-- Палитра
Kit.C = {
	wood = Color3.fromRGB(140, 95, 55),
	woodDark = Color3.fromRGB(95, 62, 35),
	woodLight = Color3.fromRGB(190, 145, 95),
	soil = Color3.fromRGB(92, 64, 42),
	soilDark = Color3.fromRGB(64, 44, 30),
	leaf = Color3.fromRGB(70, 150, 60),
	leafDark = Color3.fromRGB(45, 110, 45),
	stone = Color3.fromRGB(130, 130, 125),
	stoneDark = Color3.fromRGB(95, 95, 92),
	metal = Color3.fromRGB(165, 170, 178),
	metalDark = Color3.fromRGB(85, 90, 98),
	steel = Color3.fromRGB(120, 126, 136),
	white = Color3.fromRGB(235, 236, 238),
	black = Color3.fromRGB(28, 30, 34),
	yellow = Color3.fromRGB(245, 195, 40),
	orange = Color3.fromRGB(240, 130, 30),
	red = Color3.fromRGB(205, 50, 45),
	green = Color3.fromRGB(60, 190, 80),
	blue = Color3.fromRGB(45, 120, 220),
	cyan = Color3.fromRGB(60, 220, 240),
	purple = Color3.fromRGB(140, 70, 210),
	glass = Color3.fromRGB(170, 215, 235),
	potato = Color3.fromRGB(190, 145, 85),
	concrete = Color3.fromRGB(175, 172, 165),
	asphalt = Color3.fromRGB(60, 62, 66),
	skin = Color3.fromRGB(234, 184, 146),
	gold = Color3.fromRGB(255, 200, 40),
}

local M = Enum.Material

function Kit.new(name: string, origin: CFrame): Builder
	local model = Instance.new("Model")
	model.Name = name
	model.WorldPivot = origin
	return setmetatable({ model = model, origin = origin, target = model :: Instance }, Kit)
end

-- Вложенная группа (например, вращающиеся лопасти). Пишет детали в под-модель.
function Kit.group(self: Builder, name: string, pivot: Vector3?): Builder
	local sub = Instance.new("Model")
	sub.Name = name
	sub.WorldPivot = self.origin * CFrame.new(pivot or Vector3.zero)
	sub.Parent = self.target
	return setmetatable({ model = self.model, origin = self.origin, target = sub :: Instance }, Kit)
end

function Kit.groupModel(self: Builder): Model
	return self.target :: Model
end

local function rotation(rot: Vector3?): CFrame
	if not rot then
		return CFrame.identity
	end
	return CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
end

function Kit.place(self: Builder, part: BasePart, pos: Vector3, opts: Opts?)
	local o: Opts = opts or {}
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = self.origin * CFrame.new(pos) * rotation(o.rot)
	part.CanCollide = if o.collide == nil then true else o.collide
	part.CanTouch = false
	part.Transparency = o.transparency or 0
	part.Reflectance = o.reflectance or 0
	part.CastShadow = if o.shadow == nil then true else o.shadow
	if o.name then
		part.Name = o.name
	end
	part.Parent = o.parent or self.target
end

function Kit.box(self: Builder, size: Vector3, pos: Vector3, color: Color3, material: Enum.Material?, opts: Opts?): Part
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material or M.SmoothPlastic
	self:place(p, pos, opts)
	return p
end

-- Вертикальный цилиндр
function Kit.cyl(
	self: Builder,
	height: number,
	diameter: number,
	pos: Vector3,
	color: Color3,
	material: Enum.Material?,
	opts: Opts?
): Part
	local o: Opts = table.clone(opts or {})
	local r = o.rot or Vector3.zero
	o.rot = Vector3.new(r.X, r.Y, r.Z + 90)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(height, diameter, diameter)
	p.Color = color
	p.Material = material or M.SmoothPlastic
	self:place(p, pos, o)
	return p
end

-- Горизонтальный цилиндр вдоль X (rot позволяет развернуть)
function Kit.cylX(
	self: Builder,
	length: number,
	diameter: number,
	pos: Vector3,
	color: Color3,
	material: Enum.Material?,
	opts: Opts?
): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(length, diameter, diameter)
	p.Color = color
	p.Material = material or M.SmoothPlastic
	self:place(p, pos, opts)
	return p
end

-- Горизонтальный цилиндр вдоль Z
function Kit.cylZ(
	self: Builder,
	length: number,
	diameter: number,
	pos: Vector3,
	color: Color3,
	material: Enum.Material?,
	opts: Opts?
): Part
	local o: Opts = table.clone(opts or {})
	local r = o.rot or Vector3.zero
	o.rot = Vector3.new(r.X, r.Y + 90, r.Z)
	return self:cylX(length, diameter, pos, color, material, o)
end

function Kit.ball(
	self: Builder,
	diameter: number,
	pos: Vector3,
	color: Color3,
	material: Enum.Material?,
	opts: Opts?
): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(diameter, diameter, diameter)
	p.Color = color
	p.Material = material or M.SmoothPlastic
	self:place(p, pos, opts)
	return p
end

-- Эллипсоид (клубень, крона, купол)
function Kit.ellipsoid(
	self: Builder,
	size: Vector3,
	pos: Vector3,
	color: Color3,
	material: Enum.Material?,
	opts: Opts?
): Part
	local p = self:box(size, pos, color, material, opts)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

function Kit.wedge(
	self: Builder,
	size: Vector3,
	pos: Vector3,
	color: Color3,
	material: Enum.Material?,
	opts: Opts?
): WedgePart
	local p = Instance.new("WedgePart")
	p.Size = size
	p.Color = color
	p.Material = material or M.SmoothPlastic
	self:place(p, pos, opts)
	return p
end

-- Труба между двумя точками
function Kit.pipe(
	self: Builder,
	a: Vector3,
	b: Vector3,
	diameter: number,
	color: Color3,
	material: Enum.Material?
): Part
	local length = (b - a).Magnitude
	if math.abs((b - a).Unit.Y) > 0.999 then
		return self:cyl(length, diameter, (a + b) / 2, color, material or M.Metal, { collide = false })
	end
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(length, diameter, diameter)
	p.Color = color
	p.Material = material or M.Metal
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local mid = (a + b) / 2
	local cf = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0)
	p.CFrame = self.origin * cf
	p.Parent = self.target
	return p
end

function Kit.light(_self: Builder, part: BasePart, color: Color3, range: number?, brightness: number?, spot: boolean?)
	if spot then
		local s = Instance.new("SpotLight")
		s.Face = Enum.NormalId.Bottom
		s.Angle = 80
		s.Color = color
		s.Range = range or 10
		s.Brightness = brightness or 1.5
		s.Parent = part
	else
		local p = Instance.new("PointLight")
		p.Color = color
		p.Range = range or 10
		p.Brightness = brightness or 1.5
		p.Shadows = false
		p.Parent = part
	end
end

-- Надпись на грани детали
function Kit.label(
	_self: Builder,
	part: BasePart,
	face: Enum.NormalId,
	text: string,
	opts: {
		color: Color3?,
		background: Color3?,
		font: Enum.Font?,
		scale: number?,
		name: string?,
	}?
): TextLabel
	local o = opts or {}
	local gui = Instance.new("SurfaceGui")
	gui.Name = o.name or "Label"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = if o.background then 0 else 1
	label.BackgroundColor3 = o.background or Color3.new()
	label.TextColor3 = o.color or Color3.new(1, 1, 1)
	label.Font = o.font or Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = text
	label.Parent = gui
	local pad = Instance.new("UIPadding")
	local s = UDim.new(0.06 * (o.scale or 1), 0)
	pad.PaddingLeft = s
	pad.PaddingRight = s
	pad.PaddingTop = s
	pad.PaddingBottom = s
	pad.Parent = label
	return label
end

-- Надпись над объектом
function Kit.billboard(
	_self: Builder,
	part: BasePart,
	text: string,
	offset: number,
	color: Color3?,
	maxDistance: number?
)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Tag"
	gui.Size = UDim2.fromOffset(200, 40)
	gui.StudsOffset = Vector3.new(0, offset, 0)
	gui.MaxDistance = maxDistance or 40
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = text
	label.Parent = gui
	return label
end

function Kit.tag(_self: Builder, instance: Instance, tag: string, attributes: { [string]: any }?)
	if attributes then
		for k, v in pairs(attributes) do
			instance:SetAttribute(k, v)
		end
	end
	instance:AddTag(tag)
end

-- Клубень картофеля
function Kit.potato(self: Builder, pos: Vector3, scale: number, color: Color3?, opts: Opts?): Part
	return self:ellipsoid(Vector3.new(0.9, 0.6, 0.65) * scale, pos, color or Kit.C.potato, M.SmoothPlastic, opts)
end

export type FigureColors = {
	shirt: Color3,
	pants: Color3,
	skin: Color3?,
	hat: Color3?,
	beard: Color3?,
	avatar: boolean?, -- заменить фигурку настоящим аватаром R15 (когда игра запущена в Roblox)
}

local IDLE_ANIMATION = "rbxassetid://507766666" -- стандартная поза ожидания R15

local function weldTo(head: BasePart, part: BasePart, offset: CFrame)
	part.Anchored = false
	part.CanCollide = false
	part.Massless = true
	part.CFrame = head.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = part
	weld.Parent = part
	part.Parent = head.Parent
end

-- Аватар R15 вместо блочной фигурки. Создаётся асинхронно (описание грузится с сервера Roblox);
-- таблички и подсказки с головы фигурки переезжают на голову аватара. Без Roblox (тесты) остаётся фигурка.
function Kit.avatarize(self: Builder, fig: Model, colors: FigureColors, pos: Vector3, facing: number?, scale: number?)
	local origin = self.origin
	local s = scale or 1
	task.spawn(function()
		local ok, rig = pcall(function()
			local desc = Instance.new("HumanoidDescription")
			local skin = colors.skin or Kit.C.skin
			desc.HeadColor = skin
			desc.TorsoColor = colors.shirt
			desc.LeftArmColor = colors.shirt
			desc.RightArmColor = colors.shirt
			desc.LeftLegColor = colors.pants
			desc.RightLegColor = colors.pants
			desc.HeightScale = s
			desc.WidthScale = s
			desc.DepthScale = s
			desc.HeadScale = s
			return game:GetService("Players"):CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		end)
		if not ok or not rig or not fig.Parent then
			return
		end
		local humanoid = rig:FindFirstChildOfClass("Humanoid")
		local root = rig:FindFirstChild("HumanoidRootPart") :: BasePart?
		local head = rig:FindFirstChild("Head") :: BasePart?
		if not humanoid or not root or not head then
			rig:Destroy()
			return
		end
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		root.Anchored = true
		local lift = humanoid.HipHeight + root.Size.Y / 2
		rig:PivotTo(
			origin * CFrame.new(pos) * CFrame.Angles(0, math.rad((facing or 0) + 180), 0) * CFrame.new(0, lift, 0)
		)
		local hs = head.Size
		if colors.hat then
			local brim = Instance.new("Part")
			brim.Shape = Enum.PartType.Cylinder
			brim.Size = Vector3.new(0.1, hs.X * 1.6, hs.X * 1.6)
			brim.Color = colors.hat
			brim.Material = Enum.Material.Fabric
			weldTo(head, brim, CFrame.new(0, hs.Y * 0.42, 0) * CFrame.Angles(0, 0, math.rad(90)))
			local crown = brim:Clone()
			crown.Size = Vector3.new(hs.Y * 0.45, hs.X * 0.95, hs.X * 0.95)
			weldTo(head, crown, CFrame.new(0, hs.Y * 0.62, 0) * CFrame.Angles(0, 0, math.rad(90)))
		end
		if colors.beard then
			local beard = Instance.new("Part")
			beard.Size = Vector3.new(hs.X * 0.75, hs.Y * 0.45, hs.Z * 0.3)
			beard.Color = colors.beard
			beard.Material = Enum.Material.SmoothPlastic
			weldTo(head, beard, CFrame.new(0, -hs.Y * 0.38, -hs.Z * 0.42))
		end
		local oldHead = fig:FindFirstChild("Head")
		if oldHead then
			for _, c in ipairs(oldHead:GetChildren()) do
				if c:IsA("BillboardGui") or c:IsA("ProximityPrompt") then
					c.Parent = head
				end
			end
		end
		rig.Name = fig.Name
		rig.Parent = fig.Parent
		fig:Destroy()
		pcall(function()
			local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
			animator.Parent = humanoid
			local animation = Instance.new("Animation")
			animation.AnimationId = IDLE_ANIMATION
			animator:LoadAnimation(animation):Play()
		end)
	end)
end

-- Блочная фигурка человека (NPC без Humanoid). pos — точка на полу.
function Kit.figure(self: Builder, pos: Vector3, colors: FigureColors, facing: number?, scale: number?): Model
	local s = scale or 1
	local g = self:group("Figure", pos)
	local yaw = facing or 0
	local function at(v: Vector3): Vector3
		local r = CFrame.Angles(0, math.rad(yaw), 0) * (v * s)
		return pos + r
	end
	local rot = Vector3.new(0, yaw, 0)
	local skin = colors.skin or Kit.C.skin
	local o = { rot = rot, collide = false }
	g:box(Vector3.new(0.9, 1.9, 0.9) * s, at(Vector3.new(-0.5, 0.95, 0)), colors.pants, M.SmoothPlastic, o)
	g:box(Vector3.new(0.9, 1.9, 0.9) * s, at(Vector3.new(0.5, 0.95, 0)), colors.pants, M.SmoothPlastic, o)
	g:box(Vector3.new(2, 1.9, 1) * s, at(Vector3.new(0, 2.85, 0)), colors.shirt, M.SmoothPlastic, o)
	g:box(Vector3.new(0.85, 1.9, 0.85) * s, at(Vector3.new(-1.45, 2.85, 0)), colors.shirt, M.SmoothPlastic, o)
	g:box(Vector3.new(0.85, 1.9, 0.85) * s, at(Vector3.new(1.45, 2.85, 0)), colors.shirt, M.SmoothPlastic, o)
	local head = g:box(Vector3.new(1.15, 1.15, 1.15) * s, at(Vector3.new(0, 4.4, 0)), skin, M.SmoothPlastic, o)
	head.Name = "Head"
	-- глаза
	g:box(Vector3.new(0.18, 0.22, 0.05) * s, at(Vector3.new(-0.25, 4.5, 0.58)), Kit.C.black, M.SmoothPlastic, o)
	g:box(Vector3.new(0.18, 0.22, 0.05) * s, at(Vector3.new(0.25, 4.5, 0.58)), Kit.C.black, M.SmoothPlastic, o)
	if colors.hat then
		g:box(Vector3.new(1.35, 0.35, 1.35) * s, at(Vector3.new(0, 5.1, 0)), colors.hat, M.SmoothPlastic, o)
		g:box(Vector3.new(1.35, 0.12, 0.5) * s, at(Vector3.new(0, 4.98, 0.85)), colors.hat, M.SmoothPlastic, o)
	end
	if colors.beard then
		g:box(Vector3.new(0.9, 0.55, 0.25) * s, at(Vector3.new(0, 3.95, 0.55)), colors.beard, M.SmoothPlastic, o)
	end
	local model = g:groupModel()
	if colors.avatar then
		self:avatarize(model, colors, pos, facing, scale)
	end
	return model
end

-- Общая станина промышленного модуля: рама, корпус, панель управления, ножки
function Kit.machine(self: Builder, w: number, d: number, h: number, body: Color3, accent: Color3): Part
	local C = Kit.C
	self:box(Vector3.new(w, 0.4, d), Vector3.new(0, 0.2, 0), C.metalDark, M.DiamondPlate)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			self:box(
				Vector3.new(0.4, 1, 0.4),
				Vector3.new(sx * (w / 2 - 0.5), 0.9, sz * (d / 2 - 0.5)),
				C.black,
				M.Metal
			)
		end
	end
	local main = self:box(Vector3.new(w - 0.6, h, d - 1.2), Vector3.new(0, 1.4 + h / 2, -0.2), body, M.Metal)
	self:box(Vector3.new(w - 0.4, 0.3, d - 1), Vector3.new(0, 1.4 + h + 0.15, -0.2), accent, M.SmoothPlastic)
	-- полоса предупреждения
	self:box(
		Vector3.new(w - 0.55, 0.25, 0.05),
		Vector3.new(0, 1.7, d / 2 - 0.78),
		C.yellow,
		M.SmoothPlastic,
		{ collide = false }
	)
	-- пульт
	local panel = self:box(
		Vector3.new(1.2, 1.4, 0.3),
		Vector3.new(w / 2 - 1, 2.4, d / 2 - 0.45),
		C.black,
		M.SmoothPlastic,
		{ rot = Vector3.new(-15, 0, 0), collide = false }
	)
	self:box(
		Vector3.new(0.25, 0.25, 0.05),
		Vector3.new(w / 2 - 1.3, 2.6, d / 2 - 0.25),
		C.green,
		M.Neon,
		{ collide = false }
	)
	self:box(
		Vector3.new(0.25, 0.25, 0.05),
		Vector3.new(w / 2 - 0.7, 2.6, d / 2 - 0.25),
		C.red,
		M.Neon,
		{ collide = false }
	)
	self:label(panel, Enum.NormalId.Back, "ON", { color = accent, scale = 0.5 })
	return main
end

function Kit.finish(self: Builder, parent: Instance): Model
	self.model.Parent = parent
	return self.model
end

return Kit
