require "/scripts/util.lua"
require "/scripts/viera/vUtil.lua"

function init()  
  self.debug = false
  self.hiLimit = 1
  self.talkDelay = 0.5
  self.minShrugTime = 50
  self.maxShrugTime = 200
  self.minWagTime = 40
  self.maxWagTime = 400
  self.wagFrameDelay = 1
  self.wagFrames = {1,2,3,2,1}
  self.wagFrameLimit = #self.wagFrames
  self.minCrouchTime = 200
  self.maxCrouchTime = 600
  self.minStandTime = 300
  self.maxStandTime = 1200
  self.minBlinkTime = 5
  self.maxBlinkTime = 15
  self.minStareTime = 20
  self.maxStareTime = 150
  self.warpStates = {"inEnergy","inMatter","outMatter","outEnergy"}
  self.warpableStates = {"idle","idleShrug","crouch","crouchShrug"}  
  self.newborn = {}
  self.talking = {}
  self.wasTalking = {} 
  self.shrugging = {} 
  self.crouching = {}
  self.blinking = {}
  self.wagging = {} 
  self.groundAnimation = {}
  self.fleeing = {}  
  self.hiCount = {}
  self.talkTimer = {}
  self.shrugTimer = {}
  self.shrugRandomDelay = {}
  self.wagTimer = {}
  self.wagFrameCount = {}
  self.wagRandomDelay = {}
  self.crouchTimer = {}
  self.crouchRandomDelay = {}
  self.blinkTimer = {}
  self.blinkRandomDelay = {}    
  self.wagState = {}
  self.talkState = {}
  self.blinkState = {}  
  self.shrugState = {}  
  self.crouchState = {}  
  self.thisUID = nil
  self.lastUID = nil
  
  storage.chocobo = storage.chocobo or {}
  storage.thisUID = storage.thisUID or {}
  storage.lastUID = storage.lastUID or {}
  storage.slotCount = config.getParameter("slotCount")  
  animator.setAnimationState("stall", "stall")  
  
  for i = 1, storage.slotCount do
    local stall = "stall_"..i
    resetStall(stall)
	if storage.chocobo[stall] == nil then
      animator.setAnimationState(string.format("movement_%s",stall), "hide")  
	else
	  animateChocobo(stall, "idle")
	end	
  end
  setStoredChocobo()
    
  message.setHandler("getStorageData",
    function()
      return { 
        chocobo = storage.chocobo,
        thisUID = storage.thisUID,
        lastUID = storage.lastUID,
        position = object.position()
	  }
    end
  )
  
  message.setHandler("setStorageData",
    function( _,_, data, remote)
      --vUtil.showLog("SET STORAGE DATA()",{},{})	  
      for i = 1, storage.slotCount do
        local stall = "stall_"..i
	    if remote then		
	      if storage.chocobo[stall] and data.chocobo[stall] then
            --vUtil.showLog("WARP IN PLACE",{},{})
	        animator.playSound("warp")
	        animateChocobo(stall, "inEnergy")
		  end
          storage.chocobo[stall] = data.chocobo[stall] or storage.chocobo[stall] or nil
          storage.thisUID[stall] = data.thisUID[stall] or storage.thisUID[stall] or nil
          storage.lastUID[stall] = data.lastUID[stall] or storage.lastUID[stall] or nil  
        else
	      if storage.chocobo[stall] and not data.chocobo[stall] then
            --vUtil.showLog("WARP OUT",{},{})
	        animator.playSound("warp")
	        animateChocobo(stall, "outMatter")
            animator.playSound("return")
	        resetStall(stall)
	      end
          storage.chocobo[stall] = data.chocobo[stall] or nil
          storage.thisUID[stall] = data.thisUID[stall] or nil
          storage.lastUID[stall] = data.lastUID[stall] or nil
	    end
      end	  
	  setStoredChocobo()
    end
  )
end

