# New Tinkertown — the Loading Room

Working document for the Loading Room pass. Eight tasks. **Tasks 1, 2 and 3 are done** —
each watched in game and signed off. **Task 4 is closed as not relevant.** **Tasks 5 and 6
are written and waiting on an in-game check.** The remaining two are not started, and each
has the reconnaissance it needs written up below.

A task is only marked done here once it has been checked in game and called done.

Branch: `new-tinkertown-pass`. Commit straight onto it.
Next free SQL index: `sql/ashamane/world/2026_09_01_07_world.sql`.

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
| 45847 | S.A.F.E. Operative | sparring side of the battle — task 4; four of them are the cannon gunners — task 7 |
| 46185 | Sanitron 500 | VehicleId 1172, `npc_sanitron_5000` — tasks 5, 6 |
| 46208 | Clean Cannon X-2 | VehicleId 1173, one seat 8674, no script; each has a gunner standing on it — task 7 |
| 46165 | Decontamination Bunny | casts the wash stages |
| 46230 | S.A.F.E. Technician | speaks during the wash |

Spawn guids in the Loading Room:

- Sanitron 500 — **168370, 168381, 168860**
- Clean Cannon X-2 — **167786, 167789, 167792, 167922**, each with its gunner at
  guid + 1 — 167787, 167790, 167793, 167923 (entry 45847)
- Physician's Assistant — **167775, 167917, 169002**
- S.A.F.E. Officer — **167810, 168990** (168990 is the one that patrols; 167812 is
  deleted, see task 2), plus 167623 and 167940 which run `npc_safe_operative_firing_squad`

Quests: **27635 Decontamination**, **28169 Withdraw to the Loading Room!**

---

## Todo

### 1. Teleporter scene — survivor arrives, assistant shows it a bed  — *done, tested in game*

`npc_physicians_assistant_greeter` in `zone_dun_morogh_area_new_tinkertown.cpp`, with
`2026_08_31_04_world.sql` and `2026_09_01_00_world.sql`. The scene runs unattended on a
61 second cycle and repeated five times in the dump, identically each time, which is what
made every number below readable rather than guessed.

Watched end to end in game and signed off. It took four passes after the first build to
get there, and each one is written up in place below rather than as a list of fixes:
the legs would not move at all, the Assistant walked instead of running and cut straight
through the furniture, nobody turned to face anything when they stopped, and the arrival
was reworked to coincide with the flash and then put back because retail does not do
that. The traps behind those are the parts of this section most likely to matter to the
other six tasks.

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

### 2. Patrol path for the S.A.F.E. Officer  — *done, tested in game*

`2026_09_01_01_world.sql`. Path **1689900** on spawn **168990**, 44 nodes, one closed
circuit of the room at walk speed. Watched in game and signed off. Hand-applied, so the
updater will run it again on the next start; it is written to survive that.

**It took a worldserver restart to show, not `.reload waypoint_data`.** The spawn had no
`creature_addon` row at all, and that table has no `.reload` — until the restart,
`LoadCreatureAddons` saw no `path_id` and silently downgraded `MovementType` 2 back to
idle, so the officer stood exactly as before and nothing looked different. Worth
remembering for any of the remaining tasks that add an addon row.

The route was readable because the officer walked it **twice** inside the run — 75
splines, 44 endpoints, and all 30 nodes the two laps have in common are bit-identical
floats. A lap takes 147.3s. The loop closes: the last node is 8.3 yards from the first.

**The nodes are the spline endpoints, not the `WayPoints`.** A new spline goes out every
~2.4s and redirects the officer before the previous one finishes, so its endpoint is the
authored node while the `WayPoints` inside it are pathfinder filler. Two legs come as a
multi-point `Points` list instead (the ramp down to Z 285.59); there the last point is
the node and the rest is the ramp.

**Point 1 is the spawn point exactly** — (−5180.01, 736.88) matched a node at 0.0000
yards, which is also what identified the spawn. The recovered order started elsewhere, so
the list is rotated; `waypoint_data` is cyclic, so that changes only where the route is
entered.

**Two nodes are more than corners**, and both are in the file:

- **point 23** (−5162.50, 706.267) — the dead end at the north of the east corridor. He
  arrives, stands **4.4s**, then walks back south. Timed twice, 4.42 and 4.38.
- **point 37** (−5171.09, 773.307) — a half-second halt with a facing-only spline,
  `FaceDirection` 4.6251225, a round **265°**, which is not his direction of travel. It
  is preceded by point 36 only 0.73 yards away; both are real endpoints, so both are
  kept.

**No speed is set anywhere.** Every leg computes to 2.5 yd/s and `speed_walk` 1 on the
template already gives exactly that, so `move_type` stays 0.

