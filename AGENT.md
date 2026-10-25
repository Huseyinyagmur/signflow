# SignFlow

SignFlow, sözleşme oluşturma ve demo elektronik imzalama akışını öğreten bir üniversite projesidir. Hukuken nitelikli elektronik imza, kimlik doğrulaması veya mevzuata uygunluk iddiasında bulunulmaz.

## Ortam ve kapsam

Windows 11, Ruby 3.4.11, Rails 8.1.4, SQLite ve Tailwind CSS kullanılır. PowerShell'de Rails komutları `bundle exec rails` ile çalıştırılır. Üçüncü aşama mevcut kayıt/giriş ve demo imza akışına kullanıcıya ait değişkenli şablonlar, sürüm geçmişi ve sunucu önizlemesi ekler.

## Mimari kararlar

- MVC korunur. Controller yalnızca HTTP, kimlik doğrulama ve parametrelerle ilgilenir; belge iş kuralları Document modelindedir.
- User, bcrypt / has_secure_password ile parola hash'i saklar. E-posta normalize edilir ve benzersizdir. Asgari parola uzunluğu 12 karakterdir.
- Documents::Manage, her sorguyu oturum kullanıcısının documents ilişkisi üzerinden yapar. Controller'dan Document.find çağırmayın; kullanıcı kimliğini istek parametresinden almayın.
- Durum grafiği: draft -> pending -> signed veya expired. Geçişler send_for_signature!, sign!, expire! metotlarıyla, veritabanı kilidi ve transaction içinde yapılır. update_columns, update_all ve doğrudan SQL model korumalarını atlar; iş akışında kullanmayın.
- Gönderimden sonra metin, alıcı ve süre değiştirilemez; belge sahibi hiçbir zaman değiştirilemez. Düzeltmeler için yeni bir taslak oluşturulur.
- 32 rastgele bayt içeren URL güvenli token yalnızca gönderim metodundan bir kez döner. Veritabanına SHA-256 hash'i yazılır. Token bir bearer yetkisidir; linki bilen kişi o belgeye erişebilir. Gerçek alıcı kimliği bu aşamada doğrulanmaz.
- Alıcı işlemlerinde Documents::Signing kullanılır; belge ID'si kabul edilmez. İmzalanmış, süresi dolmuş veya bilinmeyen token aynı RecordNotFound sonucunu verir. Token, signed / expired geçişinde silinir.
- Time.current kullanılır; son tarihe eşit anda imza kabul edilmez. Documents::Expiration, liste/detay ve alıcı erişiminde ilgili kapsamı kalıcı olarak günceller. Tüm belgeler için `bundle exec rails documents:expire` çalıştırılabilir. Güvenilir otomatik zamanlayıcı kurulmuş değildir; istek gelmeyen belgeler komut çalışana kadar veritabanında pending kalabilir, ancak imzalanamaz.
- Paylaşım linki `/sign#token=...` biçimindedir. Fragment HTTP isteğine girmez; Stimulus fragment'i geçmişten temizleyip token'ı CSRF korumalı POST gövdesiyle aktarır. Token şifreli oturum cookie'sinde tutulur. Path veya query token kullanmayın. Link gönderim yanıtında yalnızca bir kez gösterilir; DB hash'inden ham token geri üretilemez. Link sayfası no-store, Turbo snapshot'ları no-cache kullanır. Alıcı sayfaları noindex kullanır.
- Referrer-Policy uygulama genelinde config/application.rb üzerinden same-origin olarak tanımlanır. Layout meta etiketi veya controller ile no-referrer eklemeyin: normal HTML POST'larında Origin: null üreterek Rails origin doğrulamasını bozar. CSRF ve origin denetimi açık kalmalıdır. Regression testlerinde gerçek form token'ı ve Origin başlığı birlikte kullanılmalıdır; yalnızca tokensız POST testi yeterli değildir.
- SignatureAcceptance açık kabul ve en çok 120 karakterlik boş olmayan ad ister. Documents::Signing imzalamadan önce bu form nesnesini doğrular. signer_name ve signed_at aynı kilitli geçişte kaydedilir; bu ad bir doğrulanmış kimlik değildir. Eski iç model çağrıları için sign! varsayılan olarak recipient_name kullanabilir; herkese açık HTTP akışı her zaman girilen adı ve açık kabulü gerektirir.
- İmza formu kendi token'ını POST gövdesinde taşır; yalnızca oturumdaki son token'a güvenmeyin. Böylece aynı tarayıcıda farklı sözleşmelerin açık sekmeleri birbirinin belgesini imzalamaz.
- Oturum Rails şifreli cookie'sinde tutulur; giriş/çıkışta reset_session yapılır. HttpOnly, SameSite=Lax, 12 saatlik süre ve production'da Secure kullanılır. Rails CSRF koruması korunur. Giriş limiti süreç başına bellek deposundadır; çok süreçli dağıtımda ortak depoya taşınmalıdır. Cookie oturumlarında çalınmış cookie'nin sunucudan tek tek iptali bulunmaz; sonraki üretim aşamasında sunucu taraflı Session modeli değerlendirilmeli.
- Template kullanıcıya aittir; current_version_id güncel TemplateVersion'a işaret eder. Başlık, açıklama ve metin sürümde saklanır. Templates::Manage oluşturma/güncellemeyi transaction ve şablon satırı kilidiyle yapar. İlk oluşturma sırasında geçici boş current_version_id yalnızca transaction içinde bulunur. Versiyon numarası şablon içinde benzersiz ve pozitiftir.
- TemplateVersion kayıt sonrası readonly'dir; eski sürümler düzenlenmez veya silinmez. Her kaydetme yeni bir tam sürüm oluşturur. current_version yalnızca aynı şablona ait olabilir. Kullanıcı ve seed_key yeniden atanamaz; şablon silme uçları bu kapsamda yoktur.
- Templates::Manage tüm liste, arama, şablon ve sürüm sorgularını kullanıcının templates ilişkisi üzerinden sınırlar. Arama yalnızca güncel sürümün başlık/açıklamasında parametreli LIKE ile yapılır; wildcard karakterleri escape edilir.
- Templates::Renderer yalnızca alici_adi, hizmet, ucret, baslangic_tarihi, bitis_tarihi adlarını kabul eder. {{alan_adi}} veya {{ alan_adi }} biçimi kullanılır. Bozuk/bilinmeyen yer tutucular, eksik/boş/fazla veya string olmayan değerler reddedilir. Değiştirme tek geçişli düz metin işlemidir; Ruby/ERB çalıştırma, eval veya recursive interpolation kullanılmaz. Sonuç HTML olarak yorumlanmaz; ERB escaping korunur.
- TemplateRevision, şablon editörünün doğrulanan form nesnesidir. Şablon metni en fazla 50000, alan değeri en fazla 5000 karakterdir. Tekrarlanan alan yalnızca bir kez sorulur. Önizleme ve kaydetme aynı sunucu renderer'ını kullanır; istemciden content kabul edilmez.
- Documents::Manage#build_from_template, sürümün sahibiyle belge sahibini doğrular ve başlık/metnin bağımsız kopyasını oluşturur. Document.template_version_id kaynak sürüme işaret eder ve belge oluşturulduktan sonra değiştirilemez. Manuel belge oluşturma geçerlidir; bu belgelerin kaynak sürümü boş olabilir. Taslak metni sonradan elle düzenlenebilir, şablon düzenlemesi mevcut belgeleri güncellemez.
- Oluşturma formu version_id ile açıldığı sürüme sabitlenir; kullanıcı formu doldururken güncel şablon değişse bile aynı sürüm kullanılır. Farklı şablon veya başka kullanıcıya ait version_id reddedilir. Birden fazla POST action'ı kullanan önizleme/kaydetme formu Rails'in oturuma bağlı global form_authenticity_token değerini taşır; CSRF ve origin kontrolü kapatılmaz.
- Templates::DemoSeeder üç ders örneğini kullanıcı başına sabit seed_key ile ekler. Yeni web kayıtları Users::Register üzerinden kullanıcı + üç şablon/sürümü aynı transaction'da oluşturur; şablon hatasında hesap da rollback edilir. User callback'i veya eski hesaplar için otomatik toplu backfill yoktur. Şablonsuz eski hesap AI sayfasındaki CSRF/session korumalı prepare_templates POST'u ile açıkça başlangıç setini ekleyebilir; GET veri yazmaz. db:seed mevcut kullanıcıları işler ancak deploy'a otomatik seed eklemeyin. Seed tekrarı mevcut veriyi veya kullanıcının düzenlediği örneği değiştirmez; mevcut seed kaydının geçerli sürümü yoksa üzerine yazılmaz, IncompleteTemplate ile güvenli hata verilir. Demo hesap/parola oluşturmayın. Ayrıntı: [yeni kullanıcı AI şablonları](docs/NEW_USER_AI_TEMPLATES.md).

