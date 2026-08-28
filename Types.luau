--!strict
--[[
    Types.luau
    Type definitions for Standalone RagdollModule.
--]]

export type RagdollOptions = {
	duration: number?,
	upperAngle: number?,
	twistLowerAngle: number?,
	twistUpperAngle: number?,
}

export type RagdollSession = {
	character: Model,
	humanoid: Humanoid,
	motors: { Motor6D },
	constraints: { Instance },
	originalCollisions: { [BasePart]: boolean },
	activeThread: thread?,
}

return {}
