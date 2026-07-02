import logging
import os
import threading

from watchdog.observers import Observer

logger = logging.getLogger("cdr_watcher")


class WatchManager:
    """Observer'i yonetir ve izlenen klasorleri config ile canli olarak
    esitler. config.json icindeki watch_folders / recursive degistiginde
    (elle duzenleme ile bile) izleme yeniden baslatilmadan guncellenir."""

    def __init__(self, config, handler, poll_interval=2.0):
        self.config = config
        self.handler = handler
        self.poll_interval = poll_interval
        self.observer = Observer()
        self._watches = {}  # (abspath, recursive) -> watch nesnesi
        self._stop = threading.Event()
        self._thread = None

    def start(self):
        self.observer.start()
        self.sync()
        self._thread = threading.Thread(target=self._poll, name="config-poller", daemon=True)
        self._thread.start()

    def sync(self):
        recursive = self.config.recursive
        desired = set()
        for folder in self.config.watch_folders:
            if os.path.isdir(folder):
                desired.add((os.path.abspath(folder), recursive))
            else:
                logger.warning("Klasor bulunamadi, atlandi: %s", folder)

        current = set(self._watches.keys())

        for key in current - desired:
            folder, _ = key
            try:
                self.observer.unschedule(self._watches.pop(key))
                logger.info("Klasor izleme durduruldu: %s", folder)
            except Exception as exc:  # noqa: BLE001 - izleme kaydi zaten gecersiz olabilir
                logger.error("Izleme durdurulamadi (%s): %s", folder, exc)
                self._watches.pop(key, None)

        for key in desired - current:
            folder, rec = key
            try:
                watch = self.observer.schedule(self.handler, folder, recursive=rec)
                self._watches[key] = watch
                logger.info("Klasor izleniyor: %s", folder)
            except Exception as exc:  # noqa: BLE001 - klasor erisilemez olabilir
                logger.error("Izleme baslatilamadi (%s): %s", folder, exc)

        if not self._watches:
            logger.warning(
                "Su an izlenen gecerli klasor yok. config.json icindeki watch_folders alanini kontrol edin."
            )

    def _poll(self):
        while not self._stop.wait(self.poll_interval):
            self.config.reload_if_changed()
            self.sync()

    def stop(self):
        self._stop.set()
        if self._thread is not None:
            self._thread.join(timeout=5)
        self.observer.stop()
        self.observer.join()
