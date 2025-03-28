require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/quests/scripts/questutil.lua"
require "/quests/scripts/portraits.lua"
require "/scripts/viera/vUtil.lua"
require "/scripts/viera/vQuest.lua"

-- STATES --

function defineStates()
  return {
    gatherGysahlGreens,
	returnToWallace
  }
end

function gatherGysahlGreens()
  vQuest.gather(1,2)
  self.state:set(states[storage.state])
end

function returnToWallace()
  vQuest.locate(2,2)
  self.state:set(states[storage.state])
end