**The long legs are straight.** Points 24→25 is 22.9 yards and 4→5 is 21.7, and the
filler inside both is a straight line down an open corridor — none of task 1's furniture
problem, so pathfinding between nodes is safe here.

**He barks twice, and the steady cadence is somebody else.** This section previously read
the ~4.8s stream of `SMSG_EMOTE` as his and concluded only that it did not line up with
either pause. Split by guid, **168990 emotes twice in the whole run** — one 6 at 20:49:07
and one 274 at 20:51:33 — while sending 75 splines, so he was visible throughout and those
two are all there is. The 56 emotes on that steady cadence belong to **167810**, the
Officer standing still in the north-west corner, who sends no spline at all. Task 3 has
him. Nothing about the patrol route changes; what changes is that the cadence was never
evidence about this spawn.

**167812 is deleted**, in `2026_09_01_02_world.sql`. It stood 0.97 yards off point 18 of
the route above, so once 168990 starts walking the officer passes through his own double.
It is the same stand-in pattern task 1 found under 42552 and 46267 — a static NPC
approximating a stretch of a scene — and it is the first confirmation that the pattern
holds under an entry other than those two. Nothing referenced the spawn: no addon,
formation, pool or event row. The row is backed up at
`/home/serverproject/dumps/safe_officer_167812_backup.sql`, which matters because the
world DB is MyISAM and the delete does not roll back.

167810 stays. It is 9.6 yards from the nearest node, far enough not to be a stand-in for
any part of the route, and it holds a post.

### 3. Emote state for the other gnomes  — *done, tested in game*

`EmoteState` reads correctly now, so this can be checked rather than guessed. Observed
values, keyed by position and matched against the world DB:

| Entry | Observed `EmoteState` | DB state |
|---|---|---|
| 42552 Physician's Assistant | 69 `EMOTE_STATE_USE_STANDING` | 167775 carries 69 and is correct; 167917 is now the task 1 scene actor and takes 69 from the script mid-run; 169002 is deleted |
| 45847 S.A.F.E. Operative | 69 at (−5164.4, 754.6); `EmoteState` 0 and `StandState` **1 SIT** at (−5187.2, 754.4) and (−5185.6, 751.7) | 168120 already carried 69; 168075 and 168133 had no addon row and inherited template **214** `EMOTE_STATE_READY_RIFLE` — written and applied, see below |
| 46230 S.A.F.E. Technician | 233 `EMOTE_STATE_WORK_MINING`, and 69 at (−5161.1, 723.8) | all eight already carry the matching value; a ninth row was a duplicate and is deleted, see below |
| 46268 Survivor | 431 `EMOTE_STATE_COWER` | template already 431 — correct |
| 46267 Rescued Survivor | `EmoteState` 0 throughout; the pose is `StandState` — 8 `KNEEL` or 1 `SIT` | written and applied, see below |

**46230 guid 169037 is deleted**, in `2026_09_01_03_world.sql`. The room held nine rows of
46230 against the eight positions the table above counts (the entry has ten spawns in all;
168119 and 168848 are outside the room): 169037 and **168135** stood 0.20
yards apart at the same height, on the same orientation 4.06662, both posed with emote
233 — one technician entered twice, with the two models inside one another. 168135 keeps
the post. Both rows are backed up at
`/home/serverproject/dumps/safe_technician_169037_backup.sql`.

This is a different fault from the stand-ins task 1 found: not an approximation of a
scene, just a duplicated row. Worth checking the other entries for both shapes — a
near-zero distance between two spawns of one entry with matching orientation is the
signature.

So most of the rest of this is **already right**. The gap is spawns with no
`creature_addon` row, which silently inherit `creature_template_addon`:

- ~~**42552 guid 169002**~~ — deleted by task 1; it was a stand-in for a node of the
  Assistant's walk, not a spawn that belongs in the room.
- ~~**45847 guids 168075, 168133**~~ — done, in `2026_09_01_04_world.sql`. They were
  reasoned about here as standing at the decontamination stations and so wanting 168120's
  emote 69. Both halves of that are wrong and the section below has the numbers.
- ~~**45847 guids 167787, 167790, 167793, 167923**~~ — these were counted here as four
  more of the same and they are not. They are the four cannon gunners, each standing on a
  Clean Cannon X-2 half a yard away; **task 7** has them. A seated passenger takes its
  pose from the vehicle seat, so 69 `USE_STANDING` would be wrong for them and 214 is
  left where it is.

**168075 and 168133 sit, and that is read rather than guessed — `2026_09_01_04_world.sql`.**
This section previously recorded that the dump does not show either spawn. It shows both,
and the filter that missed them was looking under `Creature/` guids keyed on the low
qword; the low qword repeats across unrelated entries, so it matched entry 46345 instead
and came back empty. Keyed on the full guid, each create block matches its `creature` row
on position to five decimals and on orientation to all of them:

| Guid | Position | Orientation | `EmoteState` | `StandState` | `SheatheState` |
|---|---|---|---|---|---|
| 168075 | (−5187.24, 754.415, 287.48035) | 0.541052043437957763 | 0 | **1 SIT** | 1 |
| 168133 | (−5185.63, 751.724, 287.48035) | 0.698131680488586425 | 0 | **1 SIT** | 1 |

So they are the 46267 failure again under a second entry: **the pose is `StandState` and
the emote state is 0**, and a column-wise look for their pose finds 214 and concludes they
are posed already. Giving them 69 would have stood them back up.

They are also not at the decontamination stations. 168120 is at (−5164.44, 754.585) on
Z 285.557, the lower floor; these two are 22 yards west on Z 287.48, in the north-west
corner beside Officer 167810 and kneeling Survivor 167777. A seated pair in a corner with
a standing officer is what that cluster is.

`MovementType` was already 0 with no wander on both, so the sliding-gnome trap the 46267
half hit does not apply here.

**168120 changes sheath only**, in the same file: it carries `SheathState` 2 against an
observed 1, with its emote 69 correct and unchanged. It is rewritten in full alongside the
other two so the room's three posted Operatives read from one place.

A guid row in `creature_addon` **replaces** `creature_template_addon` outright rather than
merging with it — `Creature::GetCreatureAddon` returns the guid row and stops — so emote 0
on these rows is what clears the inherited 214. `LoadCreaturesAddon` then applies
`StandState` and `SheathState` unconditionally and only writes emote when it is non-zero,
which is exactly the wanted result.

**46267 Rescued Survivor — `2026_08_31_03_world.sql`.** Worth reading before starting the
other entries, because the shape of the problem repeats. `creature_addon` has no
`.reload`, so none of it showed until the worldserver restarted.

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
| 46025 S.A.F.E. Officer | 396 OneShotTalkNoSheathe ×26, 273 OneShotYes ×11, 274 OneShotNo ×11, 6 OneShotQuestion ×10 — but **58 across two spawns, not one**: 56 of them are 167810 and only 2 are the patroller 168990 |
| 46268 Survivor | 18 OneShotCry ×5, 20 OneShotBeg ×3 |
| 46267 Rescued Survivor | 1 OneShotTalk ×2, 5 OneShotExclamation ×1, 20 OneShotBeg ×1 |
| 42552 Physician's Assistant | 25 OneShotPoint ×5 |

**The Officer in the north-west corner gestures on a timer — `npc_safe_officer_briefing`,
attached in `2026_09_01_05_world.sql`.** All 56 of the 46025 one-shots above are
**167810**, the Officer standing still beside the two Operatives that task 3 just sat
down. He sends **no spline of any kind** in the whole run: standing still and gesturing is
the entirety of what he does.

- **It is a timer, not a chance roll.** Gaps: mean 4.61s, **stdev 0.71**, range 3.59–6.10.
  A per-tick chance roll gives a geometric spread with stdev near the mean; 0.71 against
  4.61 is a repeating interval with a small random range. The gaps are in fact tri-modal —
  3.59–3.70 (×15), 4.78–4.94 (×33), 6.06–6.10 (×5), with two strays at 4.02 and 4.04 —
  and every cluster is a multiple of about 1.21s. The script rolls flat across
  3600–6100ms rather than reproducing that quantisation, which is a deliberate
  simplification: the modes are an artefact of a tick this server does not share.
- **The gesture and the interval are independent rolls.** Mean gap by preceding emote is
  4.53–4.90 and by following emote 4.45–4.67 — flat either way. Same shape task 1 found,
  where the emote is rolled separately from the line.
- **Weights.** 396 TalkNoSheathe ×26, 273 Yes ×11, 274 No ×10, 6 Question ×9 — the talking
  gesture takes about half and the other three split the rest. The script holds a six-entry
  list with 396 in it three times, which is 50/17/17/17 against an observed 46/20/18/16.
- **Scoped to the spawn, not to 46025.** The patrolling Officer emotes twice in the same
  251s while fully visible. Attaching this to the entry would put a 4.6s cadence on a
  walker that does not want it, so it goes on `creature.ScriptName` for 167810 alone —
  the same per-guid route the firing squads use. 46025 carries no template `AIName`, so
  nothing is displaced.
- **He does not turn.** No facing spline anywhere, and his spawn orientation 3.735 is a
  round **214°** that already points between the two seated Operatives. Nothing in the
  script touches his facing.