## Kodlama ve test

- Rails adlandırmalarına uyun; servisler app/services altında olmalı. Hassas alanları JSON'a otomatik dökmeyin.
- Ham token ve parolayı loglamayın, kaynak koduna veya seed'e yazmayın. Token parametreleri mevcut filter_parameters tarafından filtrelenir. Alıcıya sözleşme kimliği üzerinden erişim vermeyin. ERB otomatik escaping korunmalı; sözleşme içeriğine veya imzalayan adına raw / html_safe uygulamayın.
- Zaman testlerinde travel_to / travel bloklarını kullanın; sleep veya sabit bugünün tarihini kullanmayın. Mikrosaniyeli son tarih sınırlarında `travel_to deadline, with_usec: true` kullanın; varsayılan travel_to mikrosaniyeleri sıfırlar.
- Yeni belge uçları için sahiplik ve yetkisiz erişim testleri ekleyin. Model, servis ve oturum testlerini gerçekten çalıştırın; çalışmayan kontrolleri başarılı göstermeyin.
- SQLite yazmaları ve zaman testleri Windows'ta tek worker ile çalışır.
- Şema değiştiren migration sonrasında çalışan Rails sunucusunu tamamen yeniden başlatın. Ayrı db:migrate/runner süreci web sunucusunun Document sütun önbelleğini yenilemez. Sütun yok hatasında önce gerçek SQLite PRAGMA bilgisi, migration durumu ve temiz runner sürecini karşılaştırın. Her istekte reset_column_information çağırmayın, alanı atlayarak hatayı gizlemeyin ve mevcut sütun için tekrar migration eklemeyin. Veri değiştirmeyen tanılama: bundle exec rails runner script/check_template_schema.rb. Regresyonlar SQLite kataloğunu ve kayıtsız önizleme → kayıt → signed akışını doğrular.

