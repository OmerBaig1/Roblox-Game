# Steal a Game – rules for Claude

## How this project works
- Roblox Studio is the source of truth. The live game lives in Studio (Team Create).
- The `src/` folder and the `.rbxl` are only a backup copy for GitHub.
  They are pulled OUT of Studio, never pushed back INTO it.

## Making changes
- Make all game changes directly in Roblox Studio using the Roblox Studio MCP tools.
- Never edit files in `src/` to change the game.
- NEVER run `rojo serve`, never use the Rojo plugin's Connect button, and never use
  `rojo build` or `rojo upload`. These overwrite the game in Studio.
- Before big changes, make a backup copy of the scripts inside Studio (ServerStorage > Backups).
- Stop the playtest before editing, and playtest afterwards to check for errors.

## Saving to GitHub (only when I ask)
1. I do File > Download a Copy in Studio and save over the .rbxl in this folder.
2. Run `rojo syncback --input "Steal a Game.rbxl"` (Studio -> files only).
3. `git add -A`, `git commit -m "..."`, `git pull --rebase`, `git push`.
Never use `git push --force`.