# SignFlow Agent API — Aşama 1

25.10.2026. Bu katman deterministik şablon API'sidir; gerçek LLM entegrasyonu yoktur. [İlk plan](AGENT_FIRST_IMPLEMENTATION_PLAN.md) gelecekteki hedefleri, [Challenge](../CHALLENGE_LOG.md) gerçekleşenleri gösterir. Render'a yayınlanmadı.

## Güvenlik sınırı ve endpoint'ler

API, sunucunun ortamında `AGENT_API_ENABLED=true` olduğunda açılır. Değişken yoksa veya başka değerdeyse üç endpoint de 404. Flag değiştirildiğinde yerel web sunucusunu yeniden başlatın. Default web oturumu/CSRF/origin ayarları değiştirilmedi.

| Metot | Yol | İşlem |
| --- | --- | --- |
| GET | `/api/v1/templates/:template_id/versions/:id` | Kullanıcıya ait sabit sürümün ID/başlık/numara/değişken manifesti; tam metin verilmez. |
| POST | `/api/v1/drafts` | İzinli sürümden yalnız draft üretir; Idempotency-Key zorunlu. |
| GET | `/api/v1/drafts/:id` | Aynı kullanıcının AgentRequest kaydı olan belgesini okur; insan gönderdiyse güncel pending/signed/expired dönebilir. |

Yalnız `Authorization: Bearer` kimliği kabul edilir. Cookie, body veya query token'ı kimlik değildir. Başka kullanıcı kaynakları ve sahibinin manuel belgeleri 404. Agent için edit/send/sign endpoint'i yok. API token'ı web gönderim oturumu değildir. Yetkili insan mevcut web ekranında sözleşmeyi inceleyip kendi CSRF formuyla gönderir. Bu, teknik oturum sınırıdır; biyometrik insan ispatı değildir. Agent istemcisine parola/cookie/CSRF/imza linki verilmemeli.

Token `sf_agent_` ön eki + 32 rastgele baytın URL-safe gösterimidir. DB'de yalnız SHA-256 digest tutulur. Varsayılan ömür 7 gün, üst sınır 30 gün; tam son tarihte token geçersizdir. İptal geri alınamaz; owner/digest/son tarih güncellenemez, gerekirse yeni credential üretilir. API yanıtında imza linki/token/digest yoktur. Yanıtlar no-store'dur.

## Yerel hazırlık ve credential teslimi

Development/test SQLite korunur. Ek migration mevcut tablo kayıtlarını silmez/dönüştürmez:

```powershell
bundle exec rails db:migrate
```

Önceden var olan, size ait sentetik demo kullanıcısını ve şablon sürümünü kullanın. Bu aşamada kullanıcı credential yönetim ekranı veya halka açık credential oluşturma API'si eklenmedi. Operatörün yerel Rails erişimi gerekir:

```powershell
$env:AGENT_API_ENABLED='true'
$env:SIGNFLOW_OWNER_EMAIL='size-ait-demo-hesabi@example.com'
bundle exec rails runner script/issue_agent_credential.rb
bundle exec rails server
```

Bu araç parola/token yazdırmaz. Credential'ı **gitignored `tmp/agent-credential.json`** dosyasına tek kez teslim eder; dosya varsa üzerine yazmaz. Token DB'den geri alınamaz. Özel dosya token'ın tek yerel teslim kopyasıdır: ortak ekran/senkronize klasör kullanmayın, Windows NTFS ACL'yi yalnız hesabınızın okuyabildiği şekilde kontrol edin; `0600` NTFS ACL garantisi değildir. Hata halinde boş/eksik dosya oluşmuş olabilir; credential durumunu ve dosyayı özel olarak kontrol edin, dosyayı kaybettiyseniz ilgili credential'ı iptal edip yenileyin. Gerçek kullanıcı/production üzerinde bu çalışma sırasında provisioning yapılmadı.

İptal, owner kapsamlı operatör işlemiyle:

```powershell
$env:SIGNFLOW_CREDENTIAL_ID='iptal-edilecek-kaydin-id-si'
bundle exec rails runner "User.find_by!(email: ENV.fetch('SIGNFLOW_OWNER_EMAIL')).agent_credentials.find(ENV.fetch('SIGNFLOW_CREDENTIAL_ID')).revoke!"
```

