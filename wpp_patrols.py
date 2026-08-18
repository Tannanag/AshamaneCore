#!/usr/bin/env python3
"""
Reconstruct ordered patrol routes for named NPCs from a WPP-unparsed dump.

Builds on wpp_movement.py: takes the spawns that classify() calls PATROL,
walks the successor graph to recover node order, and reports where the route
has a hole (gap event) versus where it genuinely closes.

Usage:  python3 wpp_patrols.py [--sql] <dump_*_parsed.txt> [Name1] [Name2] ...

With --sql, emits the waypoint_data / creature_addon blocks instead of the
text report, pairing each route with the ashamane_world spawn standing on
one of its nodes.
"""
import sys, math, collections, statistics
from wpp_movement import analyse, classify

DEFAULT_TARGETS = ["Sten Stoutarm", "Jona Ironstock", "Coldridge Mountaineer",
                   "Coldridge Citizen", "Rockjaw Goon"]


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

    idx = {k: i for i, k in enumerate(nodes)}
    seq = [idx[m['dest']] for m in d if m['dest'] in idx]

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
        left = set(idx.values()) - set(used)
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
                conf=conf, orphans=[i for i in idx.values() if i not in set(order)],
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


def load_spawns(entries, cfg=None):
    """`creature` rows for the sniffed box, via the mysql client."""
    import subprocess
    c = dict(WORLD_DB, **(cfg or {}))
    q = ("SELECT guid,id,position_x,position_y,position_z FROM creature "
         "WHERE map=0 AND position_x BETWEEN -6600 AND -6000 "
         "AND position_y BETWEEN 200 AND 700 AND id IN (%s);"
         % ",".join(str(e) for e in sorted(entries)))
    out = subprocess.run(["mysql", "-h", c["host"], "-P", c["port"],
                          "-u", c["user"], "-p" + c["pw"], "-N", "-B",
                          "-e", q, c["db"]],
                         capture_output=True, text=True)
    if out.returncode:
        sys.exit("mysql: " + out.stderr.strip())
    rows = []
    for line in out.stdout.splitlines():
        g, i, x, y, z = line.split("\t")
        rows.append(dict(guid=int(g), entry=int(i),
                         pos=(float(x), float(y), float(z))))
    return rows


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


def linear_chain(rt, moves):
    """Recover an out-and-back route as an explicit round trip, or None.

    A greedy successor walk cannot represent a route that reverses at its ends:
    it stops the moment an edge leads back to a node it already emitted, which
    on the Rockjaw Goon's route meant 7 nodes out of 15 and an 87 yd jump to
    close them. Period detection is meant to cover this case but needs a clean
    lap count to lock on, and gaps depress the score below its own bar.

    So work from the shape of the route instead. Take the maximum spanning tree
    over observed transitions: when the NPC patrols a line, that tree *is* the
    line, every node of degree 2 except the two ends. Two things then separate
    a line from a circuit, which spans to a path just as readily:

      * a circuit is observed closing -- there is a transition between the two
        ends -- while a line's ends are 200 yd apart and never adjacent;
      * a line's ends are visited about half as often as its middle, because
        each lap passes through the middle twice and touches each end once.

    Returns the full round trip, out along the chain and back through its
    interior, because WaypointMovementGenerator cycles a path rather than
    ping-ponging it: `i_currentNode = (i_currentNode+1) % i_path->size()`.
    Emitting only the one-way chain would make the NPC teleport-walk from the
    far end back to the start on every lap.
    """
    nodes = rt['nodes']
    idx = {k: i for i, k in enumerate(nodes)}
    d = [m for m in moves if m['duration'] > 0 and m['dist'] > 0.5]
    seq = [idx[m['dest']] for m in d if m['dest'] in idx]
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

    # observed closing the loop -> a circuit, which the successor walk already
    # handles correctly; leave it alone
    if w.get(frozenset((chain[0], chain[-1])), 0):
        return None
    # ends touched once a lap against twice for the middle
    ev = (rt['visits'][nodes[chain[0]]] + rt['visits'][nodes[chain[-1]]]) / 2
    mid = chain[1:-1]
    mv = sum(rt['visits'][nodes[i]] for i in mid) / len(mid) if mid else 0
    if not mv or ev / mv > 0.8:
        return None
    # a couple of laps at each end before believing a reversal
    if ev < MIN_END_VISITS:
        return None

    return chain + chain[-2:0:-1]


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
        sys.exit(f"no DB spawn of entry {entry} inside the sniffed box")
    scored.sort(key=lambda t: t[0])
    d, s = scored[0]
    runner_up = scored[1][0] if len(scored) > 1 else float('inf')
    if d > MATCH_TOLERANCE:
        sys.exit(f"entry {entry}: nearest spawn is {d:.2f} yd from any node "
                 f"(tolerance {MATCH_TOLERANCE}) -- refusing to guess")
    return s, d, runner_up


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
    idx = {k: i for i, k in enumerate(rt['nodes'])}
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


