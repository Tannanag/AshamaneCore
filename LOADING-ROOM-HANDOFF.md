# New Tinkertown — the Loading Room

Working document for the Loading Room pass. Seven tasks, none of them started; what is
done so far is the toolchain and the reconnaissance each one needs.

Branch: `new-tinkertown-pass`. Commit straight onto it.
Next free SQL index: `sql/ashamane/world/2026_08_31_04_world.sql`.

Source dump: `/home/serverproject/dumps/dump_12.1.0.69497_2026-08-31_20-47-31-loading-room.pkt`
(build 12.1.0.69497, 20,440 packets, ~3m of the Loading Room).

---

## Toolchain — WowPacketParser

**Plain upstream WowPacketParser reads this build. No local patches are needed.**

The clone at `/home/serverproject/WowPacketParser` had been sitting on an old commit
with hand-added build numbers. Upstream had already done all of the 12.1 work properly —
`Add build 12.1.0.69465 and 12.1.0.69497`, `Support 12.1.0` (which fills in the opcode
table), `Fix a bunch of wrong ResetBitReader placements`, and the hotfix and update-field
updates. Pulling replaced every local change:

    cd /home/serverproject/WowPacketParser
    git pull --ff-only
    /home/serverproject/.dotnet/dotnet build WowPacketParser.slnx -c Release

Then parse:

    cd /home/serverproject/dumps
    /home/serverproject/.dotnet/dotnet \
      /home/serverproject/WowPacketParser/WowPacketParser/bin/Release/WowPacketParser.dll \
      dump_12.1.0.69497_2026-08-31_20-47-31-loading-room.pkt

**96.3% of packets parse with 0 errors.** The remaining 3.7% are opcodes with no handler
written for them at all, which is not the same as a failure. Working tree is clean at
upstream `b8531d901`.

**If a future dump parses badly, pull before doing anything else.** A stale clone shows
up as either raw hex with numeric opcodes and no names, or as named opcodes whose fields
read as garbage — positions around 1e-37, a flags field holding an object's own guid.
Both mean the checkout is behind, not that the dump is bad.

One thing worth knowing about the module layout, because it looks alarming: a stack
trace naming `WowPacketParserModule.V9_0_1_36216` does **not** mean the parser thinks
your dump is 9.0.1. Modules are named for the build at which a reader last had to
change, and each build inherits every reader it has not overridden, down a fallback
chain. `SMSG_SPELL_GO` genuinely has no reader newer than the 9.0.1 one, so that is the
one a 12.1 dump uses, correctly.

---

## The cast

Loading Room is areaId **5495**, map 0. The officer's patrol bounds it: X −5193…−5162,
Y 660…776, Z ≈ 286–288.

| Entry | Name | Notes |
|---|---|---|
| 46267 | Rescued Survivor | teleported in — task 1 |
| 42552 | Physician's Assistant | leads the survivor to a bed — task 1 |
| 46268 | Survivor | already cowers; `creature_template_addon.emote` 431 |
| 46025 | S.A.F.E. Officer | patrols — task 2 |
| 46363 / 46391 | Crazed Leper Gnome | 46363 carries auras 95205, 86400, 86414 |
| 45847 | S.A.F.E. Operative | sparring side of the battle — task 4 |
| 46185 | Sanitron 500 | VehicleId 1172, `npc_sanitron_5000` — tasks 5, 6 |
| 46208 | Clean Cannon X-2 | VehicleId 1173, no script — task 7 |
| 46165 | Decontamination Bunny | casts the wash stages |
| 46230 | S.A.F.E. Technician | speaks during the wash |

Spawn guids in the Loading Room:

- Sanitron 500 — **168370, 168381, 168860**
- Clean Cannon X-2 — **167786, 167789, 167792, 167922**
- Physician's Assistant — **167775, 167917, 169002**
- S.A.F.E. Officer — **167810, 167812, 168990** (168990 is the one that patrols),
  plus 167623 and 167940 which run `npc_safe_operative_firing_squad`

Quests: **27635 Decontamination**, **28169 Withdraw to the Loading Room!**

---

## Todo

### 1. Teleporter scene — survivor arrives, assistant shows it a bed  — *not started*

