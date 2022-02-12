# Spectator Mode
[![luacheck](https://github.com/SwissalpS/spectator_mode/workflows/luacheck/badge.svg)](https://github.com/SwissalpS/spectator_mode/actions)
[![mineunit](https://github.com/SwissalpS/spectator_mode/workflows/mineunit/badge.svg)](https://github.com/SwissalpS/spectator_mode/actions)
[![License](https://img.shields.io/badge/License-LGPLv3%20and%20CC--BY--SA--3.0-green.svg)](LICENSE)
[![Minetest](https://img.shields.io/badge/Minetest-5.0+-blue.svg)](https://www.minetest.net)

A mod for Minetest allowing you to watch other players in their 3rd person view.
You're invisible and undetectable for the players when you're in this mode.

Can be useful for admins or moderators in their task of monitoring.
Requires the privilege `watch`.

Normal players can also invite others to observe them.

## Dependencies

- `player_api` (included in [`minetest_game`](https://github.com/minetest/minetest_game))
- `default` (included in [`minetest_game`](https://github.com/minetest/minetest_game))

## Requirements

This mod requires MT 5.0.0 and above.

## Commands

All the commands can be modified in settings, here they are listed with their default names.<br>

`/watch <player name>` silently attach to player<br>
`/unwatch` (get back to your initial position)<br>
`/watchme <player name>[,<player2 name] ... playerN name]]` invite player(s) to observe caller.<br>
`/pmn` reject an invitation<br>
`/pmy` accept an invitation<br>

## Settings

- **spectator_mode.command_accept** (smy)<br>
 After an invite has successfully been sent, the watcher may accept it with this command.
- **spectator_mode.command_deny** (smn)<br>
 After an invite has successfully been sent, the watcher may decline it with this command.
- **spectator_mode.command_detach** (unwatch)<br>
To stop observing another player, issue this command.
- **spectator_mode.command_invite** (watchme)<br>
To invite another player to observe player that issued this command.
- **spectator_mode.command_attach** (watch)<br>
To start observing another player, issue this command.
- **spectator_mode.invitation_timeout** (60)<br>
Invitations invalidate after this many seconds if they haven't been accepted or denied.
- **spectator_mode.priv_invite** (interact)<br>
The priv needed to send observation invites.
- **spectator_mode.priv_watch** (watch)<br>
The priv needed to silently observe any player that isn't currently watching another one.

## Privelages

Both privelages are registered if no other mod has already done so.

## Compatibility

Before sending invites, beerchat's player meta entry is checked to make sure muted players can't invite.<br>
Other mods can override `spectator_mode.is_permited_to_invite(name_target, name_watcher)` to add own
conditions of when who can invite whom.

## Copyright

Original mod DWTFYW Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
Since 20220208 LGPLv3 and CC-BY-SA-3.0 [see LICENSE](LICENSE)
The LGPLv3 applies to all code in this project.
The CC-BY-SA-3.0 license applies to textures and any other content in this project which is not source code.

