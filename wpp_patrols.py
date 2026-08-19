#!/usr/bin/env python3
"""
Reconstruct ordered patrol routes for named NPCs from a WPP-unparsed dump.

Builds on wpp_movement.py: takes the spawns that classify() calls PATROL,
walks the successor graph to recover node order, and reports where the route
has a hole (gap event) versus where it genuinely closes.

Usage:  python3 wpp_patrols.py [options] <dump_*_parsed.txt> [Name1] [Name2] ...

Modes:
  (none)         text report of every recovered route
  --sql          waypoint_data / creature_addon blocks for spawns that do not
                 already patrol, pairing each route with the world-DB spawn
                 standing on one of its nodes
  --wander-sql   MovementType 1 + wander_distance for spawns that wander in the
                 dump and stand still on the server, and, with --retune, radius
                 corrections for spawns already wandering at the wrong range

Naming no NPCs takes every name the dump resolved. The zone is not baked in:
--box drives both the payload decoder and the world-DB query, and --map picks
the map. `python3 wpp_movement.py --probe <dump>` suggests both.
"""
import sys, math, argparse, collections, statistics
from wpp_movement import analyse, classify, parse_box, DEFAULT_BOX


def _walk(succ, start):
    """Follow dominant edges until a node repeats.

    Returns (order, tail) where `tail` is how many leading nodes are a run-in
    before the loop proper: the walk re-enters at order[tail], so order[tail:]
    is the cycle. tail is None if the walk dead-ended without closing.
    """
    order, pos, cur = [], {}, start
    while cur not in pos:
        pos[cur] = len(order); order.append(cur)
        if cur not in succ or not succ[cur]:
            return order, None
        cur = succ[cur].most_common(1)[0][0]
    return order, pos[cur]


def _greedy(seq, succ):
    """Longest dominant-successor cycle over every possible starting node.

    Starting from the most-visited node is wrong: on a route with a
    back-and-forth pair, that pair's mutual edges terminate the walk after two
    nodes and the other twenty are never reached. Starting anywhere else can
    land mid-route, so the closure test looks for the re-entry point rather
    than demanding a return to the first node emitted.
    """
    best_cycle, best_chain = [], []
    for start in set(seq):
        order, tail = _walk(succ, start)
        if len(order) > len(best_chain):
            best_chain = order
        if tail is not None:
            cycle = order[tail:]
            if len(cycle) > 2 and len(cycle) > len(best_cycle):
                best_cycle = cycle
    # A closed loop is the better answer only when it explains as much of the
    # route as the longest open chain does; otherwise report the chain.
    if len(best_cycle) >= len(best_chain):
        return best_cycle, True
    return best_chain, False