The whole scene is in the dump and decodes cleanly. The Physician's Assistant
(42552, guid low 26330530) plays **emote 25 OneShotPoint**, then walks; the Rescued
Survivor (46267, guid low 1450175) follows it. Both move in the box X −5165…−5156,
Y 754…777, Z 285.6…287.4 — 42 splines for the assistant, 28 for the survivor.

The survivor's own emotes across the run: emote 1 OneShotTalk, emote 5
OneShotExclamation, emote 20 OneShotBeg.

To do:
- Pull the full ordered timeline of the two guids (`wpp_index.py`, below) and turn the
  leg boundaries into the scene's beats.
- Find the arrival: look for the cast on 46267 near 20:48:10 and take the teleport
  visual from `SMSG_SPELL_GO` / `SMSG_SPELL_START`, whose `SpellXSpellVisualID` now
  reads correctly. The create block in `SMSG_UPDATE_OBJECT` is also readable, so the
  survivor's spawn state can be checked there directly.
- Decide summon-vs-spawn. If the survivor has to be assembled before it is seen,
  conceal it via a `Creature*` so no client ever draws it mid-assembly.
- The bed hand-off is the same shape as the carry scene already written for 46449 in
  `zone_dun_morogh_area_new_tinkertown.cpp`; read that first, it may be reusable.

### 2. Patrol path for the S.A.F.E. Officer  — *not started*

Spawn **168990** at (−5180.01, 736.88, 287.4) — the sniffed guid ends its run on that
exact point, which identifies it. 75 splines, one continuous loop around the room, sent
as a new spline roughly every 2.4s, so the path is the sequence of spline endpoints
rather than one waypoint list.

The loop, in order: south along X ≈ −5180 to Y 660, west to −5191, east across to
−5162, north up the east side to Y 706, back west to −5186, north along X ≈ −5192 to
Y 730, northeast to (−5170, 773), then a short circuit around Y 758–773 and back south
to the spawn point.

To do:
- Use the `patrol-paths` skill, but keep the SQL header short — a title line and only
  what a reader cannot get from the statements. The skill asks for a long header naming
  where the data came from; that does not apply here.
- Point 1 must be the node nearest the spawn, or the NPC walks the whole diameter of
  its own path on every respawn.
- Only guid 168990. Do not touch 167810 or 167812 — scope every DB edit to the spawns
  actually named, never to every spawn of the entry.

### 3. Emote state for the other gnomes  — *46267 done, the rest not started*

`EmoteState` reads correctly now, so this can be checked rather than guessed. Observed
values, keyed by position and matched against the world DB:

| Entry | Observed `EmoteState` | DB state |
|---|---|---|
| 42552 Physician's Assistant | 69 `EMOTE_STATE_USE_STANDING` | 167775 and 167917 already carry 69; **169002 has no `creature_addon` row** and falls back to template 0 |
| 45847 S.A.F.E. Operative | 69 at (−5164.4, 754.6) | that spawn is 168120 and already carries 69; six others in the room have no addon row and inherit template **214** `EMOTE_STATE_READY_RIFLE` |
| 46230 S.A.F.E. Technician | 233 `EMOTE_STATE_WORK_MINING`, and 69 at (−5161.1, 723.8) | all nine already carry the matching value |
| 46268 Survivor | 431 `EMOTE_STATE_COWER` | template already 431 — correct |
| 46267 Rescued Survivor | `EmoteState` 0 throughout; the pose is `StandState` — 8 `KNEEL` or 1 `SIT` | **done**, see below |

So most of this is **already right**. The gap is spawns with no `creature_addon` row,
which silently inherit `creature_template_addon`:

- **42552 guid 169002** — inherits 0 while both its siblings stand at 69.
- **45847 guids 167787, 167790, 167793, 167923, 168075, 168133** — inherit 214
  `READY_RIFLE`. 214 is right for the Operatives fighting outside, but these six stand
  at the decontamination stations inside the room, where the one spawn that does have a
  row (168120) is set to 69.

The dump does not directly show those six, so confirm in game before writing rows for
them rather than assuming they match 168120.

**46267 Rescued Survivor — done, `2026_08_31_03_world.sql`.** Worth reading before
starting the other entries, because the shape of the problem repeats.

These gnomes carry no emote state at all. `EmoteState` is 0 in every one of their
create blocks; the pose is `StandState`, which is a different field and is set from
`creature_addon.StandState`, not `emote`. Anything that goes looking for their pose in
the emote column finds nothing and concludes they are unposed.

