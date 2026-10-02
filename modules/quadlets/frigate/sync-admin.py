"""Run inside the official image; the password is supplied only on stdin."""

import sqlite3
import sys
import time
from urllib.error import URLError
from urllib.request import urlopen

# This package is supplied by the official container, not the host interpreter.
from frigate.api.auth import (  # ty: ignore[unresolved-import]
    hash_password,
    verify_password,
)


def sync(password, database="/config/frigate.db", timeout=120):
    if not password:
        raise ValueError("Frigate admin password credential is empty")

    deadline = time.monotonic() + timeout
    last_error = "admin account not created yet"
    while time.monotonic() < deadline:
        try:
            # Wait for the app, not just a database left over from the native service.
            with urlopen("http://127.0.0.1:5000/api/version", timeout=2) as response:
                response.read()
            # mode=rw must not create an empty database during startup/migration.
            connection = sqlite3.connect(
                f"file:{database}?mode=rw", uri=True, timeout=2
            )
            try:
                with connection:
                    row = connection.execute(
                        "SELECT password_hash FROM user WHERE username = ?", ("admin",)
                    ).fetchone()
                    if row is not None:
                        if not verify_password(password, row[0]):
                            connection.execute(
                                "UPDATE user SET password_hash = ?, "
                                "password_changed_at = CURRENT_TIMESTAMP WHERE username = ?",
                                (hash_password(password), "admin"),
                            )
                        print("Frigate admin password synchronized from SOPS")
                        return
            finally:
                connection.close()
        except (sqlite3.Error, URLError, TimeoutError) as error:
            last_error = str(error)
        time.sleep(1)

    raise RuntimeError(f"Timed out waiting for Frigate admin account: {last_error}")


if __name__ == "__main__":
    try:
        sync(sys.stdin.read().rstrip("\n"))
    except (ValueError, RuntimeError) as error:
        sys.exit(f"Frigate admin password synchronization failed: {error}")