**The Survivor beside him needs no change.** 167777's orientation is **6.03883934** in its
create block against **6.03884** in `creature` — already exact, and a round **346°** like
every other authored facing in this room. It points within 11.6° of the Officer, a 0.77
yard miss across the 3.8 yards between them, and no packet ever turns it further. If it has
been seen facing the wrong way in game, that is the random wander rather than the
orientation: 167777 was one of the ten on `MovementType` 1 with a 3 yard wander, which
`2026_08_31_03_world.sql` cleared. Like everything else in this task it needed the
worldserver restart before it showed.

Anim kits: **45847 → kit 573** (×45), **46363 → kit 983** and kit 0 to clear it,
**46449 → kit 989**. **None of these is in the Loading Room**, so this task sets no anim
kit at all. All 52 `SMSG_SET_AI_ANIM_KIT` resolve to six 45847 spawns at (−4950.9, 733.5)
and (−5030.4, 793.9) — the firing squads — and to 46363/46449 out east. Every creature
in the room reports `StateAnimKitID` 0 in its create block. The composition trap in the
list below therefore never comes up here, which is why the seated pair could take a plain
`StandState` with nothing to weigh against it.

**The whole room was swept for the two fault shapes, and it is now clean.** Both the
duplicate-row shape that caught 169037 and the scene stand-in shape that caught 168897,
168909, 168936, 169002 and 167812:

- **No duplicate pairs remain.** Every pair of spawns of one entry inside the room is at
  least 1.34 yards apart, and the three closest pairs — 46267 167773/167916 at 1.34,
  46267 167580/167772 at 1.59, 46230 167945/167946 at 2.71 — each appear as two separate
  create blocks with different orientations, so all six are real.
- **Every remaining spawn is accounted for.** Each of the 50 `creature` rows in the room
  matches a create block, and each block a row; nothing is left standing on a scene's
  ground. 46185 and 46208 are in there too — they come through on a **vehicle** guid type
  rather than `Creature/`, so a sweep keyed on `Creature/` silently drops all seven.

**All ten 46267 poses are confirmed.** Each of the ten static create blocks matches its
row on position and orientation, and every `StandState` agrees with what
`2026_08_31_03_world.sql` wrote — five at 8 KNEEL, five at 1 SIT, `EmoteState` 0
throughout. That half is verified against both the dump and the game.

Two observations that belong to other tasks and are recorded here only because this sweep
is what turned them up:

- **Task 7** — all four gunners report `EmoteState` **0**, not the 214 they inherit, and
  sit 0.71 above their cannons at Z 288.465 on `MovementFlags` 1536. The offset is the
  seat. Worth having when the four are finally seated.
- **Task 4** — the three Operatives already carrying the sparring script (167627, 167633,
  167938) also report `EmoteState` **0** against the 214 in their rows, and `SheatheState`
  2. They are mid-fight throughout, so this is not clean evidence of their idle pose; do
  not read it as one.

**Unrelated, and outside this pass:** entry **48956 Irradiated Roach** appears four times
inside the room and has no spawn anywhere near it — the entry has two rows in the whole
world DB, at Z 484 and Z 518. The roaches roam, so the four positions are not spawn
points and this is not a Loading Room job, but the zone is missing its roaches.

Three traps this task hit, carried forward for the remaining four:
- An anim kit composes with `StandState` but an emote state breaks it, so the two do
  not stack. Read `creature_addon` before changing either, and test poses with
  `.npc set animkit`.
- There is no `.reload` for `creature_addon` — it needs a worldserver restart, so an
  untested change silently does nothing.
- If any of this is set from a script, remember `LoadCreaturesAddon` runs when the
  creature reaches home and will undo whatever `Reset()` set.

### 4. Battle scene at the entrance  — *closed, not relevant*

The fix set already written for the other battle is: `npc_safe_operative_sparring` as
the spawn's `ScriptName`, a `creature_sparring_template` row at 85%, and
`creature_addon` carrying `SheathState` 2 with emote 214. The script exists and is
documented at the top of `zone_dun_morogh_area_new_tinkertown.cpp` — it exists solely
because it never calls `DoMeleeAttackIfReady`, which keeps the Operatives shooting.

Present state near the Loading Room:

- **Already carry the script**: 45847 guids 167627, 167633, 167938 (X −5151…−5144,
  Y 755…766), paired with Crazed Leper Gnome 46391 guids 168496, 168497.
- **Do not**: 45847 guids 168075, 168120, 168133 (X −5187…−5164, Y 752…755) — but see
  below, these three are posted rather than fighting and want no sparring script — and
  167632 at (−5101.7, 790.1) which stands near 46363 guids 984600, 984601, 984602.
- `creature_sparring_template` has 45847 and 46391 but **not 46363**.

