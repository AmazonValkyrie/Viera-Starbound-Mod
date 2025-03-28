require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/viera/vUtil.lua"

function init(dt)
  -- vUtil.showLog( "INITIALIZE", {  }, {  } )
  -- internal config settings
  self = root.assetJson("/vehicles/viera/chocobo/viera_chocobo.config")
  
  -- calculated config settings
  self.debug = true
  self.driver = nil
  self.lastDriver = nil
  self.driverSpecies = nil
  self.passenger = nil
  self.lastPassenger = nil
  self.passengerSpecies = nil
  self.ivaliceSpecies = {"viera","moogle"}
  self.wagFrameLimit = #self.wagFrames
  self.wagDelay = math.random(self.minShrugTime,self.maxShrugTime)
  self.shrugDelay = math.random(self.minShrugTime,self.maxShrugTime)
  self.blinkDelay = math.random(self.minStareTime,self.maxStareTime)
  self.crouchDelay = math.random(self.minStandTime,self.maxStandTime)
  self.waterSurface = self.maxGroundSearchDistance
  self.hazardDamageTimer = {}
  self.hazardDamageDelay = {}
  for p,v in pairs(self.hazardAlias) do
    self.hazardDamageTimer[p] = 0
    self.hazardDamageDelay[p] = 1	
  end
  
  
  -- movement controller settings
  mcontroller.resetParameters(self.movementSettings)
  self.waterBounds = mcontroller.localBoundBox()
  self.lastPosition = mcontroller.position()  
    
  -- vehicle controller config settings
  self.ID = entity.id()  
  self.UID = config.getParameter("UID")
  self.name = config.getParameter("name")
  self.breed = config.getParameter("breed")
  self.color = config.getParameter("color")
  self.music = config.getParameter("music")
  self.tandem = config.getParameter("tandem")
  self.waterSpeed = config.getParameter("waterSpeed")
  self.moveSpeed = config.getParameter("moveSpeed")
  self.jumpSpeed = config.getParameter("jumpSpeed")
  self.jumpLimit = config.getParameter("jumpLimit")
  self.jumpDelay = config.getParameter("jumpDelay")  
  self.maxHealth = config.getParameter("maxHealth")  
  self.startingHealth = config.getParameter("currentHealth")  
  self.protection = config.getParameter("protection")
  self.materialKind = config.getParameter("materialKind")
  self.equippedSaddle = config.getParameter("equippedSaddle")
  self.equippedSaddleJumpLimit = config.getParameter("equippedSaddleJumpLimit")
  self.equippedSaddleMoveSpeed = config.getParameter("equippedSaddleMoveSpeed")
  self.equippedSaddleWaterSpeed = config.getParameter("equippedSaddleWaterSpeed")
  self.equippedBarding = config.getParameter("equippedBarding")
  self.equippedBardingHealth = config.getParameter("equippedBardingHealth")
  self.equippedBardingProtection = config.getParameter("equippedBardingProtection")
  self.loungePositions = config.getParameter("loungePositions")
  self.driverRideEmote = config.getParameter("driverRideEmote")
  self.driverDamageEmote = config.getParameter("driverDamageEmote")
  self.passengerRideEmote = config.getParameter("passengerRideEmote")
  self.passengerDamageEmote = config.getParameter("passengerDamageEmote")
  self.damageEmoteDelay = config.getParameter("damageEmoteDelay")
  self.movementSettings = config.getParameter("movementSettings")
  self.unoccupiedMovementSettings = config.getParameter("unoccupiedMovementSettings")
  self.singleOccupiedMovementSettings = config.getParameter("singleOccupiedMovementSettings")
  self.doubleOccupiedMovementSettings = config.getParameter("doubleOccupiedMovementSettings")
  self.immunities = config.getParameter("immunities",{})
  vehicle.setLoungeEnabled("passengerSeat",  self.tandem)
  vehicle.setPersistent(self.UID)
    
  cleanupGear("saddle",self.equippedSaddle)
  cleanupGear("barding",self.equippedBarding)
  
  if not storage.health then
    animator.setAnimationState("movement", "inEnergy")
    storage.health = self.startingHealth
  else
    animator.setAnimationState("movement", "idle")
  end
  setAnimationTags()
  setRideEmotes()
    
  --vUtil.showLog( "CHOCOBO INITIALIZING",
  --  { "Name","Breed","Color","ID","chocoboID","UID","Driver","Health","MaxHealth","Music" },
  --  { self.name,self.breed,self.color,self.ID,self.chocoboID,self.UID,self.driver,storage.health,self.maxHealth,self.music }
  --) 
    
  -- setup store functionality
  message.setHandler("store",
    function(_, _, UID) 
	  --vUtil.showLog("STORE CHOCOBO", 
	  --  { "UID", "self.UID", "self.driver" }, 
	  --  { UID, self.UID, self.driver } 
	  --)
      if (self.UID and self.UID == UID and self.driver == nil 
	  and contains(self.warpableStates, animator.animationState("movement"))) then
        self.newborn = true
        animator.playSound("warp")
        animator.setAnimationState("movement", "outMatter")
        animator.playSound("return")
        setMusic()
        return {storable = true, currentHealth = storage.health}
      else
        return {storable = false, currentHealth = storage.health}
      end
    end
  )
  
  message.setHandler("update",
    function(_, _, UID, data) 
	  --vUtil.fieldValues(data,"UPDATE FROM CALL")
	  
      if (self.UID and self.UID == UID) then	    		
        self.equippedSaddle           = data.equippedSaddle or config.getParameter("equippedSaddle")
        self.equippedSaddleJumpLimit  = data.equippedSaddleJumpLimit or config.getParameter("equippedSaddleJumpLimit")
        self.equippedSaddleMoveSpeed  = data.equippedSaddleMoveSpeed or config.getParameter("equippedSaddleMoveSpeed")
        self.equippedSaddleWaterSpeed = data.equippedSaddleWaterSpeed or config.getParameter("equippedSaddleWaterSpeed")
		
        self.equippedBarding           = data.equippedBarding or config.getParameter("equippedBarding")
        self.equippedBardingHealth     = data.equippedBardingHealth or config.getParameter("equippedBardingHealth")
        self.equippedBardingProtection = data.equippedBardingProtection or config.getParameter("equippedBardingProtection")
        setAnimationTags()
        
		if data.healed then
		  storage.health = data.currentHealth or config.getParameter("currentHealth")
		end
        return {useThis = true, ID = self.ID, currentHealth = storage.health}
      else
        return {useThis = false, ID = self.ID, currentHealth = storage.health}
      end
    end
  )
  
  message.setHandler("apply",
    function(_, _, applyHeal, applyEffects, applyStatMutations, applyBodyMutations) 
	  storage.health = storage.health+applyHeal
	  local statMutations = vUtil.fieldValues(applyStatMutations)
	  for i=1,#statMutations do
	    self[statMutations.fields[i]] = self[statMutations.fields[i]] + statMutations.values[i]
	  end
	  self.materialKind = applyBodyMutations.materialKind or config.getParameter("materialKind")
    end
  )
