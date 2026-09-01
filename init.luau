--!strict
--[[
    RagdollModule (init.luau)
    Main entry point for modular, standalone physics ragdoll and PlatformStand disabler system.
    Supports R6 & R15 Roblox character models with LoggerModule logging.
--]]

local task = task
local script = script

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(script.Types)
local JointBuilder = require(script.JointBuilder)
local CharacterController = require(script.CharacterController)
local NetworkBridge = require(script.NetworkBridge)
local Logger = require(ReplicatedStorage.Packages.LoggerModule)

local log = Logger.create("RagdollModule")

export type RagdollOptions = Types.RagdollOptions
export type RagdollSession = Types.RagdollSession
export type NetworkProvider = NetworkBridge.NetworkProvider

local RagdollModule = {}
RagdollModule.__index = RagdollModule
RagdollModule.NetworkBridge = NetworkBridge

function RagdollModule.setNetworkProvider(provider: NetworkProvider)
	NetworkBridge.setProvider(provider)
end

local activeSessions: { [Model]: RagdollSession } = {}
local platformStandSessions: { [Model]: CharacterController.OriginalPartData } = {}

--- Toggles lightweight PlatformStand disabler on a character (preserves character joint structures while disabling standing movement)
-- @param character Model
-- @param enabled boolean
-- @param stopAnimations boolean? Optional flag to stop playing animation tracks on Humanoid Animator
function RagdollModule.SetPlatformStand(character: Model, enabled: boolean, stopAnimations: boolean?)
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	if enabled then
		CharacterController.SetPlatformStand(humanoid, true)
		if not platformStandSessions[character] then
			platformStandSessions[character] = CharacterController.EnableLimbCollisions(character)
		end

		-- Optionally stop active animation tracks and disable Roblox default Animate script if requested
		if stopAnimations == true then
			local animateScript = character:FindFirstChild("Animate")
			if animateScript and animateScript:IsA("LocalScript") then
				animateScript.Enabled = false
			end

			local animator = humanoid:FindFirstChildOfClass("Animator") :: Animator?
			if animator then
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					track:Stop(0)
				end
			end
		end

		log(string.format("🟢 ENABLED PlatformStand disabler for %s", character.Name))
	else
		local animateScript = character:FindFirstChild("Animate")
		if animateScript and animateScript:IsA("LocalScript") then
			animateScript.Enabled = true
		end

		local origData = platformStandSessions[character]
		if origData then
			CharacterController.RestoreLimbCollisions(origData)
			platformStandSessions[character] = nil
		end
		if humanoid and humanoid.Parent then
			CharacterController.RestoreHumanoid(humanoid)
		end
		log(string.format("🔴 DISABLED PlatformStand disabler for %s", character.Name))
	end
end