`issue!` dönüşünü interaktif konsolda çıplak ifade olarak yazdırmayın. Parola veya token'ı komut satırına yapıştırmayın. Sızıntı şüphesinde iptal ve yenileme yapın.

## İstek ve idempotency

Gövde JSON nesnesi, en fazla 64 KiB; ID'ler pozitif JSON integer. Aşağıdaki ID'ler örnektir, kendi sabit sürüm ID'lerinizi kullanın:

```json
{
  "template_id": 12,
  "template_version_id": 28,
  "values": {"alici_adi": "Deniz", "hizmet": "Tasarım danışmanlığı", "ucret": "1000 TRY"},
  "document": {"title": "API demo", "recipient_email": "deniz@example.com", "expires_at": "2026-10-30T18:00:00+03:00"}
}
```

Values yalnız seçilen sürümün değişkenlerini içerir; sürümde hizmet dönemi alanları da varsa onları ekleyin. Document izinleri yalnız title/recipient_name/recipient_email/expires_at. Son tarih varsa offset içeren ISO8601 string olmalı; taslak eksik alıcı/tarihle oluşabilir, insan gönderiminde modelin zorunlu/gelecek tarih kuralları yine uygulanır. Örnek tarihi güncelliği kontrol edilmeden kullanmayın. Ücret/hizmet tarihi semantik doğrulaması veya hukuki kontrol eklenmedi.

Key 16–128 karakter, `[A-Za-z0-9_-]`; header adı `Idempotency-Key`. Aynı kullanıcı + create_draft + aynı key aynı iş anlamına gelir; key yeni credential'a geçince sıfırlanmaz. Payload hash anahtar sırasından bağımsızdır; string değerleri değiştirmek yeni payload sayılır.

- İlk başarı: 201, `replayed:false`.
- Aynı key/payload: 200, aynı belge ID, `replayed:true`, güncel status. İmzalanmış belge tekrar draft olmaz.
- Aynı key/farklı payload: 409, değişiklik yok.
- Eksik/bozuk key veya JSON: 400; yanlış content type 415; büyük gövde 413; geçersiz alan/değer 422; credential geçersiz 401; kaynak yok/yetkisiz 404.
- DB unique/lock yarış hatalarında 503; caller aynı key/payload ile sınırlı retry yapabilir. İstemci kör otomatik retry yapmaz. Beklenmeyen hatalar ham exception yerine genel 500 döner; SQL/credential ayrıntısı verilmez.

AgentRequest ve Document tek transaction içindedir; `user.with_lock` aynı sahibin create/replay ve revoke işlemlerini sıralar. DB unique index `(user_id, operation, idempotency_key_digest)` son korumadır. Kaydı oluştururken hata olursa belge de rollback olur. Kayıtlar otomatik silinmez. Farklı key ile iki kez verilen aynı semantik işi engellemez; global exactly-once iddiası yoktur.

## Deterministik gerçek HTTP demosu

Sentetik payload'ı `tmp/agent-demo.json` dosyasına koyun. Aynı işin yeniden çalıştırmasında **aynı dosya ve aynı key** kullanın. Terminalde token değeri yerine özel dosya okunabilir veya env boş bırakılıp maskeli giriş yapılabilir:

```powershell
$env:SIGNFLOW_BASE_URL='http://127.0.0.1:3000'
$env:SIGNFLOW_ALLOW_LOOPBACK_HTTP='true'
$env:SIGNFLOW_IDEMPOTENCY_KEY='my-local-demo-job-0001'
ruby script/agent_demo_client.rb tmp/agent-demo.json
```

`SIGNFLOW_API_TOKEN` yoksa etkileşimli terminal gizli giriş ister. Dosyadan okumayı tercih ederseniz özel terminalde `(Get-Content tmp/agent-credential.json -Raw | ConvertFrom-Json).token` değerini yalnız env değişkenine atayın; stdout'a yazdırmayın. Secret içeren env değişkenini iş bitince kaldırın ve demo credential'ını iptal edin. HTTPS dışındaki adresler varsayılan reddedilir; HTTP yalnız açık loopback izniyle kabul edilir. TLS doğrulaması açık, proxy ortamı devralınmaz, redirect izlenmez.