def _periodic(seq):
    """Recover the lap by finding the period of the node sequence.

    A greedy successor walk cannot represent an out-and-back route, where the
    same node is visited twice per lap -- it terminates as soon as an edge
    leads back to a node it has already emitted. Period detection has no such
    limit, and majority-voting each phase absorbs combat interruptions that
    would defeat naive periodicity.
    """
    n = len(seq)
    if n < 12:
        return None, 0.0
    scores = {}
    for p in range(3, n // 2 + 1):
        scores[p] = sum(1 for i in range(n - p) if seq[i] == seq[i + p]) / (n - p)
    best_p = max(scores, key=scores.get)
    best_score = scores[best_p]
    # Gaps and combat depress the absolute score, so judge the period by how
    # far it stands out from unrelated periods rather than by a fixed bar.
    rival = max((s for p, s in scores.items()
                 if p % best_p and best_p % p), default=0.0)
    if best_score < 0.45 or best_score < 1.3 * rival:
        return None, best_score
    # majority vote per phase, over every lap
    lap = []
    for j in range(best_p):
        c = collections.Counter(seq[j::best_p])
        lap.append(c.most_common(1)[0][0])
    return lap, best_score


MERGE_TOL = 0.5   # yd; closer than this and it is one waypoint, not two


def _merge_nodes(nodes, cnt):
    """Collapse coordinates that are really the same waypoint.

    A stored waypoint does not always replay as the same float32. Approached
    from opposite directions it comes back a few centimetres off -- 0.09 yd on
    Citizen 167038's route -- and that splits one waypoint into two nodes. Each
    then carries half the visits, and the emitted lap stops at one of the pair
    on the way out and the other on the way back, so the route looks like it is
    missing a point exactly where two markers sit on top of each other.

    Cluster within MERGE_TOL and keep the best-attested coordinate of each
    cluster. Genuine waypoints are never half a yard apart.

    Returns the canonical nodes and a map from every observed destination -- the
    jittered spellings included, and the single-visit ones `route` would
    otherwise discard -- to its node index.
    """
    par = list(range(len(nodes)))
    def find(x):
        while par[x] != x:
            par[x] = par[par[x]]; x = par[x]
        return x
    for i in range(len(nodes)):
        for j in range(i + 1, len(nodes)):
            if math.dist(nodes[i], nodes[j]) <= MERGE_TOL:
                par[find(i)] = find(j)

    groups = collections.defaultdict(list)
    for i in range(len(nodes)):
        groups[find(i)].append(i)
    canonical = [max((nodes[i] for i in g), key=lambda p: cnt[p])
                 for g in groups.values()]

    canon = {}
    for p in cnt:
        best, bd = None, MERGE_TOL
        for i, q in enumerate(canonical):
            dd = math.dist(p, q)
            if dd <= bd:
                best, bd = i, dd
        if best is not None:
            canon[p] = best
    return canonical, canon


def route(moves):
    """Ordered patrol route recovered from repeated destination coordinates.

    Nodes are bit-identical destination triples seen more than once (a stored
    waypoint replays as the same float32; random wander never repeats exactly).
    """
    d = [m for m in moves if m['duration'] > 0 and m['dist'] > 0.5]
    cnt = collections.Counter(m['dest'] for m in d)
    nodes = [k for k, c in cnt.items() if c > 1]

    # Recover turnarounds lost to the "seen more than once" rule. On an
    # out-and-back route every node is passed twice per lap except the two
    # ends, which are touched once -- so a terminus observed on a single lap
    # arrives exactly once and gets discarded as wander noise. Readmit a
    # one-off destination only when it extends the route outward from its
    # nearest node by no more than a normal leg, which random wander points
    # (scattered inside the route, not beyond its ends) will not satisfy.
    if nodes:
        cx = sum(p[0] for p in nodes) / len(nodes)
        cy = sum(p[1] for p in nodes) / len(nodes)
        legs = sorted(m['dist'] for m in d if m['dist'] > 1)
        span = legs[len(legs) // 2] if legs else 0.0
        cand = []
        for p, c in cnt.items():
            if c != 1 or not span:
                continue
            near = min(nodes, key=lambda q: math.dist(q, p))
            out = math.dist(near, p)
            # Must be a genuinely new stop one normal leg out from the last
            # known node -- not a float-jittered duplicate of it (which sits
            # a fraction of a yard away), and not so far it is a chase.
            if (0.5 * span <= out <= 1.5 * span
                    and math.dist(p[:2], (cx, cy)) > math.dist(near[:2], (cx, cy))):
                cand.append((out, p))
        # a route has two ends, so never admit more than two
        cand.sort(reverse=True)
        nodes.extend(p for _, p in cand[:2])

    nodes, canon = _merge_nodes(nodes, cnt)
    seq = [canon[m['dest']] for m in d if m['dest'] in canon]

    succ = collections.defaultdict(collections.Counter)
    for a, b in zip(seq, seq[1:]):
        if a != b:
            succ[a][b] += 1

    g_order, g_closed = _greedy(seq, succ)
    p_order, p_score = _periodic(seq)

    # When gaps knock out the edges through the middle of a route, the
    # successor graph is genuinely disconnected and no single walk can cover
    # it. Peel off further chains so the unreached half is reported as a
    # fragment of the same route rather than as loose nodes.
    def fragments(used):
        frags = []
        left = set(range(len(nodes))) - set(used)
        while left:
            sub = collections.defaultdict(collections.Counter)
            for a in succ:
                if a in left:
                    for b, c in succ[a].items():
                        if b in left:
                            sub[a][b] = c
            best = max((_walk(sub, s)[0] for s in left), key=len)
            frags.append(best)
            left -= set(best)
            if len(best) == 1 and all(len(f) == 1 for f in frags[-3:]):
                break
        return [f for f in frags if len(f) > 1]

    # prefer whichever reconstruction covers more of the known nodes
    if p_order and len(set(p_order)) > len(set(g_order)):
        order, closed, method = p_order, True, f"period {len(p_order)} @ {p_score:.2f}"
    else:
        order, closed, method = g_order, g_closed, "successor walk"

    conf = {}
    for a in succ:
        tot = sum(succ[a].values())
        conf[a] = succ[a].most_common(1)[0][1] / tot

    return dict(nodes=nodes, order=order, closed=closed, visits=cnt, method=method,
                canon=canon,
                conf=conf, orphans=[i for i in range(len(nodes)) if i not in set(order)],
                frags=fragments(order), seq_len=len(seq))


def leg(a, b):
    return math.dist(a, b)


def gap_covered(g, nodes, order, tol=5.0, median_leg=None):
    """Was the stretch this gap skipped recovered at some other point?

    A gap only means missing waypoints if neither end lands on a node we know
    about. When both ends sit on recovered nodes, the NPC left and re-entered
    the known route and the nodes in between were seen on another pass -- the
    gap cost us nothing.

    Test against every recovered node, not just the main cycle: when gaps cut
    the successor graph into fragments, the node the NPC vanished at is very
    often sitting in a fragment, and measuring only against the main cycle
    scores it as unseen ground when it is nothing of the sort. Tolerance
    scales with the route's own leg length, since arriving 6 yd from a node on
    a route with 16 yd legs is the same node, not a new one.
    """
    if not order:
        return False, None, None
    if median_leg:
        tol = max(tol, 0.5 * median_leg)
    pts = list(nodes)
    i = min(range(len(pts)), key=lambda k: math.dist(pts[k], g['last']))
    j = min(range(len(pts)), key=lambda k: math.dist(pts[k], g['next']))
    di, dj = math.dist(pts[i], g['last']), math.dist(pts[j], g['next'])
    return (di <= tol and dj <= tol), (i, di), (j, dj)


# ------------------------------------------------------------------- SQL emit
# Turning a recovered route into `waypoint_data` needs three things the text
# report does not: which DB spawn the route belongs to, whether the NPC walks
# or runs it, and how long it pauses at each node.

WORLD_DB = dict(host="127.0.0.1", port="3306",
                user="ashamane", pw="ashamane", db="ashamane_world")

# 167026 is the one route whose spawn point is not bit-identical to a node
# (6.17 yd, against 13.9 yd for the next candidate), so the bar sits above it
# but well below the ~14 yd at which a pairing stops being unambiguous.
MATCH_TOLERANCE = 8.0
RUN_SPEED_CUTOFF = 4.0      # yd/s; routes land on either ~2.5 or ~6.0
VIS_RANGE = 90.0            # yd; beyond this the sniff stops seeing the NPC
MIN_DWELL_SAMPLES = 3
LEG_SANITY = 30.0           # yd; sound routes here top out around 25
MIN_END_VISITS = 3          # laps needed at a terminus to call a route out-and-back
MIN_WANDER = 1.5            # yd; below this an entry is standing still, not roaming


def mysql(query, cfg=None, db=None):
    """Run one query through the mysql client, tab-separated, no headers."""
    import subprocess
    c = dict(WORLD_DB, **(cfg or {}))
    out = subprocess.run(["mysql", "-h", c["host"], "-P", c["port"],
                          "-u", c["user"], "-p" + c["pw"], "-N", "-B",
                          "-e", query, db or c["db"]],
                         capture_output=True, text=True)
    if out.returncode:
        sys.exit("mysql: " + out.stderr.strip())
    return [l.split("\t") for l in out.stdout.splitlines()]


def load_spawns(entries, box=DEFAULT_BOX, map_id=0, cfg=None):
    """`creature` rows inside the sniffed box, with the movement they already have.

    The movement state travels with the row on purpose. Whether a spawn already
    patrols is a question about the server, not about the sniff, and answering
    it here is what keeps the emitters from proposing work that is already
    done. A spawn counts as patrolling only with all three pieces in place --
    MovementType 2, an addon path_id, and waypoint rows under that id --
    because any one of them missing is the half-applied state
    ObjectMgr::LoadCreatureAddons silently downgrades back to idle, which is a
    spawn to fix, not one to skip.
    """
    if not entries:
        return []
    (x0, x1), (y0, y1) = box[0], box[1]
    q = ("SELECT c.guid, c.id, c.position_x, c.position_y, c.position_z, "
         "c.MovementType, c.wander_distance, IFNULL(a.path_id, 0), "
         "(SELECT COUNT(*) FROM waypoint_data w WHERE w.id = a.path_id) "
         "FROM creature c LEFT JOIN creature_addon a ON a.guid = c.guid "
         f"WHERE c.map = {map_id} "
         f"AND c.position_x BETWEEN {x0:.1f} AND {x1:.1f} "
         f"AND c.position_y BETWEEN {y0:.1f} AND {y1:.1f} "
         "AND c.id IN (%s);" % ",".join(str(e) for e in sorted(entries)))
    rows = []
    for g, i, x, y, z, mt, wd, pid, wp in mysql(q, cfg):
        rows.append(dict(guid=int(g), entry=int(i),
                         pos=(float(x), float(y), float(z)),
                         movement_type=int(mt), wander_distance=float(wd),
                         path_id=int(pid), waypoints=int(wp)))
    return rows


def already_patrols(s):
    return s['movement_type'] == 2 and s['path_id'] and s['waypoints']


def spawn_counts(entries, cfg=None):
    """Server-wide spawn count per entry -- the blast-radius check.

    Alpine Hare has 562 spawns and 26 of them are in Coldridge; the number
    exists so an entry-wide UPDATE that escaped the zone would be obvious in
    the file header rather than discovered in another zone later.
    """
    if not entries:
        return {}
    q = ("SELECT id, COUNT(*) FROM creature WHERE id IN (%s) GROUP BY id;"
         % ",".join(str(e) for e in sorted(entries)))
    return {int(i): int(c) for i, c in mysql(q, cfg)}


def full_order(rt):
    """The recovered route: the main successor walk, and nothing else.

    Disconnected fragments and unreached nodes are deliberately dropped. They
    are real coordinates the NPC was seen at, but the sniff never observed the
    legs that join them to the main circuit, so their position in the route is
    guesswork -- and appending them after the last real node makes the NPC walk
    the circuit and then strike out across the map to each stray point in turn.
    A shorter route that is certainly right beats a longer one that is
    certainly out of order.
    """
    return list(rt['order'])


def observed_laps(rt, moves):
    """Every stretch of the sniff that runs from a node back to that same node.

    One such stretch is a lap, in the order the NPC actually walked it, which
    settles the question no amount of graph reasoning does cleanly: whether the
    route is a circuit (A B C A) or a back-and-forth (A B C B A). Both fall out
    of the observed sequence for free -- the second simply lists its middle
    nodes twice.

    Each lap is returned with whether it is gap-free. A lap spanning a gap
    event has the NPC moving unobserved somewhere in the middle, so the two
    nodes either side of the hole end up adjacent in the emitted path and the
    core straight-lines between them.
    """
    canon = rt['canon']
    d = [m for m in moves if m['duration'] > 0 and m['dist'] > 0.5]
    ent = [(canon[m['dest']], m) for m in d if m['dest'] in canon]
    if not ent:
        return []
    seq = [e[0] for e in ent]
    mv = [e[1] for e in ent]
    gap = [False] * len(ent)
    for k in range(len(ent) - 1):
        a, b = mv[k], mv[k + 1]
        slack = (b['ts'] - a['ts']).total_seconds() - a['duration'] / 1000.0
        if math.dist(a['dest'], b['origin']) > 3 and slack > 2:
            gap[k] = True
    pos = collections.defaultdict(list)
    for k, i in enumerate(seq):
        pos[i].append(k)
    out = []
    for ks in pos.values():
        for a, b in zip(ks, ks[1:]):
            if b - a >= 3:
                out.append((seq[a:b], not any(gap[a:b])))
    return out


def max_leg(nodes, order):
    pts = [nodes[i] for i in order]
    return max(math.dist(pts[k], pts[(k + 1) % len(pts)])
               for k in range(len(pts)))


def linear_chain(rt, moves):
    """A route that patrols a line, returned as its full round trip, or None.

    Useful when no single gap-free lap was ever captured end to end but the
    individual legs were all seen at one time or another. The maximum spanning
    tree over observed transitions is the line itself, every node of degree 2
    except the two ends.

    Two things separate a line from a circuit, which spans to a path just as
    readily: a circuit is observed closing, where a line's ends may be hundreds
    of yards apart and never adjacent; and a line's ends are visited about half
    as often as its middle, because each lap passes through the middle twice
    and touches each end once.

    The round trip runs out along the chain and back through its interior,
    because WaypointMovementGenerator cycles a path rather than ping-ponging
    it: `i_currentNode = (i_currentNode+1) % i_path->size()`. A one-way chain
    would teleport-walk the NPC from the far end back to the start every lap.
    """
    nodes = rt['nodes']
    canon = rt['canon']
    d = [m for m in moves if m['duration'] > 0 and m['dist'] > 0.5]
    seq = [canon[m['dest']] for m in d if m['dest'] in canon]
    w = collections.Counter()
    for a, b in zip(seq, seq[1:]):
        if a != b:
            w[frozenset((a, b))] += 1
    if not w:
        return None

    parent = list(range(len(nodes)))
    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]; x = parent[x]
        return x
    adj = collections.defaultdict(list)
    for e, _c in sorted(w.items(), key=lambda kv: -kv[1]):
        a, b = tuple(e)
        if find(a) != find(b):
            parent[find(a)] = find(b)
            adj[a].append(b); adj[b].append(a)

    if any(len(adj[i]) > 2 for i in range(len(nodes))):
        return None
    ends = [i for i in range(len(nodes)) if len(adj[i]) == 1]
    if len(ends) != 2:
        return None

    cur, prev, chain = ends[0], None, [ends[0]]
    while True:
        nxt = [x for x in adj[cur] if x != prev]
        if not nxt:
            break
        prev, cur = cur, nxt[0]
        chain.append(cur)
    if len(chain) != len(nodes):
        return None

    if w.get(frozenset((chain[0], chain[-1])), 0):
        return None                       # observed closing: a circuit
    ev = (rt['visits'][nodes[chain[0]]] + rt['visits'][nodes[chain[-1]]]) / 2
    mid = chain[1:-1]
    mv = sum(rt['visits'][nodes[i]] for i in mid) / len(mid) if mid else 0
    if not mv or ev / mv > 0.8 or ev < MIN_END_VISITS:
        return None

    return chain + chain[-2:0:-1]


# Legs confirmed in game that the sniff never caught. A lap is only as complete
# as the packets behind it: where the player followed a route in one direction
# only, or a spline went missing, the recovered lap can cut a corner the NPC
# does not cut. Each entry names the leg to split and the stop to put in it, by
# coordinate rather than by point number so it survives the route being
# re-derived.
IN_GAME_INSERTS = {
    # 167038's western spur was only ever caught on the return pass. Outbound it
    # ran (-6120.65, 375.19) straight to (-6130.13, 383.76), a 12.8 yd diagonal,
    # while coming back it stopped at (-6129.93, 375.75) in between. Observed in
    # game to stop there in both directions, which makes the spur symmetric and
    # replaces the diagonal with two legs of 9.3 and 8.0 yd.
    167038: [dict(after=(-6120.650, 375.186),
                  before=(-6130.130, 383.755),
                  insert=(-6129.930, 375.748))],
}


def _node_at(nodes, xy, guid):
    """Index of the node standing at xy, or bail out."""
    best, bd = None, 1.0
    for i, p in enumerate(nodes):
        dd = math.dist(p[:2], xy)
        if dd < bd:
            best, bd = i, dd
    if best is None:
        sys.exit(f"guid {guid}: in-game fix names ({xy[0]:.3f}, {xy[1]:.3f}), "
                 f"which is not a node on this route")
    return best


def apply_in_game_fixes(guid, order, nodes):
    """Splice in stops the sniff missed but the server owner confirmed.

    Matching on the pair of nodes either side of the gap, rather than on a point
    number, keeps this stable: the leg is identified by where it runs, so
    re-deriving the route cannot silently move the insertion somewhere else. If
    the leg is no longer there -- because better data already covers it -- the
    run stops rather than quietly doing nothing.
    """
    out = list(order)
    for fix in IN_GAME_INSERTS.get(guid, []):
        ia = _node_at(nodes, fix['after'], guid)
        ib = _node_at(nodes, fix['before'], guid)
        ii = _node_at(nodes, fix['insert'], guid)
        spots = [k for k in range(len(out))
                 if out[k] == ia and out[(k + 1) % len(out)] == ib]
        if len(spots) != 1:
            sys.exit(f"guid {guid}: in-game fix expected exactly one "
                     f"({fix['after']}) -> ({fix['before']}) leg, found {len(spots)}")
        out.insert(spots[0] + 1, ii)
    return out


def _dedupe_consecutive(order):
    """Drop a node that immediately repeats itself.

    Clustering jittered spellings into one waypoint can leave the same node
    twice in a row, where the sniff recorded two arrivals a few centimetres
    apart. Emitted literally that is a zero-length leg: the core issues a move
    to where the NPC already stands. The wrap-around counts too, since the path
    is cyclic.
    """
    out = []
    for i in order:
        if not out or out[-1] != i:
            out.append(i)
    while len(out) > 1 and out[0] == out[-1]:
        out.pop()
    return out


def recover_order(rt, moves):
    """The waypoint order to emit, and how it was arrived at.

    Every candidate is a real observation of the route: a lap the NPC was seen
    walking end to end, the spanning tree of its legs, or the successor walk.
    They are filtered on geometry first -- a candidate whose longest leg is
    implausible is missing a stretch, whatever produced it -- and then ranked by
    how much of the route they cover, preferring gap-free evidence and, between
    equals, the shortest.

    Coverage is ranked above gap-free deliberately, but only among candidates
    that already pass the geometry filter, so a lap that reaches one extra node
    by straight-lining 56 yd across a hole never wins.
    """
    nodes = rt['nodes']
    cands = [(w, c, "gap-free lap" if c else "lap spanning a gap")
             for w, c in observed_laps(rt, moves)]
    line = linear_chain(rt, moves)
    if line:
        cands.append((line, True, "spanning-tree line"))

    cands = [(_dedupe_consecutive(w), c, h) for w, c, h in cands]
    ok = [(w, c, h) for w, c, h in cands if w and max_leg(nodes, w) <= LEG_SANITY]
    if ok:
        w, c, h = max(ok, key=lambda t: (len(set(t[0])), t[1],
                                         -len(t[0]), -max_leg(nodes, t[0])))
        return w, h
    return _dedupe_consecutive(full_order(rt)), "successor walk"


def match_spawn(rt, order, spawns, entry):
    """Pair a route with the DB spawn standing on one of its nodes.

    A patrolling NPC's spawn point is one of its waypoints, so exact
    coincidence identifies the spawn outright -- which proximity alone cannot,
    with three Coldridge Citizen routes whose centroids are 4 yd apart.

    Matching deliberately considers every recovered node, including the ones
    full_order() drops. Where the spawn point sits in the route is a question
    about identity; which nodes we are willing to emit is a question about
    ordering, and conflating the two loses the Rockjaw Goon, whose spawn point
    was only ever observed in a fragment.
    """
    nodes = rt['nodes']
    scored = []
    for s in spawns:
        if s['entry'] != entry:
            continue
        d = min(math.dist(s['pos'][:2], p[:2]) for p in nodes)
        scored.append((d, s))
    if not scored:
        raise LookupError(f"no DB spawn of entry {entry} inside the sniffed box")
    scored.sort(key=lambda t: t[0])
    d, s = scored[0]
    runner_up = scored[1][0] if len(scored) > 1 else float('inf')
    if d > MATCH_TOLERANCE:
        raise LookupError(f"nearest spawn of entry {entry} is {d:.2f} yd from any "
                          f"node (tolerance {MATCH_TOLERANCE}) -- refusing to guess")
    return s, d, runner_up


def path_shape(order):
    """How the route runs, from the emitted order alone.

    Three shapes turn up, and they are told apart by how many times each node
    appears in one lap:

    * every node once -- a circuit, A B C A;
    * two nodes once and the rest twice -- a line walked out and back,
      A B C D C B, whose ends are the two singletons;
    * anything else -- a circuit with a spur retraced partway,
      A B C D C B E F G, which is a real shape and not a parsing failure.

    All three emit the same way: waypoint_data is a cyclic list, so a retraced
    node is simply listed again at the point it is walked again.
    """
    n = collections.Counter(order)
    once = [i for i, c in n.items() if c == 1]
    if len(order) == len(n):
        return "circuit", f"circuit of {len(n)} nodes"
    if len(once) == 2 and max(n.values()) == 2:
        return "out-and-back", (f"out-and-back over {len(n)} nodes "
                                f"({len(order)} stops per lap)")
    return "mixed", (f"circuit of {len(n)} nodes with {len(order) - len(n)} "
                     f"retraced stop(s) -- a spur walked out and back inside the lap")


def route_speed(moves):
    """Median yd/s over the route's real legs -> walk (0) or run (1)."""
    v = [m['dist'] / (m['duration'] / 1000.0)
         for m in moves if m['duration'] > 0 and m['dist'] > 3]
    return statistics.median(v) if v else 0.0


def node_delays(moves, rt, order, player_at):
    """Median pause at each node, in ms, over samples we can actually trust.

    Three things make an elapsed time something other than a dwell, and all
    three have to go or the medians come out wildly inflated:

    * the next spline starts before the current one ends (negative dwell) --
      the NPC was re-pathed mid-leg, so it never stood still at all;
    * the NPC is somewhere other than where the last spline left it, meaning
      it moved unobserved and the elapsed time covers travel, not waiting;
    * the player was beyond visibility range, so the sniff simply stopped
      receiving this NPC's packets and the clock kept running. This is the big
      one: every implausible dwell in the Coldridge data (up to 20 minutes at
      a single node) is one of these, and they all sit at a player distance of
      ~100 yd or more while every well-observed sample sits far inside it.

    A median still needs samples to be a median, so a node with fewer than
    MIN_DWELL_SAMPLES surviving observations is reported as no delay rather
    than on the strength of one or two readings that disagree by minutes.
    """
    idx = rt['canon']
    dw = collections.defaultdict(list)
    for a, b in zip(moves, moves[1:]):
        if a['dest'] not in idx or a['duration'] <= 0:
            continue
        if math.dist(a['dest'], b['origin']) > 3:
            continue
        pa, pb = player_at(a['ts']), player_at(b['ts'])
        if not pa or not pb:
            continue
        if (math.dist(pa[:2], a['dest'][:2]) > VIS_RANGE
                or math.dist(pb[:2], b['origin'][:2]) > VIS_RANGE):
            continue
        ms = (b['ts'] - a['ts']).total_seconds() * 1000 - a['duration']
        dw[idx[a['dest']]].append(max(0.0, ms))
    out = {}
    for i in order:
        s = dw.get(i, [])
        if len(s) >= MIN_DWELL_SAMPLES:
            ms = int(round(statistics.median(s)))
            if ms > 1000:
                out[i] = ms
    return out


def emit_sql(picked, by_spawn, player_at, spawns, include_existing=False):
    """Print the patrol blocks: one per matched spawn that needs one."""
    blocks, total, claimed, skipped = [], 0, {}, []
    touched = []
    for x in picked:
        v = by_spawn[(x['entry'], x['counter'])]
        rt = route(v)
        order, how = recover_order(rt, v)
        try:
            s, d, runner_up = match_spawn(rt, order, spawns, x['entry'])
        except LookupError as e:
            skipped.append((x, str(e)))
            continue
        guid = s['guid']
        # two routes landing on one guid means the pairing is wrong, and the
        # second block would silently overwrite the first
        if guid in claimed:
            sys.exit(f"guid {guid} matched by both retail spawn "
                     f"{claimed[guid]} and {x['counter']} -- ambiguous")
        claimed[guid] = x['counter']
        # Already walking a path with waypoints under it: the server has this
        # NPC's movement, and re-emitting it would replace working data with a
        # reconstruction from one sniff. --include-existing overrides, for when
        # the existing path is the thing being corrected.
        if already_patrols(s) and not include_existing:
            skipped.append((x, f"guid {guid} already patrols path {s['path_id']} "
                               f"({s['waypoints']} waypoints)"))
            continue
        # keyed by guid, so this has to wait until the spawn is identified
        before_fix = len(order)
        order = apply_in_game_fixes(guid, order, rt['nodes'])
        added = len(order) - before_fix
        mt = 1 if route_speed(v) > RUN_SPEED_CUTOFF else 0
        delays = node_delays(v, rt, order, player_at)
        nodes = rt['nodes']
        dropped = len(rt['nodes']) - len(set(order))

        # Dropping unlinked nodes can leave a stub rather than a route: if the
        # discarded nodes carried the circuit between two ends, what remains
        # closes with one implausible straight line. Legs on a sound route here
        # run to 25 yd; anything much past that, or a spawn point left off its
        # own path, means the survivors are not the whole circuit.
        pts = [nodes[i] for i in order]
        legs = [math.dist(pts[k], pts[(k + 1) % len(pts)]) for k in range(len(pts))]
        spawn_off = min(math.dist(s['pos'][:2], p[:2]) for p in pts)
        warn = []
        if max(legs) > LEG_SANITY:
            warn.append(f"longest leg is {max(legs):.0f} yd -- a stretch of this "
                        f"route was never observed, and the core will straight-line it")
        # Only a complaint if the emitted subset lost the node the spawn stands
        # on. When it is no further off than the pairing already was, that is
        # the inexact match talking, not a hole in the route.
        if spawn_off > d + 1.0:
            warn.append(f"spawn point sits {spawn_off:.0f} yd off the path, though "
                        f"it matched a node at {d:.1f} yd -- the emitted order "
                        f"dropped the node it stands on")
        uncovered = [g for g in x['gaps']
                     if not gap_covered(g, nodes, order, median_leg=x['median_leg'])[0]]
        if uncovered:
            est = sum(g['est_nodes'] for g in uncovered)
            warn.append(f"{len(uncovered)} gap(s) in the sniff span ground no lap "
                        f"covered -- roughly {est} waypoint(s) of this route were "
                        f"never seen and are not in the list below")

        print(f"-- {x['name']} (entry {x['entry']}) -- sniffed spawn {x['counter']}")
        rival = (f"next candidate {runner_up:.1f} yd" if runner_up < float('inf')
                 else "the only spawn of this entry in the box")
        print(f"--   matched guid {guid} at {d:.3f} yd from a route node ({rival})")
        kind, shape = path_shape(order)
        print(f"--   {len(order)} waypoints, {shape}, via {how}, "
              f"{'run' if mt else 'walk'} "
              f"({route_speed(v):.2f} yd/s), {len(delays)} node(s) with a delay"
              + (f", {dropped} unlinked node(s) dropped" if dropped else "")
              + (f", {added} stop(s) added from in-game observation" if added else ""))
        print(f"--   was MovementType {s['movement_type']}, "
              f"wander_distance {s['wander_distance']:.0f}, "
              + (f"path {s['path_id']} with {s['waypoints']} waypoints"
                 if s['path_id'] else "no creature_addon path"))
        for w in warn:
            print(f"--   WARNING: {w}")
        print(f"SET @NPC := {guid};  SET @PATH := @NPC * 10;")
        print("UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;")
        print("DELETE FROM `creature_addon` WHERE `guid`=@NPC;")
        print("INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,"
              "`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,"
              "`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES")
        print("(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);")
        print("DELETE FROM `waypoint_data` WHERE `id`=@PATH;")
        print("INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,"
              "`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,"
              "`wpguid`) VALUES")
        for k, i in enumerate(order, 1):
            p = nodes[i]
            sep = ";" if k == len(order) else ","
            print(f"(@PATH,{k},{p[0]:.3f},{p[1]:.3f},{p[2]:.3f},0,"
                  f"{delays.get(i, 0)},{mt},0,100,0){sep}")
        print()
        total += len(order)
        touched.append(guid)
        blocks.append((guid, len(order)))
    for x, why in skipped:
        print(f"-- SKIPPED {x['name']} (entry {x['entry']}, sniffed spawn "
              f"{x['counter']}): {why}")
    if skipped:
        print()
    print(f"-- {len(blocks)} paths, {total} waypoint rows total, "
          f"{len(skipped)} route(s) skipped")
    # Read back by wpp_apply.py to snapshot exactly these spawns before the file
    # is applied. Emitted even when empty, so a missing line means the file was
    # hand-written and has no snapshot behind it.
    print(f"-- @touched: creature,creature_addon,waypoint_data "
          f"{','.join(str(g) for g in touched)}")


def wander_radii(rows, names):
    """Radius per entry: the median across spawns of each spawn's 95th percentile.

    Per entry rather than per spawn, because a wander radius is a property of
    the creature, and because matching an individual sniffed wanderer to an
    individual DB spawn is not reliable -- critters sit densely enough that
    nearest-centroid pairing produced matches over 100 yd in Coldridge. The
    median across spawns then absorbs the one spawn that was chased across the
    zone during the sniff and would otherwise set the radius for the entry.
    """
    per = collections.defaultdict(list)
    for x in rows:
        if x['patrol']:
            continue                  # a route is not a roam
        per[x['entry']].append(x)
    out = {}
    for e, xs in per.items():
        r = statistics.median(x['wander_radius'] for x in xs)
        if r < MIN_WANDER:
            continue                  # standing still, or one combat leash
        out[e] = dict(entry=e, name=names.get(e, f'entry {e}'),
                      radius=max(1, int(round(r))), spawns=len(xs),
                      lo=min(x['wander_radius'] for x in xs),
                      hi=max(x['wander_radius'] for x in xs),
                      centres=[x['centre'] for x in xs])
    return out


def patrol_claims(picked, by_spawn, spawns):
    """Guids the patrol half of this dump is about to bind to a path.

    The two emitters answer different questions and are usually run as two
    separate commands, so without this the same spawn can be handed a route by
    one file and a wander radius by the other -- and whichever lands second
    wins, silently. A spawn that has a route is not a wanderer.
    """
    out = set()
    for x in picked:
        v = by_spawn[(x['entry'], x['counter'])]
        rt = route(v)
        order, _how = recover_order(rt, v)
        try:
            s, _d, _r = match_spawn(rt, order, spawns, x['entry'])
        except LookupError:
            continue
        out.add(s['guid'])
    return out


def emit_wander_sql(rows, names, spawns, counts, retune=0.0, claimed=(),
                    min_spawns=2):
    """Print the wander blocks: spawns to start wandering, and radii to correct.

    Two separate questions, deliberately emitted as two separate statements:
    a spawn that stands still where retail roams is missing movement, while a
    spawn already roaming at the wrong range is a number to fix. The second is
    the broader and more arguable change, so it is gated behind --retune and
    only fires past a factor, not on every disagreement.
    """
    rad = wander_radii(rows, names)
    if not rad:
        print("-- no entry in this dump wanders far enough to be worth a radius")
        return
    add, fix, touched = collections.defaultdict(list), collections.defaultdict(list), []
    for s in spawns:
        info = rad.get(s['entry'])
        if not info:
            continue
        if s['guid'] in claimed:
            continue                  # this dump gives it a patrol route instead
        # A wanderer's centre is its spawn point, so the DB spawn has to be
        # under one of the sniffed roams before its radius means anything here.
        near = min(math.dist(s['pos'][:2], c) for c in info['centres'])
        if near > max(MATCH_TOLERANCE, 1.5 * info['radius']):
            continue
        if already_patrols(s) or s['movement_type'] == 2:
            continue                  # never trade a route for a roam
        if s['movement_type'] == 0:
            add[s['entry']].append(s['guid'])
            touched.append(s['guid'])
        elif s['movement_type'] == 1 and retune:
            # One sniffed spawn is not evidence of a radius: a single NPC that
            # chased something across the zone during the sniff produces a
            # large 95th percentile with nothing to median it against, and a
            # retune would then widen every spawn of the entry on the strength
            # of one fight. Adding movement where there is none is a smaller
            # risk than rewriting movement that already works, so this bar
            # applies to corrections only.
            if info['spawns'] < min_spawns:
                continue
            have = max(s['wander_distance'], 0.5)
            if max(have / info['radius'], info['radius'] / have) >= retune:
                fix[s['entry']].append((s['guid'], s['wander_distance']))
                touched.append(s['guid'])

    print("-- Radius per entry: median over the sniffed spawns of each spawn's")
    print("-- 95th-percentile displacement from its own centre.")
    for e, info in sorted(rad.items()):
        print(f"--   {info['name']} ({e}): {info['radius']} yd from "
              f"{info['spawns']} sniffed spawn(s), range {info['lo']:.1f}-{info['hi']:.1f} yd"
              f"  [{counts.get(e, 0)} spawns server-wide]"
              + ("  -- single spawn, no median behind it"
                 if info['spawns'] < min_spawns else ""))
    print()

    if add:
        print("-- Idle on the server, roaming in the sniff.")
        for e in sorted(add):
            g = sorted(add[e])
            print(f"-- {rad[e]['name']} ({e}): {len(g)} spawn(s) -> wander_distance "
                  f"{rad[e]['radius']}")
            print(f"UPDATE `creature` SET `MovementType`=1, `wander_distance`="
                  f"{rad[e]['radius']} WHERE `id`={e} AND `guid` IN (")
            print(_guid_list(g) + ");")
        print()
    if fix:
        print(f"-- Already roaming, but at a radius off by {retune:g}x or more.")
        for e in sorted(fix):
            g = sorted(fix[e])
            was = sorted({int(w) for _, w in g})
            print(f"-- {rad[e]['name']} ({e}): {len(g)} spawn(s), "
                  f"{'/'.join(str(w) for w in was)} -> {rad[e]['radius']}")
            print(f"UPDATE `creature` SET `wander_distance`={rad[e]['radius']} "
                  f"WHERE `id`={e} AND `guid` IN (")
            print(_guid_list([x[0] for x in g]) + ");")
        print()
    print(f"-- {sum(len(g) for g in add.values())} spawn(s) gain wander, "
          f"{sum(len(g) for g in fix.values())} radius correction(s)")
    print(f"-- @touched: creature {','.join(str(g) for g in sorted(touched))}")


def _guid_list(guids, per_line=10):
    """Guids, ten to a line -- always an explicit list, never a bare `WHERE id`.

    Alpine Hare has 562 spawns and 26 of them are in the zone that was sniffed.
    An entry-wide UPDATE would retune hares in every zone in the game and
    nothing in the file would say so.
    """
    rows = [", ".join(str(g) for g in guids[i:i + per_line])
            for i in range(0, len(guids), per_line)]
    return ",\n".join("    " + r for r in rows)


def main():
    ap = argparse.ArgumentParser(
        description="Recover patrol routes and wander radii from an unparsed WPP dump.")
    ap.add_argument('dump', help='dump_*_parsed.txt from WowPacketParser')
    ap.add_argument('names', nargs='*',
                    help='NPC names to report on; default is every name in the dump')
    ap.add_argument('--sql', action='store_true', help='emit patrol path SQL')
    ap.add_argument('--wander-sql', action='store_true',
                    help='emit MovementType 1 + wander_distance SQL')
    ap.add_argument('--retune', type=float, default=0.0, metavar='FACTOR',
                    help='with --wander-sql, also correct radii that are off by '
                         'this factor or more (3 is the bar used in Coldridge)')
    ap.add_argument('--box', help='x0,x1,y0,y1[,z0,z1] -- decoder window and DB '
                                  'query bounds; wpp_movement.py --probe suggests one')
    ap.add_argument('--map', type=int, default=0, help='map id for the DB query')
    ap.add_argument('--min-wander-spawns', type=int, default=2, metavar='N',
                    help='sniffed spawns an entry needs before --retune will '
                         'correct its radius (default 2)')
    ap.add_argument('--include-existing', action='store_true',
                    help='emit paths for spawns that already patrol (replaces them)')
    ap.add_argument('--db-host'), ap.add_argument('--db-port')
    ap.add_argument('--db-user'), ap.add_argument('--db-pass')
    ap.add_argument('--db-name')
    args = ap.parse_args()

    box = parse_box(args.box) if args.box else DEFAULT_BOX
    cfg = {k: v for k, v in (('host', args.db_host), ('port', args.db_port),
                             ('user', args.db_user), ('pw', args.db_pass),
                             ('db', args.db_name)) if v}

    r = analyse(args.dump, box=box)
    rows = classify(r['moves'], r['names'], r['player_at'])
    if args.names:
        rows = [x for x in rows if x['name'] in set(args.names)]

    by_spawn = collections.defaultdict(list)
    for m in r['moves']:
        by_spawn[(m['entry'], m['counter'])].append(m)
    for v in by_spawn.values():
        v.sort(key=lambda m: m['n'])

    picked = [x for x in rows if x['patrol']]
    if args.sql or args.wander_sql:
        want = {x['entry'] for x in picked}
        if args.wander_sql:
            want |= {x['entry'] for x in rows if not x['patrol']}
        spawns = load_spawns(want, box, args.map, cfg)
        if args.sql:
            emit_sql(picked, by_spawn, r['player_at'], spawns, args.include_existing)
        if args.wander_sql:
            if args.sql:
                print()
            emit_wander_sql(rows, r['names'], spawns, spawn_counts(want, cfg),
                            args.retune, patrol_claims(picked, by_spawn, spawns),
                            args.min_wander_spawns)
        return
    print(f"# {args.dump}")
    print(f"# {len(r['moves'])} monster-moves, {len(rows)} tracked spawns, "
          f"{len(picked)} patrol spawns\n")

    for x in picked:
        v = by_spawn[(x['entry'], x['counter'])]
        rt = route(v)
        order, nodes = rt['order'], rt['nodes']
        laps = min(rt['visits'][nodes[i]] for i in order) if order else 0

        print("=" * 78)
        print(f"{x['name']}  (entry {x['entry']}, spawn {x['counter']})")
        print(f"  {x['moves']} moves | {len(set(order))}/{len(nodes)} nodes recovered "
              f"({len(order)} stops per lap, via {rt['method']}) "
              f"| determinism {x['determinism']:.2f} | radius {x['radius']:.1f} yd")
        print(f"  route is {'CLOSED loop' if rt['closed'] else 'OPEN chain (no closing edge observed)'}"
              f" | >={laps} full laps observed | completeness {100*x['completeness']:.0f}%")
        print()
        print(f"  {'#':>3} {'x':>10} {'y':>10} {'z':>8} {'leg':>7} {'visits':>6} {'edge':>5}")
        for k, i in enumerate(order):
            p = nodes[i]
            nxt = nodes[order[(k + 1) % len(order)]]
            print(f"  {k:>3} {p[0]:>10.3f} {p[1]:>10.3f} {p[2]:>8.3f} "
                  f"{leg(p, nxt):>7.1f} {rt['visits'][p]:>6} {rt['conf'].get(i, 0):>5.2f}")
        for fi, frag in enumerate(rt['frags'], 1):
            print(f"\n  disconnected fragment {fi} -- {len(frag)} more nodes of the same route, "
                  f"not joined to the section above because the linking legs were never seen:")
            for k, i in enumerate(frag):
                p = nodes[i]
                nxt = nodes[frag[k + 1]] if k + 1 < len(frag) else None
                print(f"  {k:>3} {p[0]:>10.3f} {p[1]:>10.3f} {p[2]:>8.3f} "
                      f"{leg(p, nxt) if nxt else 0:>7.1f} {rt['visits'][p]:>6} "
                      f"{rt['conf'].get(i, 0):>5.2f}")
        loose = [i for i in rt['orphans'] if not any(i in f for f in rt['frags'])]
        if loose:
            print(f"  + {len(loose)} isolated node(s) (combat detours or a branch): "
                  + ", ".join(f"({nodes[i][0]:.1f},{nodes[i][1]:.1f})" for i in loose[:6]))

        uncovered = []
        for g in x['gaps']:
            ok, a, b = gap_covered(g, nodes, order, median_leg=x['median_leg'])
            if not ok:
                uncovered.append((g, a, b))

        if not x['gaps']:
            print("\n  VERDICT: complete -- no gap events, every leg observed directly")
        elif not uncovered:
            print(f"\n  VERDICT: complete -- {len(x['gaps'])} gap event(s), but both ends of "
                  f"every gap land on recovered nodes, so another lap covered the stretch")
        else:
            est = sum(g['est_nodes'] for g, _, _ in uncovered)
            print(f"\n  VERDICT: INCOMPLETE -- {len(uncovered)} of {len(x['gaps'])} gap(s) "
                  f"span ground no lap covered, ~{est} waypoint(s) still missing:")
            for g, a, b in uncovered:
                pd = g['player_dist']
                print(f"    {g['t0'].strftime('%H:%M:%S')} -> {g['t1'].strftime('%H:%M:%S')}  "
                      f"({g['last'][0]:.1f}, {g['last'][1]:.1f}) -> "
                      f"({g['next'][0]:.1f}, {g['next'][1]:.1f})  "
                      f"{g['disp']:.1f} yd unobserved, ~{g['est_nodes']} node(s)")
                print(f"      nearest known node: {a[1]:.1f} yd from where it vanished, "
                      f"{b[1]:.1f} yd from where it reappeared"
                      + (f"  [player {pd[0]:.0f} / {pd[1]:.0f} yd away]" if pd[0] and pd[1] else ""))
        print()


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main()
