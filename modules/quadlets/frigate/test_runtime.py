"""Host-only regression tests; all databases and credentials are temporary."""

import importlib.util
import io
import json
import sqlite3
import stat
import sys
import tempfile
import types
import unittest
from contextlib import closing
from pathlib import Path
from unittest.mock import patch
from urllib.error import URLError

ROOT = Path(__file__).parent


def load_script(name, filename):
    spec = importlib.util.spec_from_file_location(name, ROOT / filename)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


renderer = load_script("frigate_render", "render-config.py")
# Test the sync control flow without requiring the container's dependencies.
auth = types.ModuleType("frigate.api.auth")
auth.__dict__.update(
    hash_password=lambda password: f"hash:{password}",
    verify_password=lambda password, stored: stored == f"hash:{password}",
)
with patch.dict(sys.modules, {"frigate.api.auth": auth}):
    admin = load_script("frigate_sync", "sync-admin.py")


class RuntimeTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.database = self.directory / "frigate.db"

    def dump(self, path):
        with closing(
            sqlite3.connect(f"{path.as_uri()}?mode=ro", uri=True)
        ) as connection:
            return "\n".join(connection.iterdump())

    def fixture(self):
        values = [
            "/var/lib/frigate/clips/native.mp4",
            "/media/frigate/clips/container.mp4",
            "/elsewhere/clips/other.mp4",
            "/var/lib/frigate-other/clips/other.mp4",
            "/var/lib/frigate",
            "/elsewhere/var/lib/frigate/clips/other.mp4",
            "/VAR/LIB/FRIGATE/clips/other.mp4",
            "/var/lib/frigate/clips/var/lib/frigate/repeated.mp4",
            "",
            None,
            b"/var/lib/frigate/blob",
        ]
        with closing(sqlite3.connect(self.database)) as connection, connection:
            for table in dict(renderer.MEDIA_PATH_COLUMNS):
                columns = [
                    column
                    for name, column in renderer.MEDIA_PATH_COLUMNS
                    if name == table
                ]
                schema = ", ".join(f'"{column}" TEXT UNIQUE' for column in columns)
                connection.execute(
                    f'CREATE TABLE "{table}" (id TEXT PRIMARY KEY, {schema}, '
                    "extra_path TEXT, data TEXT)"
                )
                placeholders = ", ".join("?" for _ in range(len(columns) + 3))
                for index, value in enumerate(values):
                    connection.execute(
                        f'INSERT INTO "{table}" VALUES ({placeholders})',
                        (
                            str(index),
                            *([value] * len(columns)),
                            "/var/lib/frigate/unknown",
                            '{"file":"/var/lib/frigate/json"}',
                        ),
                    )
            connection.execute("CREATE TABLE user (username TEXT, password_hash TEXT)")
            connection.execute(
                "INSERT INTO user VALUES ('admin', '/var/lib/frigate/not-a-path')"
            )
            connection.execute("CREATE TABLE unknown (path TEXT)")
            connection.execute(
                "INSERT INTO unknown VALUES ('/var/lib/frigate/unknown')"
            )
        return values

    def test_migrates_only_known_exact_prefixes_and_preserves_backup(self):
        values = self.fixture()
        original = self.dump(self.database)
        backup = renderer.migrate_media_paths(self.database)
        self.assertEqual(self.dump(backup), original)
        self.assertEqual(stat.S_IMODE(backup.stat().st_mode), 0o600)
        self.assertTrue(backup.name.startswith("frigate.db.pre-quadlet-"))
        with closing(sqlite3.connect(self.database)) as connection:
            for table, column in renderer.MEDIA_PATH_COLUMNS:
                rows = connection.execute(
                    f'SELECT id, "{column}", extra_path, data FROM "{table}" ORDER BY CAST(id AS INTEGER)'
                ).fetchall()
                for index, (identifier, value, extra_path, data) in enumerate(rows):
                    expected = values[index]
                    if isinstance(expected, str) and expected.startswith(
                        renderer.NATIVE_MEDIA_PREFIX
                    ):
                        expected = (
                            renderer.CONTAINER_MEDIA_PREFIX
                            + expected[len(renderer.NATIVE_MEDIA_PREFIX) :]
                        )
                    self.assertEqual((identifier, value), (str(index), expected))
                    self.assertEqual(extra_path, "/var/lib/frigate/unknown")
                    self.assertEqual(data, '{"file":"/var/lib/frigate/json"}')
            self.assertEqual(
                connection.execute("SELECT * FROM user").fetchall(),
                [("admin", "/var/lib/frigate/not-a-path")],
            )
            self.assertEqual(
                connection.execute("SELECT * FROM unknown").fetchall(),
                [("/var/lib/frigate/unknown",)],
            )

    def test_second_run_is_noop_without_another_backup(self):
        self.fixture()
        renderer.migrate_media_paths(self.database)
        previous = self.database.read_bytes()
        backups = set(self.directory.glob("*.backup"))
        self.assertIsNone(renderer.migrate_media_paths(self.database))
        self.assertEqual(self.database.read_bytes(), previous)
        self.assertEqual(set(self.directory.glob("*.backup")), backups)

    def test_missing_database_does_not_create_files_or_directories(self):
        self.assertIsNone(renderer.migrate_media_paths(self.database))
        self.assertIsNone(
            renderer.migrate_media_paths(self.directory / "absent" / "frigate.db")
        )
        self.assertEqual(list(self.directory.iterdir()), [])

    def test_noop_database_has_no_backup(self):
        with closing(sqlite3.connect(self.database)) as connection, connection:
            connection.execute("CREATE TABLE previews (path TEXT)")
            connection.execute(
                "INSERT INTO previews VALUES ('/media/frigate/already.mp4')"
            )
        previous = self.database.read_bytes()
        self.assertIsNone(renderer.migrate_media_paths(self.database))
        self.assertEqual(self.database.read_bytes(), previous)
        self.assertEqual(list(self.directory.iterdir()), [self.database])

    def test_missing_tables_and_columns_are_skipped(self):
        with closing(sqlite3.connect(self.database)) as connection, connection:
            connection.execute("CREATE TABLE previews (id TEXT)")
            connection.execute("CREATE TABLE export (video_path TEXT)")
            connection.execute(
                "INSERT INTO export VALUES ('/var/lib/frigate/exports/video.mp4')"
            )
        renderer.migrate_media_paths(self.database)
        with closing(sqlite3.connect(self.database)) as connection:
            self.assertEqual(
                connection.execute("SELECT video_path FROM export").fetchone(),
                ("/media/frigate/exports/video.mp4",),
            )

    def test_unknown_schema_is_unchanged_without_backup(self):
        with closing(sqlite3.connect(self.database)) as connection, connection:
            connection.execute("CREATE TABLE unknown (path TEXT)")
            connection.execute(
                "INSERT INTO unknown VALUES ('/var/lib/frigate/unknown')"
            )
        previous = self.database.read_bytes()
        self.assertIsNone(renderer.migrate_media_paths(self.database))
        self.assertEqual(self.database.read_bytes(), previous)
        self.assertEqual(list(self.directory.iterdir()), [self.database])

    def test_backup_names_do_not_clobber_previous_backups(self):
        self.fixture()
        sentinel = self.directory / "frigate.db.pre-quadlet-existing.backup"
        sentinel.write_bytes(b"keep existing backup")
        first = renderer.migrate_media_paths(self.database)
        first_bytes = first.read_bytes()
        with closing(sqlite3.connect(self.database)) as connection, connection:
            connection.execute(
                "UPDATE previews SET path = '/var/lib/frigate/new.mp4' WHERE id = '0'"
            )
        second = renderer.migrate_media_paths(self.database)
        self.assertNotEqual(first, second)
        self.assertEqual(first.read_bytes(), first_bytes)
        self.assertEqual(sentinel.read_bytes(), b"keep existing backup")

    def test_backup_includes_uncheckpointed_wal_data(self):
        with closing(sqlite3.connect(self.database)) as connection:
            connection.execute("PRAGMA journal_mode=WAL")
            connection.execute("PRAGMA wal_autocheckpoint=0")
            connection.execute("CREATE TABLE previews (path TEXT)")
            connection.execute(
                "INSERT INTO previews VALUES ('/var/lib/frigate/wal.mp4')"
            )
            connection.commit()
            original = "\n".join(connection.iterdump())
            backup = renderer.migrate_media_paths(self.database)
            self.assertEqual(self.dump(backup), original)
            self.assertEqual(
                connection.execute("SELECT path FROM previews").fetchone(),
                ("/media/frigate/wal.mp4",),
            )

    def test_update_failure_rolls_back_all_tables_and_keeps_backup(self):
        with closing(sqlite3.connect(self.database)) as connection, connection:
            connection.execute("CREATE TABLE previews (path TEXT)")
            connection.execute(
                "INSERT INTO previews VALUES ('/var/lib/frigate/preview.mp4')"
            )
            connection.execute("CREATE TABLE recordings (path TEXT UNIQUE)")
            connection.execute(
                "INSERT INTO recordings VALUES ('/var/lib/frigate/collision.mp4')"
            )
            connection.execute(
                "INSERT INTO recordings VALUES ('/media/frigate/collision.mp4')"
            )
        original = self.dump(self.database)
        with self.assertRaises(sqlite3.IntegrityError):
            renderer.migrate_media_paths(self.database)
        self.assertEqual(self.dump(self.database), original)
        backups = list(self.directory.glob("*.backup"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(self.dump(backups[0]), original)

    def test_backup_failure_prevents_updates_and_removes_incomplete_backup(self):
        self.fixture()
        original = self.dump(self.database)
        connect = sqlite3.connect

        def fail_backup(path, *args, **kwargs):
            if str(path).endswith(".backup"):
                raise sqlite3.OperationalError("backup unavailable")
            return connect(path, *args, **kwargs)

        with (
            patch.object(renderer.sqlite3, "connect", side_effect=fail_backup),
            self.assertRaisesRegex(sqlite3.OperationalError, "backup unavailable"),
        ):
            renderer.migrate_media_paths(self.database)
        self.assertEqual(self.dump(self.database), original)
        self.assertEqual(list(self.directory.glob("*.backup")), [])

    def test_render_escapes_secret_keeps_placeholders_and_sets_private_permissions(
        self,
    ):
        source = self.directory / "settings.json"
        settings = {
            "notifications": {"email": "placeholder"},
            "mqtt": {"password": "{FRIGATE_MQTT_PASSWORD}"},
        }
        source.write_text(json.dumps(settings))
        email = self.directory / "email"
        secret = 'quoted"\\value\n雪@example.org'
        email.write_text(secret + "\n")
        destination = self.directory / "config.yml"
        renderer.render(source, email, destination)
        expected = {**settings, "notifications": {"email": secret}}
        self.assertEqual(json.loads(destination.read_text()), expected)
        self.assertEqual(stat.S_IMODE(destination.stat().st_mode), 0o600)
        self.assertNotIn(secret, source.read_text())
        self.assertEqual(list(self.directory.glob(".config-*")), [])

    def test_failed_render_preserves_previous_config_and_cleans_temporary_file(self):
        source = self.directory / "settings.json"
        source.write_text('{"notifications": {}}')
        email = self.directory / "email"
        email.write_text("user@example.org")
        destination = self.directory / "config.yml"
        destination.write_text("original")
        with (
            patch.object(
                renderer.json, "dump", side_effect=ValueError("render failed")
            ),
            self.assertRaisesRegex(ValueError, "render failed"),
        ):
            renderer.render(source, email, destination)
        self.assertEqual(destination.read_text(), "original")
        self.assertEqual(list(self.directory.glob(".config-*")), [])
        email.write_text("")
        with self.assertRaisesRegex(ValueError, "credential is empty"):
            renderer.render(source, email, destination)
        self.assertEqual(destination.read_text(), "original")

    def test_admin_sync_updates_only_admin_and_is_idempotent(self):
        with closing(sqlite3.connect(self.database)) as connection, connection:
            connection.execute(
                "CREATE TABLE user (username TEXT, password_hash TEXT, password_changed_at TEXT)"
            )
            connection.execute("INSERT INTO user VALUES ('admin', 'hash:old', NULL)")
            connection.execute("INSERT INTO user VALUES ('viewer', 'unchanged', NULL)")
        with patch.object(
            admin, "urlopen", side_effect=lambda *args, **kwargs: io.BytesIO(b"0.17.2")
        ):
            admin.sync("replacement", str(self.database), timeout=5)
            original = self.dump(self.database)
            admin.sync("replacement", str(self.database), timeout=5)
            self.assertEqual(self.dump(self.database), original)
        with closing(sqlite3.connect(self.database)) as connection:
            self.assertEqual(
                connection.execute(
                    "SELECT password_hash FROM user WHERE username='admin'"
                ).fetchone(),
                ("hash:replacement",),
            )
            self.assertIsNotNone(
                connection.execute(
                    "SELECT password_changed_at FROM user WHERE username='admin'"
                ).fetchone()[0]
            )
            self.assertEqual(
                connection.execute(
                    "SELECT * FROM user WHERE username='viewer'"
                ).fetchone(),
                ("viewer", "unchanged", None),
            )

    def test_admin_sync_rejects_empty_password_and_reports_readiness_timeout(self):
        with self.assertRaises(ValueError):
            admin.sync("")
        with (
            patch.object(admin, "urlopen", side_effect=URLError("not ready")),
            patch.object(admin.time, "sleep"),
            self.assertRaisesRegex(RuntimeError, "not ready"),
        ):
            admin.sync("password", str(self.database), timeout=0.01)
        self.assertFalse(self.database.exists())
        with (
            patch.object(
                admin,
                "urlopen",
                side_effect=lambda *args, **kwargs: io.BytesIO(b"0.17.2"),
            ),
            patch.object(admin.time, "sleep"),
            self.assertRaisesRegex(RuntimeError, "unable to open database"),
        ):
            admin.sync("password", str(self.database), timeout=0.01)
        self.assertFalse(self.database.exists())


if __name__ == "__main__":
    unittest.main()
