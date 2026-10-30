# Acinonyx UI

Acinonyx UI is a single-file Luau UI library. It defaults to `CoreGui` for the executor environments used by the included `Example`, which loads the source with `game:HttpGet` and `loadstring`. For a normal Roblox Studio client script, pass the local player's `PlayerGui` as `GuiParent`.

## Features

- Draggable window with minimize, restore, and close controls.
- Tabs, labels, buttons, toggles, sliders, textboxes, dropdowns, and multi-select dropdowns.
- Notifications with info, success, warning, and error styles.
- Sidebar profile footer with the local player's circular headshot and a masked username. The footer shows the first two username characters followed by six bullets.
- Touch-aware dragging and sliders; buttons use Roblox's cross-device `Activated` event.
- Viewport-aware default window size.
- `Window:Destroy()` to close the window, disconnect its input listeners, and remove its notifications.

## Quick start

See [`Example`](./Example) for a small demo of the public API. Its callbacks print demo values and do not change the game state. For a repeatable review, pin the loader to a commit or use a local copy of `Init.lua` rather than tracking a moving branch URL.

### Roblox Studio client test

Place `Init.lua` in a `ModuleScript` named `Acinonyx` under `ReplicatedStorage`. From a `LocalScript` in `StarterPlayerScripts`, create the window like this:

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Acinonyx = require(ReplicatedStorage:WaitForChild("Acinonyx"))

local Window = Acinonyx:CreateWindow({
    Name = "Acinonyx Studio Test",
    GuiParent = Players.LocalPlayer:WaitForChild("PlayerGui"),
})
Window:CreateTab("Main")
```

```lua
local Window = Acinonyx:CreateWindow({Name = "My UI"})
local MainTab = Window:CreateTab("Main")

MainTab:CreateButton({
    Text = "Show notification",
    Callback = function()
        Window:Notify({Title = "Hello", Text = "It works", Type = "success"})
    end,
})

Window:Destroy()
```

## Slider options

`CreateSlider` accepts `Text`, `Min`, `Max`, `Default`, `Step`, and `Callback`. `Max` must be greater than `Min`; `Step` must be greater than zero. Values are clamped to the range and snapped to the nearest step.

## Manual checks

Run the `Example` in an authorized executor environment, or use the Studio client setup above. Confirm the first tab is selected, controls respond to input, the avatar loads, the username is masked, and closing the window removes its UI. The repository does not currently include an automated test suite.

## License

No license is currently declared in this repository. Public visibility alone does not grant permission to redistribute or reuse the code.