end

function setAnimationTags()  
  animator.setPartTag("wing", "breed", string.format("%s",self.breed)) 
  animator.setPartTag("legf", "breed", string.format("%s",self.breed)) 
  animator.setPartTag("bust", "breed", string.format("%s",self.breed)) 
  animator.setPartTag("back", "breed", string.format("%s",self.breed)) 
  animator.setPartTag("legb", "breed", string.format("%s",self.breed)) 
  animator.setPartTag("warp", "breed", string.format("%s",self.breed)) 
  
  animator.setPartTag("wing", "color", string.format("%s",self.color)) 
  animator.setPartTag("legf", "color", string.format("%s",self.color)) 
  animator.setPartTag("bust", "color", string.format("%s",self.color)) 
  animator.setPartTag("back", "color", string.format("%s",self.color)) 
  animator.setPartTag("legb", "color", string.format("%s",self.color)) 
  animator.setPartTag("warp", "color", string.format("%s",self.color)) 
  
  animator.setPartTag("back", "tail", string.format("%s",self.wagState)) 
  animator.setPartTag("back", "head", string.format("%s",self.talkState)) 
  animator.setPartTag("bust", "head", string.format("%s",self.talkState))
  animator.setPartTag("bust", "eyes", string.format("%s",self.blinkState))
  
  animator.setPartTag("saddlef", "saddle", string.format("%s",self.equippedSaddle))
  animator.setPartTag("saddle",  "saddle", string.format("%s",self.equippedSaddle))
  animator.setPartTag("saddleb", "saddle", string.format("%s",self.equippedSaddle))
  
  animator.setPartTag("bardingf", "barding", string.format("%s",self.equippedBarding))
  animator.setPartTag("barding",  "barding", string.format("%s",self.equippedBarding))
  animator.setPartTag("bardingb", "barding", string.format("%s",self.equippedBarding))
  
  animator.setPartTag("bardingf", "head", string.format("%s",self.talkState))
  animator.setPartTag("barding",  "head", string.format("%s",self.talkState))
  animator.setPartTag("bardingb", "head", string.format("%s",self.talkState))
