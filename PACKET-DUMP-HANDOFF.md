# Parsing unparsed WowPacketParser dumps — handoff

Everything below was recovered from `dump_12.1.0.69299_2026-08-13_23-58-54_parsed.txt`
(retail 12.1.0.69299 "Midnight", enUS, 32,713 packets, 10.6 MB payload, ~9m47s session).
Reusable code: `wpp_movement.py`.

## The situation

WPP has no opcode definitions for retail 12.1.0.69299 — its header even says
`Targeted database: WrathOfTheLichKing`. **Nothing is parsed.** All 32,713 packets are
raw hex blocks with zero named opcodes. Everything here came from reverse-engineering
the payloads.

## Gotcha that will bite you first

The first hex row after each packet header is WPP's **column ruler**
(`00 01 02 ... 0F`), not payload. A naive regex captures it and shifts every offset
by 16 bytes. Validate by comparing payload length against the declared `Length:` field —
it should be 0 mismatches across the whole file.

## Header-level facts (free, no decoding)

| | |
|---|---|
| Direction | 30,153 S2C / 2,560 C2S |
| ConnIdx | 1,738 on 0 (auth/instance), 30,975 on 1 (world) |
| Distinct opcodes | 324 |
| Opcode encoding | 32-bit, appears to be `group << 16 \| index` |

Traffic shape is diagnosable without names: `0x4501F2` is 11,676 packets at a **fixed
9 bytes** (heartbeat); `0x45000B` is 75 packets totalling 3.96 MB (37% of the dump —
the hotfix/DB2 bulk stream); `0x5C0000` ranges 26 B–97 KB (object updates).

## Opcode map (build 12.1.0.69299)

Confirmed by decoding:

| Opcode | Meaning | Notes |
|---|---|---|
| `0x5E0002` | monster move / spline order | 3,953 pkts — fully decoded below |
| `0x490006` | creature query response | `u32 entry` @0, null-term name @20 |
| `0x490007` | gameobject query response | same shape, 129 pkts |
| `0x41xxxx` | client movement (C2S) | player XYZ at payload offset **21** |
| `0x5C0000` | object update | spawn positions, not yet decoded |
| `0x5E000E` | position correction? | 1,209 pkts, single XYZ — not decoded |
| `0x49000F` | DB2 record/hotfix counts | plain text |
| `0x45036F` | server CVar block | ~141 config keys as text |
| `0x45021C` | shop catalog | plain text |
| `0x650012/13/14/16` | quest text (offer/complete/objective) | plain text |
| `0x4A0001` | NPC combat chatter | plain text |
| `0x450001`, `0x490005` | realm list | plain text |

Anything text-bearing can be mined with a `[\x20-\x7e]{6,}` scan without decoding
structure at all — that is how the opcode map above was bootstrapped.

## ObjectGuid (128-bit, packed)

Two mask bytes (low then high), each bit marking a present byte, then only those bytes:

```python
low, high, off = read_packed_guid(b, 0)
type    = high >> 58          # 8 = Creature, 2 = Player, 9 = Vehicle, 11 = GameObject
realm   = (high >> 42) & 0x1FFF
map     = (high >> 29) & 0x1FFF
entry   = (high >>  6) & 0x7FFFFF
counter =  low & 0xFFFFFFFFFF
server  = (low >> 40) & 0xFFFFFF
```

This dump: map 0, realm 4223, serverId 26 (constant). Sanity checks that confirmed
the layout: `type` resolves to 8/Creature, `map` to 0/Eastern Kingdoms, and `entry`
721 → Rabbit, 705 → Ragged Young Wolf (classic IDs).

Caveat: `counter` values cluster at multiples of 2^23, so the low qword is probably not
a flat counter — the field split above may be wrong past bit 23. It does not matter for
identity: `(entry, counter)` is unique per spawn because `server` is constant.

## `0x5E0002` monster move — recovered layout

```
[0]              PackedGuid  mover
[g+0]    u32     spline id            global monotonic allocator
[g+13]   u32     duration ms          0 => stop / facing-only packet
[...]            PackedGuid  face target   (optional; 172 of 3,952 packets)
[first Vec3]     DESTINATION
[...]    u32[]   packed intermediate waypoints
[last 12 bytes]  ORIGIN (current position)
```

Destination is **first**, origin is **last** — the reverse of the obvious guess.
Intermediate waypoints are 11/11/10 signed bitfields in quarter-yard units:

```python
x = sign(u        & 0x7FF, 11) * 0.25
y = sign((u>>11)  & 0x7FF, 11) * 0.25
z = sign((u>>22)  & 0x3FF, 10) * 0.25
```

### How the layout was validated

Two independent statistical checks — neither would hold under a wrong field mapping:

1. **Continuity.** `dest[N]` vs `origin[N+1]` for the same unit: median error
   **0.117 yd**, 89.8% within 3 yd. The three other first/last pairings give
   3.1–6.4 yd medians.
