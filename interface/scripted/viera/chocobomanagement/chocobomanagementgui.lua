require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/viera/vUtil.lua"

function init()
  self.chocoboData = {}
  self.chocoboItems = {} 
  self.saddleOptions = {}
  self.bardingOptions = {}
  self.selectedSaddle = nil  
  self.selectedBarding = nil  
  self.selectedChocobo = nil  
  self.saddleList  = "saddleScrollArea.saddleList"
  self.bardingList = "bardingScrollArea.bardingList"
  self.chocoboList = "chocoboScrollArea.chocoboList"
  self.gearPath = "/items/active/viera/chocobogear/chocobo%s/%s/%s.png:idle.1"
  self.chocoboPath = "/vehicles/viera/chocobo/%s/%s/choco%s.png:idle.1"
  self.greenHealAmount = config.getParameter("greenHealAmount")
  self.managerPosition = {world.entityPosition(pane.sourceEntity())[1],world.entityPosition(pane.sourceEntity())[2]}  
  self.saddleTiers = root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:saddleTiers")
  self.saddleStats = root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:saddleStats")
  self.bardingTiers = root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:bardingTiers")
  self.bardingStats = root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:bardingStats")  
  populateChocoboList()
  populateSaddleList()
  populateBardingList()
end

function update(dt)
  populateChocoboList()
  populateSaddleList()
  populateBardingList()
end