**Closed as not relevant**, and task 3 is most of the reason the open question stopped
mattering. It asked which of two candidate clusters was "the entrance", since picking
wrong would edit spawns the request never named. The western candidate is not a battle at
all: **168075 and 168133 sit**, and **168120** works a station — all three are posted, none
of them fights, and task 3 wrote their poses. That leaves 167627, 167633 and 167938 as the
only fighting cluster near the Loading Room, and those three **already carry the script,
the sparring row and the addon**. So the fix set this section describes is either already
applied or aimed at NPCs that were never fighting.

Left here as reconnaissance rather than as work. If a battle at the entrance is ever
picked up, the two things this section still has right are that `creature_sparring_template`
has 45847 and 46391 but **not 46363**, so the 46363 cluster out at (−5101.7, 790.1) could
not be capped on both sides as it stands; and that the spawns must be identified from
`.npc info`'s DB GUID, because `.guid` returns a runtime counter.

### 5. Sanitron 500 reusable by the next player  — *written, awaiting an in-game check*

`npc_sanitron_5000` in `src/server/scripts/EasternKingdoms/zone_gnomeregan.cpp`. Script
only, no SQL — task 6 took `2026_09_01_06_world.sql`.

**The machine keeps dying, because dying is the ending.** `creature_text` group 2 is
"Warning, system overload. Malfunction imminent!" and phase 9 casts 30934 on itself, so
the wash finishes with the Sanitron blowing up. Driving it home in one piece instead
would have thrown that away. What was wrong was only how long it stayed gone.

Three things were in the way, and the first is the one the section originally described:

- **`spawntimesecs` is 300 on all three spawns**, so the wreck was gone for five minutes.
  `me->DespawnOrUnsummon(0, SANITRON_RESPAWN_DELAY)` replaces `setDeathState(JUST_DIED)`
  in phase 10. `Creature::ForcedDespawn` swaps `m_respawnDelay` for the six seconds passed
  in, drops `m_corpseDelay` to zero, kills the creature and calls `RemoveCorpse(false)`,
  which also relocates it back to its spawn point. So the wreck goes with the explosion
  rather than lying on the walkway, and `Creature::Respawn` runs `AI()->Reset()` six
  seconds later, which is what puts `uiPhase` back to 0. All the state is per AI instance
  already, so the three spawns do not touch each other.

- **`uiRespawnTimer` could never have worked where it was**, which is why it is gone
  rather than wired up. `Creature::Update` only ticks `UpdateAI` while the creature is
  alive; once phase 10 has killed the machine nothing in the AI runs again until it is
  back. A countdown inside `UpdateAI` cannot bring a dead creature back by construction,
  so the delay has to be handed to the despawn call instead.

- **The respawned machine had no cursor, and this is the half that would have made a
  quick respawn useless anyway.** `Creature::setDeathState(JUST_RESPAWNED)` writes
  `UNIT_NPC_FLAGS` back from `ObjectMgr::ChooseCreatureFlags`, which reads
  `creature_template.npcflag` and then `creature.npcflag` — **both are 0** for 46185 and
  for all three spawns. The spell click flag is not in either table: `Vehicle::Vehicle`
  sets it once at construction from the usable seat count, and construction does not
  happen again on a respawn. `Vehicle::Reset` does not set it either — it only reapplies
  immunities and accessories. A `JustRespawned` override puts
  `UNIT_NPC_FLAG_SPELLCLICK` back. This is the same flag task 7 is about from the other
  end.

**A player who leaves the seat mid-wash also stranded it**, and that is fixed in the same
breath because it is the same complaint. `UpdateAI` returns on an empty seat, so a logout
or anything else that takes the passenger off froze `uiPhase` where it stood and left the
machine parked out on the walkway — and the next player to click it resumed half way
through the sequence, at the wrong place. `PassengerBoarded(..., apply = false)` now sends
it through the same despawn-and-come-back path, guarded on `uiPhase >= 10` so the end of
the run taking its own passenger off does not trip it. The despawn is delayed a second
rather than called inline, because the hook fires from inside
`Vehicle::RemovePassenger` and the core's own comments warn about scripts that despawn
from there.

To check in game:
- Ride it through to the explosion and confirm the machine is back at its spawn point
  about six seconds later, and that it is **clickable again** — that is the flag half.
- Ride a second time straight after to confirm the sequence starts from the beginning.
- Log out mid-wash, or leave the seat, and confirm it comes back rather than staying on
  the walkway.
- The dump has no ride in it — all three 46185 spawns appear only as idle create blocks —
  so none of this had a recording to check against; it is read off the core.

### 6. Sanitron refuses a player not on the quest  — *written, awaiting an in-game check*

