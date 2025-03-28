require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/viera/vUtil.lua"

function init()  
  storage.state = storage.state or config.getParameter("state") or "filled"
  storage.currentHealth = storage.currentHealth or config.getParameter("currentHealth")
  storage.percentHealth = storage.percentHealth or config.getParameter("percentHealth")  
  storage.healed = storage.healed or config.getParameter("healed") or false
  
  self.chocoboID = nil
  self.respawnTimer = 0 
  self.updateMSG = {}  
  self.updateID = {}  
  self.updating = false
  self.dismissMSG = {}  
  self.dismissID = {}  
  self.dismissing = false
  self.blocked, self.placeable, self.empty = 1, 2, 3
  self.imageParts = { "saddlefImage", "saddleImage", "saddlebImage", "bardingfImage", "bardingImage", "bardingbImage", "wingImage", "legfImage", "bustImage", "backImage", "legbImage" }
  self.bardingName = barding()
  self.saddleName = saddle()

  if storage.state == "filled" then
    self.vehicleState = self.blocked
    self.initializing = true
  else
    self.vehicleState = self.empty
    self.initializing = false
  end
  activeItem.setScriptedAnimationParameter("vehicleState", self.vehicleState)  
  for i=1,#self.imageParts do
    activeItem.setScriptedAnimationParameter(self.imageParts[i], config.getParameter(self.imageParts[i]))
  end
  updateIcon()
  
  --showLog("INITIALIZE CALL")
end

function activate(fireMode, shiftHeld)
  --showLog("CALL ACTIVATE")
  if storage.state == "filled" then
    if self.vehicleState == self.placeable then
      world.spawnVehicle(config.getParameter("vehicleType"), activeItem.ownerAimPosition(), getParameters())
      storage.state = "empty"
      self.vehicleState = self.empty
      activeItem.setInstanceValue("state", storage.state)
      activeItem.setScriptedAnimationParameter("vehicleState", self.vehicleState)
      animator.playSound("placeOk")
      self.initializing = true
      --showLog("SUMMON")
    else
      animator.playSound("placeBad")
    end
  else
    sendNearby("DISMISS")
  end
  updateIcon()
end

function getParameters()
  return {
	UID = config.getParameter("UID"),
    name = config.getParameter("chocoboName"),
    breed = config.getParameter("imageBreed"),
    color = config.getParameter("imageColor"),
    music = config.getParameter("music"),
    tandem = config.getParameter("tandem"),
    waterSpeed = config.getParameter("waterSpeed"),
    moveSpeed = config.getParameter("moveSpeed"),
    jumpSpeed = config.getParameter("jumpSpeed"),
    jumpLimit = config.getParameter("jumpLimit"),
    jumpDelay = config.getParameter("jumpDelay"),
    maxHealth = config.getParameter("maxHealth"),
    protection = config.getParameter("protection"),
    materialKind = config.getParameter("materialKind"),
    chocoboBreed = config.getParameter("chocoboBreed"),
    currentHealth = config.getParameter("currentHealth"),
    percentHealth = config.getParameter("percentHealth"),
    equippedSaddle = config.getParameter("equippedSaddle"),
    equippedSaddleJumpLimit = config.getParameter("equippedSaddleJumpLimit"),
    equippedSaddleMoveSpeed = config.getParameter("equippedSaddleMoveSpeed"),
    equippedSaddleWaterSpeed = config.getParameter("equippedSaddleWaterSpeed"),
    equippedBarding = config.getParameter("equippedBarding"),
    equippedBardingHealth = config.getParameter("equippedBardingHealth"),
    equippedBardingProtection = config.getParameter("equippedBardingProtection"),
    fromItem = true
  }
end

function update(dt)	
  updateTooltip()
  if storage.state == "filled" then
    if self.respawnTimer > 0 then
      self.respawnTimer = self.respawnTimer - dt
      self.vehicleState = self.empty
    else
      if placementValid() then
        self.vehicleState = self.placeable
      else
        self.vehicleState = self.blocked
      end
    end
  else
    if not self.dismissing and not self.updating then
	  sendNearby("UPDATE")
	elseif self.updating then
	  checkSent("UPDATE")
    elseif self.dismissing then
	  checkSent("DISMISS")
	end
  end
  activeItem.setScriptedAnimationParameter("vehicleState", self.vehicleState)  
  
  local playerItem = player.swapSlotItem()
  if playerItem ~= nil then
    if playerItem.parameters ~= nil then
      if playerItem.parameters.chocoboName ~= nil then
	    if config.getParameter("UID") == playerItem.parameters.UID then
          setTooltip("^orange;RE-EQUIP CALL TO UPDATE^reset;", true)
	    end
      end
    end
  end
