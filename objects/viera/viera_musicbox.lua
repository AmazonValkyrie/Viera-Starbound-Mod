require "/scripts/util.lua"
require "/scripts/viera/vUtil.lua"

function init()
  storage.state = storage.state or "off"
  storage.track = storage.track or 0
  
  tracks = config.getParameter("tracks") or {}
  
  players = {}
  
  track = {}
  track.number = storage.track
  track.fadeInTime = config.getParameter("fadeInTime", 0.0)
  track.fadeOutTime = config.getParameter("fadeOutTime", 0.0)
  
  color = {}
  color.on = config.getParameter("lightColorOn", { 0, 0, 0})
  color.off = config.getParameter("lightColorOff", { 0, 0, 0})

  object.setInteractive(config.getParameter("interactive", true))
  animator.setAnimationState("image", storage.state)
  --vUtil.showLog("MUSICBOX INITIALIZING", { "tracks", "track", "color" }, { tracks, track, color })
  playerScan()
end

function playerScan()
  --vUtil.showLog("OLD PLAYERS", { "players" }, { players })
  local worldPlayers = world.players()
  --vUtil.showLog("WORLD PLAYERS", { "worldPlayers" }, { worldPlayers })
  local newPlayers = util.filter(worldPlayers, function(value)    
    local exists = contains(players, value)
    --vUtil.showLog("FILTERING", { "players", "value", "exists" }, { players, value, exists })
	return not exists
  end)
  --vUtil.showLog("NEW PLAYERS", { "newPlayers" }, { newPlayers })
  if #newPlayers > 0 and track.number > 0 then
    start(newPlayers, tracks[track.number], track.fadeInTime)
  end
  players = worldPlayers
end

function update(dt)
  if track.number > 0 then
	playerScan() 
  end
end

function onInteraction(args)	
  --vUtil.showLog("INTERACTING", { "track.number" }, { track.number })
  if track.number == 0 then switch("on") end
  track.number = (#tracks > track.number) and (track.number + 1) or 0
  --vUtil.showLog("CHANGING TRACK", { "track.number" }, { track.number })
  if track.number > 0 then 
    start(players, tracks[track.number], track.fadeInTime)
  else
    stop(track.fadeOutTime)
  end
end

function switch(state)
  local stateColor = (state == "on") and color.on or color.off
  --vUtil.showLog("SWITCHING", { "state", "stateColor" }, { state, stateColor })
  animator.setAnimationState("image", state)
  object.setLightColor(stateColor)
  storage.state = state
end

function start(listeners, song, fade)
  --vUtil.showLog("STARTING", { "listeners", "song", "fade" }, { listeners, song, fade })
  for _,listener in pairs(listeners) do
    --vUtil.showLog("SENDING TO", { "listener", "song", "fade" }, { listener, song, fade })
    world.sendEntityMessage(listener, "playAltMusic", song, fade)
  end
end

function stop(fade)
  --vUtil.showLog("STOPPING", { "fade" }, { fade })
  for _,listener in pairs(players) do
    --vUtil.showLog("SENDING TO", { "listener", "fade" }, { listener, fade })
    world.sendEntityMessage(listener, "stopAltMusic", fade)
  end
  switch("off") 
end

function uninit()
  storage.track = track.number
end

function die(smash)
  stop(track.fadeOutTime)
end
