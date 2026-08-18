#!/usr/bin/env python3
"""
Extract NPC movement from WowPacketParser output that WPP could not parse.

Works on retail dumps where WPP has no opcode definitions for the build, so
every packet is a raw hex block. All structure below was recovered empirically
from build 12.1.0.69299 and validated statistically -- see PACKET-DUMP-HANDOFF.md.

Usage:  python3 wpp_movement.py <dump_*_parsed.txt> [--csv outdir]
"""
import re, sys, math, struct, pickle, datetime, bisect, collections

# ---------------------------------------------------------------- extraction
HDR = re.compile(r'^(ServerToClient|ClientToServer): (\d+) \(0x([0-9A-F]+)\) '
                 r'Length: (\d+) ConnIdx: (\d+) Time: (\S+ \S+) Number: (\d+)')
HEX = re.compile(r'^\| ((?:[0-9A-F]{2} )+)\s*\|')

def load(path):
    """Yield (dir, opcode, datetime, number, connidx, payload).

    NOTE: the first hex row after each header is WPP's column ruler
    (00 01 02 ... 0F), not payload. Including it shifts every offset by 16.
    """
    pk = None; buf = []; ruler = False; bad = 0; out = []
    def flush():
        nonlocal bad
        if pk is None: return
        b = bytes.fromhex(''.join(buf))
        if len(b) != int(pk[3]): bad += 1
        out.append((pk[0][0], pk[2],
                    datetime.datetime.strptime(pk[5], "%m/%d/%Y %H:%M:%S.%f"),
                    int(pk[6]), int(pk[4]), b))
    for line in open(path, errors='replace'):
        m = HDR.match(line)
        if m:
            flush(); pk = m.groups(); buf = []; ruler = False; continue
        m = HEX.match(line)
        if m and pk:
            if not ruler: ruler = True; continue      # skip column ruler
            buf.append(m.group(1).replace(' ', ''))
    flush()
    if bad: print(f"warning: {bad} payloads disagree with declared Length", file=sys.stderr)
    return out

# ---------------------------------------------------------------- object guid
HIGHGUID = {0:'Null',2:'Player',3:'Item',5:'StaticDoor',6:'Transport',7:'Conversation',
            8:'Creature',9:'Vehicle',10:'Pet',11:'GameObject',12:'DynamicObject',
            13:'AreaTrigger',14:'Corpse',15:'LootObject',16:'SceneObject',19:'DynamicDoor',
            21:'Vignette',22:'CallForHelp',23:'AIResource',24:'AILock'}

def read_packed_guid(b, o):
    """128-bit ObjectGuid, packed: two mask bytes then only the non-zero bytes."""
    lo_mask, hi_mask = b[o], b[o+1]; o += 2
    low = high = 0
    for i in range(8):
        if lo_mask >> i & 1: low  |= b[o] << (i*8); o += 1
    for i in range(8):
        if hi_mask >> i & 1: high |= b[o] << (i*8); o += 1
    return low, high, o

def guid_fields(low, high):
    return dict(type=HIGHGUID.get(high >> 58, high >> 58),
                realm=(high >> 42) & 0x1FFF,
                map=(high >> 29) & 0x1FFF,
                entry=(high >> 6) & 0x7FFFFF,
                counter=low & 0xFFFFFFFFFF,
                server=(low >> 40) & 0xFFFFFF)

# ------------------------------------------------------- opcodes (this build)
OP_MONSTER_MOVE   = '5E0002'   # spline order for a non-player unit
OP_CREATURE_QUERY = '490006'   # entry -> name cache
OP_CLIENT_MOVE    = '41'       # prefix; player position at payload offset 21

def world_xyz(b, i, box):
    x, y, z = struct.unpack_from('<fff', b, i)
    (x0,x1),(y0,y1),(z0,z1) = box
    return (x,y,z) if x0<x<x1 and y0<y<y1 and z0<z<z1 else None

def find_xyz(b, start, box):
    out = []; i = start
    while i <= len(b) - 12:
        p = world_xyz(b, i, box)
        if p: out.append((i, p)); i += 12
        else: i += 1
    return out

