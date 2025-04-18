require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/quests/scripts/questutil.lua"
require "/quests/scripts/portraits.lua"
require "/scripts/viera/vUtil.lua"
require "/scripts/viera/vQuest.lua"

-- STATES --

function defineStates()
  return {
    gatherChocobo,
	returnToSeonha
  }
end

function gatherChocobo()
  vQuest.gather(1,2)
  self.state:set(states[storage.state])
end

function returnToSeonha()
  vQuest.locate(2,2)
  self.state:set(states[storage.state])
end
