function build(directory, config, parameters, level, seed)
  local displayStyle = ""
  local displayCategoy = ""
  local style = config.style or ""
  local imagePath = string.format("/items/active/viera/chocoboconsumable/%s/%s/icon.png", config.category, config.itemName)
  parameters.healAmount = parameters.healAmount or config.healAmount or nil
  parameters.appliedEffects = parameters.appliedEffects or config.appliedEffects or {}
  
  if config.category == "chocobofood" then
	displayCategoy = "Chocobo Food"
  end
  
  if style ~= "" then
    displayStyle = "^yellow;["..case(style).."]^reset; "  
  end
  
  config.tooltipFields = config.tooltipFields or {}  
  config.tooltipFields.subTitle = string.format("^yellow;%s^reset;", displayCategoy)
  config.tooltipFields.dLabel = string.format("%s%s", displayStyle, config.description)
  config.tooltipFields.dImage = string.format("%s", imagePath)
  return config, parameters
end

function case(s)
  return (s:gsub("^%l", string.upper))
end
