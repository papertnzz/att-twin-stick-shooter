# Twin-Stick Shooter

A 3D top-down twin-stick shooter built in **Godot 4.6** for the *Aktuelle Themen und Trends I & II – 3D Game Development* course at Hochschule Burgenland.

Survive endless waves of skeletons in a walled arena. Move with WASD, aim with the mouse, shoot with LMB, grab power-ups to dish out more damage. Every touch hurts — no i-frames.

## Controls

| Action | Input |
| --- | --- |
| Move | `W` `A` `S` `D` |
| Aim | Mouse |
| Shoot | Left Mouse Button |
| Restart (on Game Over) | `R` |
| Toggle Fullscreen | `F11` |

## Features

- **Player** — `CharacterBody3D` with a skeleton rogue model and crossbow. Aim raycasts onto the player's ground plane, so bullets always fire toward the cursor.
- **Enemies** — skeleton minions (fast, 1 HP, touch damage) and skeleton warriors (slower, 5 HP) that join from wave 4.
- **Wave Spawner** — shuffle-and-cycle across N/E/W arena gates, escalating density and difficulty.
- **Power-Ups** — drop from kills (~15%). Picking one grants a multi-shot fan (4 arrows ±15°) for 15 seconds. Pickups stack.
- **HUD** — wave counter, heart-shield icons for HP, kill counter, power-up timer, centered wave banners and Game Over text.
- **Audio** — bow attacks, hit feedback, enemy death stingers, looping ambient track.
- **Arena** — 40×40 walled space with 6-unit gates on each wall side.

## Project Structure

```
scenes/    main.tscn, main_menu.tscn, player.tscn, bullet.tscn,
           enemy.tscn, enemy_warrior.tscn, enemy_mage.tscn,
           power_up.tscn, hud.tscn, heart_icon.tscn, mage_bullet.tscn
scripts/   player.gd, bullet.gd, enemy.gd, enemy_mage.gd,
           wave_spawner.gd, hud.gd, main_menu.gd, power_up.gd,
           mage_bullet.gd, camera_follow.gd
assets/    characters/, enemies/, player/, weapons/, walls/, floor/, audio/
```

## Running

1. Install [Godot 4.6](https://godotengine.org/) (Forward+ renderer).
2. Clone this repo.
3. Open the project folder in Godot — it will rebuild the `.godot/` cache on first import.
4. Press `F5` (or hit Play). The game opens on the main menu scene.

## Credits

3D assets from [Kenney](https://kenney.nl/):

- `mini-characters` — player & enemy models
- `blaster-kit` — projectile and weapon meshes

Audio is sourced from Kenney's sound packs.

## License

Project source is unlicensed (course assignment). Third-party assets follow their original licenses (Kenney assets are CC0).
