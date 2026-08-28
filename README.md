# 📦 Standalone RagdollModule

A modular, zero-dependency physics ragdoll package for Roblox **R6** and **R15** avatars.

---

## 📂 Package Architecture

```text
RagdollModule/
├── init.luau                 -- Main module interface (Enable, Disable, IsRagdolled)
├── JointBuilder.luau         -- Motor6D joint conversion & constraint creation logic
├── CharacterController.luau  -- Humanoid state management & limb collision toggles
├── Types.luau                -- Exported Luau type definitions
└── README.md                 -- Package documentation
```

---

## 🛠 Features

- ⚡ **Zero Dependencies**: Pure Luau package with no external framework requirements.
- 🧍 **R6 & R15 Compatible**: Automatically handles R6 and R15 character rigs.
- 📐 **Modular Sub-components**: Clean separation of physics solvers, character humanoid control, and type definitions.
- ⏱ **Flexible Timers**: Pass a duration number or an options table.

---

## 🚀 Usage

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RagdollModule = require(ReplicatedStorage.RagdollModule)

-- Enable ragdoll for 3.5 seconds on character hit
RagdollModule.Enable(character, 3.5)

-- Manually restore character to normal state
RagdollModule.Disable(character)

-- Check if character is currently ragdolled
if RagdollModule.IsRagdolled(character) then
    print("Character is tumbling!")
end
```

### Advanced Options
```luau
RagdollModule.Enable(character, {
    duration = 4.0,
    upperAngle = 85,
    twistLowerAngle = -75,
    twistUpperAngle = 75,
})
```

---

## 📄 License
MIT License - Free for use across all your Roblox projects.