end


-- ******************************
-- **** MAIN UPDATE FUNCTION ****
-- ******************************
function update(dt)
  -- vUtil.showLog( "UPDATE", {  }, {  } )
  -- display debug data
  if self.debug then 
    showDebug(
      { "Name","Breed","Color","UID","Driver","Health","MaxHealth","Music" },
      { self.name,self.breed,self.color,self.UID,self.driver,storage.health,self.maxHealth+self.equippedBardingHealth,self.music }
    )
  end
  
  -- say hi
  if self.newborn then sayHi() end
  
  -- despwan chocobo
  if mcontroller.atWorldLimit() or animator.animationState("movement") == "hide" then
    vehicle.destroy()
    return
  end
  
  -- return chocobo safely to its nest
  if storage.health <= 0 and not self.fleeing then
    storage.health = 0
	self.fleeing = true
	self.talking = true
    animator.playSound("death")
    animator.playSound("poof")
    animator.burstParticleEmitter("death")
    animator.playSound("warp")
    animator.setAnimationState("movement", "outMatter")
    animator.playSound("return")
    setMusic()
  end
  
  storage.health = math.min(storage.health,self.maxHealth+self.equippedBardingHealth)
    
  -- warp chocobo or move
  if contains(self.warpStates,animator.animationState("movement")) then
    mcontroller.setPosition(self.lastPosition)
    mcontroller.setVelocity({0, 0})
  else
    getDriver(dt)
	getFiring(dt)
	getMovement(dt)
	getFloating(dt)
    getRandomStates(dt)
  end
end
-- ******************************
-- ******************************


-- **** MOUNT/DISMOUNT/RIDING EMOTE FUNCTION ****
function getDriver(dt)
  -- vUtil.showLog( "GETDRIVER()", {  }, {  } )
  self.lastDriver = self.driver
  self.driver = vehicle.entityLoungingIn("driverSeat")
  if self.driver then self.driverSpecies = world.entitySpecies(self.driver) end
  self.lastPassenger = self.passenger
  self.passenger = nil
  if self.tandem then
    self.passenger = vehicle.entityLoungingIn("passengerSeat")
    if self.passenger then self.passengerSpecies = world.entitySpecies(self.passenger) end
  end
  if self.driver ~= self.lastDriver or self.passsenger ~= self.lastPassenger then
    setMusic()
	setRideDance()
  end
  
  -- are we driving?
  if self.driver then
    if self.lastDriver == nil then
	  self.talking = true
      animator.playSound("mount")
    end
    vehicle.setDamageTeam(world.entityDamageTeam(self.driver))
    vehicle.setInteractive(false)
  else
    vehicle.setDamageTeam({type = "passive"})
    vehicle.setInteractive(true)
  end
  
  -- ride emotes
  if self.damageEmoteTimer > self.damageEmoteDelay then
    self.damaged = false
    self.damageEmoteTimer = 0
    setRideEmotes()
  end
  if self.damaged then
    self.damageEmoteTimer = self.damageEmoteTimer + dt
  end  
  
  -- movement settings
  local movementSettings
  mcontroller.resetParameters(self.movementSettings)
  if self.driver and self.passenger then
    movementSettings = self.doubleOccupiedMovementSettings
  elseif self.driver or self.passenger then
    movementSettings = self.singleOccupiedMovementSettings
  else
    movementSettings = self.unoccupiedMovementSettings
  end
  mcontroller.applyParameters(movementSettings)  
