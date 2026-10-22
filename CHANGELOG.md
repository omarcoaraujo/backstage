# Changelog

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