The room had fifteen spawns of 46267. Eleven of them, plus one that only appears while
walking, matched a position exactly — 0.000 yards, so the DB coordinates and the room's
are the same numbers. **168897** (−5157.85, 764.98) and **168909** (−5159.82, 776.93)
matched nothing, and both stand on ground the rest of the group covers well: 168909 has
a confirmed neighbour 4.8 yards away and 168897 one at 2.4. They were extras, and both
are now deleted. The rows are backed up at
`/home/serverproject/dumps/rescued_survivor_46267_backup_2rows.sql`, which matters because
the world DB is MyISAM and the delete does not roll back.

Poses now set, all ten static spawns written out in one place in the file:

| Pose | Guids | Was |
|---|---|---|
| `StandState` 8 `KNEEL` | 167772, 167773, 167774, 167776, 167777 | already 8 — unchanged |
| `StandState` 1 `SIT` | 167580, 167581, 167582, 167916, 167918 | **no `creature_addon` row**, inheriting template 0 `STAND` |

Same failure as 42552 guid 169002 and the six 45847s above: the missing row is invisible,
because the spawn silently inherits `creature_template_addon` and looks deliberate.

All ten also sat on `MovementType` 1 with `wander_distance` 3, and none of them move —
`MovementFlags` 0 and not one spline across the whole run, while the scene survivor next
to them sends five or six. Random movement never clears a stand state, so what this
produced was a gnome drifting around its spawn point still kneeling. That is now
`MovementType` 0, `wander_distance` 0. **Check the other entries for the same thing
before writing their poses** — setting a pose on a wandering spawn just gives you a
sliding gnome.

**168936 was deliberately left alone** — `MovementType` 1, no addon row. It is the task 1
scene survivor: it is the one that walks and it is correct standing at spawn. Task 1
decides what happens to it.

`creature_addon` has no `.reload`, so none of this shows until the worldserver restarts.

One-shot emotes, which are a separate thing from the state and come from `SMSG_EMOTE`:

| Entry | One-shots seen |
|---|---|
| 46025 S.A.F.E. Officer | 396 OneShotTalkNoSheathe ×26, 273 OneShotYes ×11, 274 OneShotNo ×11, 6 OneShotQuestion ×10 |
| 46268 Survivor | 18 OneShotCry ×5, 20 OneShotBeg ×3 |
| 46267 Rescued Survivor | 1 OneShotTalk ×2, 5 OneShotExclamation ×1, 20 OneShotBeg ×1 |
| 42552 Physician's Assistant | 25 OneShotPoint ×5 |

Anim kits: **45847 → kit 573** (×45), **46363 → kit 983** and kit 0 to clear it,
**46449 → kit 989**.

To do:
- An anim kit composes with `StandState` but an emote state breaks it, so the two do
  not stack. Read `creature_addon` before changing either, and test poses with
  `.npc set animkit`.
- There is no `.reload` for `creature_addon` — it needs a worldserver restart, so an
  untested change silently does nothing.
- If any of this is set from a script, remember `LoadCreaturesAddon` runs when the
  creature reaches home and will undo whatever `Reset()` set.

### 4. Battle scene at the entrance  — *not started, one open question*

The fix set already written for the other battle is: `npc_safe_operative_sparring` as
the spawn's `ScriptName`, a `creature_sparring_template` row at 85%, and
`creature_addon` carrying `SheathState` 2 with emote 214. The script exists and is
documented at the top of `zone_dun_morogh_area_new_tinkertown.cpp` — it exists solely
because it never calls `DoMeleeAttackIfReady`, which keeps the Operatives shooting.

Present state near the Loading Room:

- **Already carry the script**: 45847 guids 167627, 167633, 167938 (X −5151…−5144,
  Y 755…766), paired with Crazed Leper Gnome 46391 guids 168496, 168497.
- **Do not**: 45847 guids 168075, 168120, 168133 (X −5187…−5164, Y 752…755), and 167632
  at (−5101.7, 790.1) which stands near 46363 guids 984600, 984601, 984602.
- `creature_sparring_template` has 45847 and 46391 but **not 46363**.

**Open question — which pair is "the entrance"?** Two candidate clusters, and picking
wrong would edit spawns the request never named. Resolve with `.npc info` on the
Operative and the gnome actually fighting at the entrance and work from those DB GUIDs
— note `.guid` returns a runtime counter, so it has to be `.npc info`'s DB GUID. If it
turns out to be the 46363 cluster, that entry also
needs its own `creature_sparring_template` row or neither side can be capped.