end

-- **** PRIMARY/ALT FIRING FUNCTION ****
function getFiring(dt)
  -- vUtil.showLog( "GETFIRING()", {  }, {  } )
  -- primary fire
  if (vehicle.controlHeld("driverSeat", "PrimaryFire")) then
    local fireMode = "primary"
    if not self.firing1 then
	  if not self.talking then 
        animator.playSound("talk1")
        self.firing1 = true;
	    self.talking = true
	  end
    end	
  else
    self.firing1 = false;
  end
  
  -- alt fire
  if (vehicle.controlHeld("driverSeat", "AltFire")) then
    local fireMode = "alt"
    if not self.firing2 then
	  if not self.talking then
        animator.playSound("talk2")
        self.firing2 = true;
	    self.talking = true
	  end
    end
  else
    self.firing2 = false;
  end 
end

-- **** MOVEMENT CONTROL FUNCTION ****
function getMovement(dt)
  -- vUtil.showLog( "GETMOVEMENT()", {  }, {  } )
  -- get horizontal movement
  local moveDir = 0
  if vehicle.controlHeld("driverSeat", "right") then
    moveDir = moveDir + 1
  end
  if vehicle.controlHeld("driverSeat", "left") then
    moveDir = moveDir - 1
  end
  self.moving = math.abs(moveDir)> 0 and true or false
  self.currentFacing = moveDir
  
  -- track if jump button has been released and increment jump counter
  if self.jumping and not vehicle.controlHeld("driverSeat", "jump") then
	self.jumping = false
    self.jumpReleased = true
	self.jumpCount = self.jumpCount+1
  end  
  
  -- go up if previous jump has been released, player is pressing jump key, and hasnt been going up for longer than the jumpDelay
  if self.jumpReleased and vehicle.controlHeld("driverSeat", "jump") and (self.jumpTimer <= self.jumpDelay) then
	self.jumping = true
	if (self.jumpTimer == 0) then
      if (self.jumpCount < (self.jumpLimit+self.equippedSaddleJumpLimit)) or self.jumpLimit == 0 then
        animator.playSound("flap")
	  end
	end
    self.jumpTimer = self.jumpTimer+dt
	if (self.jumpCount < (self.jumpLimit+self.equippedSaddleJumpLimit)) or self.jumpLimit == 0 then
      mcontroller.setYVelocity(self.jumpSpeed)
	end
  else
    self.jumpTimer = 0
	if self.jumping then
      self.jumpReleased = false
	end
  end
  
  -- reset jump count when hitting the ground
  if mcontroller.onGround() or self.floating then 
    self.jumpCount = 0
  end
  
  -- determine if moving backwards or walking and slow speed accodingly
  local speedMod = 1.0
  local walking = false
  local backstepping = false
  local aim = vehicle.aimPosition("driverSeat")
  local localAim = world.distance(aim, mcontroller.position())
  if moveDir * localAim[1] < 0 then backstepping = true end
  if backstepping or walking or self.floating or self.surfacing then speedMod = 0.6 end
  mcontroller.setXVelocity(moveDir * (self.moveSpeed+self.equippedSaddleMoveSpeed) * speedMod)
  
  
  -- determine if on ground/falling/landing/floating
  self.groundAnimation = true
  animator.setFlipped(localAim[1] < 0)
  if mcontroller.onGround() then
	if not self.landed and self.fallTimer >= self.fallDelay then 
      animator.playSound("landing")	
	  self.landed = true
      self.fallTimer = 0
	end
  else
    self.landed = false
    if self.fallTimer >= self.fallDelay and not self.floating then
	  self.groundAnimation = false
	else
      self.fallTimer = self.fallTimer+0.1
	end
  end  
  
  -- play movement sounds
  if self.moving and not self.stillMoving and mcontroller.onGround() then
    animator.playSound("step", -1)
  elseif not self.moving or not mcontroller.onGround() then
    animator.stopAllSounds("step", 0.5)
  end
  if self.moving and not self.stillMoving and self.floating then
    animator.playSound("swim", -1)
  elseif not self.floating then
    animator.stopAllSounds("swim", 0.5)
  end
  
  -- get environmental damage
  if self.driver ~= nil then
    for _, hazardName in pairs(world.environmentStatusEffects(mcontroller.position())) do
	  getHazardDamage(dt, hazardName)
	end
  end
  
  self.stillMoving = self.moving
  self.lastPosition = mcontroller.position()
