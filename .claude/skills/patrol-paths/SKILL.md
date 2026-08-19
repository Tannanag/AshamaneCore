---
name: patrol-paths
description: Turn a raw WoW packet sniff (.pkt) into NPC patrol paths and wander radii in the ashamane_world DB. Use when handed a dump and asked to give NPCs their retail movement — waypoints, patrol routes, roaming, wander_distance — on the private server.
---

# Patrol paths from a packet sniff

Takes a raw `.pkt`, recovers each NPC's movement, and writes only the movement the
server is missing: patrol routes for spawns that stand still, wander for spawns that
should roam. Everything already correct on the server is left alone and reported as
skipped.

Retail coordinates go in **as-is**. Coldridge Valley geometry is unchanged between
7.3.5 and 12.1.0, and 8 of 9 routes matched a live spawn point bit-for-bit. Never
snap, translate, or round a node.

## Tools

| file | what it does |
|---|---|
| `wpp_movement.py` | decodes raw `0x5E0002` splines, classifies patrol vs wander |
| `wpp_patrols.py` | recovers node order, emits patrol and wander SQL |
| `wpp_apply.py` | snapshots, applies, and writes the untracked revert |
| `PACKET-DUMP-HANDOFF.md` | how the packet layout was recovered, and why each check is there |

WPP itself cannot parse these builds — it has no opcode tables for retail 12.x, so
every packet arrives as raw hex and the scripts decode it directly. That is expected;
a header saying `Targeted database: WrathOfTheLichKing` is not an error.

## 1. Parse the dump

```bash
cd /home/serverproject/WowPacketParser/WowPacketParser/bin/Release
DOTNET_ROOT=/home/serverproject/.dotnet /home/serverproject/.dotnet/dotnet \
    WowPacketParser.dll /home/serverproject/dumps/<dump>.pkt
```

Writes `<dump>_parsed.txt` next to the input (~7x the .pkt size). Parse once — every
step below reads that file, and each read takes a few minutes on a 100 MB text dump.

`Parsed 0 (0.000%) packets successfully, skipped N (100.000%)` is the expected result,
not a failure — WPP has no opcode tables for retail 12.x and the raw hex is the input.

**A build WPP has never seen fails differently**: a `TypeInitializationException` from
`UpdateFields`, a zero-byte parsed file, and nothing else. WPP throws while setting the
version, before it reads a packet. Register the build as an alias of the newest one it
does know — four sites, all mechanical, mirroring the previous build's entries:

- `Enums/ClientVersionBuild.cs` — `V12_1_0_69382 = 69382,`
- `Enums/Version/UpdateFields.cs` and `Enums/Version/Opcodes.cs` — add the `case` to the
  switch that returns the version-defining build
- `Misc/ClientVersion.cs` — the same `case`, plus a date row in the build list

Then `dotnet build WowPacketParser/WowPacketParser.csproj -c Release` (with `DOTNET_ROOT`
set as above) and parse again. The 12.1.0 modules are empty stubs, so this only makes WPP
willing to dump the hex — which is all the decoder needs. Confirm with step 3 rather than
assuming the alias was safe; 69382 passed unchanged against a layout recovered on 69299.

## 2. Find the zone

```bash
python3 wpp_movement.py --probe /home/serverproject/dumps/<dump>_parsed.txt
```

Prints where the player walked, a suggested `--box`, the map ids, and the entries with
the most movement. **The box is a decoder input, not a filter** — coordinates are found
by scanning payloads for the first plausible float triple, so a box on the wrong zone
decodes nothing. Pass it with an equals sign, or argparse eats the leading minus:
`--box=-6563,-5905,155,800,178,599`.

## 3. Check the decode holds for this build

The layout was recovered from 12.1.0.69299. A newer build may have moved it.

```bash
python3 wpp_movement.py --stats --box=<box> <dump>_parsed.txt
```

Expect continuity median well under 1 yd and >50% of legs at exactly 2.5 yd/s (69299
gives 0.560 yd and 88.8%). If continuity is tens of yards and the speeds scatter, the
field offsets no longer fit — **stop and say so**. Do not emit SQL from a failed decode.

## 4. Read the routes before writing anything

```bash
python3 wpp_patrols.py --box=<box> <dump>_parsed.txt > /tmp/routes.txt
```

Name NPCs as trailing arguments to narrow it; with none, every resolved name is
reported. Per route the report gives the recovered order, node visit counts, whether
the route closed, and a VERDICT on completeness. Three shapes come out of the observed
lap, and all three are emitted the same way — `waypoint_data` is a cyclic list, so a
retraced node is simply listed again where it is walked again:

