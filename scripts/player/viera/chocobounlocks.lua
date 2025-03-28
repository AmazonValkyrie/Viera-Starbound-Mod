require "/scripts/viera/vUtil.lua"

function init()  
  storage.unlockCategories = root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:unlockCategories")
  storage.chocoboSaddleNames = root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:saddleNames")
  storage.chocoboBardingNames = root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:bardingNames")
  storage.unlockedChocoboSaddles = vUtil.cleanup(player.getProperty("unlockedChocoboSaddles"), storage.chocoboSaddleNames)
  storage.unlockedChocoboBarding = vUtil.cleanup(player.getProperty("unlockedChocoboBarding"), storage.chocoboBardingNames)
  
  player.setProperty("unlockedChocoboSaddles", storage.unlockedChocoboSaddles)
  player.setProperty("unlockedChocoboBarding", storage.unlockedChocoboBarding)
  
  message.setHandler("chocoboUnlock", 
    function(_,_,category,unlock) 
	  if vUtil.contains(storage.unlockCategories,category) then
	    local property = storage.unlockCategories[category]
        local unlocked = player.getProperty(property) or {}
	    vUtil.addItem(unlocked, unlock)  
        player.setProperty(property,unlocked)
	  end
    end
  ) 
end

function update(dt)  
  -- showDebug()  
end

function showDebug()
  local o,p = 0,vec2.add(mcontroller.position(),{0,-15})
  
  local data = {
    biome = world.type(),
    underground = world.underground(mcontroller.position()),
	species = status.statusProperty("species"),
	gender = status.statusProperty("gender")
  }
  local display = vUtil.fieldValues(data)
  o = vUtil.showDebug(display.fields, display.values, p, o)
  
  data = {
    health = status.resource("health"),
	healthMax = status.resourceMax("health"),
	healthPercent = status.resourcePercentage("health")*100,
    healthRegen = status.stat("healthRegen")
  }
  display = vUtil.fieldValues(data)
  o = vUtil.showDebug(display.fields, display.values, p, o)
  
  data = {
    energy = status.resource("energy"),
	energyMax = status.resourceMax("energy"),
	energyPercent = status.resourcePercentage("energy")*100,
    energyRegen = status.stat("energyRegenPercentageRate")
  }
  display = vUtil.fieldValues(data)
  o = vUtil.showDebug(display.fields, display.values, p, o)
  
  data = {
    power = status.stat("powerMultiplier"),
    protection = status.stat("protection")
  }
  display = vUtil.fieldValues(data)
  o = vUtil.showDebug(display.fields, display.values, p, o)
  
  data = {
    physicalResistance  = status.stat("physicalResistance"),
    fireResistance      = status.stat("fireResistance"),
    iceResistance       = status.stat("iceResistance"),
    electricResistance  = status.stat("electricResistance"),
    poisonResistance    = status.stat("poisonResistance"),
    radiationResistance = status.stat("radiationResistance"),
    cosmicResistance    = status.stat("cosmicResistance"),
    shadowResistance    = status.stat("shadowResistance")
  }
  display = vUtil.fieldValues(data)
  o = vUtil.showDebug(display.fields, display.values, p, o)
  
  data = {
    slimestickImmunity     = status.stat("slimestickImmunity"),
    slimefrictionImmunity  = status.stat("slimefrictionImmunity"),
    fujungleslowImmunity   = status.stat("fujungleslowImmunity"),
    fumudslowImmunity      = status.stat("fumudslowImmunity"),
    electricStatusImmunity = status.stat("electricStatusImmunity")
  }
  display = vUtil.fieldValues(data)
  o = vUtil.showDebug(display.fields, display.values, p, o)
 
  local persistantEffects = vUtil.fieldValues(status.getPersistentEffects("player"))
  for i = 1,#persistantEffects do
    display = vUtil.fieldValues(persistantEffects[i])
    o = vUtil.showDebug(display.fields, display.values, p, o)
  end
end