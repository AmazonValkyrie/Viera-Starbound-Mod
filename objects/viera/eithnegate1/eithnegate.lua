require "/scripts/util.lua"

function init()
  self.detectArea = config.getParameter("detectArea")
  self.detectArea[1] = object.toAbsolutePosition(self.detectArea[1])
  self.detectArea[2] = object.toAbsolutePosition(self.detectArea[2])

  storage.active = storage.active or config.getParameter("startActive", false)

  message.setHandler("activate", function()
    storage.active = true
    animator.setAnimationState("console", "turnon")
    object.setLightColor(config.getParameter("lightColor", {255, 255, 255}))
  end)

  message.setHandler("isActive", function() return storage.active == true end)

  message.setHandler("addDestination", function(custom) addDestination(custom) end)

  self.isEithneGate = world.terrestrial()

  storage.currentDestinations = config.getParameter("currentDestinations", {})
  
  if (#storage.currentDestinations) < 1 then
    addDestination()
  end

  if storage.active then
    animator.setAnimationState("console", "on")
    object.setLightColor(config.getParameter("lightColor", {255, 255, 255}))
  else
    animator.setAnimationState("console", "off")
    object.setLightColor(config.getParameter("lightColor", {255, 255, 255}))
  end
  local nodes = config.getParameter("inputNodes", {})
  storage.maxNode = #nodes - 1
end


function addDestination(custom)
  custom = custom or {}
  local UUID = custom.UUID or sb.makeUuid()
  local threat = config.getParameter("level", world.threatLevel())
  
  local destinationName = config.getParameter("destinationName", "Journey through the Wood") .. " : level " .. math.floor(threat)
  local planetName = config.getParameter("planetName", "") .. " " .. UUID
  local destinationIcon = config.getParameter("destinationIcon", "default")
  local warpAction = config.getParameter("destinationType", "InstanceWorld:vieravillages:") .. UUID .. ":" .. threat
  
  storage.currentDestinations[#storage.currentDestinations + 1] = {
    name = custom.destinationName or destinationName,
    planetName = custom.planetName or planetName,
    icon = custom.destinationIcon or destinationIcon,
    warpAction = custom.warpAction or warpAction
  }

  object.setConfigParameter("currentDestinations", storage.currentDestinations)
end


function onInputNodeChange(args)
  if storage.maxNode > 0 and object.getInputNodeLevel(1) then
    storage.currentDestinations = {}
    addDestination()
  elseif object.getInputNodeLevel(0) then
    addDestination()
  end
end


function onInteraction()
  if config.getParameter("returnDoor") then
    return { "OpenTeleportDialog", {
        canBookmark = false,
        includePlayerBookmarks = false,
        destinations = {
          {
            name = "Exit Portal",
            planetName = "Return to World... Hopefully!",
            icon = "return",
            warpAction = "Return"
          }
        }
      }
    }
  elseif self.isEithneGate then
    if not storage.active then
      return {config.getParameter("inactiveInteractAction"), config.getParameter("inactiveInteractData")}
    else
      local data = {
        canBookmark = false,
        includePlayerBookmarks = false,
        destinations = {}
      }
      for k, world in ipairs(storage.currentDestinations) do
        data.destinations[k] = world
      end
    
      return { "OpenTeleportDialog", data }
    end
  end
end

function update(dt)
  if self.isEithneGate then
    if storage.active then
      local players = world.entityQuery(self.detectArea[1], self.detectArea[2], {
          includedTypes = {"player"}
        })

      if #players > 0 and animator.animationState("console") == "off" then
        animator.setAnimationState("console", "turnon")
        animator.playSound("on");
        object.setLightColor(config.getParameter("lightColor", {255, 255, 255}))
      elseif #players == 0 and animator.animationState("console") == "on" then
        animator.setAnimationState("console", "turnoff")
        object.setLightColor(config.getParameter("lightColor", {255, 255, 255}))
      end
    end
  else
    if storage.vaultActive then
      if world.time() > storage.vaultCloseTime then
        closeVault()
      end
    end
  end
end