-- ******************************
-- **** MAIN UPDATE FUNCTION ****
-- ******************************
function update(dt)
  for i = 1, storage.slotCount do
    local state = "idle"
    local stall = "stall_"..i
	self.lastUID = storage.lastUID[stall]
	self.thisUID = storage.thisUID[stall]	
	if storage.chocobo[stall] then
      if self.debug then showDebug(i) end
      if not contains(self.warpStates,animator.animationState(string.format("movement_%s",stall))) then

	    -- warp in or move
		if self.thisUID ~= self.lastUID and self.thisUID then
	      storage.lastUID[stall] = storage.thisUID[stall]
          --vUtil.showLog("WARP IN",{},{})
	      animator.playSound("warp")
		  state = "inEnergy"
		else
          getRandomStates(dt,stall)		  
		end
		
		-- animate
	    animateChocobo(stall, state)
	  end
	end
  end
end
-- ******************************
-- ******************************

function setStoredChocobo()
  --vUtil.showLog("SET STORED CHOCOBO()",{},{})
  for i = 1, storage.slotCount do
    local stall = "stall_"..i
    local param = "storedChocobo"..i
    object.setConfigParameter(param,storage.chocobo[stall])
  end
end

function eject(item)
  --vUtil.showLog("EJECT()",{},{})
  if item then
    world.spawnItem(item.name, object.position(), item.count, item.parameters)
  end
end

function die(smash)
  --vUtil.showLog("DIE()",{},{})
  for i = 1, storage.slotCount do
    local stall = "stall_"..i
	resetStall(stall)
    eject(storage.chocobo[stall])
  end
end

-- **** CROUCH/BLINK/SHRUG/TALK FUNCTIONS ****
function getRandomStates(dt,stall)
  --vUtil.showLog("GET RANDOM STATES()",{},{})
  local stallState = string.format("movement_%s",stall)
  
  -- say hi
  if self.newborn[stall] then sayHi(stall) end	  
  
  -- crouch
  if self.crouchTimer[stall] <= self.crouchRandomDelay[stall] then
    self.crouchTimer[stall] = self.crouchTimer[stall]+(dt*10)	
  else
	crouch(stall)
  end
  
  -- blink
  if self.blinkTimer[stall] <= self.blinkRandomDelay[stall] then
    self.blinkTimer[stall] = self.blinkTimer[stall]+(dt*10)
  else
    blink(stall)
  end
    
  -- shrug
  if animator.animationState(stallState) ~= "idleShrug" and animator.animationState(stallState) ~= "crouchShrug" then
    self.shrugging[stall] = false
  end
  if self.shrugTimer[stall] <= self.shrugRandomDelay[stall] then
    self.shrugTimer[stall] = self.shrugTimer[stall]+(dt*10)
  else
    shrug(stall)
  end
  
  -- wag
  if self.wagTimer[stall] <= self.wagRandomDelay[stall] then
    self.wagTimer[stall] = self.wagTimer[stall]+(dt*10)
  else
    wag(stall)
  end
  
  -- talk
  if self.talking[stall] and self.wasTalking[stall] and self.talkTimer[stall] <= self.talkDelay then
    self.talkTimer[stall] = self.talkTimer[stall]+dt
  elseif self.talking[stall] then
    talk(stall)  
  end
    
  -- set movement animation state
  if self.groundAnimation[stall] then
    if self.shrugging[stall] then
      --vUtil.showLog("SHRUGGING",{},{})
      animator.setAnimationState(stallState, string.format("%s",self.shrugState[stall]))
    elseif self.crouching[stall] then    
      --vUtil.showLog("CROUCHING",{},{})
      animator.setAnimationState(stallState, string.format("%s",self.crouchState[stall]))
    else
      --vUtil.showLog("IDLING",{},{})
      animator.setAnimationState(stallState, "idle")
    end
  end
end

-- **** BLINK ****
function blink(stall)
  --vUtil.showLog("BLINK()",{},{})
  self.blinkTimer[stall] = 0
  if self.blinking[stall] then
  --sb.logInfo("  ==> STARE")
    self.blinking[stall] = false
	self.blinkState[stall] = "stare"
	self.blinkRandomDelay[stall] = math.random(self.minStareTime,self.maxStareTime)
  else
  --sb.logInfo("  ==> BLINK")
    self.blinking[stall] = true
	self.blinkState[stall] = "blink"
	self.blinkRandomDelay[stall] = math.random(self.minBlinkTime,self.maxBlinkTime)
  end
  animator.setPartTag(string.format("bust_%s",stall), "eyes", string.format("%s",self.blinkState[stall])) 