end

-- **** FLOAT/SURFACE FUNCTION ****
function getFloating(dt)
  -- vUtil.showLog( "GETFLOATING()", {  }, {  } )
  -- work out water surface
  self.waterBounds = mcontroller.localBoundBox()
  self.currentLiquid = mcontroller.liquidPercentage();  
  if (self.currentLiquid > 0) then
    self.waterSurface = (self.waterBounds[4] * self.currentLiquid) + (self.waterBounds[2] * (1.0 - self.currentLiquid))
  else
    self.waterSurface = self.maxGroundSearchDistance
  end
  self.waterBounds[2] = self.waterSurface +0.25
  self.waterBounds[4] = self.waterSurface +0.5
  
  -- get state
  self.floating = self.currentLiquid > self.minLiquidToFloat and self.previousLiquid < self.maxLiquidToFloat
  self.surfacing = self.previousLiquid >= self.maxLiquidToFloat
  if self.floating then
    if self.canSplash then
      animator.playSound("splash")
      self.canSplash = false
	end
  elseif self.surfacing then
    mcontroller.setYVelocity(1)
  else
    self.canSplash = true
  end
  
  -- get floating liquid
  local floatingLiquid = nil
  local liquidName = root.liquidName(mcontroller.liquidId())  
  if self.liquidParticleTypes[liquidName] then
    floatingLiquid = self.liquidParticleTypes[liquidName]
  end
    
  -- set splash emitter (jumping/landing)
  if self.floating and self.currentLiquid > (self.previousLiquid + self.splashEpsilon) then
    if floatingLiquid ~= nil then
      local spEmitter = "splash"..floatingLiquid
      animator.setParticleEmitterOffsetRegion(spEmitter, self.waterBounds)
      animator.burstParticleEmitter(spEmitter)
    end
  end
  
  -- set bow emitter (moving)
  if self.moving and self.floating then
    if floatingLiquid ~= nil then
      local bEmitter = "bow"..floatingLiquid
      local bEmissionRate = self.bowMaxEmission * (math.abs(mcontroller.xVelocity())/(self.waterSpeed+self.equippedSaddleWaterSpeed)) 
      animator.setParticleEmitterEmissionRate(bEmitter, bEmissionRate)
      animator.setParticleEmitterOffsetRegion(bEmitter, self.waterBounds)
      animator.setParticleEmitterActive(bEmitter, true)        
    end
  else
    animator.setParticleEmitterActive("bowLava", false)
    animator.setParticleEmitterActive("bowWater", false)
    animator.setParticleEmitterActive("bowPoison", false)
  end
  
  -- get damage/healing from liquid
  if self.driver ~= nil then
    getHazardDamage(dt, liquidName)
  end
    
  -- cleanup
  self.previousFacing = self.currentFacing
  self.previousLiquid = self.currentLiquid
end

