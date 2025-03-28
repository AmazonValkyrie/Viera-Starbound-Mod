require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/quests/scripts/questutil.lua"
require "/quests/scripts/portraits.lua"
require "/scripts/viera/vUtil.lua"
require "/scripts/viera/vQuest.lua"

-- STATES --

function defineStates()
  return {
    gatherMagicite,
    refineMagicite,
    gatherMaterial,
    returnToSeonha
  }
end

function gatherMagicite()
  vQuest.gather(1,2)
  self.state:set(states[storage.state])
end

function refineMagicite()
  vQuest.gather(2,3)
  self.state:set(states[storage.state])
end

function gatherMaterial()
  vQuest.gather(3,4)
  self.state:set(states[storage.state])
end

function returnToSeonha()
  vQuest.locate(4,4)
  self.state:set(states[storage.state])
end

