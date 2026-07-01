import os

import pystray
from PIL import Image, ImageDraw


def _make_icon(color):
    image = Image.new("RGB", (64, 64), "white")
    draw = ImageDraw.Draw(image)
    draw.ellipse((8, 8, 56, 56), fill=color)
    return image


def run_tray(config, config_path, log_path):
    icon_holder = {}

    def refresh_icon():
        icon = icon_holder["icon"]
        icon.icon = _make_icon("green" if config.enabled else "gray")
        icon.title = "CDR Auto Renamer - " + ("Aktif" if config.enabled else "Deaktif")

    def toggle_enabled(icon, item):
        config.enabled = not config.enabled
        refresh_icon()

    def toggle_auto_open(kind):
        def _toggle(icon, item):
            current = config.auto_open_setting(kind).get("enabled", False)
            config.set_auto_open_enabled(kind, not current)
        return _toggle

    def is_enabled(item):
        return config.enabled

    def is_auto_open_enabled(kind):
        def _check(item):
            return bool(config.auto_open_setting(kind).get("enabled", False))
        return _check

    def open_config(icon, item):
        os.startfile(config_path)

    def open_log(icon, item):
        if os.path.exists(log_path):
            os.startfile(log_path)

    def quit_app(icon, item):
        icon.stop()

    menu = pystray.Menu(
        pystray.MenuItem("Aktif", toggle_enabled, checked=is_enabled),
        pystray.MenuItem(
            "Yeni .cdr dosyalarini otomatik ac",
            toggle_auto_open("cdr"),
            checked=is_auto_open_enabled("cdr"),
        ),
        pystray.MenuItem(
            "Yeni .pdf dosyalarini Corel ile otomatik ac",
            toggle_auto_open("pdf"),
            checked=is_auto_open_enabled("pdf"),
        ),
        pystray.MenuItem("Ayarlar Dosyasini Ac (config.json)", open_config),
        pystray.MenuItem("Gunlugu Ac", open_log),
        pystray.MenuItem("Cikis", quit_app),
    )

    icon = pystray.Icon(
        "cdr_auto_renamer",
        _make_icon("green" if config.enabled else "gray"),
        "CDR Auto Renamer",
        menu,
    )
    icon_holder["icon"] = icon
    refresh_icon()
    icon.run()
