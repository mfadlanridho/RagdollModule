--!strict
--[[
    JointBuilder.luau
    Converts Motor6D joints into BallSocketConstraint and NoCollisionConstraint physics solvers.
--]]

local Instance = Instance

local JointBuilder = {}

--- Replaces a single Motor6D with BallSocketConstraint and NoCollisionConstraint
function JointBuilder.CreateRagdollJoint(
	motor: Motor6D,
	upperAngle: number?,
	twistLowerAngle: number?,
	twistUpperAngle: number?
): (BallSocketConstraint?, Attachment?, Attachment?, NoCollisionConstraint?)
	local part0 = motor.Part0
	local part1 = motor.Part1
	if not part0 or not part1 then return nil, nil, nil, nil end

	local att0 = Instance.new("Attachment")
	att0.Name = "RagdollAtt0_" .. motor.Name
	att0.CFrame = motor.C0
	att0.Parent = part0

	local att1 = Instance.new("Attachment")
	att1.Name = "RagdollAtt1_" .. motor.Name
	att1.CFrame = motor.C1
	att1.Parent = part1

	local ballSocket = Instance.new("BallSocketConstraint")
	ballSocket.Name = "RagdollSocket_" .. motor.Name
	ballSocket.Attachment0 = att0
	ballSocket.Attachment1 = att1
	ballSocket.LimitsEnabled = true
	ballSocket.UpperAngle = upperAngle or 75
	ballSocket.TwistLimitsEnabled = true
	ballSocket.TwistLowerAngle = twistLowerAngle or -60
	ballSocket.TwistUpperAngle = twistUpperAngle or 60
	ballSocket.Parent = part1

	local noCollide = Instance.new("NoCollisionConstraint")
	noCollide.Name = "RagdollNoCollide_" .. motor.Name
	noCollide.Part0 = part0
	noCollide.Part1 = part1
	noCollide.Parent = part1

	return ballSocket, att0, att1, noCollide
end

--- Creates NoCollisionConstraints between all BaseParts in the character model
function JointBuilder.CreateFullBodyNoCollisions(character: Model): { NoCollisionConstraint }
	local constraints: { NoCollisionConstraint } = {}
	local parts: { BasePart } = {}

	for _, child in ipairs(character:GetDescendants()) do
		if child:IsA("BasePart") then
			table.insert(parts, child)
		end
	end

	for i = 1, #parts do
		for j = i + 1, #parts do
			local p0 = parts[i]
			local p1 = parts[j]
			local nc = Instance.new("NoCollisionConstraint")
			nc.Name = string.format("RagdollFullNoCollide_%s_%s", p0.Name, p1.Name)
			nc.Part0 = p0
			nc.Part1 = p1
			nc.Parent = p1
			table.insert(constraints, nc)
		end
	end

	return constraints
end

return JointBuilder
