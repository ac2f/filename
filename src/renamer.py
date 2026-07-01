import logging
import os
import time

from watchdog.events import FileSystemEventHandler

from opener import open_with

logger = logging.getLogger("cdr_watcher")


class CdrEventHandler(FileSystemEventHandler):
    """Yeni eklenen dosyalari izler: .cdr.zip -> .cdr yeniden adlandirmasi
    ve ayarlara gore .cdr / .pdf dosyalarinin otomatik acilmasini yapar."""

    def __init__(self, config):
        self.config = config

    def on_created(self, event):
        if event.is_directory:
            return
        self._handle(event.src_path)

    def on_moved(self, event):
        if event.is_directory:
            return
        self._handle(event.dest_path)

    def _handle(self, path):
        self.config.reload_if_changed()
        if not self.config.enabled:
            return

        lower = path.lower()

        for rule in self.config.rename_rules:
            suffix = rule.get("match_suffix", "").lower()
            if suffix and lower.endswith(suffix):
                self._rename_and_maybe_open(path, suffix, rule.get("new_suffix", ""))
                return

        if lower.endswith(".cdr"):
            self._maybe_open("cdr", path)
        elif lower.endswith(".pdf"):
            self._maybe_open("pdf", path)

    def _wait_until_stable(self, path, timeout=30):
        interval = self.config.stability_check_seconds
        deadline = time.time() + timeout
        last_size = -1
        while time.time() < deadline:
            try:
                size = os.path.getsize(path)
            except OSError:
                return False
            if size == last_size and size > 0:
                return True
            last_size = size
            time.sleep(interval)
        return False

    def _rename_and_maybe_open(self, path, old_suffix, new_suffix):
        if not self._wait_until_stable(path):
            logger.warning("Dosya boyutu stabil olmadi, yeniden adlandirma atlandi: %s", path)
            return

        base = path[: -len(old_suffix)]
        new_path = base + new_suffix
        try:
            if os.path.exists(new_path):
                logger.info("Hedef dosya zaten var, yeniden adlandirma atlandi: %s", new_path)
                return
            os.rename(path, new_path)
            logger.info("Yeniden adlandirildi: %s -> %s", path, new_path)
        except OSError as exc:
            logger.error("Yeniden adlandirma basarisiz (%s): %s", path, exc)
            return

        new_lower = new_path.lower()
        if new_lower.endswith(".cdr"):
            self._maybe_open("cdr", new_path)
        elif new_lower.endswith(".pdf"):
            self._maybe_open("pdf", new_path)

    def _maybe_open(self, kind, path):
        setting = self.config.auto_open_setting(kind)
        if setting.get("enabled"):
            open_with(setting.get("app_path"), path)
