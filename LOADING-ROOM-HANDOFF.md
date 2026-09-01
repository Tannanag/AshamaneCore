# New Tinkertown — the Loading Room

Working document for the Loading Room pass. Seven tasks, none of them started; what is
done so far is the toolchain and the reconnaissance each one needs.

Branch: `new-tinkertown-pass`. Commit straight onto it.
Next free SQL index: `sql/ashamane/world/2026_09_01_01_world.sql`.

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

### 1. Teleporter scene — survivor arrives, assistant shows it a bed  — *done*

`npc_physicians_assistant_greeter` in `zone_dun_morogh_area_new_tinkertown.cpp`, plus
`2026_08_31_04_world.sql`. The scene runs unattended on a 61 second cycle and repeated
five times in the dump, identically each time, which is what made every number below
readable rather than guessed.

The run, timed from the moment the gnome appears:

| T+ | What happens |
|---|---|
| 0.000 | Rescued Survivor summoned on the Gnomeregan Teleporter at (−5161.76, 754.665, 286.039) facing 1.88496, and casts **spell 7791 Teleport** on itself |
| 2.067 | plays one of emote **1 Talk / 5 Exclamation / 20 Beg** |
| 2.167 | says one of its seven lines |
| 6.889 | steps off the pad to (−5163.96, 759.53) — the Assistant leaves its spot in the same instant, **at a run** |
| 10.071 | Assistant reaches (−5163.26, 763.441), turns to 4.24115 and plays **25 OneShotPoint** |
| 10.229 | Assistant says "Ah, a new arrival. Right this way, sir." |
| 15.007 | Assistant sets off back, leading; the gnome follows at 15.400 |
| 22.683 | Assistant reaches its post at (−5161.37, 775.453), turns to 0.71558 and takes **EmoteState 69** |
| 27.543 | gnome reaches Gnomeregan Mat 156538, turns to 4.38078 and takes **StandState 1 SIT** (the script does both on arrival, which is a little earlier) |
| 38.471 | Assistant drops the emote state and walks home |
| 48.591 | gnome despawns |
| 61.073 | the next one arrives |

**The teleport effect is one spell and nothing else.** 7791 "Teleport" is a one second
dummy with a server-side script; the flash is `SpellXSpellVisualID` **312** and the
client resolves it alone. No visual kit, no gameobject animation — the teleporter
itself sends nothing. The cast must not be triggered, or only `SMSG_SPELL_GO` goes out
and the flash plays across the pair.

**The gnome is visible for about a second before the flash, and that is correct.** The
create block and `SMSG_SPELL_START` share a timestamp, and `SMSG_SPELL_GO` — which is
where the flash lands — comes 0.817s later, so the gnome is standing on the pad before
the effect goes off. This was checked in game on retail and it is what retail does.

Summoning it concealed and revealing it on the flash was built and then reverted. It is
the tighter effect and it is the wrong one. Two things fall out of having tried it, worth
keeping:

- The cast **must not be triggered**. A triggered cast sends only `SMSG_SPELL_GO`, which
  collapses the second away and lands the flash with the gnome rather than after it.
- If a scene here ever does need the two to coincide, the shape is: summon, conceal
  through a `Creature*` in the same breath, then reveal and cast one tick later, **reveal
  first**. A client that has never been sent the creature drops a spell cast by it, so a
  cast ahead of the create block loses the flash rather than mistiming it. `AddToMap`
  sends a create block for anything it puts in the world and runs inside
  `SummonCreature`, so concealing after the fact is the only hook — and
  `SummonCreature`'s own `visibleBySummonerOnly` argument does nothing to a creature, for
  the reason written up on `npc_safe_operative_bearer`.

**The endpoints are furniture, and that is how they were confirmed.** The pad is
gameobject **156676 Gnomeregan Teleporter**; the seat is **156538 Gnomeregan Mat** at
(−5160.01, 776.535), 0.4 yards from where the gnome stops. The other three mats in the
room each have a static Survivor on them, which is worth carrying into task 3 — a mat
is where one of these gnomes belongs.