2. **Speed.** `distance / duration` puts **2,673 of 3,107** moves at exactly
   **2.50 yd/s** — WoW's canonical NPC walk speed — with clean secondary clusters at
   6.0, 8.0 and 10.0 (run/chase). 591 packets have `duration == 0` (stops).

Unresolved: the first-Vector3 offset varies (30, 31, 35, 46 bytes past the GUID) — about
10% of packets use a layout variant not fully mapped. The `+13` duration offset and the
face-GUID scan are heuristics validated statistically, not from symbols.

## Distinguishing patrol from random wander

The discriminator, in order of strength:

1. **Bit-identical destinations.** A patrol node is a stored coordinate replayed each
   lap, so it arrives as the *same float32 triple* every time. Random wander
   (`RANDOM_MOTION_TYPE`) picks a fresh continuous point and **never** repeats exactly.
   Do **not** use distance clustering — a 1 yd epsilon inside a 2.5 yd wander disc
   invents nodes that do not exist.
2. **Successor determinism.** Given node A, how often is the next node the same B?
   Patrol ≈ 1.0, wander ≈ 1/n. Survives combat interruption; periodicity detection
   does not.
3. **Radius gate.** A 2 yd "cycle" is a wanderer that got lucky. Require ≥6 yd extent.

**Movement type is per-spawn, not per-entry** — it maps to the creature table's
`MovementType` column. Coldridge Citizen (entry 37218) has 10 tight wanderers *and*
2 genuine patrollers under one entry ID. Never classify at entry level.

## Distinguishing a gap from a pause

Three things look alike in the stream:

| | test |
|---|---|
| **Idle pause** | silence with no displacement — normal waypoint delay |
| **Interruption** | `origin[N+1] ≠ dest[N]`, elapsed ≤ spline duration — combat re-order |
| **Gap** | `origin[N+1] ≠ dest[N]`, elapsed > duration + 2s, displacement > median leg |

Silence alone proves nothing: Sten Stoutarm was silent 405 of 504 observed seconds with
zero gaps — it just stands at nodes.

**Gaps are the visibility horizon.** Every gap event in this dump opens at 83–130 yd
player distance. Distribution of all received monster-moves: p50 71 yd, **p90 99.8 yd**,
p99 110 yd — the ~100 yd active-object radius. The NPC walks out of range, keeps
patrolling unobserved, and reappears elsewhere on its route. The data was never sent;
no amount of parsing recovers it.

Consequence: reconstructed "closed loops" may be an artifact of closing across a hole.
In this dump the long closure legs (87.8 yd on Rockjaw Goon 16681829, 49.9 on Coldridge
Citizen 33411320, 42.4 on Mountaineer 58577144) each coincide with a gap event — those
are **open routes with a missing segment**, not circuits.

## Results from this dump

23 creature types, 211 tracked spawns. Excluding critters, 40 spawns had enough data;
**9 are on a set patrol path**:

| NPC | spawn | nodes | det | complete |
|---|---|---|---|---|
| Sten Stoutarm | 8245495 | 3 | 1.00 | 100% |
| Jona Ironstock | 8245496 | 6 | 1.00 | 100% |
| Coldridge Mountaineer | 25022712 | 15 | 0.97 | 94% |
| Coldridge Citizen | 33411320 | 19 | 0.93 | 90% |
| Coldridge Mountaineer | 66965752 | 20 | 0.92 | 81% |
| Coldridge Mountaineer | 58577144 | 9 | 0.84 | 87% |
| Coldridge Citizen | 66965752 | 21 | 0.78 | 86% |
| Coldridge Mountaineer | 41799928 | 4 | 0.78 | 81% |
| Rockjaw Goon | 16681829 | 12 | 0.57 | 92% |

Only the two 1.00-determinism routes are complete. The rest are missing an estimated
2–15 waypoints each beyond the visibility horizon.

Also extractable and confirmed: an NPC-vs-NPC aggro graph from the 172 face-target GUIDs
(Coldridge Mountaineer → Rockjaw Invader ×67, etc.), and a server-load side channel —
the spline ID allocator ran 141,165,621 → 142,760,456 over 562 s, i.e. ~2,837 splines/sec
realm-wide, of which this client received 0.248%.

## Capturing better data

To close the gaps, park the character where the far ends of the routes sit inside 100 yd.
For this zone: ~(−6180, 375) covers Mountaineers 66965752 and 58577144; ~(−6060, 375)
covers Citizen 66965752. Roughly three vantage points at ten minutes each would complete
all seven incomplete routes.

## Relevance to TC/LC comparison work

This is a **retail 12.1.0** dump — opcode numbers and packet structures share nothing
with the 7.3.5 LegionCore/TrinityCore trees. Its value to that project is the *string*
content (spell/quest/creature/gameobject names, DB2 record counts, CVar names), not the
wire format. The movement decoding above is only reusable against other dumps of the
same or near build.

## Scrub before sharing

The dump contains account identifiers in cleartext: BattleTag `axer#11776`, WoW account
`991731939#1`, character names `Tannanag / Tanntwo / Kuhmawn / Pilosa / Rosythunder`,
realm Aegwynn.