end

function sendNearby(style)
  local v = 0
  local vehiclesNearby = {}
  local nearby = world.entityQuery(entity.position(), 1000, {includedTypes = {"vehicle"}, order = "nearest"})
  --vUtil.showLog(style.." NEARBY", {"entity.position()", "nearby"}, {entity.position(), nearby} )
  for i,vehicle in pairs(nearby) do
    --vUtil.showLog("NEARBY", {"i", "vehicle"}, {i, vehicle} )
    if style == "UPDATE" then
      if not contains(self.updateID, vehicle) then
		v = v+1
		local data = getParameters()
		data.healed = storage.healed
	    self.updateID[v] = vehicle
        self.updateMSG[v] = world.sendEntityMessage(vehicle, "update", config.getParameter("UID"), data)
        self.updating = true
        --showLog("UPDATING....")
      end
    elseif style == "DISMISS" then
      if not contains(self.dismissID, vehicle) then
		v = v+1
        self.dismissID[v] = vehicle
        self.dismissMSG[v] = world.sendEntityMessage(vehicle, "store", config.getParameter("UID"))
        self.dismissing = true
		--showLog("DISMISSING....")
      end
    end
  end
end
	  
function checkSent(style)
  local v = 0
  local checkID = {}
  local checkMSG ={}
  local checkAgain = {}
  if style == "UPDATE" then
    checkID = self.updateID
	checkMSG = self.updateMSG
	self.updateID = {}
	self.updateMSG = {}
    self.updating = false
  elseif style == "DISMISS" then
    checkID = self.dismissID
	checkMSG = self.dismissMSG 
	self.dismissID = {}
	self.dismissMSG = {}
    self.dismissing = false
  else
    return
  end
  --vUtil.showLog("CHECKING "..style.."....", { "checkMSG" }, { checkMSG })
  for i,msg in pairs(checkMSG) do
    local id = checkID[i]
    if msg:finished() then
      --vUtil.showLog("CHECKING FINISHED....", {  }, {  })
      local msgResult = msg:result()
      if msgResult then
        --vUtil.showLog("CHECKING RESULT....", { "msgResult" }, { msgResult })
		if style == "UPDATE" then
	      self.updating = false
		  if msgResult.useThis then
	        self.chocoboID = msgResult.ID
	        activeItem.setInstanceValue("healed", false)
			updateHealth(msgResult)
		  end		  
		elseif style == "DISMISS" then
	      self.dismissing = false
          if msgResult.storable then
            --showLog("DISMISSED!!!")
            storage.state = "filled"
            self.vehicleState = self.blocked
            self.respawnTimer = config.getParameter("respawnTime")
            activeItem.setInstanceValue("state", storage.state)
			updateHealth(msgResult)
            updateIcon()		
          end
		end
      end
    else
      if style == "UPDATE" then
	    v = v+1
	    self.updateID[v] = id
        self.updateMSG[v] = msg
      elseif style == "DISMISS" then
	    v = v+1 
        self.dismissID[v] = id
	    self.dismissMSG[v] = msg
      end
	  checkAgain[checkID[i]] = msg
    end
  end
  if style == "UPDATE" and #self.updateMSG > 0 then
	self.updating = true	
  elseif style == "DISMISS" and #self.dismissMSG > 0 then
	self.dismissing = true	
  end
  --vUtil.showLog("DONE CHECK....", { "checkAgain" }, { checkAgain })
end

function updateHealth(data)
  storage.currentHealth = data.currentHealth
  storage.percentHealth = storage.currentHealth/(config.getParameter("maxHealth")+config.getParameter("equippedBardingHealth"))
  activeItem.setInstanceValue("currentHealth", storage.currentHealth)
  activeItem.setInstanceValue("percentHealth", storage.percentHealth)
end

function updateTooltip()  
  local displayState = ""
  if config.getParameter("state") == "filled" then
    displayState = "^cyan;Dismissed^reset;"
  elseif config.getParameter("state") == "empty" then
    displayState = "^green;Summoned^reset;"   
  end
  if self.chocoboID ~= nil or self.initializing then 
    setTooltip(string.format("Currently - %s", displayState), false)
  else
    setTooltip("^orange;CHOCOBO OUT OF RANGE^reset;", true) 
  end
end