-- **** CROUCH/BLINK/SHRUG/TALK FUNCTIONS ****
function getRandomStates(dt)
  -- vUtil.showLog( "GETRANDOMSTATES()", {  }, {  } )
  -- crouch
  if self.driver and self.crouching then 
	crouch()
  elseif not self.driver then
    if self.crouchTimer <= self.crouchDelay then
      self.crouchTimer = self.crouchTimer+(dt*10)	
	else
	  crouch()
	end
  end  
  
  -- blink
  if self.blinkTimer <= self.blinkDelay then
    self.blinkTimer = self.blinkTimer+(dt*10)
  else
    blink()
  end
    
  -- shrug
  if animator.animationState("movement") ~= "idleShrug" and animator.animationState("movement") ~= "crouchShrug" then
    self.shrugging = false
  end
  if self.shrugTimer <= self.shrugDelay then
    self.shrugTimer = self.shrugTimer+(dt*10)
  else
    shrug()
  end
  
  -- wag
  if self.wagTimer <= self.wagDelay then
    self.wagTimer = self.wagTimer+(dt*10)
  else
    wag()
  end
  
  -- talk
  if self.talking and self.wasTalking and self.talkTimer <= self.talkDelay then
    self.talkTimer = self.talkTimer+dt
  elseif self.talking then
    talk()  
  end
    
  -- set movement animation state
  if self.moving and self.groundAnimation then
    if backstepping then
      animator.setAnimationState("movement", "backstep")
    elseif walking then
      animator.setAnimationState("movement", "walk")
	else
      animator.setAnimationState("movement", "run")
    end
  elseif not self.groundAnimation then
    if mcontroller.yVelocity() > 0.0 then
      animator.setAnimationState("movement", "jump")
    else
      animator.setAnimationState("movement", "fall")
    end 
  elseif self.floating or self.surfacing then
    animator.setAnimationState("movement", "swim")
  elseif self.shrugging then
    animator.setAnimationState("movement", string.format("%s",self.shrugState))
  elseif self.crouching then    
    animator.setAnimationState("movement", string.format("%s",self.crouchState))
  else
    animator.setAnimationState("movement", "idle")
  end
end

-- **** BLINK ****
function blink()
  -- vUtil.showLog( "BLINK()", {  }, {  } )
  self.blinkTimer = 0
  if self.blinking then
  --sb.logInfo("  ==> STARE")
    self.blinking = false
	self.blinkState = "stare"
	self.blinkDelay = math.random(self.minStareTime,self.maxStareTime)
  else
  --sb.logInfo("  ==> BLINK")
    self.blinking = true
	self.blinkState = "blink"
	self.blinkDelay = math.random(self.minBlinkTime,self.maxBlinkTime)
  end
  animator.setPartTag("bust", "eyes", string.format("%s",self.blinkState)) 
end

-- **** CROUCH ****
function crouch()
  -- vUtil.showLog( "CROUCH()", {  }, {  } )
  self.crouchTimer = 0
  if self.crouching then
  --sb.logInfo("  ==> IDLE")
    self.crouching = false
	self.crouchState = "idle"
	self.crouchDelay = math.random(self.minStandTime,self.maxStandTime)
  else
  --sb.logInfo("  ==> CROUCH")
    self.crouching = true
	self.crouchState = "crouch"
	self.crouchDelay = math.random(self.minCrouchTime,self.maxCrouchTime)
  end
end

-- **** SHRUG ****
function shrug()
  -- vUtil.showLog( "SHRUG()", {  }, {  } )
  self.shrugging = true
  self.shrugTimer = 0
  self.shrugDelay = math.random(self.minShrugTime,self.maxShrugTime)
  if self.crouching then
  --sb.logInfo("  ==> CROUCHSHRUG")  
	self.shrugState = "crouchShrug"
  else
  --sb.logInfo("  ==> IDLESHURG")
	self.shrugState = "idleShrug"
  end
end

-- **** WAG ****
function wag()
  -- vUtil.showLog( "WAG()", {  }, {  } )
  self.wagTimer = 0
  if self.wagFrameCount < self.wagFrameLimit then
  --sb.logInfo("  ==> WAGGING: %s", self.wagFrameCount+1)  
    self.wagFrameCount = self.wagFrameCount + 1
	self.wagState = "wag_"..string.format("%s",self.wagFrames[self.wagFrameCount])
    self.wagDelay = self.wagFrameDelay  
  else
  --sb.logInfo("  ==> DONE WAGGING")
    self.wagFrameCount = 0
	self.wagState = "still"
    self.wagDelay = math.random(self.minWagTime,self.maxWagTime)  
  end
  animator.setPartTag("back", "tail", string.format("%s",self.wagState)) 
end