- **circuit** — every node once, `A B C A`.
- **out-and-back** — two nodes once, the rest twice, `A B C D C B`. The core cycles a
  path rather than ping-ponging it, so the return leg has to be in the table.
- **mixed** — a loop with a spur retraced partway, `A B C D C B E F G A`. This is a real
  shape, not a parsing failure; report it as such.

**Say plainly when data is missing.** The sniff only sees ~100 yd, so an NPC that walks
out of range keeps patrolling unobserved and the packets were never sent. The signals,
all reported for you: an INCOMPLETE verdict with estimated missing nodes, a
`longest leg is N yd` warning (sound routes here top out near 25 yd), completeness under
90%. A "closed loop" that closes across a gap is an open route with a hole in it. Tell
the user which stretch is missing and where to stand for a better sniff — the far ends
of the incomplete routes, ten minutes each.

## 5. Emit the SQL

```bash
python3 wpp_patrols.py --box=<box> --sql <dump>_parsed.txt > /tmp/patrols.sql
python3 wpp_patrols.py --box=<box> --wander-sql --retune 3 <dump>_parsed.txt > /tmp/wander.sql
```

Both refuse to guess and skip rather than die, so read the `-- SKIPPED` lines.

**Patrols.** Each route is paired with the DB spawn standing on one of its nodes —
a patrolling NPC's spawn point is one of its waypoints, which identifies it outright
where proximity alone cannot. Spawns that already have `MovementType=2` plus an addon
`path_id` plus waypoint rows are skipped as already done. A match at ~0.00 yd is
certain; anything past ~1 yd with a close runner-up is a guess, so **ask the user to
`.npc info` that NPC in game and give you the DB GUID** before writing it (`.guid`
returns a runtime counter, not the spawn id).

**Wander.** Radius is per entry — the median across sniffed spawns of each spawn's
95th-percentile displacement from its own centre — because a radius is a property of the
creature and matching individual critters to individual spawns is unreliable. Spawns
that stand still on the server and roam in the sniff gain `MovementType=1`; with
`--retune 3`, spawns already roaming at a radius off by 3x or more get corrected.
Patrolling spawns are never traded for a roam.

Guids are always written as an explicit `WHERE id=E AND guid IN (...)` list. Alpine Hare
has 562 spawns and 26 in this zone — an entry-wide UPDATE would silently retune hares in
every zone in the game. Never widen the scope past the spawns the evidence names.

## 6. Write the update files

One file per part in `sql/ashamane/world/`, named `<date>_NN_world.sql`, so each can be
reverted independently: patrols first, then spawns gaining wander, then radius retunes.
Match the house style of `sql/ashamane/world/2026_08_17_00_world.sql` — a long `--`
header naming the zone, the guids, where the data came from, the numeric justification,
what was checked, and what was deliberately left alone. Keep the emitter's own comment
lines; they carry the match distance, shape, speed and warnings.

Keep the `-- @touched:` line at the end of each file. `wpp_apply.py` reads it to know
what to snapshot, and refuses to run without it.

Two things that will bite otherwise:
- `ObjectMgr::LoadCreatureAddons` silently downgrades `MovementType=2` to idle when the
  spawn has no `creature_addon.path_id`. The addon row is mandatory.
- The column is `wander_distance` on this branch, not `spawndist`.

## 7. Apply, with an undo

```bash
python3 wpp_apply.py --dry-run --revert-dir /home/serverproject/coldridge-reverts \
    sql/ashamane/world/<file>.sql     # snapshot + revert only
python3 wpp_apply.py --revert-dir /home/serverproject/coldridge-reverts \
    sql/ashamane/world/<file>.sql     # then apply for real
```

The world DB is MyISAM — there is no transaction to roll back, so the revert file *is*
the undo. It is written before the forward file runs, alongside a raw snapshot of every
row that could be overwritten. **Reverts stay untracked**, outside the repo: they record
one server's state at one moment, not a change to the branch.

After applying, ask the user to run `.reload waypoint_data` in the worldserver console
(or restart it) and to check the log for `sql.sql` errors — a missing `path_id` logs
"has movement type set to WAYPOINT_MOTION_TYPE but no path assigned". Zero such lines is
the real pass signal. Then have them watch one short route in game; NPCs pathing through
geometry means a leg needs the intermediate spline points, which are still in the dump.

## 8. Commit

One commit per file on the working branch, `DB/Creature:` prefix, prose message with
concrete numbers — `39c816e922` and `e3000aff80` are the templates. Commit the SQL and
any script changes; never the revert directory, the parsed dump, or the raw `.pkt`.

Dumps carry account identifiers, character names and BattleTags in cleartext. Do not
paste raw dump content into commit messages, issues, or anything published.