function populateChocoboList() 
  self.chocoboData = {}
  local chocoboItems = {}
  local storageChocoboItems = searchStorage() 
  for s = 1,#storageChocoboItems do
    local thisItem = storageChocoboItems[s]
    thisItem = cleanupGear("saddle",thisItem.parameters.equippedSaddle,thisItem)
    thisItem = cleanupGear("barding",thisItem.parameters.equippedBarding,thisItem)
	table.insert(chocoboItems,thisItem)
  end
  
  local playerChocoboItems = searchPlayer()
  for p = 1,#playerChocoboItems do
    local thisItem = playerChocoboItems[p]
    thisItem = cleanupGear("saddle",thisItem.parameters.equippedSaddle,thisItem)
    thisItem = cleanupGear("barding",thisItem.parameters.equippedBarding,thisItem)
	table.insert(chocoboItems,thisItem)
  end
  
  table.sort(chocoboItems, function(a, b)
    return chocoboHealth(a,"factor") < chocoboHealth(b,"factor")
  end)
  
  widget.setVisible("emptyChocoboLabel", #chocoboItems == 0)
  
  if not compare(chocoboItems, self.chocoboItems) then
    self.chocoboItems = chocoboItems
    self.playerChocoboItems = playerChocoboItems
    self.storageChocoboItems = storageChocoboItems
    widget.clearListItems(self.chocoboList)
    widget.setButtonEnabled("healButton", false)
    widget.setButtonEnabled("equipButton", false)
    
	local t = #self.chocoboItems or 0
    for i,item in pairs(self.chocoboItems) do
      local p = 1
      local params = {}
      local values = {}
      local config = root.itemConfig(item.name)
      local icon = self.chocoboData[item.parameters.UID].icon
      local name = item.parameters.chocoboName or "Chocobo"
      local chocobo = string.format("%s.%s", self.chocoboList, widget.addListItem(self.chocoboList))
      local description = string.format("%s (%s)", name, config.config.chocoboBreed)
      icon = util.absolutePath(config.directory, icon)
      widget.setImage(string.format("%s.icon", chocobo), icon)
      widget.setText(string.format("%s.name", chocobo), description)
      widget.setProgress(string.format("%s.health", chocobo), chocoboHealth(item,"percentage"))
      widget.setData(chocobo, i)	  
      for parameter,value in pairs(item.parameters) do
        params[p] = parameter
        values[p] = value
	    p = p+1
      end
      --vUtil.showLog("POPULATING CALL ITEM "..i.." of "..t, params, values)
    end

    self.selectedChocobo = nil
    showGreenCost(nil)
  end
end

function searchStorage()
  local chocoboItems = {}
  local nearbyStorage = world.objectQuery(self.managerPosition, 500, { name = "viera_chocobostable2" })
  for s = 1,#nearbyStorage do
    local storageID = nearbyStorage[s]
	local storageSize = world.getObjectParameter(storageID,"slotCount")
	local storageIcon = world.getObjectParameter(storageID,"inventoryIcon")
	for i = 1,storageSize do
	  local slot = "storedChocobo"..i
	  local chocobo = world.getObjectParameter(storageID,slot)
	  if chocobo ~= nil then
	    self.chocoboData[chocobo.parameters.UID] = {}
	    self.chocoboData[chocobo.parameters.UID].icon = storageIcon
	    self.chocoboData[chocobo.parameters.UID].stall = "stall_"..i
		self.chocoboData[chocobo.parameters.UID].storageID = storageID
		self.chocoboData[chocobo.parameters.UID].storageSize = storageSize
	    table.insert(chocoboItems,chocobo)
	  end
	end
  end
  return chocoboItems
end

function searchPlayer()
  local chocoboItems = {}
  local playerItems = player.itemsWithTag("chocobocall")
  for p = 1,#playerItems do
    local chocobo = playerItems[p]
	if chocobo ~= nil then
	  self.chocoboData[chocobo.parameters.UID] = {}
	  self.chocoboData[chocobo.parameters.UID].icon = chocobo.parameters.inventoryIcon
	  self.chocoboData[chocobo.parameters.UID].stall = "player"
	  self.chocoboData[chocobo.parameters.UID].storageID = nil
	  self.chocoboData[chocobo.parameters.UID].storageSize = 0
	  table.insert(chocoboItems,chocobo)
	end
  end
  return chocoboItems
end

function populateSaddleList()
  local unlockedChocoboSaddles = player.getProperty("unlockedChocoboSaddles")
  
  widget.setVisible("emptySaddleLabel", #unlockedChocoboSaddles == 0)
  
  if not compare(unlockedChocoboSaddles, self.unlockedChocoboSaddles) then
    self.saddleOptions = {}
    self.unlockedChocoboSaddles = unlockedChocoboSaddles
    widget.clearListItems(self.saddleList)
    
    for i,saddle in pairs(self.unlockedChocoboSaddles) do
      local icon  = string.format("/items/active/viera/chocobogear/chocobosaddle/%s/icon.png", saddle)
      local names = root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:saddleNames")
      local name  = string.format("%s", names[saddle])
	  local thisSaddle = widget.addListItem(self.saddleList)
      local saddleOption = string.format("%s.%s", self.saddleList, thisSaddle)
	  
	  self.saddleOptions[saddle] = thisSaddle
	  
      widget.setImage(string.format("%s.icon", saddleOption), icon)
      widget.setText(string.format("%s.name", saddleOption), name)
      widget.setData(saddleOption, saddle)
    end

    self.selectedSaddle = nil
  end
end

function populateBardingList()
  local unlockedChocoboBarding = player.getProperty("unlockedChocoboBarding")
  
  widget.setVisible("emptyBardingLabel", #unlockedChocoboBarding == 0)
  
  if not compare(unlockedChocoboBarding, self.unlockedChocoboBarding) then
    self.BardingOptions = {}
    self.unlockedChocoboBarding = unlockedChocoboBarding
    widget.clearListItems(self.bardingList)
    
    for i,barding in pairs(self.unlockedChocoboBarding) do
      local icon  = string.format("/items/active/viera/chocobogear/chocobobarding/%s/icon.png", barding)
      local names = root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:bardingNames")
      local name  = string.format("%s", names[barding])
	  local thisBarding = widget.addListItem(self.bardingList)
      local bardingOption = string.format("%s.%s", self.bardingList, thisBarding)
	  
	  self.bardingOptions[barding] = thisBarding
	  
      widget.setImage(string.format("%s.icon", bardingOption), icon)
      widget.setText(string.format("%s.name", bardingOption), name)
      widget.setData(bardingOption, barding)
    end

    self.selectedBarding = nil
  end
end

function updateDisplay(style,item)
  if style == "clear" then
    widget.setImage("chocoboDisplay.wing", "")  
    widget.setImage("chocoboDisplay.legf", "")  
    widget.setImage("chocoboDisplay.bust", "")  
    widget.setImage("chocoboDisplay.back", "")  
    widget.setImage("chocoboDisplay.legb", "") 
    widget.setImage("chocoboDisplay.saddlef", "")  
    widget.setImage("chocoboDisplay.saddle", "")  
    widget.setImage("chocoboDisplay.saddleb", "")
    widget.setImage("chocoboDisplay.bardingf", "")   
    widget.setImage("chocoboDisplay.barding", "")   
    widget.setImage("chocoboDisplay.bardingb", "")   
  elseif style == "chocobo" then
    widget.setImage("chocoboDisplay.wing", string.format(self.chocoboPath,item.parameters.imageBreed,item.parameters.imageColor,"wing"))  
    widget.setImage("chocoboDisplay.legf", string.format(self.chocoboPath,item.parameters.imageBreed,item.parameters.imageColor,"legf"))  
    widget.setImage("chocoboDisplay.bust", string.format(self.chocoboPath,item.parameters.imageBreed,item.parameters.imageColor,"bust_silent_stare"))  
    widget.setImage("chocoboDisplay.back", string.format(self.chocoboPath,item.parameters.imageBreed,item.parameters.imageColor,"back_silent_still"))  
    widget.setImage("chocoboDisplay.legb", string.format(self.chocoboPath,item.parameters.imageBreed,item.parameters.imageColor,"legb")) 
    widget.setImage("chocoboDisplay.saddlef", string.format(self.gearPath,"saddle",item.parameters.equippedSaddle,"saddlef")) 
    widget.setImage("chocoboDisplay.saddle",  string.format(self.gearPath,"saddle",item.parameters.equippedSaddle,"saddle")) 
    widget.setImage("chocoboDisplay.saddleb", string.format(self.gearPath,"saddle",item.parameters.equippedSaddle,"saddleb")) 
    widget.setImage("chocoboDisplay.bardingf", string.format(self.gearPath,"barding",item.parameters.equippedBarding,"bardingf_silent")) 
    widget.setImage("chocoboDisplay.barding",  string.format(self.gearPath,"barding",item.parameters.equippedBarding,"barding_silent")) 
    widget.setImage("chocoboDisplay.bardingb", string.format(self.gearPath,"barding",item.parameters.equippedBarding,"bardingb_silent")) 
  elseif style == "saddle" then
    widget.setImage("chocoboDisplay."..style.."f", string.format(self.gearPath, style, item, style.."f")) 
    widget.setImage("chocoboDisplay."..style,      string.format(self.gearPath, style, item, style)) 
    widget.setImage("chocoboDisplay."..style.."b", string.format(self.gearPath, style, item, style.."b")) 
  elseif style == "barding" then
    widget.setImage("chocoboDisplay."..style.."f", string.format(self.gearPath, style, item, style.."f_silent")) 
    widget.setImage("chocoboDisplay."..style,      string.format(self.gearPath, style, item, style.."_silent")) 
    widget.setImage("chocoboDisplay."..style.."b", string.format(self.gearPath, style, item, style.."b_silent")) 
  end
  widget.setButtonEnabled("equipButton", false)	
  if self.selectedChocobo then
    local selectedData = widget.getData(string.format("%s.%s", self.chocoboList, self.selectedChocobo))
    local chocobo = self.chocoboItems[selectedData]
    local equippedSaddle = chocobo.parameters.equippedSaddle
    local equippedBarding = chocobo.parameters.equippedBarding
    if chocobo.parameters.state == "empty" then
      widget.setText("healButton", string.format("HEAL"))
    else
      widget.setText("healButton", string.format("HEAL"))	
	end
    if self.selectedSaddle or self.selectedBarding then	  
      local selectedSaddle = widget.getData(string.format("%s.%s", self.saddleList, self.selectedSaddle))
      local selectedBarding = widget.getData(string.format("%s.%s", self.BardingList, self.selectedBarding))
	  if self.selectedSaddle and equippedSaddle ~= selectedSaddle then
        widget.setButtonEnabled("equipButton", true)
	  end
	  if self.selectedBarding and equippedBarding ~= selectedBarding then
        widget.setButtonEnabled("equipButton", true)
	  end
	end
  end
  --vUtil.showLog( "UDPATING DISPLAY", { "style", "item" }, { style, item } )
end

-- SELECTED ITEM FUNCTION, TRIGGERED FROM CONFIG
function itemSelected(widgetName)
  if widgetName == "saddleList" then
    self.selectedSaddle = widget.getListSelected(self.saddleList)
    --vUtil.showLog( "SADDLE SELECTED", { "widgetName", "self.selectedSaddle" }, { widgetName, self.selectedSaddle } )
    if self.selectedSaddle and self.selectedChocobo then
      local saddle = widget.getData(string.format("%s.%s", self.saddleList, self.selectedSaddle))
	  updateDisplay("saddle", saddle)
    end
  elseif widgetName == "bardingList" then
    self.selectedBarding = widget.getListSelected(self.bardingList)
    --vUtil.showLog( "BARDING SELECTED", { "widgetName", "self.selectedBarding" }, { widgetName, self.selectedBarding } )
    if self.selectedBarding then
      local barding = widget.getData(string.format("%s.%s", self.bardingList, self.selectedBarding))
	  updateDisplay("barding", barding)
    end
  elseif widgetName == "chocoboList" then
    self.unlockedChocoboSaddles = nil
    self.unlockedChocoboBarding = nil
    populateSaddleList()
    populateBardingList()
    self.selectedChocobo = widget.getListSelected(self.chocoboList)
    if self.selectedChocobo then
      local selectedData = widget.getData(string.format("%s.%s", self.chocoboList, self.selectedChocobo))
      local chocobo = self.chocoboItems[selectedData]
      local saddle = chocobo.parameters.equippedSaddle
	  local saddleOption = self.saddleOptions[saddle]
      local barding = chocobo.parameters.equippedBarding
	  local bardingOption = self.bardingOptions[barding]
      --vUtil.showLog( "CHOCOBO SELECTED", 
	  --  { "widgetName", "selectedData", "chocobo", "saddle", "self.saddleOptions", "saddleOption", "barding", "self.bardingOptions", "bardingOption" }, 
      --  { widgetName, selectedData, chocobo, saddle, self.saddleOptions, saddleOption, barding, self.bardingOptions, bardingOption } 
	  --)
	  widget.setListSelected(self.saddleList,saddleOption)
	  widget.setListSelected(self.bardingList,bardingOption)
      self.selectedSaddle = widget.getListSelected(self.saddleList)
      self.selectedBarding = widget.getListSelected(self.bardingList)
      self.selectedChocobo = widget.getListSelected(self.chocoboList)
	  updateDisplay("chocobo",chocobo)
      showGreenCost(chocobo)
    end
  else
    return
  end
end

-- PERFORM EQUIP FUNCTIONS, TRIGGERED FROM CONFIG
function doEquip()
  if self.selectedChocobo then
    if self.selectedSaddle or self.selectedBarding then
      local selectedData = widget.getData(string.format("%s.%s", self.chocoboList, self.selectedChocobo))
      local chocobo = self.chocoboItems[selectedData]
      if chocobo ~= nil then
        if self.chocoboData[chocobo.parameters.UID].storageID ~= nil then
          local equippedChocobo = equipping(chocobo, "STORAGE")
          updateRemotely(equippedChocobo)
	    else
          if player.consumeItem(chocobo,nil,true) then
            local equippedChocobo = equipping(chocobo, "INVENTORY")
            player.giveItem(equippedChocobo)
          end
		end
        updateDisplay("clear",nil)
        self.chocoboItems = {} 
        populateChocoboList()
      end
	end
  end
end

function equipping(chocobo, style)
  local equippedChocobo  = copy(chocobo)
  --vUtil.showLog( "EQUIPPING "..style,{ "chocobo", "equippedChocobo", "self.selectedSaddle", "self.selectedBarding" },{ chocobo, equippedChocobo, self.selectedSaddle, self.selectedBarding })
  if self.selectedSaddle then
    local saddle = widget.getData(string.format("%s.%s", self.saddleList, self.selectedSaddle))
	local saddleOption = self.saddleOptions[saddle]
    --vUtil.showLog("SELECTING SADDLE",{ "self.saddleOptions", "saddleOption", "saddle" },{ self.saddleOptions, saddleOption, saddle })
	equippedChocobo.parameters.equippedSaddle = saddle
	equippedChocobo.parameters.equippedSaddle = saddle
	equippedChocobo.parameters.equippedSaddleJumpLimit = self.saddleStats[self.saddleTiers[saddle]].jumpLimit
	equippedChocobo.parameters.equippedSaddleMoveSpeed = self.saddleStats[self.saddleTiers[saddle]].moveSpeed
	equippedChocobo.parameters.equippedSaddleWaterSpeed = self.saddleStats[self.saddleTiers[saddle]].waterSpeed
    equippedChocobo.parameters.saddlefImage = string.format(self.gearPath, "saddle", saddle, "saddlef")
    equippedChocobo.parameters.saddleImage  = string.format(self.gearPath, "saddle", saddle, "saddle")
    equippedChocobo.parameters.saddlebImage = string.format(self.gearPath, "saddle", saddle, "saddleb")
  end
  if self.selectedBarding then
    local barding = widget.getData(string.format("%s.%s", self.bardingList, self.selectedBarding))
	local bardingOption = self.bardingOptions[barding]
    local maximumHealth = equippedChocobo.parameters.maxHealth + self.bardingStats[self.bardingTiers[barding]].health
    --vUtil.showLog( "SELECTING BARDING",{ "self.bardingOptions", "bardingOption", "barding" },{ self.bardingOptions, bardingOption, barding })
	equippedChocobo.parameters.equippedBarding = barding
	equippedChocobo.parameters.equippedBardingHealth = self.bardingStats[self.bardingTiers[barding]].health
	equippedChocobo.parameters.equippedBardingProtection = self.bardingStats[self.bardingTiers[barding]].protection
    equippedChocobo.parameters.bardingfImage = string.format(self.gearPath, "barding", barding, "bardingf_silent")
    equippedChocobo.parameters.bardingImage  = string.format(self.gearPath, "barding", barding, "barding_silent")
    equippedChocobo.parameters.bardingbImage = string.format(self.gearPath, "barding", barding, "bardingb_silent")	
    equippedChocobo.parameters.currentHealth = math.floor((maximumHealth*equippedChocobo.parameters.percentHealth)+0.5)
	equippedChocobo.parameters.healed = true
  end
  local p = 1
  local params = {}
  local values = {}
  for parameter,value in pairs(equippedChocobo.parameters) do
    params[p] = parameter
	values[p] = value
	p = p+1
  end
  --vUtil.showLog( "EQUIPPED CALL ITEM", params, values )
  return equippedChocobo
end

-- PERFORM HEAL FUNCTIONS, TRIGGERED FROM CONFIG
function doHeal()
  if self.selectedChocobo then
    local selectedData = widget.getData(string.format("%s.%s", self.chocoboList, self.selectedChocobo))
    local chocobo = self.chocoboItems[selectedData]
    if chocobo ~= nil then
      if self.chocoboData[chocobo.parameters.UID].storageID ~= nil then
        local healedChocobo = healing(chocobo, "STORAGE")
        updateRemotely(healedChocobo)
	  else
        if player.consumeItem(chocobo,nil,true) then
          local healedChocobo = healing(chocobo, "INVENTORY")
		  player.giveItem(healedChocobo)
        end
	  end
      populateChocoboList()
    end
  end
end

function healing(chocobo, style)
  local healedChocobo  = copy(chocobo)
  local consumed = player.consumeItem({name = "viera_gysahlgreens", count = healCost(chocobo)}, true)
  if consumed then
    local healAmount = consumed.count * self.greenHealAmount
	local returnedHealth = chocoboHealth(healedChocobo,nil) + healAmount
	local maximumHealth = healedChocobo.parameters.maxHealth + healedChocobo.parameters.equippedBardingHealth
    healedChocobo.parameters.currentHealth = math.max(maximumHealth, returnedHealth)
    healedChocobo.parameters.percentHealth = returnedHealth/maximumHealth
	healedChocobo.parameters.healed = true
  end
  --vUtil.showLog( "HEALING "..style, 
  --  { "chocobo", "currentHealth", "chocobo", "injured health", "healedChocobo", "healed health" }, 
  --  { chocobo, chocoboHealth(chocobo,nil), chocobo, chocoboHealth(chocobo,nil), healedChocobo, chocoboHealth(healedChocobo,nil) }  
  --)
  return healedChocobo
end

-- EXTRA HEAL FUNCTIONS
function healCost(chocobo)
  if chocobo == nil then return 0 end
  local healAmount = (chocobo.parameters.maxHealth + chocobo.parameters.equippedBardingHealth) - chocoboHealth(chocobo,nil)
  return math.ceil(healAmount / self.greenHealAmount)
end

function chocoboHealth(chocobo,style)
  local maxHealth = (chocobo.parameters.maxHealth + chocobo.parameters.equippedBardingHealth)
  local currentHealth = chocobo.parameters.currentHealth or 1.0
  if style == "factor" then
    return maxHealth+((currentHealth/maxHealth)/10)
  elseif style == "percentage" then
    return currentHealth/maxHealth
  end
  return currentHealth
end

function showGreenCost(chocobo)
  local enableButton = false
  local greensCount = player.hasCountOfItem("viera_gysahlgreens")
  if greensCount > 99999 then 
    widget.setText("ownedGreens", string.format("+99999"))
  else
    widget.setText("ownedGreens", string.format("%s", greensCount))
  end  
  if chocobo and healCost(chocobo) > 0 then
    if greensCount > 0 then enableButton = true end
    widget.setText("neededGreens", string.format("%s", healCost(chocobo)))
  else
    widget.setText("neededGreens", string.format("--"))
  end
  widget.setButtonEnabled("healButton", enableButton)
end

-- UPDATE REMOTELY
function updateRemotely(chocobo)
  local choco = self.chocoboData[chocobo.parameters.UID]
  local data = {}
  data.chocobo = {}
  data.thisUID = {}
  data.lastUID = {}
  for i = 1,choco.storageSize do
    local stall = "stall_"..i
    data.chocobo[stall] = nil
    data.thisUID[stall] = nil
    data.lastUID[stall] = nil
  end
  data.chocobo[choco.stall] = chocobo
  world.sendEntityMessage(choco.storageID, "setStorageData", data, true)
end

-- REMOVE MISSING GEAR ****
function cleanupGear(style,equipped,chocobo)
  local keep = nil
  local good = vUtil.cleanup({equipped},root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:"..style.."Names"))
  for _,this in pairs(good) do
    if this ~= "naked" or keep == nil then
	  keep = this	  
	end
  end
  if keep == "naked" then
    if style == "saddle" then
      chocobo.parameters.equippedSaddle = "naked"
      chocobo.parameters.equippedSaddleJumpLimit = 0
      chocobo.parameters.equippedSaddleMoveSpeed = 0
      chocobo.parameters.equippedSaddleWaterSpeed = 0
	elseif style  == "barding" then
      chocobo.parameters.equippedBarding = "naked"
      chocobo.parameters.equippedBardingHealth = 0
      chocobo.parameters.equippedBardingProtection = 0
	end
  end
  return chocobo
end