def unpack_delta(u):
    """Intermediate spline point: 11/11/10 signed, quarter-yard units."""
    s = lambda v, bits: v - (1 << bits) if v >> (bits-1) else v
    return (s(u & 0x7FF, 11)*0.25, s((u >> 11) & 0x7FF, 11)*0.25, s((u >> 22) & 0x3FF, 10)*0.25)

def parse_monster_move(b, box):
    """
    Empirically recovered layout:
      [0]            PackedGuid  mover
      [g+0]  u32     spline id   (global monotonic allocator)
      [g+13] u32     duration ms (0 => stop/facing-only packet)
      [...]          optional PackedGuid  face/chase target
      [first Vec3]   destination
      [...]  u32[]   packed intermediate waypoints
      [last 12 B]    current position (origin)
    Validated: dest[N] vs origin[N+1] median error 0.117 yd; distance/duration
    piles up on exactly 2.50 yd/s (NPC walk) for 86% of moves.
    """
    low, high, o = read_packed_guid(b, 0)
    g = guid_fields(low, high)
    if o + 17 > len(b): return None
    pts = find_xyz(b, o, box)
    if not pts: return None
    g['spline']   = struct.unpack_from('<I', b, o)[0]
    g['duration'] = struct.unpack_from('<I', b, o+13)[0]
    g['dest']     = pts[0][1]
    g['origin']   = pts[-1][1]
    g['dist']     = math.dist(g['dest'], g['origin'])
    g['face']     = None
    stop = pts[0][0]
    for i in range(o+17, max(o+17, stop-10)):
        if b[i] and b[i+1]:
            try: l2, h2, e2 = read_packed_guid(b, i)
            except IndexError: continue
            f = guid_fields(l2, h2)
            if e2 <= stop and f['type'] in ('Player','Creature','Vehicle') \
               and f['map'] == g['map'] and 0 < f['entry'] < 200000:
                g['face'] = f; break
    if len(pts) > 1:
        a, z = pts[0][0]+12, pts[-1][0]
        g['waypoints'] = [unpack_delta(struct.unpack_from('<I', b, i)[0])
                          for i in range(a, z-3, 4)]
    else:
        g['waypoints'] = []
    return g

# -------------------------------------------------------------------- driver
def analyse(path, box=((-7000,-5500),(0,1500),(200,800)), exclude=()):
    pkts = load(path)
    names = {}
    for d, op, t, n, ci, b in pkts:
        if op == OP_CREATURE_QUERY and len(b) > 24:
            e = struct.unpack_from('<I', b, 0)[0]
            s = b[20:].split(b'\0')[0].decode('utf8', 'replace')
            if s: names[e] = s
    track = []
    for d, op, t, n, ci, b in pkts:
        if d == 'C' and op.startswith(OP_CLIENT_MOVE) and len(b) >= 33:
            p = world_xyz(b, 21, box)
            if p: track.append((t, p))
    track.sort(); times = [x[0] for x in track]
    def player_at(ts):
        if not track: return None
        return track[min(bisect.bisect_left(times, ts), len(track)-1)][1]

    moves = []
    for d, op, t, n, ci, b in pkts:
        if op != OP_MONSTER_MOVE: continue
        g = parse_monster_move(b, box)
        if g and g['entry'] not in exclude:
            g['ts'] = t; g['n'] = n; moves.append(g)
    return dict(packets=pkts, names=names, moves=moves,
                track=track, player_at=player_at)

