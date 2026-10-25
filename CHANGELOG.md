# Changelog

## 0.14.0

- When more than one person has the window open, each one now sees the others' cursors with their names, on the same value.
- What someone is dragging, typing in, pressing or has open gets an outline in their color on everyone else's window.
- While someone is using a value, nobody else can change it: the row is dimmed and the controls ignore the others until they let go.
- The `apply` command now asks you to paste the values, so it works without a pipe or a file.
- The export button has a new icon.

## 0.13.0

- The tool has a new `apply` command that writes the values from the export button into your scripts.
- The export panel no longer shows an error when you click the text.

## 0.12.0

- Backstage can now run on places you choose with the `places` option of `start`, shared by the server and every player.
- A new button next to the theme button shows the changed values, ready to copy into the game.

## 0.11.2

- An array inside a config now reports its real length with `#`, instead of 0.

## 0.11.1

- The window title now shows the Backstage logo.
- Buttons now end at the same edge as the fields above them.

## 0.11.0

- The callback of `on_any_change` now receives `(value, previous, path)`, the same order as `on_change`. It used to receive the path first, so swap the arguments if you use it.
- Reacting to a whole group now types the changed value as `backstage.value` instead of leaving it open.
- A string now becomes a choice when its limit is just a list of options, like `mode = { "follow", "orbit" }`. The old `{ choices = { ... } }` form is gone, so move your lists out of `choices`.
- The arrow of the dropdown now matches the arrow of the groups.

## 0.10.0

- The window got a cleaner, minimal look, with softer borders, rounded corners and a blue accent.
- Added a light theme, switched by a new button in the title bar, and a `theme` option on `start` to pick the one it opens with.
- New reset icon.
- Editing a number passed to a helper function by hand, like the `10` in `item(10, 2)`, now reaches the game too.
- Editing a script by hand now also updates the window in the stories, not only in a play session.
- Groups that were open stay open when a script is edited by hand while the game runs.
- The reset button in the title bar no longer gets stuck visible after a script is edited by hand.
- The window now stays on screen when the screen gets smaller.
- Hints now open above the row by default and point at it with a small arrow.

## 0.9.0

- Editing a config script by hand while the game is running now updates the game, the window and every player, without a restart.
- Reacting to a change can now watch a whole group, or every value at once.
- The saving tool now refuses connections from web pages.
- The example shows a Charm label that follows the values, and the last change.

## 0.8.2

- Groups can now be closed while searching, and they open again when the search text changes.
- Values built by a helper function, such as an item made by `item(10, 2)`, can now be saved. Changing a value that lives inside the helper changes it for every call.

## 0.8.1

- Groups no longer take a hint, only values and buttons do.

## 0.8.0

- The window now starts with every group closed.
- Buttons and groups can now have a hint that shows when you hover them.
- Groups now have a reset arrow that puts back every value inside them, and the title bar has one that puts back all of them.
- Values shown as read-only now follow the game while the window is open, instead of staying at the value they had when it opened.
- Numbers and vectors now keep three decimals, so what you see is what is saved.
- The window is a little wider, so long numbers fit.
- Configs can be grouped under one name by writing it with a dot, such as "pet.drops" and "pet.skins" inside a "pet" group, and their edits are saved to the right script. Studio warns when two such configs define the same value.

## 0.7.0

- The window can now be shown inside a storybook such as UI Labs while you edit in Studio, without pressing play, and it keeps its position and size every time the story reloads. The close button hides it and Ctrl + B brings it back.
- In a storybook, your edits are now saved to your script when you close the story, so it no longer reloads in the middle of tuning.
- In a storybook, the reset button keeps going back to the value you started with, even after the story reloads with your saved edits.
- The connection to the tool that saves your edits now closes by itself when you stop editing, and opens again on the next edit, so reloading stories no longer piles up connections until Studio refuses new ones.

## 0.6.0

- Values that exist only in client scripts now show up on the server too, so editing them in the window is no longer lost.
- The tool that saves your edits now warns on startup about a config whose name is not plain text, since edits to it cannot be saved.
- The tool that saves your edits now ignores the folders listed in your project's ignore file.
- Studio now warns when Vide is swapped after values were already being tracked, instead of failing silently.

## 0.5.0

- Reacting to a change now takes the value itself, like `config.size`, instead of its name in quotes. A typo in the name is caught, and any other use shows an error in Studio.
- The window now covers the whole screen, including the area under the top bar.
- The tool that saves your edits now starts with `backstage serve`, like Rojo, with colors and clearer messages when something goes wrong.

## 0.4.0

- Your game can now react when a value changes in the window, without adding anything to your game scripts.
- Each value can now have a short explanation that shows when you hover its row.
- Values you read from your config now update live in Vide and Charm code while you tune them in the window.

## 0.3.0

- A small reset button shows up next to a value you changed, and one click puts it back to how it was when you pressed play.
- Values you change in the window can now be saved straight into your config scripts while Studio is open, with a small program you download from the release.

## 0.2.0

- Tune values and press buttons that live on the server, from the same window.
- Edits made in the window now reach the server and every player.
- Fixed values showing twice in the window after it refreshes.

## 0.1.0

First release.

- A window to tune your game values while you play in Studio, opened with Ctrl + B or a key you choose.
- Sliders, toggles, text, choices, colors with a picker, vectors and buttons.
- Limits for each value: minimum, maximum, step and a list of choices.
- Search bar that filters the list by name.
- Groups that open and close, with a line showing the nesting.
- Read-only values and tables that expand.
- A draggable and resizable window that reopens in the center.
- Nothing runs outside Studio, and your values ship as you declared them.
- An `example/` project with a pet that follows the player.
