--!nonstrict
--[[
    CharacterController.luau
    Handles Humanoid state changes, PlatformStand toggles, and body part collision states with LoggerModule logging.
--]]

local Enum = Enum
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local loggerScript = (ReplicatedStorage:FindFirstChild("Submodules") and ReplicatedStorage.Submodules:FindFirstChild("LoggerModule"))
	or (ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("LoggerModule"))
local Logger = if loggerScript then require(loggerScript :: ModuleScript) else nil
local log = if Logger and typeof(Logger.create) == "function" then Logger.create("CharacterController") else function(...) end

local CharacterController = {}

export type OriginalPartData = {
	canCollide: boolean,
	customProps: PhysicalProperties?,
}

--- Prepares a Humanoid for ragdoll physics (sets platform stand, disables getting up)
function CharacterController.PrepareHumanoid(humanoid: Humanoid)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false

	log(string.format("Prepared Humanoid [%s] -> Physics State, PlatformStand=true", humanoid.Parent and humanoid.Parent.Name or "Unknown"))
end

--- Restores Humanoid states back to normal upright standing state
function CharacterController.RestoreHumanoid(humanoid: Humanoid)
	humanoid.PlatformStand = false
	humanoid.AutoRotate = true
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

	log(string.format("Restored Humanoid [%s] -> GettingUp State, PlatformStand=false", humanoid.Parent and humanoid.Parent.Name or "Unknown"))
end

--- Lightweight PlatformStand disabler toggle
function CharacterController.SetPlatformStand(humanoid: Humanoid, enabled: boolean)
	humanoid.PlatformStand = enabled
	humanoid.AutoRotate = not enabled
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, not enabled)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, not enabled)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, not enabled)

	if enabled then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	else
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end

	log(string.format("SetPlatformStand [%s] -> PlatformStand=%s", humanoid.Parent and humanoid.Parent.Name or "Unknown", tostring(enabled)))
end

--- Sets limb collision states and low-density physics properties for crisp responsiveness
function CharacterController.EnableLimbCollisions(character: Model): { [BasePart]: OriginalPartData }
	local originalData: { [BasePart]: OriginalPartData } = {}
	local count = 0
	local lowDensityProps = PhysicalProperties.new(0.05, 0.1, 0, 1, 1)

	for _, child in ipairs(character:GetDescendants()) do
		if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
			originalData[child] = {
				canCollide = child.CanCollide,
				customProps = child.CustomPhysicalProperties,
			}
			child.CanCollide = true
			child.CustomPhysicalProperties = lowDensityProps
			count += 1

			-- Apply random initial angular velocity impulse to create active flailing
			local rx = (math.random() - 0.5) * 15
			local ry = (math.random() - 0.5) * 15
			local rz = (math.random() - 0.5) * 15
			child.AssemblyAngularVelocity = Vector3.new(rx, ry, rz)
		end
	end

	log(string.format("Enabled low-density physics and flail impulses for %d parts in %s", count, character.Name))
	return originalData
end

--- Restores original limb collision states and physical properties
function CharacterController.RestoreLimbCollisions(originalData: { [BasePart]: OriginalPartData })
	for part, data in pairs(originalData) do
		if part and part.Parent then
			part.CanCollide = data.canCollide
			part.CustomPhysicalProperties = data.customProps
		end
	end
	log("Restored original limb collision states and physical properties.")
end

return CharacterController
