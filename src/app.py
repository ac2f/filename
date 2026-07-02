import os

from config import Config
from logger_setup import setup_logger
from renamer import CdrEventHandler
from tray import run_tray
from watcher import WatchManager

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(BASE_DIR, "config.json")


def main():
    config = Config(CONFIG_PATH)
    logger = setup_logger(BASE_DIR, config.log_file)
    logger.info("CDR Auto Renamer basliyor")

    handler = CdrEventHandler(config)
    manager = WatchManager(config, handler)
    manager.start()

    try:
        run_tray(config, CONFIG_PATH, os.path.join(BASE_DIR, config.log_file))
    finally:
        manager.stop()


if __name__ == "__main__":
    main()
