import json
import os
import threading

DEFAULT_CONFIG = {
    "enabled": True,
    "watch_folders": [
        os.path.join(os.path.expanduser("~"), "Downloads")
    ],
    "recursive": True,
    "rename_rules": [
        {"enabled": True, "match_suffix": ".cdr.zip", "new_suffix": ".cdr"}
    ],
    "auto_open": {
        "cdr": {
            "enabled": False,
            "app_path": "C:\\Program Files\\Corel\\CorelDRAW Graphics Suite X7\\Programs64\\CorelDRW.exe"
        },
        "pdf": {
            "enabled": False,
            "app_path": "C:\\Program Files\\Corel\\CorelDRAW Graphics Suite X7\\Programs64\\CorelDRW.exe"
        }
    },
    "stability_check_seconds": 1.0,
    "log_file": "cdr_watcher.log"
}


class Config:
    """JSON tabanli ayar dosyasini okur/yazar; disktaki degisiklikleri de yakalar."""

    def __init__(self, path):
        self.path = path
        self._lock = threading.Lock()
        self._mtime = None
        self.data = {}
        self.load(create_if_missing=True)

    def load(self, create_if_missing=False):
        with self._lock:
            self._load_locked(create_if_missing=create_if_missing)

    def _load_locked(self, create_if_missing=False):
        if not os.path.exists(self.path):
            if create_if_missing:
                self.data = json.loads(json.dumps(DEFAULT_CONFIG))
                self._write_locked()
            return
        with open(self.path, "r", encoding="utf-8") as f:
            self.data = json.load(f)
        self._mtime = os.path.getmtime(self.path)

    def _write_locked(self):
        tmp_path = self.path + ".tmp"
        with open(tmp_path, "w", encoding="utf-8") as f:
            json.dump(self.data, f, ensure_ascii=False, indent=2)
        os.replace(tmp_path, self.path)
        self._mtime = os.path.getmtime(self.path)

    def update(self, mutate):
        """Diskteki en guncel ayarlari okur, sadece istenen alani degistirip
        geri yazar. Boylece kullanicinin config.json uzerinde elle yaptigi
        degisiklikler (ornegin watch_folders) ust uste yazilarak kaybolmaz."""
        with self._lock:
            self._load_locked(create_if_missing=True)
            mutate(self.data)
            self._write_locked()

    def reload_if_changed(self):
        with self._lock:
            try:
                mtime = os.path.getmtime(self.path)
            except OSError:
                return
            if self._mtime is None or mtime > self._mtime:
                self._load_locked()

    @property
    def enabled(self):
        return bool(self.data.get("enabled", True))

    def toggle_enabled(self):
        def mutate(data):
            data["enabled"] = not bool(data.get("enabled", True))
        self.update(mutate)
        return self.enabled

    @property
    def watch_folders(self):
        return list(self.data.get("watch_folders", []))

    @property
    def recursive(self):
        return bool(self.data.get("recursive", True))

    @property
    def rename_rules(self):
        return [r for r in self.data.get("rename_rules", []) if r.get("enabled", True)]

    def auto_open_setting(self, kind):
        return self.data.get("auto_open", {}).get(kind, {"enabled": False, "app_path": ""})

    def toggle_auto_open(self, kind):
        def mutate(data):
            node = data.setdefault("auto_open", {}).setdefault(kind, {})
            node["enabled"] = not bool(node.get("enabled", False))
        self.update(mutate)
        return bool(self.auto_open_setting(kind).get("enabled", False))

    @property
    def stability_check_seconds(self):
        return float(self.data.get("stability_check_seconds", 1.0))

    @property
    def log_file(self):
        return self.data.get("log_file", "cdr_watcher.log")
