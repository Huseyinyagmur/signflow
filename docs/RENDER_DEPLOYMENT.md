# Render production kurulumu

Bu çalışma yalnızca hazırlıktır. Render hesabında kaynak oluşturulmadı; deploy, commit veya push yapılmadı. Yeni production PostgreSQL boş başlar; development/test SQLite kayıtları taşınmaz. SignFlow demo imzalama sunar, doğrulanmış kimlik veya nitelikli elektronik imza sunmaz.

## Servisler ve plan seçimi

Render'da Native Ruby Web Service ve aynı bölgede Render Postgres elle oluşturulur. Docker runtime seçmeyin: mevcut Dockerfile, bin/docker-entrypoint ve config/deploy.yml önceki Kamal iskeletidir; bu rehberin dağıtım yolu değildir. render.yaml eklenmedi; otomatik kaynak oluşturma yoktur.

- Önerilen web: 0.5c-512mb (eski adı Starter), ücretli; tek süreç ve üç thread.
- Önerilen PostgreSQL: 0.1c-256mb (eski adı Basic-256mb), ücretli, süreli ücretsiz kaynak yerine kalıcı veritabanı. Storage ve backup/retention politikasını ayrıca inceleyin.
- Daha düşük demo maliyeti için ücretsiz web + ücretli PostgreSQL seçilebilir. Ücretsiz web uykuya geçer; ilk erişim gecikebilir.
- Ücretsiz PostgreSQL kalıcı hedefi karşılamaz: 30 günde sona erer; ek 14 günlük geçiş süresinden sonra silinir.
- Redis, worker, cron veya persistent disk mevcut sözleşme akışı için gerekmez. PDF/dosya yükleme ve gerçek e-posta yoktur.