PowerShell komutları:

```powershell
bundle install
bundle exec rails db:migrate
bundle exec rails db:prepare RAILS_ENV=test
bundle exec rails db:seed
bundle exec rails test
bundle exec rails zeitwerk:check
bundle exec rails tailwindcss:build
bundle exec rails documents:expire
bundle exec rubocop
```

## GitHub Actions CI

- .github/workflows/ci.yml main push ve main hedefli pull_request olaylarında çalışır. Ubuntu 24.04, ruby/setup-ruby@v1, Ruby 3.4.11 ve bundler-cache kullanılır. Gemfile.lock Windows ve x86_64-linux platformlarını içerir; CI sırasında bundle update veya lockfile yeniden üretme kullanmayın.
- Workflow RAILS_ENV=test ile SQLite test veritabanını hazırlar. Native bağımlılıklar: build-essential, pkg-config, libsqlite3-dev, sqlite3, libvips-dev. CI komutları: bundle exec rails db:prepare; bundle exec rails zeitwerk:check; bundle exec rails test; bundle exec rubocop -f github.
- Mevcut Brakeman, Bundler Audit ve Importmap audit işleri korunur. Windows binstub'larındaki ruby.exe shebang'ini Linux'ta doğrudan çalıştırmayın; gerekli wrapper'ları bundle exec ruby bin/... ile çağırın.
- Test veya kontrol hatalarını continue-on-error, || true veya exit 0 ile gizlemeyin. Uzaktaki CI sonucunu yerel testten tahmin etmeyin. Actions run ve commit bilgisini doğrulamadan uzaktaki işi başarılı raporlamayın.
- İsteğe bağlı yerel CI benzetiminde PowerShell için $env:CI="true" ve $env:RAILS_ENV="test" kullanın; iş bitince önceki ortam değerlerini geri yükleyin. rails zeitwerk tanımlı değildir; gerçek kontrol zeitwerk:check'tir.
- Kullanıcı istemedikçe commit, push, workflow_dispatch, merge veya deploy yapmayın. Projede test/system bulunmadığından tarayıcı testi sonucu iddia etmeyin.

