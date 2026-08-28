# 📦 Standalone RagdollModule

A modular, zero-dependency physics ragdoll package for Roblox **R6** and **R15** avatars.

---

## 📂 Package Architecture

```text
RagdollModule/
├── init.luau                 -- Main module interface (Enable, Disable, setNetworkProvider)
├── NetworkBridge.luau        -- Dual-compatible network adapter (ByteNet / RemoteEvents / Local)
├── JointBuilder.luau         -- Motor6D joint conversion & constraint creation logic
├── CharacterController.luau  -- Humanoid state management & limb collision toggles
├── Types.luau                -- Exported Luau type definitions
└── README.md                 -- Package documentation
```

---

## 🛠 Features

- 🔌 **100% Plug & Play**: Drop into any project and start calling functions immediately with zero configuration required.
- ⚡ **Zero Dependencies**: Pure Luau package with no external framework requirements.
- 🌐 **Dual Networking Adapter**: Built-in auto-detection for **ByteNet** buffer serialization, native **RemoteEvents**, or **Local Standalone** mode.
- 🧍 **R6 & R15 Compatible**: Automatically handles R6 and R15 character rigs.
- 📐 **Modular Sub-components**: Clean separation of physics solvers, character humanoid control, and type definitions.
- ⏱ **Flexible Timers**: Pass a duration number or an options table.

---

## 🌐 Dual Networking & Custom Providers

`RagdollModule` includes a self-contained `NetworkBridge.luau` that automatically detects the host project environment:
1. **ByteNet Mode**: If `ReplicatedStorage.Packages.ByteNet` exists, it routes network events over ByteNet buffers.
2. **RemoteEvent Mode**: If `ReplicatedStorage.Remotes` or `RemoteEvents` exist, it routes over Roblox `RemoteEvents`.
3. **Local Standalone Mode**: If no networking library is found, it runs locally without errors.

### Explicit Custom Provider Override
You can explicitly inject a custom networking handler during game bootstrap:
```luau
RagdollModule.setNetworkProvider({
    send = function(actionName, payload, targetPlayer)
        -- Route through custom networking engine (e.g. ByteNet, Zap, ReplicaService)
    end,
    listen = function(actionName, callback)
        -- Route listener
    end,
})
```

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
