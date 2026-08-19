#!/usr/bin/env python3
"""
Apply a generated movement SQL file, leaving an untracked revert beside it.

The world DB is MyISAM, so there is no transaction to roll back: the only undo
for a forward file is a second file that puts the old rows back. This snapshots
exactly the spawns the forward file names -- it reads them from the
`-- @touched:` line the emitters in wpp_patrols.py write -- then applies, then
verifies the rows landed.

The revert lives outside the repo on purpose. It is a record of one server's
state at one moment, not a change to the branch, and committing it would mean
every checkout carries an undo for a database it has never seen.

Usage:  python3 wpp_apply.py [--dry-run] [--revert-dir DIR] <forward.sql>
"""
import os, re, sys, glob, argparse, datetime, subprocess

WORLD_DB = dict(host="127.0.0.1", port="3306",
                user="ashamane", pw="ashamane", db="ashamane_world")
DEFAULT_REVERT_DIR = os.path.expanduser("~/movement-reverts")
TOUCHED = re.compile(r'^--\s*@touched:\s*([\w,]+)\s+([\d,]*)\s*$', re.M)


def _args(c):
    return ["-h", c["host"], "-P", c["port"], "-u", c["user"], "-p" + c["pw"]]


def mysql(query, c, fetch=True):
    r = subprocess.run(["mysql"] + _args(c) + ["-N", "-B", "-e", query, c["db"]],
                       capture_output=True, text=True)
    if r.returncode:
        sys.exit("mysql: " + r.stderr.strip())
    return [l.split("\t") for l in r.stdout.splitlines()] if fetch else None


def dump_rows(table, where, c):
    """Original rows as INSERT statements, escaping and all, via mysqldump."""
    r = subprocess.run(["mysqldump"] + _args(c) +
                       ["--no-create-info", "--complete-insert",
                        "--skip-extended-insert", "--no-tablespaces",
                        "--compact", "--where=" + where, c["db"], table],
                       capture_output=True, text=True)
    if r.returncode:
        sys.exit("mysqldump: " + r.stderr.strip())
    return [l for l in r.stdout.splitlines() if l.startswith("INSERT")]


def touched(path):
    """Guids and tables the forward file declares it will change.

    Refusing to run without the line is the point: a file with no declaration
    is one whose blast radius is unknown, and snapshotting a guess is worse
    than not snapshotting at all.
    """
    text = open(path).read()
    tabs, guids = set(), set()
    for t, g in TOUCHED.findall(text):
        tabs |= {x for x in t.split(",") if x}
        guids |= {int(x) for x in g.split(",") if x}
    if not tabs:
        sys.exit(f"{path} has no `-- @touched:` line -- generate it with "
                 f"wpp_patrols.py, or add the line by hand naming every guid "
                 f"the file changes")
    return sorted(tabs), sorted(guids)


def snapshot(guids, tables, c, outdir):
    """Everything the forward file could overwrite, before it does."""
    os.makedirs(outdir, exist_ok=True)
    gl = ",".join(str(g) for g in guids)
    # orientation travels with the movement columns: a file that stands an NPC
    # still usually turns it to face something, and a revert that restored the
    # movement but not the facing would leave the spawn half-reverted.
    state = mysql(
        "SELECT c.guid, c.id, c.MovementType, c.wander_distance, "
        "IFNULL(a.path_id, 0), c.orientation FROM creature c "
        "LEFT JOIN creature_addon a ON a.guid = c.guid "
        f"WHERE c.guid IN ({gl});", c)
    missing = set(guids) - {int(r[0]) for r in state}
    if missing:
        sys.exit(f"guids not in `creature`: {sorted(missing)} -- the forward file "
                 f"names spawns this server does not have")

    # Both the path the spawn uses now and the one the forward file will bind
    # it to (the guid*10 convention). The second may already hold rows from an
    # earlier run, and those are just as lost if they are not captured here.
    paths = {int(r[4]) for r in state if int(r[4])} | {g * 10 for g in guids}
    pl = ",".join(str(p) for p in sorted(paths))

    snap = dict(state=state, addon=[], waypoints=[])
    if "creature_addon" in tables:
        snap["addon"] = dump_rows("creature_addon", f"guid IN ({gl})", c)
    if "waypoint_data" in tables:
        snap["waypoints"] = dump_rows("waypoint_data", f"id IN ({pl})", c)
        snap["paths"] = sorted(paths)
    with open(os.path.join(outdir, "creature.tsv"), "w") as f:
        for r in state:
            f.write("\t".join(r) + "\n")
    for name, key in (("creature_addon.sql", "addon"), ("waypoint_data.sql", "waypoints")):
        if snap.get(key):
            with open(os.path.join(outdir, name), "w") as f:
                f.write("\n".join(snap[key]) + "\n")
    return snap