## Render production hazırlığı

- Kurulum: [docs/RENDER_DEPLOYMENT.md](docs/RENDER_DEPLOYMENT.md). Yalnızca hazırlık yetkilendirildi; Render hesabında işlem/kaynak oluşturma, deploy, commit veya push yapmayın.
- Dev/test SQLite kalır; production DATABASE_URL üzerinden PostgreSQL kullanır. SQLite verilerini silmeyin/dönüştürmeyin. Production db/schema.rb dump edilmez.
- Native Ruby 3.4.11; build: bash bin/render-build.sh; start: bash bin/render-start.sh; health: /up. Pre-deploy varsayılmaz. Build assets derler; start db:migrate sonrası exec Puma çalıştırır. Seed/reset/drop/schema:load eklemeyin.
- Secrets yalnızca Environment: DATABASE_URL, RAILS_MASTER_KEY. RAILS_ENV, RUBY_VERSION, BUNDLE_WITHOUT, WEB_CONCURRENCY, RAILS_MAX_THREADS, RAILS_LOG_TO_STDOUT rehberde açıklanır; APP_HOST, PGSSLMODE, RAILS_LOG_LEVEL isteğe bağlıdır. Render PORT ve RENDER_EXTERNAL_HOSTNAME sağlar. SECRET_KEY_BASE_DUMMY runtime'a taşınmaz.
- HTTPS/assume_ssl/force_ssl, Secure cookie, same-origin, CSRF/origin ve host listesi korunur. PGSSLMODE production'da require kalır; disable yalnızca ayrı local loopback cluster'ında kullanılabilir.
- Production memory cache, async ActiveJob/ActionCable kullanır. Solid adaptörleri/bin/jobs açılmamalı; kalıcı job veya çok instance ayrıca tasarlanır. Domain kayıtları PostgreSQL'dedir.
- render.yaml yoktur. Ücretli plan/fiyat kullanıcı tarafından oluşturma sırasında onaylanır. Ücretsiz 30 günlük PostgreSQL kalıcı hedef değildir. Mevcut Docker/Kamal iskeleti native Render yolu değildir.
- bin/render-*.sh LF satır sonlarını .gitattributes ile koruyun. Windows ruby.exe shebang'li binstub'ları Linux'ta doğrudan çalıştırmayın.
- Kontroller: bundle exec rails test; bundle exec rubocop; bundle exec rails zeitwerk:check; bundle exec rails tailwindcss:build. Eksik zeitwerk/tailwindcss komutlarını başarılı raporlamayın.
- script/check_render_production.rb yalnızca ayrı loopback *_production_check PostgreSQL DB'sinde production runner ile çalışır; deneme kayıtları ekler. Canlı DB'de çalıştırmayın. Komut/ortam ayrıntıları rehberdedir.
- /up yalnızca boot sağlığıdır. Gerçek browser/JS/TLS, restart sonrası kalıcılık ve backup geri yükleme deploy sonrası ayrıca doğrulanır. Yerel başarı uzaktaki başarı değildir. Migration rollback otomatik yapılmaz; backup ve eski/yeni sürüm uyumluluğu değerlendirilir.

## SignFlow Agent — Aşama 1 (25.10.2026)