**Spawns the scene replaced.** Both were static stand-ins for parts of the run:

- **168936** stood on the teleporter, at the arrival position *and facing* to five
  decimal places. The script reads its numbers.
- **169002** (42552) stood on a node of the Assistant's own walk back. Only two spawns
  of 42552 appear anywhere in the dump — 167775, static and correct, and the scene
  actor — so this one was surplus.
- **167917** became the scene actor. It was standing on the *post*, the spot the
  Assistant occupies for 16 seconds mid-scene; it is moved to (−5164.96, 775.741,
  287.3875) facing 3.06154, which is where the Assistant idles between runs and returns
  to. The post is a position in the script now.

This is the same pattern as the two Rescued Survivors deleted in task 3: **168909** sat
exactly on the mat the scene gnome sits on, and **168897** sat 0.2 yards off a node of
the gnome's walk. Whoever built the room approximated the scene with static NPCs, so
expect more of them under the other entries.

**Speech.** `creature_text` group 0 on both entries, from `broadcast_text` **46477–46484**
(that table lives in `ashamane_hotfixes`, not the world DB). Four of the seven arrival
lines were heard; the other three sit in the same block and are the only ones in it that
fit. The emote is rolled separately from the line rather than being a property of it —
three emotes appeared against four texts, and every one of the seven broadcast texts
carries `EmoteID` 0.

**One leg is run and the rest are walked.** The Assistant's dash over to a new arrival
is the only one: 21.9 yards travelled in 2882ms, **8.01 yards a second**. Every other
leg in the scene, both actors, comes out at 2.5 — walk speed. `speed_walk` 1 and
`speed_run` 1.14286 on both templates already give exactly those two numbers, so no
speed is set anywhere in the script.

The parser hands you the speed directly — `Computed Distance` and `Computed Speed` at
the foot of every `SMSG_ON_MONSTER_MOVE`. Never compute it from the straight line
between the endpoints.

**Every route is written out, and pathfinding is not used.** There is a table and four
chairs standing between the Assistant's spot and the teleporter, and the scene walks
around them: the run over is 12.4 yards apart and 21.9 travelled. Asking
`MovePoint(…, generatePath = true)` for that leg gets a straight line through the
table — **none of that furniture is in the navmesh**, which is built from terrain and
statics and knows nothing about gameobject spawns. So the nodes come out of the sniff
instead, thinned to about a yard apart.

The waypoints are in each `SMSG_ON_MONSTER_MOVE` as `WayPoints`, separate from `Points`,
which holds only the destination. Two things to know when reading them back:

- **Legs overlap.** Most are issued while the previous one is still running and simply
  redirect the walker from wherever it has got to, so the tail of each leg's route was
  never walked. Keep only the part before the next leg's start position; concatenating
  whole legs double-counts and gives a route that doubles back.
- **Some of it is pathfinder noise worth dropping.** The gnome's second leg goes 4 yards
  north to y 767.5 and straight back south to 763.5 before carrying on. That is real —
  it is why the leg took 12.1s rather than the 8.8 the distance implies — but it is a
  navmesh artefact rather than anything the scene wants, and the overlap rule above
  removes it. It also means the gnome reaches the mat about 3.4s earlier than retail's
  clock says, which is why the sit is driven by arriving rather than by the clock.

**The way out and the way back are the same corridor.** Retail sends the way out as one
spline and the way back as four, but the four trace the outbound route to within a yard
the whole way. The script therefore holds **one** `AssistantRoute` array and walks it
backwards on the return, stopping at the post rather than carrying on to the idle spot —
so the two directions cannot drift apart. Checked against the sniffed return leg by leg
before being collapsed that way. The lengths confirm it: 19.1 yards at walk speed is
7.66s against retail's 7.68.

**`MoveSmoothPath` overwrites element 0** with the mover's real position
(`MoveSplineInit::Launch`), so the first entry of every route array is the point the
mover is standing on when the leg goes out, never a destination. A one-node path has its
only destination eaten and moves nobody, which is the failure that first showed up as
"the Assistant points and speaks without walking over".

