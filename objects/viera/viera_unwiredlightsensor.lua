function init()
  self.state = "init"
  self.sampleTime = 0
  self.lightSample = 0
  self.detectThresholdMax = config.getParameter("detectThresholdMax")
  self.detectThresholdMed = config.getParameter("detectThresholdMed")
end

function getSample()
  local sample = world.lightLevel(object.position())
  return math.floor(sample * 1000) * 0.1
end

function update(dt)
  self.lastSample = self.lightSample
  self.lightSample = getSample()  
  if self.lightSample >= self.detectThresholdMax then
	self.state = "max"
  elseif self.lightSample >= self.detectThresholdMed then
	self.state = "med"
  else
	self.state = "min"
  end
  animator.setAnimationState("sensorState", self.state)
  
  if self.lightSample == self.lastSample then 
    self.sampleTime = self.sampleTime+dt
  else
    -- sb.logInfo("[******* DEBUG DATA START *******]")
    -- sb.logInfo("Time Passed: %s", self.sampleTime)
    -- sb.logInfo("Light Sample: %s", self.lightSample) 
    -- sb.logInfo("Effect State: %s", self.state)
    -- sb.logInfo("[******** DEBUG DATA END ********]")
    self.sampleTime = 0
  end
end
