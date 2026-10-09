-- Реестр всех моделей построек: ключ из Config.Items[...].model → функция-строитель

local Kit = require(script.Parent.ModelKit)

local Library = {}

local builders: { [string]: (Kit.Builder, any) -> () } = {}
for _, moduleScript in ipairs(script.Parent.Models:GetChildren()) do
	if moduleScript:IsA("ModuleScript") and moduleScript.Name ~= "Misc" then
		for key, fn in pairs(require(moduleScript) :: any) do
			if type(fn) == "function" and string.match(key, "^%u") then
				builders[key] = fn
			end
		end
	end
end

function Library.has(key: string): boolean
	return builders[key] ~= nil
end

-- Строит модель постройки. origin — CFrame пятна на полу базы.
function Library.build(item, origin: CFrame, parent: Instance): Model
	local b = Kit.new(item.id, origin)
	local builder = builders[item.model]
	if builder then
		builder(b, item)
	else
		warn("[ModelLibrary] нет модели " .. tostring(item.model) .. ", ставлю заглушку")
		b:box(Vector3.new(item.size[1], 2, item.size[2]), Vector3.new(0, 1, 0), Kit.C.metal, Enum.Material.Metal)
	end
	b.model:SetAttribute("ItemId", item.id)
	return b:finish(parent)
end

return Library