İstemci sırası: manifest GET → create → aynı key/payload replay → farklı payload 409 → GET güncel belge. Çıktı yalnız HTTP kodları, belge ID'si ve status; içerik/alıcı/anahtar yok. İlk create daha önce yapılmışsa 200 kabul eder. Timeout sonrası dosyayı/key'i değiştirmeden yeniden çalıştırın. Bu **LLM agent değil**, deterministik smoke istemcisidir; send/sign denemez.

## Gerçek doğrulamalar — 25.10.2026

| Kontrol | Sonuç |
| --- | --- |
| İlk test yazımı | Ruby blok çağrısında parantez eksikliği SyntaxError; test kodu düzeltildi. |
| Uygulama öncesi yeni test paketi | 16 run, 1 failure, 15 error; AgentCredential henüz yoktu. |
| İlk uygulama sonrası hedefli paket | 16 test / 158 assertion; 0 failure/error/skip. |
| Tam SQLite paketi | 113 test / 1100 assertion; 0 failure/error/skip. Eski sözleşme/şablon/CSRF testleri dahil. |
| İlk PostgreSQL agent paketi | 19 test / 178 assertion; 1 failure, 0 error. Testin global AgentRequest.count varsayımı, önceki yarış test kayıtlarını saydı. |
| Düzeltilmiş PostgreSQL 18 paketi | 19 test / 178 assertion; 0 failure/error/skip. İki ayrı bağlantılı aynı key yarışı ve farklı payload yarışı dahil. |
| HTTP smoke, gerçek yerel Puma + ayrı PG test DB | Manifest 200; create 201; replay 200; conflict 409; query 200/draft. İkinci istemci çalıştırması da aynı ID'yi verdi; ilk create artık 200. |
| HTTP iptal ve kapanış | Demo credential'ı iptal edildi; gerçek HTTP GET 401/unauthorized döndü. Açılan yerel Puma ve ayrı PostgreSQL cluster'ı kapatıldı. |
| Secret log taraması | Gerçek yerel HTTP demo token'ı `log/test.log` ve `log/development.log` içinde bulunmadı. Proxy/Render log kanıtı değildir. |
| RuboCop | 82 dosya, ihlal yok. |
| Zeitwerk | `bundle exec rails zeitwerk:check`: All is good! |
| Tailwind | `bundle exec rails tailwindcss:build`: başarılı. |
| Brakeman | Çıkış 0, raporda 0 error / 0 security warning. Ancak Windows Ruby Ractor/fork/forwardable tanılama mesajları çıktı; Linux CI sonucu yerine geçirilmez. |
| Yerel development migration | Yalnız yeni agent tabloları eklendi. Önce/sonra satır hash'leri aynı: 1 kullanıcı / 2 belge / 3 şablon / 3 sürüm. |

Tam test komutu `bundle exec rails test` (SQLite). PostgreSQL testi için yeni, yalnız size ait, boş loopback DB oluşturun; adı `*_agent_test` ile bitsin. Asla canlı URL kullanmayın:

```powershell
$env:RAILS_ENV='test'
$env:SIGNFLOW_AGENT_TEST_DATABASE_URL='postgresql://yerel-test-kullanicisi@127.0.0.1:55439/signflow_agent_test'
$env:SCHEMA='C:/signflow/tmp/agent-postgresql-schema.rb'
bundle exec rails db:migrate
bundle exec rails test test/models/agent_credential_test.rb test/integration/agent_api_test.rb test/postgresql/agent_concurrency_test.rb
```

Bu oturumdaki yerel PostgreSQL 18 cluster'ı `tmp/agent-stage1/postgres-data` içinde, yalnız 127.0.0.1:55439 üzerinde ayrı oluşturuldu. Trust auth yalnız bu yerel deneme cluster'ı içindir; production için öneri değildir. Yarış testleri rollback dışı sentetik kayıtlar bırakır; mevcut kayıt silmez. Normal testlere dönmeden env değişkenlerini kaldırın/yeni PowerShell açın. SQLite'a özgü PRAGMA testleri ayrı kaldı. `.github/workflows/ci.yml` ek PostgreSQL job'ını içerir; uzaktan tetiklenmedi, sonucu bilinmiyor.

## Aşama 2 öncesi açık konular