function setTooltip(stateLabel,err)
  local c,ei = "^white;", ""
  if err then
    c = "^red;"
	ei = config.getParameter("errorImage")
  end
  local tooltip = config.getParameter("tooltipFields") or {}
  tooltip.chocoboLabel    = string.format("%s%s - %s^reset;", c, config.getParameter("chocoboName"), config.getParameter("chocoboBreed"))
  tooltip.stateLabel      = string.format("%s", stateLabel)
  tooltip.saddleLabel     = string.format("%s%s^reset;", c, saddle())
  tooltip.bardingLabel    = string.format("%s%s^reset;", c, barding())
  tooltip.healthLabel     = string.format("%s%s/%s^reset;", c, config.getParameter("currentHealth"), (config.getParameter("maxHealth")+config.getParameter("equippedBardingHealth")))
  tooltip.protectionLabel = string.format("%s%s^reset;", c, (config.getParameter("protection")+config.getParameter("equippedBardingProtection")))
  tooltip.moveSpeedLabel  = string.format("%s%s^reset;", c, (config.getParameter("moveSpeed")+config.getParameter("equippedSaddleMoveSpeed")))
  tooltip.waterSpeedLabel = string.format("%s%s^reset;", c, (config.getParameter("waterSpeed")+config.getParameter("equippedSaddleWaterSpeed")))
  tooltip.jumpLimitLabel  = string.format("%s%s^reset;", c, (config.getParameter("jumpLimit")+config.getParameter("equippedSaddleJumpLimit")))
  tooltip.errorImage      = ei
  tooltip.saddlefImage    = config.getParameter("saddlefImage")
  tooltip.saddleImage     = config.getParameter("saddleImage")
  tooltip.saddlebImage    = config.getParameter("saddlebImage")
  tooltip.bardingfImage   = config.getParameter("bardingfImage")
  tooltip.bardingImage    = config.getParameter("bardingImage")
  tooltip.bardingbImage   = config.getParameter("bardingbImage")
  tooltip.wingImage       = config.getParameter("wingImage")
  tooltip.legfImage       = config.getParameter("legfImage")
  tooltip.bustImage       = config.getParameter("bustImage")
  tooltip.backImage       = config.getParameter("backImage")
  tooltip.legbImage       = config.getParameter("legbImage")
  activeItem.setInstanceValue("tooltipFields", tooltip)
end

function updateIcon()
  if storage.state == "filled" then
    animator.setAnimationState("controller", "full")
    activeItem.setInventoryIcon(config.getParameter("filledInventoryIcon"))
  else
    animator.setAnimationState("controller", "empty")
    activeItem.setInventoryIcon(config.getParameter("emptyInventoryIcon"))
  end
end

function placementValid()
  local aimPosition = activeItem.ownerAimPosition()
  if world.lineTileCollision(mcontroller.position(), aimPosition) then
    return false
  end
  local vehicleBounds = {
    config.getParameter("vehicleBoundingBox")[1] + aimPosition[1],
    config.getParameter("vehicleBoundingBox")[2] + aimPosition[2],
    config.getParameter("vehicleBoundingBox")[3] + aimPosition[1],
    config.getParameter("vehicleBoundingBox")[4] + aimPosition[2]
  }
  if world.rectTileCollision(vehicleBounds, {"Null", "Block", "Dynamic", "Slippery"}) then
    return false
  end
  return true
end

function saddle()
  local names = root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:saddleNames")
  return names[config.getParameter("equippedSaddle")]
end

function barding()
  local names = root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:bardingNames")
  return names[config.getParameter("equippedBarding")]
end

function showLog(title)
  vUtil.showLog(title,
    { 
	  "self.chocoboID", "self.updating", "self.updateID", "self.updateMSG", "self.dismissing", "self.dismissID", "self.dismissMSG", "storage.state", 
	  "config.getParameter(state)", "config.getParameter(chocoboID)", "config.getParameter(UID)", "config.getParameter(currentHealth)", "config.getParameter(percentHealth)" 
	},
    { 
	  self.chocoboID, self.updating, self.updateID, self.updateMSG, self.dismissing, self.dismissID, self.dismissMSG, storage.state, 
	  config.getParameter("state"), config.getParameter("chocoboID"), config.getParameter("UID"), config.getParameter("currentHealth"), config.getParameter("percentHealth") 
	}
  )
end

function uninit() 
  storage.state = config.getParameter("state")
  storage.currentHealth = config.getParameter("currentHealth")
  storage.percentHealth = config.getParameter("percentHealth")
  storage.healed = config.getParameter("healed")
  
  if storage.state == "empty" then
    setTooltip("^orange;RE-EQUIP CALL TO UPDATE^reset;", true)
  end
  --showLog("UNINITIALIZE CALL")
end