`2026_09_01_06_world.sql`. One `conditions` row, no script change. Hand-applied, so the
updater will run it again on the next start; it is written to survive that, and applying
it twice was checked to leave exactly one row.

`OnGossipHello` already gated on
`GetQuestStatus(QUEST_DECONTAMINATION) == QUEST_STATUS_INCOMPLETE`, so the gossip path was
correct. The spell click that boards the vehicle bypasses gossip entirely and had no
`conditions` row at all, so any player could click straight into the seat:

    (18, 46185, 125095, 0, 0, 9, 0, 27635, 0, 0, 0, 0, 0, '', 'Required quest active for spellclick')

Source type **18** `CONDITION_SOURCE_TYPE_SPELL_CLICK_EVENT`, condition type **9**
`CONDITION_QUESTTAKEN`, both read off `ConditionMgr.h` rather than assumed. Spell 125095 is
**Ride Vehicle Hardcoded**, a control-vehicle spell, checked on its Wowhead page before the
id went into the file. `ConditionMgr` stores the row as
`SpellClickEventConditionStore[SourceGroup][SourceEntry]`, so the entry goes in the group
and the spell in the entry, which is the way round the row above is written.

**The condition matches the gossip gate exactly rather than approximately.**
`CONDITION_QUESTTAKEN` evaluates to `condMeets = (status == QUEST_STATUS_INCOMPLETE)` — the
same single test the script makes — so the two doors cannot disagree about who gets in.

**It also takes the cog cursor away, and that is the half worth testing.** The condition is
read in two places, not one:

- `Unit::HandleSpellClick` skips the click outright — the refusal.
- `Player::CanSeeSpellClickOn`, which `Unit::BuildValuesUpdate` calls to mask
  `UNIT_NPC_FLAG_SPELLCLICK` out of `UNIT_NPC_FLAGS` **per target**. A player who fails the
  condition is never sent the flag and so never gets a cursor.

That is the same flag tasks 5 and 7 are about from their own ends, and it matters that this
is a per-player mask at packet-build time rather than anything cleared on the creature: it
does not disturb the `JustRespawned` flag restore task 5 added, nor the seat-count
arithmetic task 7 relies on.

The per-target masking is the one thing to watch in game. The flag is stripped as the
values block is built, so a player who accepts the quest while standing next to the machine
sees the cursor appear only once the Sanitron next sends them a values update. If it does
not show the instant the quest is accepted, step out of range and back before treating it
as a failure.

**Nothing kicks a rider mid-wash.** Phase 8 calls `player->CompleteQuest(QUEST_DECONTAMINATION)`,
which flips the status to complete and makes this condition false — but the condition is
only read on boarding and the player is seated well before then. Phases 9 and 10 blow the
machine up and empty the seat exactly as before.

Every input the load-time validation checks is present: `creature_template` 46185, quest
27635, and spell 125095 resolving from the DB2 store. The hotfixes `spell` table holds only
four override rows, so 125095 being absent from it means nothing — and `DBErrors.log`,
which does record this class of fault, carries no complaint for either id.

To check in game:
- On the quest: the cursor is there and the ride starts as before.
- Never taken it, and again after handing it in: no cog cursor, and clicking does nothing.
- `.reload conditions` picks the row up. Unlike the `creature_addon` work in tasks 2 and 3,
  this one needs no worldserver restart.

### 7. Clean Cannon X-2 — put its gunner in it  — *not started*

Each of the four cannons has a **S.A.F.E. Operative standing on top of it**, and none of
them is seated. Seating them is the task; the cog cursor below turns out to be the same
problem seen from the other end, and seating the gunner is what fixes it.

| Cannon 46208 | Gunner 45847 | apart | orientation |
|---|---|---|---|
| 167786 (−5163.96, 719.311) | **167787** | 0.572 | 3.15905 both |
| 167789 (−5184.19, 712.642) | **167790** | 0.564 | 0.226893 both |
| 167792 (−5164.86, 709.828) | **167793** | 0.571 | 2.67035 both |
| 167922 (−5183.92, 722.26) | **167923** | 0.565 | 5.88176 both |

The pairing is not a guess. Each gunner is the cannon's guid **+1**, so they were entered
together; the orientations match to all six decimals; every gap is 0.56–0.57 yards; and
every gunner sits at Z 287.754 against the cannon's 287.48, a uniform 0.274 **above** it.
Four spawns, four cannons, one each.

**Nothing seats them today.** `vehicle_template_accessory` and `vehicle_accessory` are
both empty for 46208 — and for 46185 as well. One of those two tables is the mechanism:
`vehicle_template_accessory` keyed on entry 46208 covers all four in a single row, and
every spawn of 46208 is one of these four, so entry scope and guid scope come to the same
thing here. `vehicle_accessory` keyed on the four guids is the narrower option.