def write_revert(path, forward, snap, tables, guids, when):
    rows = snap["state"]
    with open(path, "w") as f:
        w = f.write
        w(f"-- REVERT of {forward}\n--\n")
        w(f"-- Snapshot taken {when} from ashamane_world, immediately before that\n"
          f"-- file was applied. Not tracked in the repo on purpose: MyISAM has no\n"
          f"-- rollback, so this is the undo, and it describes one server's state at\n"
          f"-- one moment rather than anything about the branch.\n--\n")
        w(f"-- {len(guids)} spawn(s): "
          + ", ".join(str(g) for g in guids[:20])
          + (" ..." if len(guids) > 20 else "") + "\n\n")

        w("-- creature: the movement and facing each spawn had before\n")
        for guid, entry, mt, wd, _pid, o in rows:
            w(f"UPDATE `creature` SET `MovementType`={mt}, `wander_distance`={wd}, "
              f"`orientation`={o} WHERE `guid`={guid};  -- entry {entry}\n")
        if "creature_addon" in tables:
            gl = ", ".join(str(g) for g in guids)
            w(f"\n-- creature_addon: {len(snap['addon'])} row(s) existed before\n")
            w(f"DELETE FROM `creature_addon` WHERE `guid` IN ({gl});\n")
            for line in snap["addon"]:
                w(line + "\n")
        if "waypoint_data" in tables:
            pl = ", ".join(str(p) for p in snap.get("paths", []))
            w(f"\n-- waypoint_data: {len(snap['waypoints'])} row(s) existed before "
              f"under path id(s) {pl}\n")
            w(f"DELETE FROM `waypoint_data` WHERE `id` IN ({pl});\n")
            for line in snap["waypoints"]:
                w(line + "\n")
        w("\n-- After running this, `.reload waypoint_data` or restart worldserver.\n")


def apply_file(path, c):
    with open(path) as f:
        r = subprocess.run(["mysql"] + _args(c) + [c["db"]],
                           stdin=f, capture_output=True, text=True)
    if r.returncode:
        sys.exit("apply failed, revert file is already written: " + r.stderr.strip())
    return r.stderr.strip()


def verify(guids, c):
    gl = ",".join(str(g) for g in guids)
    return mysql(
        "SELECT c.guid, c.id, c.MovementType, c.wander_distance, "
        "IFNULL(a.path_id, 0), "
        "(SELECT COUNT(*) FROM waypoint_data w WHERE w.id = a.path_id) "
        f"FROM creature c LEFT JOIN creature_addon a ON a.guid = c.guid "
        f"WHERE c.guid IN ({gl}) ORDER BY c.id, c.guid;", c)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('forward', help='the SQL file to apply')
    ap.add_argument('--revert-dir', default=DEFAULT_REVERT_DIR)
    ap.add_argument('--dry-run', action='store_true',
                    help='snapshot and write the revert, but do not apply')
    ap.add_argument('--db-host'), ap.add_argument('--db-port')
    ap.add_argument('--db-user'), ap.add_argument('--db-pass')
    ap.add_argument('--db-name')
    a = ap.parse_args()
    c = dict(WORLD_DB, **{k: v for k, v in (('host', a.db_host), ('port', a.db_port),
                                            ('user', a.db_user), ('pw', a.db_pass),
                                            ('db', a.db_name)) if v})

    tables, guids = touched(a.forward)
    if not guids:
        sys.exit(f"{a.forward} declares no guids -- nothing to do")
    when = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    base = os.path.basename(a.forward).rsplit('.', 1)[0]
    # The file name is in the directory name, not just the timestamp:
    # applying three files in the same second otherwise puts three
    # snapshots in one directory, each overwriting the last.
    backup = os.path.join(a.revert_dir, f"backup-{stamp}-{base}")
    revert = os.path.join(a.revert_dir, base + "_revert.sql")

    print(f"{a.forward}: {len(guids)} spawn(s), tables {', '.join(tables)}")
    snap = snapshot(guids, tables, c, backup)
    print(f"snapshot -> {backup}")
    write_revert(revert, a.forward, snap, tables, guids, when)
    print(f"revert   -> {revert}")
    if a.dry_run:
        print("dry run: not applied")
        return

    warn = apply_file(a.forward, c)
    if warn:
        print(warn)
    print(f"applied.\n\n{'guid':>8} {'entry':>7} {'mt':>3} {'wander':>7} "
          f"{'path':>8} {'wps':>4}")
    for guid, entry, mt, wd, pid, wp in verify(guids, c):
        print(f"{guid:>8} {entry:>7} {mt:>3} {float(wd):>7.0f} {pid:>8} {wp:>4}")
    print("\nNow `.reload waypoint_data` in the worldserver console (or restart), "
          "then check the log for sql.sql errors.")


if __name__ == '__main__':
    main()
