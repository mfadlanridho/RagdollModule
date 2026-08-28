--!strict
--[[
    RagdollModule (init.luau)
    Main entry point for modular, standalone physics ragdoll system.
    Supports R6 & R15 Roblox character models.
--]]

local task = task
local script = script

local Types = require(script.Types)
local JointBuilder = require(script.JointBuilder)
local CharacterController = require(script.CharacterController)

export type RagdollOptions = Types.RagdollOptions
export type RagdollSession = Types.RagdollSession

local RagdollModule = {}
RagdollModule.__index = RagdollModule

local activeSessions: { [Model]: RagdollSession } = {}

--- Enables physics ragdoll state on a character model.
-- @param character Model - The character model (R6 or R15)
-- @param options (number | RagdollOptions)? - Duration in seconds or options table
function RagdollModule.Enable(character: Model, options: (number | RagdollOptions)?): boolean
	if not character then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

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

	-- Cancel existing ragdoll session if active
	if activeSessions[character] then
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

	-- Prepare Humanoid & Limb collisions
	CharacterController.PrepareHumanoid(humanoid)
	session.originalCollisions = CharacterController.EnableLimbCollisions(character)

	-- Convert Motor6D joints into physical BallSocket & NoCollision constraints
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") and descendant.Name ~= "RootJoint" then
			local socket, att0, att1, noCollide = JointBuilder.CreateRagdollJoint(descendant, upperAngle, twistLowerAngle, twistUpperAngle)
			if socket and att0 and att1 and noCollide then
				descendant.Enabled = false
				table.insert(session.motors, descendant)
				table.insert(session.constraints, socket)
				table.insert(session.constraints, att0)
				table.insert(session.constraints, att1)
				table.insert(session.constraints, noCollide)
			end
		end
	end

	activeSessions[character] = session

	-- Optional automatic recovery timer
	if duration and duration > 0 then
		session.activeThread = task.delay(duration, function()
			RagdollModule.Disable(character)
		end)
	end

	return true
end

--- Disables physics ragdoll and restores the character humanoid to normal state.
-- @param character Model - The character model to restore
function RagdollModule.Disable(character: Model)
	local session = activeSessions[character]
	if not session then return end

	if session.activeThread then
		task.cancel(session.activeThread)
		session.activeThread = nil
	end

	-- Clean up physical constraints & attachments
	for _, obj in ipairs(session.constraints) do
		obj:Destroy()
	end

	-- Re-enable Motor6D joints
	for _, motor in ipairs(session.motors) do
		motor.Enabled = true
	end

	-- Restore limb collisions & Humanoid states
	CharacterController.RestoreLimbCollisions(session.originalCollisions)
	if session.humanoid and session.humanoid.Parent then
		CharacterController.RestoreHumanoid(session.humanoid)
	end

	activeSessions[character] = nil
end

--- Returns whether a character is currently in a ragdoll state.
-- @param character Model
-- @return boolean
function RagdollModule.IsRagdolled(character: Model): boolean
	return activeSessions[character] ~= nil
end

return RagdollModule