- Kullanıcının onayladığı yeni kapsam dar bearer API'dir; LLM/ücretli servis/Render deploy bu aşamaya dahil değildir. Önceki AI kapsam yasağı gerçek LLM için sürer.
- Rehber: [docs/AGENT_API_STAGE1.md](docs/AGENT_API_STAGE1.md). `AGENT_API_ENABLED` tam olarak `true` değilse API 404 döner. Web oturumu, CSRF/origin ve mevcut geçiş kuralları değiştirilmez.
- API `ActionController::API` tabanında cookie'den kullanıcı üretmez; send/sign/edit endpoint'i eklemeyin. Kullanıcı sahipliği Templates::Manage ve Documents::Manage üzerinden sınırlandırılır; yalnız AgentRequest ile ilişkilendirilmiş belgeler okunur.
- AgentCredential 32 rastgele baytlı token'ın yalnız SHA-256 özetini saklar; varsayılan 7 gün, azami 30 gün; iptal geri alınmaz. Kimlik ve süre kayıt sonrası değişmez. Ham token konsol çıktısı/parametre/URL/log/model context'ine girmez.
- AgentRequest + Document aynı kullanıcı kilidi/transaction içindedir; owner/operation/key digest benzersiz DB index'i korunur. Aynı payload replay; farklı payload 409. İdempotency kayıtlarını otomatik silmeyin. Ağ hatasında aynı key ve aynı payload ile tekrar deneyin; yeni key mükerrer iş oluşturabilir.
- `script/agent_demo_client.rb` deterministik HTTP smoke istemcisidir, LLM agent değildir. Provisioning aracı `script/issue_agent_credential.rb` yalnız operatör içindir; token'ı gitignored tmp dosyasına özel olarak teslim eder. Windows'ta NTFS ACL ayrıca kontrol edilir; POSIX 0600 tek başına Windows izin garantisi değildir.
- Normal testler SQLite kalır. Ayrı PostgreSQL testi yalnız loopback ve `*_agent_test` DB'yi kabul eden `SIGNFLOW_AGENT_TEST_DATABASE_URL` ile açılır; production URL kullanmayın. Komut: `bundle exec rails test test/models/agent_credential_test.rb test/integration/agent_api_test.rb test/postgresql/agent_concurrency_test.rb`. Ayrı dump için `SCHEMA` ignored tmp dosyasına yönlendirilir.
- Tam regresyon: `bundle exec rails test`; lint: `bundle exec rubocop`; autoload: `bundle exec rails zeitwerk:check`. `.github/workflows/ci.yml` ek agent_postgresql job'ını içerir; uzaktan çalışmadıkça başarılı raporlamayın.

## SignFlow Agent — Aşama 2 (25.10.2026)

- Kullanıcının yeni talebi, yalnız yerel Ruby LLM istemcisini ve testlerini yetkilendirir. Ücretli model çağrısı, commit, push ve Render deploy ayrıca yetkilendirilmiş değildir. Önceki aşamaların LLM yasağı bu istemci geliştirmesi için genişletilmiştir.
- `script/signflow_agent.rb`, Rails'ten bağımsızdır. Yalnız get_template_version / create_draft / get_draft; shell, SQL, keyfi HTTP, cookie, CSRF veya send/sign aracı eklemeyin. `script/agent_demo_client.rb` deterministik istemci olarak kalır.
- Rehberler: [docs/AGENT_LLM_STAGE2.md](docs/AGENT_LLM_STAGE2.md), [docs/AGENT_LLM_DEMO.md](docs/AGENT_LLM_DEMO.md). Gerçek model çağrısı yoksa LLM başarısı diye raporlamayın. Fake provider testleri model zekâsını kanıtlamaz.
- Anthropic anahtarı yalnız sabit sağlayıcı transport'una, SignFlow anahtarı yalnız sabit API host'una gider; model bağlamına veya loga girmez. Env veya maskeli console girişi; gerçek `.env` ignored, `.env.example` yalnız isim/örnektir, otomatik yüklenmez. Rails development artık development grubundaki dotenv-rails ile `.env` yükler; mevcut process ENV önceliklidir. Test/production yerel dotenv dosyası yüklemez; Render Environment Variables kullanır. Bağımsız Ruby CLI otomatik dotenv yüklemez. Gerçek `.env`/anahtar içeriğini incelemeyin veya loglamayın; testler yalnız geçici sentetik dosyalarda çalışmalıdır.
- Yeni LLM çalıştırması `SIGNFLOW_SYNTHETIC_DATA=true` ve kullanıcının ücret izni anlamına gelen `SIGNFLOW_ALLOW_PAID_LLM=true` ister; kodlama ajanı bunu gerçek ücretli deneme için kendiliğinden açmaz. Model erişimi hesapta preflight yapılmadan varsayılmaz.
- Model alanları kullanıcı mesajına dayanmalı, ücret tam açık TL/TRY/₺ ifadesiyle korunmalı; eksik alanlar sorulur. Taslak öncesi yerel alan onayı ayrıca gerekir. Bu, doğru hukuki/semantik çıkarım garantisi değildir; web incelemesi/gönderimi korunur.
- `tmp/llm-jobs` içindeki özel job kaydı secret içermez ama sentetik payload içerir. Kimlik/binding/key ve payload korunur; timeout sonrası aynı job ile `--resume` kullanılır. Yeni key üretmek/alanları değiştirerek sessiz retry yapmak yok. Resume deterministik API recovery'dir, yeni LLM çağrısı değildir.
- Normal CI gerçek LLM'e erişmez; testlerde fake provider kullanılır. Kullanım: `bundle exec rails test`; PostgreSQL job'ı yeni handoff testini de kapsar. Canlı billing/usage ve Render kanıtını bu testlerden çıkarmayın.