Planlar öneridir; fiyatı ve ücretli kaynak oluşturmayı kullanıcı kendi hesabında onaylar. Bu çalışma hiçbir kaynak oluşturmadı. Güncel kaynaklar: [plan adları](https://render.com/docs/compute-plans), [ücretsiz kaynak sınırları](https://render.com/docs/free), [Rails 8 rehberi](https://render.com/docs/deploy-rails-8).

## Environment

Gizli değerleri kaynak koduna, README'ye, terminal çıktısına veya issue'ya yazmayın.

| Ad | Render ayarı |
| --- | --- |
| DATABASE_URL | Aynı bölgedeki Postgres kaynağının Internal Database URL değerini gizli olarak girin. PostgreSQL zorunludur; SQLite fallback yoktur. |
| RAILS_MASTER_KEY | Gitignored config/master.key değerini gizli olarak girin; config/credentials.yml.enc ile eşleşmeli. |
| RAILS_ENV | production |
| RUBY_VERSION | 3.4.11 |
| BUNDLE_WITHOUT | development:test |
| WEB_CONCURRENCY | 0 (tek süreç) |
| RAILS_MAX_THREADS | 3; DB bağlantı havuzu da aynı değişkeni kullanır. |
| RAILS_LOG_TO_STDOUT | true; mevcut Rails 8 logger zaten daima STDOUT kullanır, bu değişkene bağımlı değildir. |
| PGSSLMODE | İsteğe bağlı; varsayılan require. Render'da disable yapmayın. |
| APP_HOST | İsteğe bağlı özel alan adı; çıplak hostname, protokol/path/port olmadan. |
| RAILS_LOG_LEVEL | İsteğe bağlı; varsayılan info. Production'da debug kullanmayın. |
| RENDER_EXTERNAL_HOSTNAME | Render otomatik sağlar; onrender.com hostname'i izin listesine eklenir. |
| PORT | Render otomatik sağlar; Puma 0.0.0.0 üzerinde dinler. |

SECRET_KEY_BASE_DUMMY'yi Render Environment'a eklemeyin. Yalnızca asset komutunun süresince script tarafından atanır; start script'i runtime'da bu değişken varsa hata verir. Ayrı SECRET_KEY_BASE girmek gerekmez; mevcut şifreli credentials/master key kullanılır. Anahtarı kaybetmeyin veya commit etmeyin. Anahtar değişimi eski oturum cookie'lerini geçersiz kılabilir.

[Render ortam değişkenleri](https://render.com/docs/environment-variables), [Ruby sürümü](https://render.com/docs/ruby-version).

## Build, start ve migration

Build Command:

```bash
bash bin/render-build.sh
```

Start Command:

```bash
bash bin/render-start.sh
```

Health Check Path: /up. Pre-Deploy Command: boş. Root Directory: repo kökü.

Build bundle install ve production assets:precompile çalıştırır; Tailwind hook'u dahildir. DB migration veya seed çalıştırmaz. Start gerekli değişkenleri doğrular, db:migrate çalıştırır ve başarılıysa exec ile Puma'yı başlatır. Migration hatası sunucunun açılmasını engeller. db:create, db:reset, db:drop, db:schema:load, db:prepare veya SQLite dönüşümü yapılmaz. Render Postgres kaynağını önceden oluşturun.

Ücretsiz web hizmetinde ücretli pre-deploy özelliği varsayılmaz. Start migration'ları ilk deploy ve yeniden başlatmalarda Rails migration kayıtlarıyla takip edilir. Eşzamanlı deploy başlatmayın; PostgreSQL migration kilidi çakışırsa ilk işlem bitince hatalı deploy'u yeniden deneyin. Uzun migration servis açılışını geciktirir. Gelecek şema değişiklikleri eski/yeni uygulama sürümleriyle aynı anda uyumlu olmalı. Kod rollback'i veritabanını geri almaz; önemli migration öncesi backup alın, otomatik yıkıcı rollback yapmayın.

[Pre-deploy kısıtları](https://render.com/docs/deploys), [PORT ve web servisleri](https://render.com/docs/web-services).

## Elle ilk deploy

1. Yerelde test, RuboCop, Zeitwerk ve Tailwind kontrollerini çalıştırın. Diff'i ve gizli dosyaların gitignored olduğunu inceleyin. Commit/push işlemini kendiniz yapın.
2. Render New → Postgres: isim, bölge, plan, storage ve fiyatı inceleyip kendiniz onaylayın. Kaynağın hazır olmasını bekleyin.
3. New → Web Service: Huseyinyagmur/signflow, main ve Ruby native runtime seçin. Dockerfile bulunduğundan otomatik Docker seçilmediğinden emin olun.
4. Postgres ile aynı bölgeyi, seçtiğiniz web planını, build/start komutlarını ve /up health path'ini ayarlayın. İlk kontrollü yayında otomatik deploy'u kapalı tutabilirsiniz.
5. Environment değişkenlerini girin. Internal DATABASE_URL ve doğru RAILS_MASTER_KEY kullanın. Pre-deploy alanını boş bırakın.
6. Ayarları ve ücretleri inceleyip servisi kendiniz oluşturun. Build, migration ve Puma loglarını izleyin; PORT binding ve /up kontrolünü doğrulayın.
7. Tek HTTPS hostname kullanın. Özel alan adı için önce Render Custom Domains/DNS ayarlarını tamamlayıp APP_HOST ekleyin ve yeniden deploy edin. onrender.com ve özel alan adı ayrı cookie/origin kapsamlarıdır.
8. Aşağıdaki tarayıcı kontrolünü yapın. İkinci deploy/restart sonrasında aynı hesap, belge ve şablonların durduğunu doğrulayın.
9. Backup/retention ayarlarını plan üzerinde doğrulayın ve geri yükleme prosedürü belirleyin. Kalıcı veritabanı tek başına backup garantisi değildir.

## Güvenlik ve kalıcılık

- Production tek PostgreSQL kullanır; dev/test aynı SQLite yapılandırmasında kalır. Production migration sonrası db/schema.rb dump edilmez.
- Dört migration PostgreSQL 18'de sıfırdan uygulandı. Foreign key, unique index ve CHECK kısıtları uyumludur; mevcut migration'ları değiştirmek gerekmedi.
- Uygulama sorgularında SQLite PRAGMA, strftime veya INSERT OR REPLACE yoktur. PRAGMA kullanan schema regresyonları SQLite test ortamındadır. Parametreli LIKE PostgreSQL'de geçerlidir; büyük/küçük harf eşleşmesi SQLite'tan farklı olabilir.
- Render TLS reverse proxy kabul edilir: assume_ssl ve force_ssl açıktır. Secure/HttpOnly/SameSite=Lax cookie, CSRF/origin ve Referrer-Policy same-origin korunur.
- Host listesi APP_HOST ve RENDER_EXTERNAL_HOSTNAME ile sınırlıdır; eksik/geçersiz runtime hostname açılışı durdurur. Yalnızca /up dahili health host/redirect denetiminden muaftır.
- İmza token'ı fragment üzerinden taşınır; POST token/parola parametreleri filtrelenir. Sözleşme metni, placeholder değerleri ve adlar da parametre loglarında filtrelenir. Başlıklar hâlâ loglanabilir; log erişimini sınırlayın.
- Domain kayıtları PostgreSQL'de kalıcıdır. Kullanılmayan Solid Cache/Queue/Cable production adaptörleri memory/async kullanır. Cache, async job ve ActionCable süreçler arasında paylaşılmaz, restart'ta kaybolur. Kalıcı job/çok instance ayrıca tasarlanmalı; bu kurulumda bin/jobs çalıştırmayın.
- Giriş/kayıt rate limit'i süreç belleğindedir; başlangıç tek süreciyle uyumludur. Yatay ölçekleme öncesi ortak limit deposu gerekir.
- Render dosya sistemi ephemeral'dir. Mevcut akış dosya yüklemiyor; ActiveStorage local gelecekte yüklenen dosyalara kalıcılık sağlamaz. Böyle bir özellikte object storage gerekir.
- Otomatik expiration scheduler kurulmadı. Erişim sırasında süre sonu kalıcı işlenir; süresi dolmuş belge imzalanamaz. Pasif pending kayıtları topluca işlemek için production yönetim ortamında bundle exec rails documents:expire ayrıca çalıştırılabilir. Ücretli cron oluşturulmaz.

## Deploy sonrası tarayıcı kabul kontrolü

- HTTPS ana sayfa → kayıt → giriş → dashboard; logo dashboard'a dönmeli.
- Manuel taslak oluştur/düzenle → alıcı ve gelecekte tarih → imzaya gönder.
- HTTPS linkini gizli pencere/başka tarayıcıda aç; metni gör, ad ve kabul ile imzala.
- Signed zamanı/adı görünmeli; gönderilmiş belge değiştirilememeli ve link tekrar kullanılamamalı.
- Şablon oluştur → değişkenler → önizleme → taslak → gönder → ayrı tarayıcıda imzala.
- Çıkış sonrası özel uçlar giriş istemeli; süresi dolmuş link reddedilmeli.
- Deploy/restart ardından aynı kayıtları kontrol et. DevTools'ta Secure cookie, HTTPS POST Origin ve CSRF aktarımını incele. Token'ı log/screenshot paylaşımına koyma.

Bu çalışmada Render browser/TLS ve Linux runtime testi yapılmadı. Yerel PostgreSQL production kontrolü in-process HTTPS istek simülasyonudur; JavaScript/browser yürütmez.

## Yerel PostgreSQL production kontrolü

script/check_render_production.rb yalnızca production, PostgreSQL, loopback host ve adı _production_check ile biten ayrı deneme DB'sinde çalışır. Deneme kayıtları oluşturur; canlı DB'ye yöneltmeyin. Minitest SQLite kalır. Ayrı PostgreSQL veritabanını önceden oluşturun ve production asset derlemesini tamamlayın.

PowerShell'de yalnızca ilgili shell için RAILS_ENV=production, APP_HOST=signflow.test ve ayrı deneme DATABASE_URL değerini ayarlayın. RAILS_MASTER_KEY veya mevcut gitignored config/master.key eşleşmeli. PGSSLMODE=disable yalnızca TLS olmayan izole loopback deneme cluster'ında kullanılabilir.

```powershell
bundle exec rails db:migrate
bundle exec rails runner script/check_render_production.rb
bundle exec rails zeitwerk:check
```

İş bitince shell'i kapatın; production environment ile SQLite test çalıştırmayın. Deneme script'i veri silmez; sadece ayrı deneme kayıtları ekler.

## Sorun giderme

| Belirti | Kontrol |
| --- | --- |
| Encryption key / decryption error | RAILS_MASTER_KEY ve credentials.yml.enc eşleşmesini kontrol edin; anahtarı loglamayın/yeniden üretip eskisini kaybetmeyin. |
| DATABASE_URL / bağlantı / SSL | Kaynak hazır mı, internal URL/bölge doğru mu, PGSSLMODE require mı? SSL kapatarak gizlemeyin. |
| Blocked hosts | APP_HOST çıplak hostname olmalı; RENDER_EXTERNAL_HOSTNAME mevcut olmalı. Wildcard ile tüm host'ları açmayın. |
| CSRF / null origin | Tek HTTPS host kullanın, eski formu yenileyin, Referrer-Policy same-origin kalsın. CSRF/origin kapatmayın. |
| Port scan / health | Ruby runtime, start komutu, PORT binding ve migration hatasını inceleyin. /up boot sağlığıdır; DB uçtan uca testi değildir. |
| Eksik CSS | Build assets:precompile/Tailwind loglarını kontrol edin. Shell script LF satır sonları .gitattributes ile korunur. |
| ruby.exe / shebang | Native Ruby kullanın; script bash ile, Rails bundle exec rails ile çalışmalı. Windows binstub'ını doğrudan çalıştırmayın. |
| cache DB not configured | Production memory cache kullanır; cache.yml içine eski database: cache bağlantısını geri eklemeyin. |
| Solid Queue tablo hatası | Production async kullanır; SOLID_QUEUE_IN_PUMA/bin/jobs açmayın. Kalıcı kuyruk ayrı altyapı ister. |
| Restart sonrası veri kaybı | Yanlış/geçici URL ve ücretsiz Postgres süresini kontrol edin. reset/schema:load yapmayın. |

Windows yerel kontrollerinde opsiyonel libvips modül DLL uyarıları ve Puma Unix sinyali uyarıları görüldü; kontroller tamamlandı. Linux Render'da aynı uyarıların olacağı/olmayacağı iddia edilmez.

## Bu hazırlıkta gerçek doğrulamalar (14 Ekim 2026)

| Komut/kontrol | Sonuç |
| --- | --- |
| bundle install | Başarılı; pg Windows/Linux lockfile varyantları eklendi, diğer bağımlılıklar yükseltilmedi. |
| bundle exec rails test | 92 test, 900 assertion, 0 failure, 0 error, 0 skip. SQLite test ortamı. |
| bundle exec rubocop | 68 dosya, ihlal yok. |
| bundle exec rails zeitwerk | Başarısız: Unrecognized command; çıkış kodu 1. |
| bundle exec rails zeitwerk:check | Başarılı: All is good! Ayrıca PostgreSQL production ortamında da geçti. |
| bundle exec rails tailwindcss | Başarısız: Unrecognized command; çıkış kodu 1. |
| bundle exec rails tailwindcss:build | Başarılı. |
| Production SECRET_KEY_BASE_DUMMY=1 ile assets:precompile | Başarılı; flag yalnızca ilgili shell/komutta kullanıldı. |
| Git Bash bash -n: iki Render script'i | Başarılı; Linux Render build/start işlemleri henüz çalıştırılmadı. |
| Ayrı PostgreSQL 18 DB: production db:migrate | Dört migration uygulandı; PostgreSQL kataloğunda beş foreign key ve iki CHECK doğrulandı. |
| Production runner script/check_render_production.rb | Başarılı: kayıt/giriş, secure cookie, manuel ve şablonlu signed akışı, kayıtsız önizleme, CSRF/origin reddi, token replay reddi, immutable belge, host, health ve çıkış. |
| Production Puma: PORT=3107 | 0.0.0.0:3107 dinledi; gerçek HTTP /up yanıtı 200. Kontrol sunucusu kapatıldı. |
| Development SQLite satır hash karşılaştırması | Değişmedi: 1 kullanıcı, 2 belge, 3 şablon, 3 sürüm. |

Production açılış kontrolü eski cache.yml içindeki database: cache bağlantısının eager loading sırasında hata verdiğini yakaladı; bağlantı kaldırıldı ve production runner/Zeitwerk yeniden başarılı çalıştı. Deneme PostgreSQL cluster'ı kapatıldı; dosyaları ignored tmp altında kaldı. Render kaynakları, gerçek TLS/browser/JavaScript ve uzaktaki CI bu çalışma sırasında çalıştırılmadı.