### 5. Sanitron 500 reusable by the next player  — *not started*

`npc_sanitron_5000` in `src/server/scripts/EasternKingdoms/zone_gnomeregan.cpp`.

At the end of the ride, phase 10 calls `me->setDeathState(JUST_DIED)`. The spawn's
`spawntimesecs` is **300**, so the machine is gone for five minutes and the next player
on the quest finds nothing. `uiRespawnTimer` is initialised to 6000 in `Reset()` and
then **never read anywhere in `UpdateAI`** — the intended quick respawn was written and
never wired up.

To do:
- Decide between reviving on a short timer and not killing it at all — after
  `RemoveAllPassengers()` the machine could simply return to its spawn point and reset
  `uiPhase`, which avoids the corpse entirely.
- Either way `uiRespawnTimer` should be used or removed; leaving a dead field is what
  hid this.
- Three spawns share the entry (168370, 168381, 168860), so whichever way it goes must
  be per-creature state, not static.

### 6. Sanitron refuses a player not on the quest  — *not started*

`OnGossipHello` already gates on
`GetQuestStatus(QUEST_DECONTAMINATION) == QUEST_STATUS_INCOMPLETE`, so the gossip path
is correct. **The spell-click path is not gated at all**, and it bypasses gossip
entirely:

    npc_spellclick_spells: npc_entry 46185, spell_id 125095, cast_flags 1, user_type 1

There is **no `conditions` row** for it — nothing at `SourceTypeOrReferenceId` 18,
`SourceGroup` 46185. Any player can click straight into the seat.

To do:
- Add the condition: source type **18** (`CONDITION_SOURCE_TYPE_SPELL_CLICK_EVENT`),
  `SourceGroup` 46185, `SourceEntry` 125095, condition type **9**
  (`CONDITION_QUESTTAKEN`), `ConditionValue1` 27635.
- Read spell 125095's Wowhead page before the id goes into the file.
- The file must survive being applied twice: hand-applying skips the `updates` row, so
  the updater will run it again.

### 7. Clean Cannon X-2 not interactable  — *not started*

46208 has `VehicleId` 1173 and **no `npc_spellclick_spells` row at all**. This is the
failure the carry scene already documented: `Vehicle::Install` sets
`UNIT_NPC_FLAG_SPELLCLICK` whenever a seat is usable, so the client draws the cog
cursor and offers an interaction that cannot do anything, because there is no
spellclick spell behind it.

Current `unit_flags` is 33536 = `UNIT_FLAG_IMMUNE_TO_PC` | `UNIT_FLAG_IMMUNE_TO_NPC` |
`UNIT_FLAG_UNK_15` — nothing there stops the cursor.

To do:
- The cannons are scenery that the Sanitron script fires by guid
  (`cannon->CastSpell(player, SPELL_CANNON_BURST, true)`), so they never need to be
  clicked. Suppressing the flag is safe.
- Options, cheapest first: clear `UNIT_NPC_FLAG_SPELLCLICK` from the spawn's `npcflag`;
  or add `UNIT_FLAG_NOT_SELECTABLE` (0x02000000); or make the seat non-usable so
  `Vehicle::Install` never sets the flag. Only the last actually addresses the cause,
  but check it does not break `SPELL_CANNON_BURST`.
- All four guids: 167786, 167789, 167792, 167922.

---

## Re-reading the dump

`wpp_index.py` in the repo root walks the parsed `.txt` into packet blocks (opcode,
direction, time, packet number, body lines) and is the quickest way back in. It sits
alongside `wpp_movement.py` and is excluded from git the same way, by the `wpp_*.py`
line in `.git/info/exclude`.

    python3 wpp_index.py SMSG_EMOTE          # dump every block of one opcode

    python3 -c "
    from wpp_index import blocks
    for b in blocks():
        if b['op']=='SMSG_EMOTE': print(b['time'], b['lines'])
    "

Filter by entry with a regex for `Entry: <n>` over the joined body lines. **Do not use
guid `Low` to tell two spawns of one entry apart** — the values come back clustered at
multiples of 2^23 and repeat across unrelated entries, so the low qword is not a flat
counter. Key on the decoded position instead and match it against `creature`, which is
how the emote-state spawns in task 3 were identified.