def emit_sql(picked, by_spawn, player_at):
    """Print the Part A patrol blocks: one per matched spawn."""
    spawns = load_spawns({x['entry'] for x in picked})
    blocks, total, claimed = [], 0, {}
    for x in picked:
        v = by_spawn[(x['entry'], x['counter'])]
        rt = route(v)
        roundtrip = linear_chain(rt, v)
        order = roundtrip if roundtrip else full_order(rt)
        s, d, runner_up = match_spawn(rt, order, spawns, x['entry'])
        guid = s['guid']
        # two routes landing on one guid means the pairing is wrong, and the
        # second block would silently overwrite the first
        if guid in claimed:
            sys.exit(f"guid {guid} matched by both retail spawn "
                     f"{claimed[guid]} and {x['counter']} -- ambiguous")
        claimed[guid] = x['counter']
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
            warn.append(f"longest leg is {max(legs):.0f} yd")
        if spawn_off > 5.0:
            warn.append(f"spawn point sits {spawn_off:.0f} yd off the path")

        print(f"-- {x['name']} (entry {x['entry']}) -- retail spawn {x['counter']}")
        rival = (f"next candidate {runner_up:.1f} yd" if runner_up < float('inf')
                 else "the only spawn of this entry in the box")
        print(f"--   matched guid {guid} at {d:.3f} yd from a route node ({rival})")
        shape = ("out-and-back round trip over %d nodes" % len(set(order))
                 if roundtrip else "circuit")
        print(f"--   {len(order)} waypoints, {shape}, {'run' if mt else 'walk'} "
              f"({route_speed(v):.2f} yd/s), {len(delays)} node(s) with a delay"
              + (f", {dropped} unlinked node(s) dropped" if dropped else ""))
        for w in warn:
            print(f"--   WARNING: {w} -- the dropped nodes probably carried the "
                  f"route between two ends, leaving a stub rather than a circuit")
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
        blocks.append((guid, len(order)))
    print(f"-- {len(blocks)} paths, {total} waypoint rows total")


def main():
    argv = sys.argv[1:]
    sql = '--sql' in argv
    argv = [a for a in argv if a != '--sql']
    path = argv[0]
    targets = argv[1:] or DEFAULT_TARGETS
    r = analyse(path)
    rows = classify(r['moves'], r['names'], r['player_at'])

    by_spawn = collections.defaultdict(list)
    for m in r['moves']:
        by_spawn[(m['entry'], m['counter'])].append(m)
    for v in by_spawn.values():
        v.sort(key=lambda m: m['n'])

    picked = [x for x in rows if x['patrol'] and x['name'] in targets]
    if sql:
        emit_sql(picked, by_spawn, r['player_at'])
        return
    print(f"# {path}")
    print(f"# {len(r['moves'])} monster-moves, {len(rows)} tracked spawns, "
          f"{len(picked)} patrol spawns among {len(targets)} targeted names\n")

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
