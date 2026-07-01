import os

from watchdog.observers import Observer

from config import Config
from logger_setup import setup_logger
from renamer import CdrEventHandler
from tray import run_tray

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(BASE_DIR, "config.json")


def main():
    config = Config(CONFIG_PATH)
    logger = setup_logger(BASE_DIR, config.log_file)
    logger.info("CDR Auto Renamer basliyor")

    handler = CdrEventHandler(config)
    observer = Observer()

    watched_any = False
    for folder in config.watch_folders:
        if os.path.isdir(folder):
            observer.schedule(handler, folder, recursive=config.recursive)
            logger.info("Klasor izleniyor: %s", folder)
            watched_any = True
        else:
            logger.warning("Klasor bulunamadi, atlandi: %s", folder)

    if not watched_any:
        logger.error("Izlenecek gecerli klasor bulunamadi. config.json icindeki watch_folders alanini kontrol edin.")

    observer.start()

    try:
        run_tray(config, CONFIG_PATH, os.path.join(BASE_DIR, config.log_file))
    finally:
        observer.stop()
        observer.join()


if __name__ == "__main__":
    main()
