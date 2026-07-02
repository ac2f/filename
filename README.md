# CDR Auto Renamer

WhatsApp'tan indirilen `.cdr` dosyaları bazen `.cdr.zip` uzantısıyla iner. Bu
küçük Windows uygulaması, seçtiğiniz klasörleri arka planda izler ve **bundan
sonra** o klasörlere düşen yeni `.cdr.zip` dosyalarını otomatik olarak `.cdr`
uzantısına çevirir. Daha önce indirilmiş dosyalara dokunmaz, sadece yeni
gelenleri işler.

Ek olarak:
- Yeni eklenen `.cdr` dosyalarını CorelDRAW ile otomatik açma
- Yeni eklenen `.pdf` dosyalarını CorelDRAW (X7) ile otomatik açma

özellikleri de ayarlardan açılıp kapatılabilir.

Windows'un sistem tepsisinde (saat yanındaki simgeler) bir simge belirir; bu
simgeye sağ tıklayarak uygulamayı aktif/deaktif yapabilir, otomatik açma
özelliklerini değiştirebilir ve ayar dosyasını açabilirsiniz.

## Gereksinimler

- Windows 10/11
- [Python 3](https://www.python.org/downloads/) (kurulum sırasında **"Add
  python.exe to PATH"** kutusunu işaretleyin)

Python zaten kuruluysa ekstra bir şey yapmanıza gerek yok, kurulum betiği
gerisini halleder.

## Tek Tıkla Kurulum

1. Bu klasörü bilgisayarınıza indirin (veya bu depoyu klonlayın).
2. `install.bat` dosyasına çift tıklayın.
   - Gerekli Python paketlerini otomatik kurar.
   - Uygulamayı `%LOCALAPPDATA%\CdrAutoRenamer` klasörüne kurar.
   - Windows başlangıcına otomatik çalışacak şekilde bir kısayol ekler
     (`shell:startup` klasörüne).
   - Uygulamayı hemen başlatır; sistem tepsisinde simgesini görürsünüz.
3. Kurulumdan hemen sonra `%LOCALAPPDATA%\CdrAutoRenamer\config.json`
   dosyasını açıp **izlenecek klasörü** kendi WhatsApp indirme klasörünüzle
   değiştirin (bkz. aşağıdaki "Ayarlar" bölümü). Sistem tepsisindeki simgeye
   sağ tıklayıp "Ayarlar Dosyasını Aç" seçeneğiyle de ulaşabilirsiniz.

Bilgisayarı her açtığınızda uygulama kendiliğinden başlar, tekrar kurulum
yapmanıza gerek yoktur.

## Ayarlar (`config.json`)

Kurulumdan sonra ayar dosyası `%LOCALAPPDATA%\CdrAutoRenamer\config.json`
konumunda bulunur. Dosyayı Not Defteri ile açıp düzenleyebilir, kaydettiğiniz
anda uygulama yeni ayarları otomatik olarak algılar (yeniden başlatmaya gerek
yoktur). İzlenecek klasörleri (`watch_folders`) değiştirdiğinizde birkaç saniye
içinde yeni klasör izlenmeye başlar; sistem tepsisinden aktif/deaktif yapmanız
**gerekmez**. Tepsi menüsünden yapılan aç/kapat işlemleri de `config.json`
içinde elle yaptığınız düzenlemeleri (örneğin izlenen klasör) bozmaz.

```json
{
  "enabled": true,
  "watch_folders": [
    "C:\\Users\\KULLANICI_ADIN\\Downloads"
  ],
  "recursive": true,
  "rename_rules": [
    { "enabled": true, "match_suffix": ".cdr.zip", "new_suffix": ".cdr" }
  ],
  "auto_open": {
    "cdr": {
      "enabled": false,
      "app_path": "C:\\Program Files\\Corel\\CorelDRAW Graphics Suite X7\\Programs64\\CorelDRW.exe"
    },
    "pdf": {
      "enabled": false,
      "app_path": "C:\\Program Files\\Corel\\CorelDRAW Graphics Suite X7\\Programs64\\CorelDRW.exe"
    }
  },
  "stability_check_seconds": 1.0,
  "log_file": "cdr_watcher.log"
}
```

Alan açıklamaları:

| Alan | Açıklama |
| --- | --- |
| `enabled` | Uygulamanın tamamını aç/kapat (sistem tepsisi menüsündeki "Aktif" ile aynı ayar). |
| `watch_folders` | İzlenecek klasörlerin listesi. Birden fazla klasör ekleyebilirsiniz, örn. hem WhatsApp klasörü hem Downloads. |
| `recursive` | `true` ise alt klasörler de izlenir. |
| `rename_rules` | Hangi uzantının hangisine çevrileceğini tanımlar. `enabled: false` yaparak bu kuralı kapatabilirsiniz. |
| `auto_open.cdr.enabled` | Yeni gelen (veya yeniden adlandırılan) `.cdr` dosyalarını otomatik açar/kapatır. |
| `auto_open.pdf.enabled` | Yeni gelen `.pdf` dosyalarını otomatik açar/kapatır. |
| `auto_open.*.app_path` | Dosyayı açacak programın tam yolu (varsayılan CorelDRAW X7 yolu; kendi kurulumunuza göre düzeltin). |
| `stability_check_seconds` | Dosyanın indirmesinin bittiğinden emin olmak için kullanılan bekleme aralığı (saniye). |
| `log_file` | İşlemlerin kaydedildiği günlük dosyasının adı. |

CorelDRAW farklı bir sürüm/klasörde kuruluysa `app_path` değerlerini kendi
`CorelDRW.exe` yolunuzla değiştirin.

## Sistem Tepsisi Menüsü

Simgeye sağ tıkladığınızda:

- **Aktif** – uygulamayı tamamen açar/kapatır (yeşil = aktif, gri = deaktif).
- **Yeni .cdr dosyalarını otomatik aç** – açık/kapalı.
- **Yeni .pdf dosyalarını Corel ile otomatik aç** – açık/kapalı.
- **Ayarlar Dosyasını Aç (config.json)** – ayar dosyasını Not Defteri ile açar.
- **Günlüğü Aç** – işlem geçmişini gösteren log dosyasını açar.
- **Çıkış** – uygulamayı kapatır (bir sonraki oturum açılışında tekrar
  başlayacaktır).

## Kaldırma

`uninstall.bat` dosyasına çift tıklayın. Başlangıç kısayolunu kaldırır ve
isterseniz kurulum klasörünü de siler.

## Gelişmiş: Python'suz tek dosya (.exe) üretme

Hedef bilgisayara Python kurmak istemiyorsanız, Windows üzerinde
`build_exe.ps1` betiğini çalıştırarak PyInstaller ile tek dosyalık
`dist\CdrAutoRenamer.exe` üretebilirsiniz. Bu adım isteğe bağlıdır; normal
`install.bat` kurulumu için Python yeterlidir.

## Notlar

- Uygulama sadece **kurulumdan sonra** o klasörlere düşen yeni dosyaları
  işler; daha önce indirilmiş dosyalara dokunmaz.
- Bu proje Windows'a özeldir (CorelDRAW ve sistem tepsisi entegrasyonu
  nedeniyle); Linux/macOS üzerinde çalışmaz.
