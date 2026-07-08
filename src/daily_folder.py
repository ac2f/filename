import datetime
import logging
import os

logger = logging.getLogger("cdr_watcher")

# Turkce gun isimleri (Ingilizce/ASCII karakterlerle).
# datetime.weekday(): Pazartesi=0 ... Pazar=6
TURKISH_DAYS = {
    0: "pazartesi",
    1: "sali",
    2: "carsamba",
    3: "persembe",
    4: "cuma",
    5: "cumartesi",
    6: "pazar",
}


def folder_name_for(date, date_format, separator):
    day = TURKISH_DAYS[date.weekday()]
    return date.strftime(date_format) + separator + day


class DailyFolderManager:
    """Sadece o gun geldiginde, secilen dizin icinde gunun tarih + Turkce gun
    adiyla (ornek: 25-07-2026--pazartesi) bir klasor olusturur. Gelecekteki
    gunleri onceden olusturmaz."""

    def __init__(self, config):
        self.config = config
        self._last_created = None  # olusturuldugu son tarih (datetime.date)

    def tick(self):
        setting = self.config.daily_folders
        if not setting.get("enabled"):
            return

        base = setting.get("base_dir")
        if not base:
            logger.warning("Gunluk klasor icin base_dir tanimli degil (config.json).")
            return

        today = datetime.date.today()
        if self._last_created == today:
            return

        name = folder_name_for(
            today,
            setting.get("date_format", "%d-%m-%Y"),
            setting.get("separator", "--"),
        )
        path = os.path.join(base, name)
        try:
            os.makedirs(base, exist_ok=True)
            if not os.path.exists(path):
                os.makedirs(path)
                logger.info("Gunluk klasor olusturuldu: %s", path)
            self._last_created = today
        except OSError as exc:
            logger.error("Gunluk klasor olusturulamadi (%s): %s", path, exc)