end

-- **** CROUCH ****
function crouch(stall)
  --vUtil.showLog("CROUCH()",{},{})
  self.crouchTimer[stall] = 0
  if self.crouching[stall] then
  --sb.logInfo("  ==> IDLE")
    self.crouching[stall] = false
	self.crouchState[stall] = "idle"
	self.crouchRandomDelay[stall] = math.random(self.minStandTime,self.maxStandTime)
  else
  --sb.logInfo("  ==> CROUCH")
    self.crouching[stall] = true
	self.crouchState[stall] = "crouch"
	self.crouchRandomDelay[stall] = math.random(self.minCrouchTime,self.maxCrouchTime)
  end
end

-- **** SHRUG ****
function shrug(stall)
  --vUtil.showLog("SHRUG()",{},{})
  self.shrugging[stall] = true
  self.shrugTimer[stall] = 0
  self.shrugRandomDelay[stall] = math.random(self.minShrugTime,self.maxShrugTime)
  if self.crouching[stall] then
  --sb.logInfo("  ==> CROUCHSHRUG")  
	self.shrugState[stall] = "crouchShrug"
  else
  --sb.logInfo("  ==> IDLESHURG")
	self.shrugState[stall] = "idleShrug"
  end
end

-- **** WAG ****
function wag(stall)
  --vUtil.showLog("WAG()",{},{})
  self.wagTimer[stall] = 0
  if self.wagFrameCount[stall] < self.wagFrameLimit then
  --sb.logInfo("  ==> WAGGING: %s", self.wagFrameCount[stall]+1)  
    self.wagFrameCount[stall] = self.wagFrameCount[stall] + 1
	self.wagState[stall] = "wag_"..string.format("%s",self.wagFrames[self.wagFrameCount[stall]])
    self.wagRandomDelay[stall] = self.wagFrameDelay  
  else
  --sb.logInfo("  ==> DONE WAGGING")
    self.wagFrameCount[stall] = 0
	self.wagState[stall] = "still"
    self.wagRandomDelay[stall] = math.random(self.minWagTime,self.maxWagTime)  
  end
  animator.setPartTag(string.format("back_%s",stall), "tail", string.format("%s",self.wagState[stall])) 
end

-- **** TALK ****
function talk(stall)  
  --vUtil.showLog("TALK()",{},{})
  if self.talkTimer[stall] <= self.talkDelay then
  --sb.logInfo("  ==> NOISY")
    self.talkState[stall] = "noisy"
    self.wasTalking[stall] = true
  else
  --sb.logInfo("  ==> SILENT")
    self.talkState[stall] = "silent"
    self.talkTimer[stall] = 0
    self.talking[stall] = false
    self.wasTalking[stall] = false  
  end
  animator.setPartTag(string.format("back_%s",stall), "head", string.format("%s",self.talkState[stall])) 
  animator.setPartTag(string.format("bust_%s",stall), "head", string.format("%s",self.talkState[stall]))
end

-- **** SAY HI ON INITIALIZE ****
function sayHi(stall)
  --vUtil.showLog("SAY HI()",{},{})
  self.talking[stall] = true
  animator.playSound("warp")
  self.hiCount[stall] = self.hiCount[stall]+1
  if self.hiCount[stall] > self.hiLimit then
    self.newborn[stall] = false 
  end
end

