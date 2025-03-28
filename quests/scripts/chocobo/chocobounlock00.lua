require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/quests/scripts/questutil.lua"
require "/quests/scripts/portraits.lua"
require "/scripts/viera/vUtil.lua"
require "/scripts/viera/vQuest.lua"

-- STATES --

function defineStates()
  return {
    findChocoboKnight
  }
end

function findChocoboKnight()
  vQuest.locate(1,1)
  self.state:set(states[storage.state])
end