-- **** TALK ****
function talk()  
  -- vUtil.showLog( "TALK()", {  }, {  } )
  if self.talkTimer <= self.talkDelay then
  --sb.logInfo("  ==> NOISY")
    self.talkState = "noisy"
    self.wasTalking = true
  else
  --sb.logInfo("  ==> SILENT")
    self.talkState = "silent"
    self.talkTimer = 0
    self.talking = false
    self.wasTalking = false  
  end
  animator.setPartTag("back", "head", string.format("%s",self.talkState)) 
  animator.setPartTag("bust", "head", string.format("%s",self.talkState))
  animator.setPartTag("bardingf", "head", string.format("%s",self.talkState))
  animator.setPartTag("barding",  "head", string.format("%s",self.talkState))
  animator.setPartTag("bardingb", "head", string.format("%s",self.talkState))
end


-- **** HANDLE ENVIRONMENTAL/LIQUID DAMAGE ****
function getHazardDamage(dt, hazardName)
  local hazardAlias = self.hazardAlias[hazardName] or nil
  if hazardAlias then
    local dr = {}
    dr.sourceEntityId = entity.id()
    dr.damage = self.hazardDamage[hazardAlias]
    dr.damageSourceKind = hazardAlias
    dr.damageType = "Damage"
    if dr.damage < 0 then
      dr.damageType = "IgnoresDef" 	
    end
    self.hazardDamageTimer[hazardName] = math.min(self.hazardDamageTimer[hazardName]+dt,self.hazardDamageDelay[hazardName])
    if not contains(self.immunities,dr.damageSourceKind) then 
      if self.hazardDamageTimer[hazardName] == self.hazardDamageDelay[hazardName] then 
        local dmg = applyDamage(dr)
        local damageHazard = "standard"
        if self.hazardDamageTypes[hazardAlias] then
          damageHazard = self.hazardDamageTypes[hazardAlias]
        end
        if dmg[1].damageDealt < 0 then
          animator.burstParticleEmitter("heal")			
        else
          animator.burstParticleEmitter("damage")		
        end
        animator.burstParticleEmitter(damageHazard.."damage"..math.abs(dmg[1].damageDealt))
        self.hazardDamageTimer[hazardName] = 0
      end
    end
  end
end

-- **** CHOCOBO DAMAGE/DAMAGE EMOTES FUNCTION ****
function applyDamage(damageRequest)
  -- vUtil.showLog( "APPLYDAMAGE()", {  }, {  } )
  local damage = 0
  if damageRequest.damageType == "Damage" then
    damage = damage + root.evalFunction2("protection", damageRequest.damage, self.protection+self.equippedBardingProtection)
  elseif damageRequest.damageType == "IgnoresDef" then
    damage = damage + damageRequest.damage
  else
    return {}
  end
  damage = math.floor(damage+0.5)

  setDamageEmotes()
  local healthLost = math.min(damage, storage.health)
  storage.health = storage.health - healthLost
  storage.health = math.floor(storage.health+0.5)

  return {{
    sourceEntityId = damageRequest.sourceEntityId,
    targetEntityId = entity.id(),
    position = mcontroller.position(),
    damageDealt = damage,
    healthLost = healthLost,
    hitType = "Hit",
    damageSourceKind = damageRequest.damageSourceKind,
    targetMaterialKind = self.materialKind,
    killed = storage.health <= 0
  }}
end

-- **** DAMAGE EMOTES ****
function setDamageEmotes()
  -- vUtil.showLog( "SETDAMAGEEMOTES()", {  }, {  } )
  if not self.damaged then 
    self.damaged = true
    vehicle.setLoungeEmote("driverSeat", self.driverDamageEmote)
    if self.tandem then
      vehicle.setLoungeEmote("passengerSeat", self.passengerDamageEmote)
    end
  end
end

-- **** RIDING EMOTES ****
function setRideEmotes()
  -- vUtil.showLog( "SETRIDEEMOTES()", {  }, {  } )
  vehicle.setLoungeEmote("driverSeat", self.driverRideEmote)
  if self.tandem then
    vehicle.setLoungeEmote("passengerSeat", self.passengerRideEmote)
  end
end