## SignFlow Agent — Aşama 3 hazırlığı (25.10.2026)

- Credential UI `AgentCredentialsController` ve `Agents::Credentials` ile current_user kapsamında çalışır. Yalnız label/1-7-30 günlük süre alınır; ham token yalnız create POST yanıtındadır, flash/session/URL/DB'ye taşınmaz. Liste hash göstermez. no-store/noindex/Turbo no-cache ve CSRF/origin korunur.
- API flag kapalıyken yeni credential oluşturulmaz; oturum sahibi mevcut erişimlerini listeleyebilir/iptal edebilir. İptal incident sırasında flag'den bağımsız kalmalı; agent bearer'ı web kimliği değildir.
- `Agents::RateLimiter`: credential başına ayrı 60 GET/HEAD ve 10 POST / 60 saniye, process-local Mutex + MemoryStore. Replay ve validation başarısızlıkları da sayılır; 429 Retry-After döner. Restart/eviction reset, çok process/instance ortak kota değildir. DB idempotency/iptali kota belleğine taşımayın; auth/iptal kontrolü kotadan önce kalmalıdır.
- Rehberler: [docs/AGENT_STAGE3_REPORT.md](docs/AGENT_STAGE3_REPORT.md), [docs/REAL_LLM_QUICKSTART.md](docs/REAL_LLM_QUICKSTART.md), [docs/RENDER_AGENT_RELEASE_CHECKLIST.md](docs/RENDER_AGENT_RELEASE_CHECKLIST.md). Gerçek anahtar/LLM/Render API veya production işlemi, ücretli servis, commit/push/deploy bu görevde yoktur. Public doküman model kontrolünü hesap erişimi gibi sunmayın.
- Test helper memory kotasını integration testleri arasında temizler; bu API'den erişilen bir reset endpoint'i değildir. PG CI job'ı UI/kota/iptal ve concurrency testlerini de kapsar; uzak sonucu çalışmadan başarılı göstermeyin.

## Gemini sağlayıcısı (25.10.2026)

- `SIGNFLOW_LLM_PROVIDER=gemini` açık model ID'si ister; belirtilmezse Anthropic varsayılanı sürer. Üç araç, Runner/Tools, EVET, web gönderimi, kota ve DB idempotency sınırları korunur. Gemini/Anthropic ortak system policy'si `llm/policy.rb` içindedir.
- Gemini free varsayılanı gerçek free/billing-off proje teyidi için `SIGNFLOW_GEMINI_FREE_TIER_CONFIRMED=true` ister; uygulama Cloud Billing'i okuyamaz/ücretsiz-only isteği garanti edemez. Paid modunda ayrıca `SIGNFLOW_ALLOW_PAID_LLM=true` gerekir. Fallback/ücretli yükseltme yok. Kamuya açık free model allowlist'i hesap erişimi kanıtı değildir.
- Gemini key yalnız `GEMINI_API_KEY` env veya maskeli giriş, sabit Google host'una x-goog-api-key header'ı; modele/loga/URL'ye/job'a yazılmaz. Model functionCall/Response ve opaque thoughtSignature'lar adaptörde dönüştürülür; Runner'a signature eklemeyin, iş kaydına/kanıt loguna koymayın.
- Bu görevde gerçek ücretsiz/ücretli Gemini çağrısı da yasaktır; kullanıcı kendi terminalinde [docs/GEMINI_INTEGRATION.md](docs/GEMINI_INTEGRATION.md) rehberini uygular. Key aramayın/okumayın, fake testleri gerçek model başarısı diye sunmayın. Free tier'da gerçek müşteri/kişisel/gizli veri gönderilmez.

