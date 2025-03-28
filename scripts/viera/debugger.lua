require "/scripts/viera/vUtil.lua"

oldInit = init
function init()  
  oldInit()
  
  script.setUpdateDelta(1)
  PEType = "crew" -- probably change this eventually  
end

oldUpdate = update
function update(dt)  
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
 
  display = vUtil.fieldValues(status.getPersistentEffects(PEType))
  o = vUtil.showDebug(display.fields, display.values, p, o)
 
  display = vUtil.fieldValues(status.getPersistentEffects("viera_archer"))
  o = vUtil.showDebug(display.fields, display.values, p, o)  
 
  display = vUtil.fieldValues(status.getPersistentEffects("viera_fencer"))
  o = vUtil.showDebug(display.fields, display.values, p, o)  
 
  display = vUtil.fieldValues(status.getPersistentEffects("viera_woodwarder"))
  o = vUtil.showDebug(display.fields, display.values, p, o)  
  
  return oldUpdate(dt)
end