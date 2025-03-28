function update()
  localAnimator.clearDrawables()

  VehicleBlocked, VehiclePlaceable, VehicleEmpty = 1, 2, 3

  local vehicleState = animationConfig.animationParameter("vehicleState")

  if (vehicleState == VehicleEmpty) then
    return {}
  else
    local spawnPosition = activeItemAnimation.ownerAimPosition()
    local highlightColor = vehicleState == VehiclePlaceable and {150, 255, 150, 255} or {255, 150, 150, 255}
	
	local imageParts = {}
    imageParts[11] = "bardingfImage"
    imageParts[10]  = "wingImage"
    imageParts[9]  = "saddlefImage"
    imageParts[8]  = "legfImage"
    imageParts[7]  = "bustImage"
    imageParts[6]  = "saddleImage"
    imageParts[5]  = "bardingImage"
    imageParts[4]  = "backImage"
    imageParts[3]  = "saddlebImage"
    imageParts[2]  = "legbImage"
    imageParts[1]  = "bardingbImage"
	
    for i,part in pairs(imageParts) do
	  localAnimator.addDrawable({
        image = animationConfig.animationParameter(part),
        position = spawnPosition,
        color = highlightColor,
        fullbright = true
      })
	end
  end
end