**This is also the cursor fix, and it retires the option list that used to be here.**
Vehicle **1173 has exactly one seat, 8674**. `Vehicle::Vehicle` counts the seats that
pass `CanEnterOrExit()` into `UsableSeatNum` and sets `UNIT_NPC_FLAG_SPELLCLICK` when
that count is non-zero, with the core's own comment reading *"Set or remove correct flags
based on available seats. Will overwrite db data (if wrong)."* Two things follow:

- **Clearing `UNIT_NPC_FLAG_SPELLCLICK` from the spawn's `npcflag` cannot work.** The
  constructor recomputes the flag from the seat count on every spawn and overwrites
  whatever the DB said. That was the first and cheapest option in the old list and it is
  a dead end.
- **`Vehicle::AddPassenger` decrements `UsableSeatNum`, and when it reaches zero it
  removes the flag itself.** With one seat and a gunner in it the count goes to zero, so
  the cog cursor goes away as a consequence of seating the Operative. No flag edit is
  needed at all.

That the cursor appears today is itself the proof that seat 8674 passes
`CanEnterOrExit()` — the flag is only ever set when the count is above zero. The seat's
`Flags` in `VehicleSeat.db2` agree, on either of the two readings the collapsed-array
field mapping allows.

**The gunners inherit emote 214** `EMOTE_STATE_READY_RIFLE` from
`creature_template_addon` — none of the four has a `creature_addon` row. For a gunner
that is plausible as it stands, and a seated passenger takes its pose from the seat
anyway, so leave it until the four have been seen in the seat.

To do:
- Seat 167787, 167790, 167793 and 167923 in cannons 167786, 167789, 167792 and 167922.
- **Confirm the seat index before writing the row.** 8674 is the only seat on the
  vehicle, but which of `SeatID1`…`SeatID8` holds it decides whether the accessory row
  says seat 0 or seat 1, and the DB2 reader's field mapping for the collapsed array is
  off by one — so it cannot be read straight off. `.npc info` on a cannon, or a seat
  index that simply works in game, settles it.
- Check `SPELL_CANNON_BURST` still fires. The Sanitron script casts it from the cannon by
  guid (`cannon->CastSpell(player, SPELL_CANNON_BURST, true)`), and an occupied cannon
  has a passenger it did not have before.
- Passenger facing is hardcoded to 0 on seating, so check which way the gunners end up
  pointing rather than assuming the spawn orientation survives.
- Leave `unit_flags` 33536 alone unless the cursor is still there after seating.

**This corrects task 3, and task 3 then corrected the rest of it.** That section listed
six 45847 spawns with no `creature_addon` row and reasoned that they "stand at the
decontamination stations inside the room", so they should probably take 168120's emote 69.
Four of those six — 167787, 167790, 167793, 167923 — are these gunners and are nowhere
near the stations; giving them `EMOTE_STATE_USE_STANDING` would be wrong, and they still
have no addon row. The other two are not at the stations either: **168075** and **168133**
sit on Z 287.48 in the north-west corner, 22 yards from 168120 and on the floor above it,
and they take a stand state rather than an emote. Task 3 has the numbers.

### 8. Quest text for the Pinned Down chain  — *not started*

Every quest from **27670 Pinned Down** to the end of the gnome starting experience is
missing its **Progress** and **Completion** text. This is not a Loading Room job — it runs
the length of the zone — but it is the chain the Loading Room sits in the middle of.

**The Description half is already there; the other two are not there at all.** Measured
across the whole chain:

- `quest_template.QuestDescription` — **present on all 37**, 394 to 508 characters. Two
  were read word for word against Wowhead (27670 and 26373) and match exactly, tokens
  aside. So this column probably needs checking rather than rewriting; fix only the ones
  that differ.
- **Progress** — `quest_request_items.CompletionText`. **No row at all** for any of the 37.
- **Completion** — `quest_offer_reward.RewardText`. **No row at all** for any of the 37.

Missing rows rather than empty strings is why this is invisible from the server side:
`ObjectMgr` loads both tables optionally and logs nothing for a quest that has no row, so
there is no error to find. The player just gets an empty box.

**The chain is exactly `QuestSortID` 6457, and the number confirms itself.** All 37 quests
carrying that sort id lack both rows, and the set is identical to the one you get by
walking `quest_template_addon.PrevQuestID`/`NextQuestID` and `RewardNextQuest` out from
27670 — which is also the 37 Wowhead counts for this chain. So the sort id is a safe
handle and nothing has to be picked out by hand:

    SELECT ID FROM quest_template WHERE QuestSortID = 6457;