# ------------------------------------------------- patrol / wander / gap logic
def classify(moves, names, player_at):
    spawns = collections.defaultdict(list)
    for m in moves: spawns[(m['entry'], m['counter'])].append(m)
    out = []
    for (e, ctr), v in spawns.items():
        v.sort(key=lambda m: m['n'])
        d = [m for m in v if m['duration'] > 0 and m['dist'] > 0.5]
        if len(d) < 8: continue
        # a stored waypoint replays as the SAME float32 triple; random wander never does
        cnt = collections.Counter(m['dest'] for m in d)
        nodes = {k: i for i, (k, c) in enumerate(cnt.items()) if c > 1}
        seq = [nodes[m['dest']] for m in d if m['dest'] in nodes]
        succ = collections.defaultdict(collections.Counter)
        for a, b in zip(seq, seq[1:]): succ[a][b] += 1
        tot = sum(sum(x.values()) for x in succ.values())
        det = sum(x.most_common(1)[0][1] for x in succ.values())/tot if tot else 0.0
        cx = sum(m['dest'][0] for m in d)/len(d); cy = sum(m['dest'][1] for m in d)/len(d)
        rad = max(math.dist(m['dest'][:2], (cx, cy)) for m in d)
        legs = sorted(m['dist'] for m in v if m['dist'] > 1)
        med = legs[len(legs)//2] if legs else 1.0
        # What share of this unit's movement actually lands on stored nodes?
        # A wanderer that returns to its spawn point after every leash/combat
        # replays that one coordinate bit-identically, so it accumulates a
        # "node" with dozens of visits and, having almost nothing to choose
        # between, a deceptively high determinism. Counting nodes and scoring
        # successors cannot see this; the giveaway is that the other 80% of its
        # destinations are one-off continuous points. Genuine patrols sit at
        # 91-100% on-node, home-returning wanderers at 15-23% -- nothing lands
        # in between.
        on_node = len(seq) / len(d)
        patrol = on_node >= 0.5 and \
                 ((rad >= 6 and len(nodes) >= 3 and len(seq) >= 10 and det >= 0.75) or
                  (rad >= 15 and len(nodes) >= 8 and len(seq) >= 20 and det >= 0.50))
        # gap: moved while unobserved (displaced AND elapsed exceeds the spline's own duration)
        gaps = []
        for a, b in zip(v, v[1:]):
            slack = (b['ts']-a['ts']).total_seconds() - a['duration']/1000.0
            disp = math.dist(a['dest'], b['origin'])
            if disp > 3 and slack > 2.0 and disp > med:
                pa = player_at(a['ts']); pb = player_at(b['ts'])
                gaps.append(dict(t0=a['ts'], t1=b['ts'], slack=slack, disp=disp,
                                 last=a['dest'], next=b['origin'],
                                 est_nodes=round(disp/med),
                                 player_dist=(math.dist(pa[:2], a['dest'][:2]) if pa else None,
                                              math.dist(pb[:2], b['origin'][:2]) if pb else None)))
        seen = sum(m['dist'] for m in v); unseen = sum(g['disp'] for g in gaps)
        out.append(dict(entry=e, name=names.get(e, f'entry {e}'), counter=ctr,
                        moves=len(v), nodes=len(nodes), determinism=det, radius=rad,
                        median_leg=med, patrol=patrol, gaps=gaps, unseen=unseen, on_node=on_node,
                        completeness=seen/(seen+unseen) if seen+unseen else 1.0))
    return sorted(out, key=lambda r: (-r['patrol'], -r['determinism']))

if __name__ == '__main__':
    if len(sys.argv) < 2: sys.exit(__doc__)
    r = analyse(sys.argv[1])
    print(f"packets {len(r['packets'])}  monster-moves {len(r['moves'])}  "
          f"names {len(r['names'])}  player samples {len(r['track'])}\n")
    rows = classify(r['moves'], r['names'], r['player_at'])
    print(f"{'name':24s} {'spawn':>10} {'mv':>4} {'nodes':>5} {'det':>5} {'rad':>6} "
          f"{'onnode':>6} {'unseen':>6} {'compl':>6}  kind")
    for x in rows:
        print(f"{x['name'][:24]:24s} {x['counter']:>10} {x['moves']:>4} {x['nodes']:>5} "
              f"{x['determinism']:>5.2f} {x['radius']:>6.1f} {100*x['on_node']:>5.0f}% {x['unseen']:>6.0f} "
              f"{100*x['completeness']:>5.0f}%  {'PATROL' if x['patrol'] else 'wander/combat'}"
              + (f"  [{len(x['gaps'])} gap]" if x['gaps'] else ""))
