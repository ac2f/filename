import logging
import os
from logging.handlers import RotatingFileHandler


def setup_logger(base_dir, log_file_name):
    log_path = os.path.join(base_dir, log_file_name)
    logger = logging.getLogger("cdr_watcher")
    logger.setLevel(logging.INFO)
    if not logger.handlers:
        handler = RotatingFileHandler(log_path, maxBytes=1_000_000, backupCount=3, encoding="utf-8")
        handler.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
        logger.addHandler(handler)
    return logger