| # | Quests |
|---|---|
| the Loading Room run | 27670 Pinned Down, 28167 Report to Carvo Blastbolt, 27671 See to the Survivors, 28169 Withdraw to the Loading Room!, 27635 Decontamination, 27674 To the Surface |
| the class fork | 26197, 26199, 26202, 26203, 26206, 31135, 41217 — all *The Future of Gnomeregan* |
| still forked | 26421, 26422, 26423, 26424, 26425, 31137, 41218 — all *Meet the High Tinker* |
| rejoined | 26208 The Fight Continues, 26566 A Triumph of Gnomish Ingenuity, 26222 Scrounging for Parts |
| side quests off 26222 | 26264 What's Left Behind, 26265 Dealing with the Fallout |
| out to the surface | 26205 A Job for the Multi-Bot, 26316 What's Keeping Jessup?, 26284 Missing in Action, 26285 Get Me Explosives Back! |
| Crushcog | 26318 Finishin' the Job, 26329 One More Thing, 26331 Crushcog's Minions, 26333 No Tanks! |
| Brewnall and out | 26339 Staging in Brewnall, 26342 Paint it Black, 26364 Down with Crushcog!, 26373 On to Kharanos |

**The fork is per class and the text differs across it**, so those fourteen cannot be
written once and copied. `quest_template_addon.AllowableClasses` gives the mapping
outright — 1 warrior 26203 → 26425, 4 hunter 41217 → 41218, 8 rogue 26206 → 26423,
16 priest 26199 → 26422, 128 mage 26197 → 26421, 256 warlock 26202 → 26424, 512 monk
31135 → 31137 — and all seven pairs rejoin at 26208. The seven Descriptions already in the
DB are 446–504 characters and all different from one another, which is the shape to expect
from the two missing columns as well.

**Five more hang off it and are a scope decision.** 26198 The Arts of a Mage, 26200 Priest,
26201 Warlock, 26204 Warrior, 26207 Rogue — each the follow-up to its class's *The Future
of Gnomeregan*. They are `QuestSortID` **801**, not 6457, so they are outside the count
above, and they are missing both rows too. Take them or leave them, but decide rather than
discover it later.

**When each string is actually seen**, which is also how to test it:

- **Completion** is the hand-in box — `SendQuestGiverOfferReward`.
- **Progress** is the box you get when you talk to the ender **while the quest is still
  incomplete**. `PlayerMenu::SendQuestGiverRequestItems` returns early into the offer
  reward for any quest without `QUEST_SPECIAL_FLAGS_DELIVER` once it can be completed, so
  on a kill or talk quest the Progress text never appears after the objective is done. A
  test that finishes the objective first will report the text as fine when it is empty.

Writing it:

- The text comes off each quest's Wowhead page. **Not every quest has a Progress** — 26373
  On to Kharanos has none — and a quest with no Progress on Wowhead should get no
  `quest_request_items` row rather than a row holding an empty string.
- **The tokens have to go back in by hand, and this is the actual work.** The DB text uses
  `$B` for a line break, `$N`/`$n` player name, `$C`/`$c` class, `$R`/`$r` race and
  `$G he:she;` for gender; Wowhead renders all of them, so what you copy has `<name>` in it
  and no paragraph breaks. 27670's Description already in the DB is the reference for the
  house style: `...S.A.F.E.$B$BI don't know how you managed to survive the radiation down
  here, $n, but...`
- Columns are `ID, EmoteOnComplete, EmoteOnIncomplete, EmoteOnCompleteDelay,
  EmoteOnIncompleteDelay, CompletionText, VerifiedBuild` and `ID, Emote1..Emote4,
  EmoteDelay1..EmoteDelay4, RewardText, VerifiedBuild`. The house style in the rows either
  side of these ids: emotes and delays 0, or `EmoteOnComplete` 1 with `EmoteOnIncomplete` 0,
  which is the most common pair in the table (5122 rows against 3090 at 0/0);
  `quest_offer_reward.Emote1` is 0 on 9159 rows and 1 on 1820. `VerifiedBuild` 0.
- **The file must survive being applied twice** — hand-applying skips the `updates` row, so
  the updater runs it again on the next start. `DELETE FROM ... WHERE ID IN (...)` ahead of
  the inserts, both tables.
- Locales are separate tables (`quest_offer_reward_locale`, `quest_request_items_locale`)
  and are out of scope; `quest_template_locale` already carries eight locale rows per quest
  here, so only the enUS base rows are being added.

**This gap is not specific to the gnome chain** — 800 of the 990 quests in the 27000 id
band have no `quest_offer_reward` row either, and the table covers 12,081 of 29,007 quests
in all. Do not let the fix widen: this task is the 37 (or 42 with the class quests), and
the rest of the DB is somebody else's pass.

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