function setRideDance()
  -- vUtil.showLog( "SETRIDEDANCE()", {  }, {  } )
  local driverDance = self.loungePositions.driverSeat.dance
  if vUtil.contains(self.ivaliceSpecies,nil,self.driverSpecies) then
	driverDance = self.driverSpecies..driverDance
	if self.driverSpecies == "moogle" then
	  driverDance = driverDance.."-sit"
	end
  end
  vehicle.setLoungeDance("driverSeat", driverDance)
	
  if self.tandem then
	local passengerDance = self.loungePositions.passengerSeat.dance
	if vUtil.contains(self.ivaliceSpecies,nil,self.passengerSpecies) then
	  passengerDance = self.passengerSpecies..passengerDance
	  if self.passengerSpecies == "moogle" then
	    passengerDance = passengerDance.."-sit"
	  end
    end
    vehicle.setLoungeDance("passengerSeat", self.passengerDamageDance)
  end
end

function setMusic()
  --vUtil.showLog( "SETMUSIC()", {  }, {  } )
  if self.driver and not self.fleeing then
    if not self.lastDriver then
      --vUtil.showLog( "PLAYING", { "self.driver", "self.music", "self.fade" }, { self.driver, self.music, self.fade } )
      world.sendEntityMessage(self.driver, "playAltMusic", self.music, self.fade)
	end
  elseif self.lastDriver then
    --vUtil.showLog( "STOPPING", { "self.lastDriver", "self.music", "self.fade" }, { self.lastDriver, self.music, self.fade } )
    world.sendEntityMessage(self.lastDriver, "stopAltMusic", self.fade)
  elseif fleeing then
    --vUtil.showLog( "STOPPING", { "self.driver", "self.music", "self.fade" }, { self.driver, self.music, self.fade } )
    world.sendEntityMessage(self.driver, "stopAltMusic", self.fade)
  end
  if self.passenger then
    if not self.lastPassenger then
      --vUtil.showLog( "PLAYING", { "self.passenger", "self.music", "self.fade" }, { self.passenger, self.music, self.fade } )
      world.sendEntityMessage(self.passenger, "playAltMusic", self.music, self.fade)
	end
  elseif self.lastPassenger then
    --vUtil.showLog( "STOPPING", { "self.lastPassenger", "self.music", "self.fade" }, { self.lastPassenger, self.music, self.fade } )
    world.sendEntityMessage(self.lastPassenger, "stopAltMusic", self.fade)
  end
end

-- **** SAY HI ON INITIALIZE ****
function sayHi()
  -- vUtil.showLog( "SAYHI()", {  }, {  } )
  self.talking = true
  animator.playSound("warp")
  self.hiCount = self.hiCount+1
  if self.hiCount > self.hiLimit then
    self.newborn = false 
  end
end

-- **** REMOVE MISSING GEAR ****
function cleanupGear(style,equipped)
  local keep = nil
  local good = vUtil.cleanup({equipped},root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:"..style.."Names"))
  for _,this in pairs(good) do
    if this ~= "naked" or keep == nil then
	  keep = this	  
	end
  end
  if keep == "naked" then
    if style == "saddle" then
      self.equippedSaddle = "naked"
      self.equippedSaddleJumpLimit = 0
      self.equippedSaddleMoveSpeed = 0
      self.equippedSaddleWaterSpeed = 0
	elseif style  == "barding" then
      self.equippedBarding = "naked"
      self.equippedBardingHealth = 0
      self.equippedBardingProtection = 0
	end
  end
end

-- **** DEBUG DISPLAY ****
function showDebug(fields,values)
  local yPos = #fields+1
  local xPos = 2
  local xLimit = 27.75  
  local position = mcontroller.position()
  local debar = "|-------------------------------------------------------|"
  world.debugText(debar, vec2.add(position,{xPos,yPos}),"yellow")
  for i,field in pairs(fields) do
    local text = string.format("%s:  %s", field,values[i])
    world.debugText("|", vec2.add(position,{xPos,yPos-i}),       "yellow")
    world.debugText(text,vec2.add(position,{xPos+1,yPos-i}),     "white")
    world.debugText("|", vec2.add(position,{xPos+xLimit,yPos-i}),"yellow")
  end
  world.debugText(debar, vec2.add(position,{xPos,0}),"yellow")
end

-- **** STORE DATA ON UNINITIALIZE ****
function uninit()
end