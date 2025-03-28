require "/scripts/viera/vUtil.lua"

function build(directory, config, parameters, level, seed)
  parameters.UID = parameters.UID or sb.makeUuid()
  parameters.chocoboName = parameters.chocoboName or name()
  parameters.music = parameters.music or config.music or nil
  parameters.state = parameters.state or config.state or "filled"
  parameters.healed = parameters.healed or config.healed or false
  parameters.maxHealth = parameters.maxHealth or config.maxHealth
  parameters.currentHealth = parameters.currentHealth or parameters.maxHealth or config.maxHealth
  parameters.protection = parameters.protection  or config.protection
  parameters.jumpLimit = parameters.jumpLimit  or config.jumpLimit
  parameters.moveSpeed = parameters.moveSpeed  or config.moveSpeed
  parameters.waterSpeed = parameters.waterSpeed  or config.waterSpeed
  parameters.imageBreed = parameters.imageBreed or config.imageBreed
  parameters.imageColor = parameters.imageColor or config.imageColor
  parameters.chocoboBreed = parameters.chocoboBreed or config.chocoboBreed
  parameters.equippedSaddle = parameters.equippedSaddle or "naked"
  parameters.equippedSaddleJumpLimit = parameters.equippedSaddleJumpLimit or 0
  parameters.equippedSaddleMoveSpeed = parameters.equippedSaddleMoveSpeed or 0
  parameters.equippedSaddleWaterSpeed = parameters.equippedSaddleWaterSpeed or 0
  parameters.equippedBarding = parameters.equippedBarding or "naked"
  parameters.equippedBardingHealth = parameters.equippedBardingHealth or 0
  parameters.equippedBardingProtection = parameters.equippedBardingProtection or 0
  parameters.percentHealth = parameters.currentHealth/(parameters.maxHealth+parameters.equippedBardingHealth)
  
  parameters = cleanupGear("saddle",parameters.equippedSaddle,parameters)
  parameters = cleanupGear("barding",parameters.equippedBarding,parameters)
  
  parameters.emptyInventoryIcon  = parameters.emptyInventoryIcon or string.format("/items/active/viera/chocobocall/calls/%s/%s/icon.png:empty", parameters.imageBreed, parameters.imageColor)
  parameters.filledInventoryIcon = parameters.filledInventoryIcon or string.format("/items/active/viera/chocobocall/calls/%s/%s/icon.png:full", parameters.imageBreed, parameters.imageColor)
  parameters.inventoryIcon = parameters.inventoryIcon or parameters.filledInventoryIcon
  
  if parameters.state == "filled" then
    parameters.displayState = "^cyan;Dismissed^reset;"
  elseif parameters.state == "empty" then
    parameters.displayState = "^green;Summoned^reset;"   
  end
  
  parameters.errorImage    =  string.format("/vehicles/viera/chocobo/error.png")
  parameters.saddlefImage  =  string.format("/items/active/viera/chocobogear/chocobosaddle/%s/saddlef.png:idle.1", parameters.equippedSaddle)
  parameters.saddleImage   =  string.format("/items/active/viera/chocobogear/chocobosaddle/%s/saddle.png:idle.1", parameters.equippedSaddle)
  parameters.saddlebImage  =  string.format("/items/active/viera/chocobogear/chocobosaddle/%s/saddleb.png:idle.1", parameters.equippedSaddle)
  parameters.bardingfImage =  string.format("/items/active/viera/chocobogear/chocobobarding/%s/bardingf_silent.png:idle.1", parameters.equippedBarding)
  parameters.bardingImage  =  string.format("/items/active/viera/chocobogear/chocobobarding/%s/barding_silent.png:idle.1", parameters.equippedBarding)
  parameters.bardingbImage =  string.format("/items/active/viera/chocobogear/chocobobarding/%s/bardingb_silent.png:idle.1", parameters.equippedBarding)
  parameters.wingImage     =  string.format("/vehicles/viera/chocobo/%s/%s/chocowing.png:idle.1", parameters.imageBreed, parameters.imageColor)
  parameters.legfImage     =  string.format("/vehicles/viera/chocobo/%s/%s/chocolegf.png:idle.1", parameters.imageBreed, parameters.imageColor)
  parameters.bustImage     =  string.format("/vehicles/viera/chocobo/%s/%s/chocobust_silent_stare.png:idle.1", parameters.imageBreed, parameters.imageColor)
  parameters.backImage     =  string.format("/vehicles/viera/chocobo/%s/%s/chocoback_silent_still.png:idle.1", parameters.imageBreed, parameters.imageColor)
  parameters.legbImage     =  string.format("/vehicles/viera/chocobo/%s/%s/chocolegb.png:idle.1", parameters.imageBreed, parameters.imageColor)
      
  config.tooltipFields = config.tooltipFields or {}  
  config.tooltipFields.chocoboLabel    = string.format("^red;%s - %s^reset;", parameters.chocoboName, parameters.chocoboBreed)
  config.tooltipFields.stateLabel      = string.format("^orange;RE-EQUIP CALL TO UPDATE^reset;")
  config.tooltipFields.saddleLabel     = string.format("^red;%s^reset;", saddle(parameters.equippedSaddle))
  config.tooltipFields.bardingLabel    = string.format("^red;%s^reset;", barding(parameters.equippedBarding))
  config.tooltipFields.healthLabel     = string.format("^red;%s/%s^reset;", parameters.currentHealth, (parameters.maxHealth+parameters.equippedBardingHealth))
  config.tooltipFields.protectionLabel = string.format("^red;%s^reset;", (parameters.protection+parameters.equippedBardingProtection))
  config.tooltipFields.moveSpeedLabel  = string.format("^red;%s^reset;", (parameters.moveSpeed+parameters.equippedSaddleMoveSpeed))
  config.tooltipFields.waterSpeedLabel = string.format("^red;%s^reset;", (parameters.waterSpeed+parameters.equippedSaddleWaterSpeed))
  config.tooltipFields.jumpLimitLabel  = string.format("^red;%s^reset;", (parameters.jumpLimit+parameters.equippedSaddleJumpLimit))
  config.tooltipFields.errorImage    = "/vehicles/viera/chocobo/error.png"
  config.tooltipFields.saddlefImage  = parameters.saddlefImage
  config.tooltipFields.saddleImage   = parameters.saddleImage
  config.tooltipFields.saddlebImage  = parameters.saddlebImage
  config.tooltipFields.bardingfImage = parameters.bardingfImage
  config.tooltipFields.bardingImage  = parameters.bardingImage
  config.tooltipFields.bardingbImage = parameters.bardingbImage
  config.tooltipFields.wingImage     = parameters.wingImage
  config.tooltipFields.legfImage     = parameters.legfImage
  config.tooltipFields.bustImage     = parameters.bustImage
  config.tooltipFields.backImage     = parameters.backImage
  config.tooltipFields.legbImage     = parameters.legbImage
  return config, parameters
end

function name()
  math.randomseed(os.time())
  for i=1,math.random(3,9) do 
    local toss = math.random() 
  end
  local names = root.assetJson("/vehicles/viera/chocobo/viera_chocobo.config:chocoboNames")
  return names[math.random(1,#names)]
end

function saddle(x)
  local names = root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:saddleNames")
  return names[x]
end

function barding(x)
  local names = root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:bardingNames")
  return names[x]
end

function cleanupGear(style,equipped,parameters)
  local keep = nil
  local good = vUtil.cleanup({equipped},root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:"..style.."Names"))
  for _,this in pairs(good) do
    if this ~= "naked" or keep == nil then
	  keep = this	  
	end
  end
  if keep == "naked" then
    if style == "saddle" then
      parameters.equippedSaddle = "naked"
      parameters.equippedSaddleJumpLimit = 0
      parameters.equippedSaddleMoveSpeed = 0
      parameters.equippedSaddleWaterSpeed = 0
	elseif style  == "barding" then
      parameters.equippedBarding = "naked"
      parameters.equippedBardingHealth = 0
      parameters.equippedBardingProtection = 0
	end
  end
  return parameters
end