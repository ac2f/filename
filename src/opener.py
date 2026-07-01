import logging
import subprocess

logger = logging.getLogger("cdr_watcher")


def open_with(app_path, file_path):
    if not app_path:
        logger.warning("Uygulama yolu tanimli degil, dosya acilamadi: %s", file_path)
        return
    try:
        subprocess.Popen([app_path, file_path])
        logger.info("Dosya acildi: %s (%s)", file_path, app_path)
    except OSError as exc:
        logger.error("Dosya acilamadi (%s uygulamasi ile %s): %s", app_path, file_path, exc)
