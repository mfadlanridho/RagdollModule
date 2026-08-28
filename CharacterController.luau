--!strict
--[[
    CharacterController.luau
    Handles Humanoid state changes, PlatformStand toggles, and body part collision states during ragdoll transitions.
--]]

local Enum = Enum
local pcall = pcall

local CharacterController = {}

--- Prepares a Humanoid for ragdoll physics (disables evaluate state machine, sets platform stand, disables getting up)
function CharacterController.PrepareHumanoid(humanoid: Humanoid)
	pcall(function()
		humanoid.EvaluateStateMachine = false
	end)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false
end

--- Restores Humanoid states back to normal upright standing state
function CharacterController.RestoreHumanoid(humanoid: Humanoid)
	humanoid.PlatformStand = false
	humanoid.AutoRotate = true
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	pcall(function()
		humanoid.EvaluateStateMachine = true
	end)
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

--- Sets limb collision states for clean floor tumbling
function CharacterController.EnableLimbCollisions(character: Model): { [BasePart]: boolean }
	local originalCollisions: { [BasePart]: boolean } = {}
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
			originalCollisions[child] = child.CanCollide
			child.CanCollide = true
		end
	end
	return originalCollisions
end

--- Restores original limb collision states
function CharacterController.RestoreLimbCollisions(originalCollisions: { [BasePart]: boolean })
	for part, originalCanCollide in pairs(originalCollisions) do
		if part and part.Parent then
			part.CanCollide = originalCanCollide
		end
	end
end

return CharacterController
