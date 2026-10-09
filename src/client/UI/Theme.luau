-- Оформление интерфейса и помощники для создания элементов

local Theme = {}

Theme.Colors = {
	Panel = Color3.fromRGB(28, 32, 42),
	PanelLight = Color3.fromRGB(42, 48, 62),
	Card = Color3.fromRGB(50, 57, 74),
	Stroke = Color3.fromRGB(255, 255, 255),
	Text = Color3.fromRGB(245, 245, 250),
	Muted = Color3.fromRGB(170, 178, 195),
	Cash = Color3.fromRGB(120, 230, 110),
	Gold = Color3.fromRGB(255, 205, 60),
	Star = Color3.fromRGB(255, 225, 90),
	Energy = Color3.fromRGB(90, 200, 255),
	Danger = Color3.fromRGB(240, 80, 70),
	Accent = Color3.fromRGB(255, 160, 50),
	Button = Color3.fromRGB(70, 175, 90),
	ButtonOff = Color3.fromRGB(85, 90, 105),
	Purple = Color3.fromRGB(165, 110, 255),
}

Theme.Font = Enum.Font.GothamBold
Theme.FontBlack = Enum.Font.GothamBlack
Theme.FontRegular = Enum.Font.Gotham

-- New("Frame", {props}, {children})
function Theme.New(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				(inst :: any)[k] = v
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function Theme.corner(radius: number?): UICorner
	return Theme.New("UICorner", { CornerRadius = UDim.new(0, radius or 10) })
end

function Theme.stroke(color: Color3?, thickness: number?, transparency: number?): UIStroke
	return Theme.New("UIStroke", {
		Color = color or Theme.Colors.Stroke,
		Thickness = thickness or 1.5,
		Transparency = transparency or 0.85,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Theme.padding(px: number): UIPadding
	local u = UDim.new(0, px)
	return Theme.New("UIPadding", { PaddingLeft = u, PaddingRight = u, PaddingTop = u, PaddingBottom = u })
end

function Theme.label(props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = Theme.Font,
		TextColor3 = Theme.Colors.Text,
		TextScaled = true,
		Text = "",
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	return Theme.New("TextLabel", defaults)
end

function Theme.button(props: { [string]: any }, onClick: () -> ()): TextButton
	local defaults = {
		BackgroundColor3 = Theme.Colors.Button,
		Font = Theme.Font,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		AutoButtonColor = true,
		Text = "",
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	local button = Theme.New("TextButton", defaults, { Theme.corner(8) })
	button.Activated:Connect(onClick)
	return button
end

return Theme