--- Enables full physics joint ragdoll state on a character model.
-- @param character Model - The character model (R6 or R15)
-- @param options (number | RagdollOptions)? - Duration in seconds or options table
function RagdollModule.Enable(character: Model, options: (number | RagdollOptions)?): boolean
	if not character then
		log("⚠️ Enable failed: character is nil")
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		log(string.format("⚠️ Enable failed: %s has no active Humanoid", character.Name))
		return false
	end

	local duration: number? = nil
	local upperAngle: number? = nil
	local twistLowerAngle: number? = nil
	local twistUpperAngle: number? = nil

	if type(options) == "number" then
		duration = options
	elseif type(options) == "table" then
		duration = options.duration
		upperAngle = options.upperAngle
		twistLowerAngle = options.twistLowerAngle
		twistUpperAngle = options.twistUpperAngle
	end

	if activeSessions[character] then
		log(string.format("Cancelling existing ragdoll session for %s", character.Name))
		RagdollModule.Disable(character)
	end

	local session: RagdollSession = {
		character = character,
		humanoid = humanoid,
		motors = {},
		constraints = {},
		originalCollisions = {},
		activeThread = nil,
	}

	log(string.format("🟢 ENABLING FULL PHYSICS RAGDOLL for character: %s", character.Name))

	CharacterController.PrepareHumanoid(humanoid)
	session.originalCollisions = CharacterController.EnableLimbCollisions(character)

	-- Stop playing animation tracks and disable Roblox default Animate script
	local animateScript = character:FindFirstChild("Animate")
	if animateScript and animateScript:IsA("LocalScript") then
		animateScript.Enabled = false
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
	end

	local totalJointsFound = 0
	local jointsConverted = 0

	for _, descendant in ipairs(character:GetDescendants()) do
		local isMotor = descendant:IsA("Motor6D")
		local isAnimConstraint = descendant:IsA("AnimationConstraint")

		if (isMotor or isAnimConstraint) and descendant.Name ~= "RootJoint" and descendant.Name ~= "Root" then
			totalJointsFound += 1
			local joint = descendant :: Instance & { Enabled: boolean }

			-- 1. Disable the motor or animation constraint
			joint.Enabled = false
			table.insert(session.motors, joint)

			if isMotor then
				(descendant :: Motor6D).Transform = CFrame.new()
			end

			-- 2. Check for built-in BallSocketConstraint (common in AnimationConstraint avatars)
			local parent = descendant.Parent
			local socketName = descendant.Name .. "BallSocket"
			local existingSocket = parent and parent:FindFirstChild(socketName) :: BallSocketConstraint?

			if existingSocket and existingSocket:IsA("BallSocketConstraint") then
				existingSocket.Enabled = true
				existingSocket.LimitsEnabled = false
				existingSocket.TwistLimitsEnabled = false
				jointsConverted += 1
				table.insert(session.constraints, existingSocket)
			else
				-- 3. If Motor6D without existing BallSocket, generate new BallSocketConstraint & Attachment pair
				if isMotor then
					local socket, att0, att1, noCollide = JointBuilder.CreateRagdollJoint(descendant :: Motor6D, upperAngle, twistLowerAngle, twistUpperAngle)
					if socket and att0 and att1 and noCollide then
						jointsConverted += 1
						table.insert(session.constraints, socket)
						table.insert(session.constraints, att0)
						table.insert(session.constraints, att1)
						table.insert(session.constraints, noCollide)
					end
				end
			end
		end
	end

	local fullNoCollides = JointBuilder.CreateFullBodyNoCollisions(character)
	for _, nc in ipairs(fullNoCollides) do
		table.insert(session.constraints, nc)
	end

	activeSessions[character] = session
	log(string.format("✅ FULL RAGDOLL ENABLED for %s: Disabled %d joints, active %d physical constraints", character.Name, totalJointsFound, #session.constraints))

	if duration and duration > 0 then
		session.activeThread = task.delay(duration, function()
			RagdollModule.Disable(character)
		end)
	end

	return true
end

--- Disables physics ragdoll or PlatformStand disabler and restores the character humanoid to normal state.
-- @param character Model - The character model to restore
function RagdollModule.Disable(character: Model)
	if platformStandSessions[character] then
		RagdollModule.SetPlatformStand(character, false)
	end

	local session = activeSessions[character]
	if not session then return end

	log(string.format("🔴 DISABLING FULL RAGDOLL for character: %s", character.Name))

	if session.activeThread then
		task.cancel(session.activeThread)
		session.activeThread = nil
	end

	-- Clean up or disable physical constraints
	for _, obj in ipairs(session.constraints) do
		if obj:IsA("BallSocketConstraint") then
			if string.find(obj.Name, "BallSocket$") then
				obj.Enabled = false
			else
				obj:Destroy()
			end
		else
			obj:Destroy()
		end
	end

	-- Re-enable animation constraints & Motor6D joints
	for _, joint in ipairs(session.motors) do
		(joint :: Instance & { Enabled: boolean }).Enabled = true
	end

	CharacterController.RestoreLimbCollisions(session.originalCollisions)
	if session.humanoid and session.humanoid.Parent then
		CharacterController.RestoreHumanoid(session.humanoid)
	end

	local animateScript = character:FindFirstChild("Animate")
	if animateScript and animateScript:IsA("LocalScript") then
		animateScript.Enabled = true
	end

	activeSessions[character] = nil
	log(string.format("✅ FULL RAGDOLL DISABLED for %s: Restored joints & Humanoid states", character.Name))
end

--- Returns whether a character is currently in a ragdoll or platform stand state.
-- @param character Model
-- @return boolean
function RagdollModule.IsRagdolled(character: Model): boolean
	return activeSessions[character] ~= nil or platformStandSessions[character] ~= nil
end

return RagdollModule