- LLM/model/tool döngüsü ve gerçek LLM maliyeti henüz yok. Mevcut istemciyi LLM diye sunmayın.
- API rate limit/kota, kullanıcı credential yönetim UI'sı ve otomatik credential temizliği eklenmedi. Genel kullanıma açmadan önce kota ve credential operasyonunu tasarlayın; DB idempotency kaydını key ömrü belirsiz biçimde temizlemeyin.
- Yerel dosya teslimi demo operatörüne yöneliktir; NTFS ACL ve güvenli secret store operasyonu kullanıcı tarafından kontrol edilmeli. Gerçek müşteri verisi/model sağlayıcısı aktarımı için ayrıca politika gerekir.
- CI'nin uzak sonucu, Render Auto-Deploy/plan/backup, canlı API/TLS/proxy logları ve canlı tarayıcı testi doğrulanmadı. Feature flag kapalı kalmalı; canlıya geçiş ayrı yetki ve kontrol ister.
- İnsan onayı teknik olarak yetkili web oturumu eylemidir. Agent'a cookie/parola verilirse bu sınır ortadan kalkar; ürün biyometrik insan kontrolü sunmaz.
- Yeni tablolardan sonra uzun süredir çalışan yerel Rails sürecini yeniden başlatın. Production migration/deploy yapılmadı; yeni SQLite/PG test sonuçlarını canlı başarı diye sunmayın.

## Dosya envanteri

| Dosya | Değişiklik |
| --- | --- |
| `app/models/agent_credential.rb` | Yeni token üretim/doğrulama, expiry/revoke ve sahiplik modeli. |
| `app/models/agent_request.rb` | Yeni salt okunur idempotency/mülkiyet kaydı. |
| `app/models/user.rb` | İki sahiplik ilişkisi eklendi. |
| `app/services/agents/create_draft.rb` | Girdi doğrulama, fingerprint, kilit/transaction, servislerden üretim ve replay. |
| `app/controllers/api/v1/base_controller.rb` | Bearer-only authentication, feature flag, güvenli yanıt/hata tabanı. |
| `app/controllers/api/v1/drafts_controller.rb` | Draft create/show. |
| `app/controllers/api/v1/template_versions_controller.rb` | Sabit sürüm manifesti. |
| `config/routes.rb` | Üç dar API endpoint'i. |
| `config/initializers/filter_parameter_logging.rb` | Yeni credential/header/veri filtreleri. |
| `config/database.yml` | Normal SQLite korunarak opt-in loopback PG test bağlantısı. |
| `db/migrate/20261025000100_create_agent_access.rb` | Ek tablolar, FK/CHECK/unique index. |
| `db/schema.rb` | Migration'ın ürettiği güncel SQLite şeması. |
| `script/agent_demo_client.rb` | LLM olmayan gerçek HTTP smoke akışı. |
| `script/support/agent_http_client.rb` | Güvenli host/TLS/redirect/timeout ve sınırlı çıktı taşıması. |
| `script/issue_agent_credential.rb` | Operatörün credential'ı stdout yerine özel yerel dosyaya teslim etmesi. |
| `test/models/agent_credential_test.rb` | Token, expiry, revoke ve immutable sahiplik testleri. |
| `test/integration/agent_api_test.rb` | API, isolation, idempotency, loglar, rollback, insan CSRF/signed akışı. |
| `test/lib/agent_http_client_test.rb` | Unsafe URL ve redirect sızıntısı reddi. |
| `test/postgresql/agent_concurrency_test.rb` | Opt-in iki bağlantılı eşzamanlı istekler. |
| `.github/workflows/ci.yml` | Mevcut job'lara ek izole PostgreSQL job'ı. |
| `AGENT.md`, `README.md` | Yeni aşama kuralları ve kullanım bağlantıları. |
| `CHALLENGE_LOG.md` | Prompt biçimi düzeltmesi, gerçek başarı/başarısızlıklar ve eksikler. |
| `docs/AGENT_API_STAGE1.md` | Bu kullanım/kanıt/dosya raporu. |

`docs/AGENT_FIRST_IMPLEMENTATION_PLAN.md` önceki planlama aşamasından zaten untracked olarak vardı; bu uygulama aşamasında içeriği değiştirilmedi. `tmp/agent-stage1/*`, yerel DB/log ve derlenmiş asset'ler ignored test artefaktlarıdır; Git'e eklenecek teslim dosyaları değildir. Ham token taraması Git-visible dosyalarda eşleşme bulmadı. Eski Document modeli, web Authentication concern'i ve session initializer SHA-256 karşılaştırmasında değişmedi. Secret'lar veya özel anahtar dosyaları rapora konmadı.
