"""Migrate native media paths, then render a runtime-only Frigate config."""

import json
import os
import sqlite3
import sys
import tempfile
from contextlib import closing
from pathlib import Path

NATIVE_MEDIA_PREFIX = "/var/lib/frigate/"
CONTAINER_MEDIA_PREFIX = "/media/frigate/"
MEDIA_PATH_COLUMNS = (
    ("previews", "path"),
    ("recordings", "path"),
    ("export", "video_path"),
    ("export", "thumb_path"),
    ("reviewsegment", "thumb_path"),
)


def migrate_media_paths(database):
    database = Path(database).resolve()
    if not database.exists():
        return None

    uri = database.as_uri()
    with closing(sqlite3.connect(f"{uri}?mode=rw", uri=True, timeout=30)) as connection:
        with connection:
            connection.execute("BEGIN IMMEDIATE")
            tables = {
                row[0]
                for row in connection.execute(
                    "SELECT name FROM sqlite_schema WHERE type = 'table'"
                )
            }
            updates = []
            for table, column in MEDIA_PATH_COLUMNS:
                if table not in tables:
                    continue
                columns = {
                    row[1]
                    for row in connection.execute(f'PRAGMA table_info("{table}")')
                }
                if column not in columns:
                    continue
                predicate = (
                    f"typeof(\"{column}\") = 'text' AND "
                    f'substr("{column}", 1, ?) = ? COLLATE BINARY'
                )
                parameters = (len(NATIVE_MEDIA_PREFIX), NATIVE_MEDIA_PREFIX)
                if connection.execute(
                    f'SELECT 1 FROM "{table}" WHERE {predicate} LIMIT 1', parameters
                ).fetchone():
                    updates.append((table, column, predicate, parameters))

            if not updates:
                return None

            fd, filename = tempfile.mkstemp(
                dir=database.parent,
                prefix=f"{database.name}.pre-quadlet-",
                suffix=".backup",
            )
            os.close(fd)
            backup = Path(filename)
            try:
                # A separate reader avoids backing up our own write transaction.
                # BEGIN IMMEDIATE prevents concurrent writers until updates commit.
                with (
                    closing(sqlite3.connect(f"{uri}?mode=ro", uri=True)) as source,
                    closing(sqlite3.connect(backup)) as target,
                ):
                    source.backup(target)
            except (sqlite3.Error, OSError):
                backup.unlink(missing_ok=True)
                raise
            print(f"Frigate pre-Quadlet database backup: {backup}", flush=True)

            changed = 0
            for table, column, predicate, parameters in updates:
                changed += connection.execute(
                    f'UPDATE "{table}" SET "{column}" = ? || substr("{column}", ?) '
                    f"WHERE {predicate}",
                    (CONTAINER_MEDIA_PREFIX, len(NATIVE_MEDIA_PREFIX) + 1, *parameters),
                ).rowcount
        print(f"Frigate native media paths normalized: {changed} field values")
        return backup


def render(source, email_file, destination):
    settings = json.loads(Path(source).read_text())
    email = Path(email_file).read_text().rstrip("\n")
    if not email:
        raise ValueError("Frigate notification email credential is empty")
    settings["notifications"]["email"] = email

    destination = Path(destination)
    # Atomic replacement never touches the persistent database or media.
    fd, temporary = tempfile.mkstemp(dir=destination.parent, prefix=".config-")
    try:
        with os.fdopen(fd, "w") as output:
            json.dump(settings, output, indent=2)
            output.write("\n")
        os.replace(temporary, destination)
    finally:
        Path(temporary).unlink(missing_ok=True)


if __name__ == "__main__":
    # Do not use StateDirectory: it would recursively change native ownership.
    Path("/var/lib/frigate").mkdir(mode=0o750, parents=True, exist_ok=True)
    migrate_media_paths("/var/lib/frigate/frigate.db")
    render(*sys.argv[1:])
