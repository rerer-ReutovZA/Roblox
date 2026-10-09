-- Модели из Blender (art/blender) поверх процедурных построек.
--
-- Шаблоны лежат в ServerStorage.Assets (импорт art/export/fbx/*.fbx через 3D Importer, см. docs/ART_PIPELINE.md).
-- Процедурный строитель по-прежнему создаёт «скелет» постройки: подсказки ProximityPrompt, атрибуты,
-- коллизии, свет, дым. Если для ключа модели есть шаблон, его детали становятся видимой частью,
-- а процедурные детали — невидимыми коллизиями. Нет шаблона — остаётся процедурная модель.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local AssetName = require(ReplicatedStorage.Shared.AssetName)
local ModelText = require(ReplicatedStorage.Shared.Config.ModelText)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)

local Templates = {}

local ANIM_TAGS = { "Spin", "Slide", "Bob", "Sway", "Pulse" }
local MARKER = "Origin__Pivot"
-- группы, которые остаются видимыми (NPC-фигуры до перехода на аватары)
local KEEP_VISIBLE = { Figure = true }

type Prepared = {
	parts: { { part: BasePart, info: AssetName.Parsed, rel: CFrame } },
	scale: number,
}

local cache: { [string]: Prepared | false } = {}

local function findTemplate(key: string): Model?
	local folder = ServerStorage:FindFirstChild("Assets")
	if not folder then
		return nil
	end
	for _, d in ipairs(folder:GetDescendants()) do
		if d:IsA("Model") and d.Name == key and d:FindFirstChild(MARKER, true) then
			return d
		end
	end
	return nil
end

-- Разбирает шаблон один раз: относительные CFrame деталей от маркера начала координат и масштаб импорта
local function prepare(key: string): Prepared?
	local cached = cache[key]
	if cached ~= nil then
		return cached or nil
	end
	local template = findTemplate(key)
	if not template then
		cache[key] = false
		return nil
	end
	local marker = template:FindFirstChild(MARKER, true) :: BasePart
	-- маркер — куб 1x1x1: по нему видно, в каких единицах импортирован файл
	local scale = 1 / math.max(marker.Size.X, 1e-3)
	local root = marker.CFrame
	local prepared: Prepared = { parts = {}, scale = scale }
	for _, d in ipairs(template:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= MARKER then
			local info = AssetName.parse(d.Name)
			if info then
				table.insert(prepared.parts, { part = d, info = info, rel = root:ToObjectSpace(d.CFrame) })
			end
		end
	end
	cache[key] = prepared
	return prepared
end

function Templates.has(key: string): boolean
	return prepare(key) ~= nil
end

local function insideKept(inst: Instance, model: Model): boolean
	local node = inst.Parent
	while node and node ~= model do
		if KEEP_VISIBLE[node.Name] then
			return true
		end
		node = node.Parent
	end
	return false
end

-- SurfaceGui с собственным именем — живой текст (табло выработки): такая деталь остаётся как есть
local function hasLiveGui(part: BasePart): boolean
	for _, c in ipairs(part:GetChildren()) do
		if c:IsA("SurfaceGui") and c.Name ~= "Label" then
			return true
		end
	end
	return false
end

-- Процедурные детали: декоративные удаляются, носители подсказок/эффектов/хитбоксы становятся невидимыми.
-- Коллизии дают детали шаблона (корпус), поэтому невидимые стены не мешают игроку.
local function hideProcedural(model: Model)
	for _, d in ipairs(model:GetDescendants()) do
		if not d.Parent or insideKept(d, model) or d:GetAttribute("KeepVisible") then
			continue
		end
		for _, tag in ipairs(ANIM_TAGS) do
			if d:HasTag(tag) then
				d:RemoveTag(tag)
			end
		end
		if d:IsA("BasePart") then
			if hasLiveGui(d) then
				continue
			end
			local invisible = d.Transparency >= 1
			local functional = #d:GetChildren() > 0 or invisible or d == model.PrimaryPart
			if not functional then
				d:Destroy()
			elseif not invisible then
				d.Transparency = 1
				d.CastShadow = false
				d.CanCollide = false
			end
		elseif d:IsA("SurfaceGui") and d.Name == "Label" then
			d.Enabled = false
		elseif d:IsA("Decal") then
			d.Transparency = 1
		end
	end
end

-- Детали, которые двигаются или растут, не сталкиваются с игроком
local NO_COLLIDE_GROUPS = { Bush = true, Tubers = true, Flames = true }

local function collides(info: AssetName.Parsed): boolean
	if info.anim or info.pivot then
		return false
	end
	for _, name in ipairs(info.path) do
		if NO_COLLIDE_GROUPS[name] then
			return false
		end
	end
	return true
end

-- Находит или создаёт вложенную группу (процедурные Bush/Tubers/Stack переиспользуются)
local function group(parent: Instance, name: string, origin: CFrame): Model
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Model") then
		return existing
	end
	local m = Instance.new("Model")
	m.Name = name
	m.WorldPivot = origin
	m.Parent = parent
	return m
end

local function applyAnimation(inst: Instance, anim: string, phaseOffset: number, scale: number)
	local tag, attrs = AssetName.animation(anim)
	if not tag or inst:HasTag(tag) then
		return
	end
	if (tag == "Bob" or tag == "Slide") and attrs.Amplitude then
		attrs.Amplitude *= scale -- ход в стадах растёт вместе с моделью
	end
	if attrs.Phase then
		-- общий сдвиг на модель: лапы одного жука согласованы, а разные жуки — нет
		attrs.Phase += phaseOffset
	end
	for k, v in pairs(attrs) do
		inst:SetAttribute(k, v)
	end
	inst:AddTag(tag)
end

-- Надпись на модели: текст Roblox на грани плоской метки. Исходный текст английский;
-- TextLabel.AutoLocalize (включён по умолчанию) отдаёт его автопереводу Roblox.
local function addLabel(part: BasePart, label: ModelText.Label, color: Color3, neon: boolean)
	part.Transparency = 1
	part.CastShadow = false
	local gui = Instance.new("SurfaceGui")
	gui.Name = "ModelText"
	gui.Face = (Enum.NormalId :: any)[label.face] or Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.LightInfluence = if neon then 0 else 1
	gui.Brightness = if neon then 2 else 1
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBlack
	text.TextScaled = true
	text.TextColor3 = color
	text.Text = label.text
	text.Parent = gui
	gui.Parent = part
end

export type DressOptions = {
	scale: number?, -- например, жук-босс в 3 раза больше
	tint: { [string]: Color3 }?, -- перекраска ключа палитры (цвет дрона по сотруднику)
}

-- Ставит детали шаблона в модель. origin — CFrame пятна постройки (как у процедурного строителя).
function Templates.dress(model: Model, key: string, origin: CFrame, opts: DressOptions?): boolean
	local prepared = prepare(key)
	if not prepared then
		return false
	end
	local o: DressOptions = opts or {}
	hideProcedural(model)
	local userScale = o.scale or 1
	-- позиции деталей — в единицах импорта (масштаб по маркеру); точки вращения в именах — уже в стадах
	local s = prepared.scale * userScale
	local animated: { [Instance]: boolean } = {}
	local phaseOffset = math.random()
	for _, rec in ipairs(prepared.parts) do
		local info = rec.info
		local part = rec.part:Clone()
		for _, child in ipairs(part:GetChildren()) do
			if child:IsA("SurfaceAppearance") or child:IsA("Decal") or child:IsA("Texture") then
				child:Destroy()
			end
		end
		local spec = Palette[info.key]
		if spec then
			part.Color = spec.color
			part.Material = spec.material
			part.Transparency = spec.transparency or 0
		end
		local tint = o.tint and o.tint[info.key]
		if tint then
			part.Color = tint
		end
		if s ~= 1 then
			part.Size *= s
		end
		part.CFrame = origin * (CFrame.new(rec.rel.Position * s) * rec.rel.Rotation)
		part.Anchored = true
		part.CanCollide = collides(info)
		part.CanQuery = part.CanCollide
		part.CanTouch = false
		part.CastShadow = part.Size.Magnitude > 0.6
		part.Locked = true
		-- путь групп; у анимируемой группы (#x,y,z) точка вращения совпадает с пустышкой из Blender
		local container: Instance = model
		for i, name in ipairs(info.path) do
			local isScope = i == #info.path and info.pivot ~= nil
			local pivot = if isScope then origin * CFrame.new((info.pivot :: Vector3) * userScale) else origin
			container = group(container, name, pivot)
			if isScope and info.anim and not animated[container] then
				-- группа могла появиться раньше как промежуточная (дети обработаны первыми)
				animated[container] = true
				local m = container :: Model
				m.WorldPivot = pivot
				applyAnimation(m, info.anim, phaseOffset, userScale)
			end
		end
		if info.anim and not info.pivot then
			applyAnimation(part, info.anim, phaseOffset, userScale)
		end
		local labels = ModelText[key]
		local label = info.label and labels and labels[info.label]
		if label then
			addLabel(part, label, part.Color, part.Material == Enum.Material.Neon)
			part.CanCollide = false
			part.CanQuery = false
		elseif info.label then
			part.Transparency = 1 -- метка без текста (устаревший экспорт)
		end
		if table.find(info.path, "Flames") then
			-- пламя шаттла видно только во время старта (Effects.launch)
			part.Transparency = 1
			part:SetAttribute("LaunchOnly", true)
		end
		part.Parent = container
	end
	model:SetAttribute("Template", key)
	return true
end

-- Для тестов: сбросить кэш (после добавления шаблонов в ServerStorage.Assets)
function Templates.reset()
	table.clear(cache)
end

return Templates