## SignFlow AI web kapsamı (25.10.2026)

- Kullanıcının yeni görevi mevcut yerel LLM istemcisini session doğrulamalı web arayüzüne genişletir; önceki CLI-only kapsam bu web geliştirmesi için genişletilmiştir. Gerçek model çağrısı/key arama veya okuma, production DB, commit/push/deploy yetkisi verilmez.
- Rehberler: [web raporu](docs/AI_CONTRACT_WEB_REPORT.md), [güvenli demo](docs/AI_CONTRACT_WEB_DEMO.md). `AI_CONTRACTS_ENABLED` varsayılan kapalı; web bearer veya kendi API'sine HTTP istemez. Current_user/CSRF/origin kontrolleri korunur. AI send/sign endpoint'i eklemeyin.
- Shared Runner/Tools/GeminiProvider/Manage/Renderer kullanılır. `Runner#advance` create_draft önerisinde yazmadan durur; web controller `confirm_proposal!` çağırmaz. Yalnız ayrı insan POST'u server-side öneriyi yeniden doğrulayarak `AiContracts::CreateDraft` ile kaydeder. Model/client payload'ını doğrudan yazmayın.
- Konuşma DB receipt'i yalnız owner, sabit version, UUID/TTL ve document FK tutar; chat/model yanıtı/secret DB'ye konmaz. Receipt'leri otomatik silmeyin. Konuşma satır kilidi ve unique index'ler/transaction korunur. Mesaj step+digest replay'ini atlayıp yeniden model çağırmayın.
- Diyalog/opaque signature durumu bellekte, mantıksal TTL bir saat, en fazla 64/süreç; eski girdiler sonraki start/state erişiminde temizlenir. Restart/reload/farklı worker durum kaybettirir; açık hata gerekir. DB receipt tamamlanmış belgeyi belleksiz kurtarır. Çok instance için ortak güvenli durum/kota tasarlanmadan bu demo ölçeklenmez.
- Kullanıcı başına fixed 10 dakikada 5 start ve 24 provider işlemi; preflight ve başarısız çağrılar sayılır. Kota süreç bazlıdır; dolar/fatura üst sınırı değildir. Model/input/tool sınırları, sentetik veri ve free/paid izinleri korunur. Runtime secret yalnız backend'dedir; env dump/debug model logu yoktur.
- Yeni testler tam `bundle exec rails test` ile çalışır. PG CI job'ı web integration/service ve `test/postgresql/ai_contract_concurrency_test.rb` içerir; yalnız loopback *_agent_test opt-in DB. Lint/zeitwerk:check/tailwindcss:build komutları korunur. Fake testleri gerçek Google/browser başarısı diye sunmayın.

## Korunan genel kapsam sınırları

- Mevcut Rails projesini silmeyin, yeniden üretmeyin veya kullanıcı dosyalarının üzerine topluca yazmayın.
- Kullanıcı talebi olmadan db:drop / db:reset, force push, deploy veya GitHub'a push yapmayın.
- PDF, gerçek e-posta servisi, gelişmiş şablon iş akışları, ödeme veya deploy eklemeyin. Yerel LLM istemcisi yalnız yukarıdaki Aşama 2 kurallarıyla sınırlıdır; gerçek ücretli çağrı ayrıca kullanıcı izni ister. Temel değişkenli şablonlar ve sürüm geçmişi korunur.
- Yetkilendirmeyi istemciye bırakmayın; sahibin belge sorgularını global kapsamdan yapmayın.
- Demo onayını hukuken nitelikli elektronik imza olarak sunmayın.
