--!nonstrict
--[[
    State.luau
    Pre-built StateDefinition for physics ragdoll & knockback state.
    Exported as RagdollModule.State for plug-and-play FSM integration.
--]]

local script = script

local RagdollModule: any = nil
local function getRagdollModule()
	if not RagdollModule then
		RagdollModule = require(script.Parent :: ModuleScript)
	end
	return RagdollModule
end

local RagdollState = {
	name = "Ragdolled",

	canEnter = function(context, fromState)
		if fromState == "SafeZone" then
			return false, "immune_in_safe_zone"
		end
		return true, nil
	end,

	enter = function(context, fromState)
		print(string.format("[RagdollState] %s forced into Ragdoll state!", context.player and context.player.Name or "Unknown"))

		local payload = context.payload
		local launchVector = payload and payload.launchVector
		local module = getRagdollModule()
		local mode = (payload and (payload.mode or payload.ragdollType)) or module.DefaultMode or "Full"
		context._activeRagdollMode = mode

		local char = context.character or (context.player and context.player.Character)
		if char then
			-- Apply optional physical knockback impulse vector
			if launchVector then
				local hrp = context.rootPart or char:FindFirstChild("HumanoidRootPart") :: BasePart
				if hrp then
					hrp.AssemblyLinearVelocity = launchVector
				end
			end

			-- Execute selected mode: Lightweight PlatformStand knockdown vs Full floppy ragdoll
			if mode == "PlatformStand" then
				module.SetPlatformStand(char, true, true)
			else
				module.Enable(char)
			end
		end
	end,

	exit = function(context, toState)
		print(string.format("[RagdollState] %s recovering from Ragdoll state.", context.player and context.player.Name or "Unknown"))

		local char = context.character or (context.player and context.player.Character)
		if char and char.Parent then
			local module = getRagdollModule()
			local mode = context._activeRagdollMode or module.DefaultMode or "Full"

			-- Restore based on which mode was enabled
			if mode == "PlatformStand" then
				module.SetPlatformStand(char, false, false)
			else
				module.Disable(char)
			end
			context._activeRagdollMode = nil
		end
	end,

	update = function(context)
		return nil
	end,
}

return RagdollState
