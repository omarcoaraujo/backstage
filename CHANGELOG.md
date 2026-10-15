# Changelog

## Unreleased

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