**The gnome sits when it reaches the mat, not when the clock says so.** It is a summon
carrying the entry's default AI, so its `MovementInform` goes there and never reaches the
script. The way to hear about its arrival from outside it is to watch
`movespline->Finalized()` in the Assistant's `UpdateAI` — the scheduler is updated first
in that method, so a leg issued on the same tick has already been launched and cannot
read as finished. A distance check against the mat goes with it, so a spline that fails
to launch cannot be mistaken for an arrival. `ARRIVE_TO_SIT` is still there as a backstop
for a walk that never arrives at all, and is normally already spent by the time it fires.

**The gnome has no AI of its own.** The Assistant drives every leg of it. Its
`MovementInform` goes to the entry's default AI and not to the script, which is one
reason the scene is timed rather than chained off arrivals — the other being that this
is how it actually runs. Legs go out on the clock while the previous one is still
moving, redirecting the walker from wherever it has got to. Only the Assistant's walk
home is answered on arrival, so its facing can be put back once it is standing there.

**Every stop sets a facing, and I nearly missed all four of them.** A walk that ends
without one leaves the walker looking whichever way its last node pointed it, which at
the mat is straight into the north wall. The facings arrive as a facing-only spline —
`Face: 3 (Angle)` with `PointsCount: 0` — in the same `SMSG_ON_MONSTER_MOVE` that stops
the walk:

| Where | Facing | |
|---|---|---|
| Assistant at the meet point | 4.2411499 | 243° |
| Assistant at the post | 0.7155849 | 41° |
| Assistant at home | 1.3962633 | 80° |
| gnome on the mat | 4.3807764 | 251° |

All four are whole degrees, so they are authored values rather than anything to
recompute from the direction of travel. Two are corroborated by the stand-in spawns this
scene replaced: **0.71558 is exactly the orientation 167917 was standing at** (the post)
and **4.38078 exactly 168909's** (the mat).

The Assistant's home facing lives on the spawn in `creature.orientation`, where a home
facing belongs, and the script reads it back on arrival. The first version of this pass
derived that value from the direction the last leg leaves it in and got 3.06154, which
is wrong by 95° — `2026_09_01_00_world.sql` corrects it to 1.3962633.

**Reading facings out of the dump:** they are nested two levels deep, as
`(MovementMonsterSpline) (MovementSpline) FaceDirection:`. A filter that matches on the
start of the line finds nothing and the whole thing looks like it sends no facings at
all, which is what happened here. Match anywhere in the line.

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
| 42552 Physician's Assistant | 69 `EMOTE_STATE_USE_STANDING` | 167775 carries 69 and is correct; 167917 is now the task 1 scene actor and takes 69 from the script mid-run; 169002 is deleted |
| 45847 S.A.F.E. Operative | 69 at (−5164.4, 754.6) | that spawn is 168120 and already carries 69; six others in the room have no addon row and inherit template **214** `EMOTE_STATE_READY_RIFLE` |
| 46230 S.A.F.E. Technician | 233 `EMOTE_STATE_WORK_MINING`, and 69 at (−5161.1, 723.8) | all nine already carry the matching value |
| 46268 Survivor | 431 `EMOTE_STATE_COWER` | template already 431 — correct |
| 46267 Rescued Survivor | `EmoteState` 0 throughout; the pose is `StandState` — 8 `KNEEL` or 1 `SIT` | **done**, see below |

So most of this is **already right**. The gap is spawns with no `creature_addon` row,
which silently inherit `creature_template_addon`:

- ~~**42552 guid 169002**~~ — deleted by task 1; it was a stand-in for a node of the
  Assistant's walk, not a spawn that belongs in the room.
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
are now deleted. **Task 1 then explained them**: 168909 sat exactly on the mat the scene
gnome sits on, and 168897 0.2 yards off a node of its walk. They were static stand-ins
for a scene, which is a pattern worth expecting under the other entries too. The rows are backed up at
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