function animateChocobo(stall,state)
  --vUtil.showLog("ANIMATE CHOCOBO()",{},{})
  local wagState = self.wagState[stall]
  local talkState = self.talkState[stall]
  local blinkState = self.blinkState[stall]
  local breed = storage.chocobo[stall].parameters.imageBreed
  local color = storage.chocobo[stall].parameters.imageColor
  local saddle = storage.chocobo[stall].parameters.equippedSaddle
  local barding = storage.chocobo[stall].parameters.equippedBarding
  animator.setPartTag(string.format("wing_%s",stall), "breed", breed) 
  animator.setPartTag(string.format("legf_%s",stall), "breed", breed) 
  animator.setPartTag(string.format("bust_%s",stall), "breed", breed) 
  animator.setPartTag(string.format("back_%s",stall), "breed", breed) 
  animator.setPartTag(string.format("legb_%s",stall), "breed", breed) 
  animator.setPartTag(string.format("warp_%s",stall), "breed", breed)   
  animator.setPartTag(string.format("wing_%s",stall), "color", color) 
  animator.setPartTag(string.format("legf_%s",stall), "color", color) 
  animator.setPartTag(string.format("bust_%s",stall), "color", color) 
  animator.setPartTag(string.format("back_%s",stall), "color", color) 
  animator.setPartTag(string.format("legb_%s",stall), "color", color) 
  animator.setPartTag(string.format("warp_%s",stall), "color", color) 
  animator.setPartTag(string.format("back_%s",stall), "tail", wagState) 
  animator.setPartTag(string.format("back_%s",stall), "head", talkState) 
  animator.setPartTag(string.format("bust_%s",stall), "head", talkState)
  animator.setPartTag(string.format("bust_%s",stall), "eyes", blinkState)  
  animator.setPartTag(string.format("saddlef_%s",stall), "saddle", saddle)  
  animator.setPartTag(string.format("saddle_%s",stall),  "saddle", saddle)  
  animator.setPartTag(string.format("saddleb_%s",stall), "saddle", saddle)  
  animator.setPartTag(string.format("bardingf_%s",stall), "head", talkState)
  animator.setPartTag(string.format("barding_%s",stall),  "head", talkState)
  animator.setPartTag(string.format("bardingb_%s",stall), "head", talkState)  
  animator.setPartTag(string.format("bardingf_%s",stall), "barding", barding)
  animator.setPartTag(string.format("barding_%s",stall),  "barding", barding)
  animator.setPartTag(string.format("bardingb_%s",stall), "barding", barding)
  animator.setAnimationState(string.format("movement_%s",stall), state)  
end

function resetStall(stall)
  --vUtil.showLog("RESET STALL()",{},{})
  self.newborn[stall] = true
  self.wagging[stall] = false 
  self.fleeing[stall] = false
  self.talking[stall] = false
  self.wasTalking[stall] = false 
  self.blinking[stall] = false
  self.shrugging[stall] = false 
  self.crouching[stall] = false
  self.groundAnimation[stall] = true	 
  self.hiCount[stall] = 0
  self.talkTimer[stall] = 0
  self.shrugTimer[stall] = 0
  self.shrugRandomDelay[stall] = math.random(self.minShrugTime,self.maxShrugTime)
  self.wagTimer[stall] = 0
  self.wagFrameCount[stall] = 0
  self.wagRandomDelay[stall] = math.random(self.minShrugTime,self.maxShrugTime)
  self.crouchTimer[stall] = 0
  self.crouchRandomDelay[stall] = math.random(self.minStandTime,self.maxStandTime)
  self.blinkTimer[stall] = 0
  self.blinkRandomDelay[stall] = math.random(self.minStareTime,self.maxStareTime)  
  self.wagState[stall] = "still"
  self.talkState[stall] = "silent"
  self.blinkState[stall] = "stare"	
  storage.chocobo[stall] = storage.chocobo[stall] or nil
  storage.thisUID[stall] = storage.thisUID[stall] or nil
  storage.lastUID[stall] = storage.lastUID[stall] or nil	
end

-- **** DEBUG DISPLAY ****
function showDebug(s)  
  local stall = "stall_"..s
  local fields = { "STALL","Name","Breed","Color","Saddle","Barding","UID" }
  local values = { 
    s,
    storage.chocobo[stall].parameters.chocoboName,
    storage.chocobo[stall].parameters.imageBreed,
    storage.chocobo[stall].parameters.imageColor,
    storage.chocobo[stall].parameters.equippedSaddle,
    storage.chocobo[stall].parameters.equippedBarding,
    storage.chocobo[stall].parameters.UID
  }
  vUtil.showDebug(fields,values,object.position(),s)
end

function uninit()
end