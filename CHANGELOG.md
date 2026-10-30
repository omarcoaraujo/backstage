# Changelog

## Unreleased

- You can open more than one window at the same time with `Ctrl + Shift + B`, each with its own search, open groups and scroll, so one can edit while another is used to look things up.

- The window now draws only the rows you can see, so it opens and updates in a few milliseconds even with thousands of values, and a search that opens every group no longer hangs.

## 0.16.1

- Searching in a window with thousands of text values no longer freezes Studio or shows a script timeout, and the window no longer reads every text value until you type a search.

## 0.16.0

- The search now also looks inside the text of a value, so typing the name of an item, like a petal named in a text box, finds the group that holds it and opens it.
- The window now builds the rows of a group only when you open it, and when a search needs them, so opening it with thousands of values is far lighter and quicker.
- Pressing the check mark that keeps the current state as the new starting point is now much lighter on a window with many values: it no longer rebuilds the window or resends every value to the other players.
- A value you declared with more decimals than its step allows, like 0.117 with a step of 0.005, now keeps exactly that value and no longer shows as changed when the game joins the shared view. The step only applies when you edit the control, and clicking into a number box and leaving it without typing no longer changes the value.

## 0.15.0

- The window and the shared view now rebuild once per frame no matter how many values are declared in a row, so a game with hundreds of values no longer freezes while it declares them.
- A value can now take different shapes, like an effect that is either a glow or a pulse. The window shows a choice for the shape, picking another one swaps its fields, and the script keeps the shape you picked.
- The check mark and the reset of a group now show only while the mouse is over the group, and the buttons in a group header stand out better from its hover color.
- Next to the reset of a group, and of the whole window, there is now a check mark that keeps the current state as the new starting point. From then on the reset goes back to it.
- When the reset brings back a removed entry, the script gets it back exactly as it was, in the same place, even if it was the only one left or the one used as a model to add new ones.
- An entry added or brought back from the window is now written to the script in its place, in order, instead of at the end of the list.
- When the script cannot save a change, a notice now appears at the bottom right of the screen, for every player, and goes away by itself or when clicked.
- The library can now also be installed with Wally, not only pesde.
- In a first person game the mouse is now free while the window is open, so you can move it and click.
- In a list of entries, like a price list or all the skins, the window now has a + to add an entry and a red × to remove one. Both show only when the mouse is over it, and the changes are written to the script too.
- Buttons, fields and headers now change softly when you hover or focus them, and when you switch between the light and dark theme, instead of jumping.
- When the name of a new entry is refused, because it already exists or is not a valid name, the window now says why, in red inside the field.
- Adding or removing an entry from the window now reaches the server, so it is saved to the script while you play and every other player sees it.
- If the script cannot take a new or removed entry, the game now takes it back, so the window and the script never disagree.
- Resetting a list brings back the entries that were removed and drops the ones that were added.
- One limit or hint can now cover every entry of a list, like all the skins, instead of being written again for each one.
- A value the window cannot edit, like an animation or a model, no longer breaks the config: it is simply not shown, and the game reads it as usual.

## 0.14.2

- The `apply` command now saves values that sit under a numbered key like `[10] = { ... }`, and values written with a type after them, like `"legendary" :: name`.

## 0.14.1

- Numbers with a very small step, like 0.0001, keep all their decimals in the window and in the export, and no longer show as changed when nobody touched them.

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
