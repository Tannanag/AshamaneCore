# New Tinkertown — the Loading Room

Working document for the Loading Room pass. Seven tasks, none of them started; what is
done so far is the toolchain and the reconnaissance each one needs.

Branch: `new-tinkertown-pass`. Commit straight onto it.
Next free SQL index: `sql/ashamane/world/2026_08_31_03_world.sql`.

Source dump: `/home/serverproject/dumps/dump_12.1.0.69497_2026-08-31_20-47-31-loading-room.pkt`
(build 12.1.0.69497, 20,440 packets, ~3m of the Loading Room).

---

## Toolchain — WowPacketParser now reads this build

This was the blocker and it is cleared. Re-parse with:

    cd /home/serverproject/dumps
    /home/serverproject/.dotnet/dotnet \
      /home/serverproject/WowPacketParser/WowPacketParser/bin/Release/WowPacketParser.dll \
      dump_12.1.0.69497_2026-08-31_20-47-31-loading-room.pkt

Four changes, all uncommitted in `/home/serverproject/WowPacketParser` (that clone
already carried uncommitted build additions for 69382/69404/69465; these sit on top):

1. **Build 69497 registered** in `ClientVersionBuild.cs`, `Opcodes.cs`,
   `UpdateFields.cs` and `ClientVersion.cs`, following the pattern the earlier builds
   use.

2. **The 12.1.0 opcode table was an empty stub.** `Enums/Version/V12_1_0_69214/Opcodes.cs`
   came from upstream's "Init 12.1.0" commit with both dictionaries declared and left
   empty, so every packet in every 12.1 dump printed as raw hex with a numeric opcode
   and no name — 0 of 65,404 named in the earlier 69465 parse. It is now generated from
   TrinityCore master's `src/server/game/Server/Protocol/Opcodes.h`, which is at
   12.1.0.69497 exactly. 2,404 of 2,431 opcodes; the 27 skipped are Discord, Housing and
   LFG-list names that have no entry in WPP's own `Opcode` enum.
   Generator kept at `/home/serverproject/.claude/jobs/6f4bdc96/tmp/genop.py`.

3. **`SMSG_ON_MONSTER_MOVE` was misread.** Two fields moved in 12.0 and the V11 reader
   desynced on both, reporting positions in the 1e-37 range before running off the end
   of the packet:
   - `MonsterMove::Write` is `MoverGUID`, `SplineData`, `Pos` — `Pos` used to be second
     and is now written **last**.
   - `MovementMonsterSpline` is `ID`, `Move`, then the CrzTeleport /
     StopUseFaceDirection / StopSplineStyle bits — that bit block used to **precede**
     the spline.

   A 12.x reader now lives at
   `WowPacketParserModule.V12_0_0_65390/Parsers/MovementHandler.cs`. Because `Pos` is
   read last and the packed deltas are stored relative to the midpoint between `Pos` and
   the first spline point, the deltas are held packed until `Pos` is known. It also
   takes the optional spline filter *after* the point arrays, where 12.1 writes it.

   Handler resolution: 69497's `VersionDefiningBuild` is `V12_0_0_65390`, so the loader
   picks this module ahead of the V11 fallback.

**Result: 76.2% of packets parse, up from 65.3% named / 0% before.** All 2,227
monster-move packets now decode to real coordinates.

### Still broken — `SMSG_UPDATE_OBJECT`

Object updates remain desynced for 12.1: the create block reads `Position` as garbage
and `MovementFlags2` comes back holding the object's own guid low. **So no update-field
value from this dump can be trusted** — that includes `EmoteState`, `NpcFlags`,
`UnitFlags` and every stat. Anything below that needed those was taken from the world
DB or from a dedicated opcode instead. Fixing it means aligning the movement status
block and the 12.1 update-field masks, and is its own job.

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
- Pull the full ordered timeline of the two guids (`idx.py`, below) and turn the leg
  boundaries into the scene's beats.
- Find the arrival: look for the summon and the cast on 46267 near 20:48:10, and
  identify the teleport visual from `SMSG_SPELL_GO` / `SMSG_SPELL_START` rather than
  from update fields, which are unreliable here.
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

### 3. Emote state for the other gnomes  — *not started*

Careful: **the persistent emote state cannot be read from this dump** — see the
`SMSG_UPDATE_OBJECT` note above. What *is* trustworthy is `SMSG_EMOTE`, which carries
the one-shots, and `SMSG_SET_AI_ANIM_KIT`:

| Entry | One-shot emotes seen |
|---|---|
| 46025 S.A.F.E. Officer | 396 OneShotTalkNoSheathe ×26, 273 OneShotYes ×11, 274 OneShotNo ×11, 6 OneShotQuestion ×10 |
| 46268 Survivor | 18 OneShotCry ×5, 20 OneShotBeg ×3 |
| 46267 Rescued Survivor | 1 OneShotTalk ×2, 5 OneShotExclamation ×1, 20 OneShotBeg ×1 |
| 42552 Physician's Assistant | 25 OneShotPoint ×5 |

Anim kits: **45847 → kit 573** (×45), **46363 → kit 983** and kit 0 to clear it,
**46449 → kit 989**.

To do:
- Establish which gnomes read wrong in game first — the current values are
  `creature_template_addon.emote` 214 on 45847, 431 on 46268, 0 elsewhere.
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

Filter by entry with a regex for `Entry: <n>` over the joined body lines; guid low
distinguishes individual spawns of the same entry.
