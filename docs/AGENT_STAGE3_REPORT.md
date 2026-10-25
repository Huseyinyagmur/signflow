# Aşama 3 hazırlığı — credential yönetimi ve API kotası

25.10.2026. Başlangıç yerel commit: `7878ea949b75c3bd80f295bd82ca7ed43ee071a5` (`feat: add LLM agent client with safe tool calling`). Yeni kod commit edilmedi. Gerçek Anthropic/Render API çağrısı, ücretli servis, production DB işlemi, push/deploy yapılmadı.

## Uygulananlar

- **GET `/agent_credentials`**: web oturumu sahibinin erişimlerini listeler; hash/token göstermez.
- **POST `/agent_credentials`**: API flag açıkken label ve izinli 1/7/30 günlük süreyle mevcut AgentCredential.issue! kullanır. Sahip daima current_user'dır. Raw token yalnız bu POST yanıtında gösterilir; GET show endpoint'i, flash/session/URL saklaması yoktur. Yenileme/yeni POST yeni credential oluşturabilir; eski token hash'inden yeniden gösterim mümkün değildir.
- **POST `/agent_credentials/:id/revoke`**: owner kapsamlı iptal. CSRF ve Origin kontrolü korunur. İptal kalıcıdır; API kapalıyken de liste/iptal çalışır. Bearer token web oturumu değildir.
- Sayfalar no-store/noindex, token paneli data-turbo-temporary; layout'ın mevcut Turbo no-cache meta'sı korunur. Formlar Rails helper + CSRF; hassas oluşturma/iptal formları Turbo kullanmaz. Referrer-Policy same-origin değişmedi. Tarayıcı/OS ekran kaydı veya kullanıcı kopyası sunucudan geri silinemez; özel token ekranı paylaşılmaz.
- `Agents::Credentials`: liste/oluştur/iptal sahiplik ve süre politikası. Modelin mevcut hash-only token, immutable identity, maksimum 30 gün, expiry/revoke kuralları yeniden yazılmadı. Anahtar ayarı/model key'i istenmedi veya kaydedilmedi; yalnız test DB'lerinde sentetik credential'lar üretildi.
- **Kota:** authenticated credential başına ayrı read/write fixed window. İlk istekte başlayan 60 saniyede GET/HEAD manifest+draft toplam 60; draft POST toplam 10. Başarısız doğrulama ve replay POST'ları da sayılır. 429 `{error:rate_limit_exceeded}` + Retry-After saniyesi + no-store. Başka credential'ın sayacı ayrıdır; aynı sahibin döndürülmüş credential'ıyla replay yine aynı DB idempotency kaydını bulur.
- Kota auth/expiry/iptal denetiminden sonra uygulanır. İptal edilmiş credential, kota dolu olsa da 401 alır. DB transaction/unique index ve insan gönderim sınırı değiştirilmedi.

## Kota sınırı

Mutex + 2 MiB MemoryStore yalnız tek süreçte atomik sayaç sağlar. Restart, cache eviction veya yeni process kota resetler; çok instance/Puma worker ortak sınır değildir. İptal ve idempotency PostgreSQL/SQLite'da kalıcı kalır. Bu, üretim DDoS/IP koruması veya kullanıcı genelinde harcama kotası değildir. Daha çok process/instance için shared store/edge çözümü gerekir; yeni ücretli servis açılmadı.

CLI iki transport denemesi ve 0,5 sn backoff kullanıyor; tüm 60 sn kota penceresini beklemez. 429 sonrası aynı job/key/payload korunarak bekleyip `--resume` kullanılmalı. Yeni key ile kota/idempotency atlanmaz.

## Testler ve başarısız denemeler

| Kontrol | Gerçek sonuç |
| --- | --- |
| Test-first, henüz UI/kota yokken | 9 test / 75 assertion, 2 failure, 7 error. Eksik routes/limiter ve 429 yerine 200 beklenen başlangıç başarısızlıkları. |
| İlk uygulama sonrası | 9 test / 153 assertion, 3 failure, 2 error. Testte CSRF form token'ının yanlış action'a taşınması, 422 sonrası olmayan formdan token okuma, textarea ilk newline'ı ve iç içe travel_to düzeltildi; CSRF kapatılmadı. |
| Düzeltilmiş ilk hedefli paket | 9 test / 190 assertion, 0 failure/error/skip. Sonra HEAD ve iptal-kota sırası kapsamı eklendi. |
| Tam `bundle exec rails test` | **140 test / 1404 assertion, 0 failure/error/skip**. Önceki tüm model/API/LLM fake-provider ve imzalama testleri dahil. |
| API güvenlik/credential/iptal/kota hedefli paket | **27 test / 357 assertion, 0 failure/error/skip**. |
| Ayrı PostgreSQL 18 genişletilmiş paket | **30 test / 387 assertion, 0 failure/error/skip**. İki bağlantılı idempotency yarışı ve yeni UI/kota dahil. |
| `bundle exec rubocop` | **98 dosya, 0 ihlal**. |
| `bundle exec rails zeitwerk:check` | All is good! |
| `bundle exec rails tailwindcss:build` | Başarılı. |

Windows opsiyonel libvips DLL ve Rack literal string uyarıları görüldü; başarısız test gibi sayılmadı veya gizlenmedi. UI testleri gerçek ERB/formları Rails integration stack'inde render etti; manuel tarayıcı/görsel/Render doğrulaması yapılmadı. Uzak Actions çalıştırılmadı; yeni dosyalar SQLite job'ında toplanır, PostgreSQL job'ına hedefli dosyalar eklendi.

## Anthropic hazırlığı ve canlı yayın

Kod yapılandırması incelendi: sabit HTTPS api.anthropic.com, Models preflight, sabit model ID, 2023-06-01 header, maskeli secret okuma, ücret/sentetik veri guard'ları ve sessiz fallback olmaması korunuyor. 25.10.2026 [resmî model sayfası](https://platform.claude.com/docs/en/models/haiku-4-5/overview) `claude-haiku-4-5-20251001` için Active (legacy), $1/1M input ve $5/1M output gösterdi. Kamuya açık belge kontrolü hesap erişimi değildir. Gerçek Models/Messages çağrısı **0**, gerçek token usage yok; bu çalışmanın ücretli LLM çağrı maliyeti 0 $, hesap faturası denetlenmedi.

Kullanıcı için [kısa gerçek LLM rehberi](REAL_LLM_QUICKSTART.md), [Render kontrol listesi](RENDER_AGENT_RELEASE_CHECKLIST.md) hazır. Dashboard erişimi/Auto-Deploy/backup/canlı SHA/migration durumu bilinmiyor. Bu aşama migration eklemedi; production'a komut çalıştırılmadı. Uzakta Aşama 1 migration'ı uygulanmış mı, kullanıcı ayrıca doğrulamalı.

## Dosya envanteri

| Dosya | İşlev |
| --- | --- |
| `app/controllers/agent_credentials_controller.rb` | Oturum/CSRF korumalı index/create/revoke, tek POST token yanıtı. |
| `app/services/agents/credentials.rb` | Kullanıcıya ait kayıtlar ve izinli geçerlilik süreleri. |
| `app/views/agent_credentials/index.html.erb`, `created.html.erb` | Liste/oluştur/iptal ve özel tek gösterim sayfası. |
| `app/services/agents/rate_limiter.rb` | Thread-safe, tek süreçli credential read/write kotası. |
| `app/controllers/api/v1/base_controller.rb` | Authentication sonrası kota ve 429/Retry-After. |
| `config/routes.rb`, `app/views/layouts/application.html.erb` | Yönetim rotaları ve Agent erişimi menüsü. |
| `test/integration/agent_credentials_test.rb` | CSRF/origin, owner isolation, tek gösterim, token iptali, flag kapalı davranışı. |
| `test/integration/agent_rate_limit_test.rb`, `test/services/agent_rate_limiter_test.rb` | Kota/HEAD, sınır zamanı, replay, credential ayrımı, iptal sırası ve thread yarışı. |
| `test/test_helper.rb` | Integration testleri arasında process sayacını temizler; production davranışını değiştirmez. |
| `.github/workflows/ci.yml` | PG job'ına yeni hedefli testler. |
| `CHALLENGE_LOG.md`, `AGENT.md`, `README.md` | Güncel durum, yeni kurallar ve gerçek kayıtlar. |
| `docs/AGENT_LLM_STAGE2.md`, `docs/AGENT_LLM_DEMO.md` | Eski Aşama 2 raporunun tarihsel kapsamı ve yeni credential ekranına yönlendirme. |
| `docs/AGENT_STAGE3_REPORT.md`, `docs/REAL_LLM_QUICKSTART.md`, `docs/RENDER_AGENT_RELEASE_CHECKLIST.md` | Bu rapor, güvenli kullanıcı denemesi ve doğrulanmamış dağıtım kontrolleri. |

Yeni DB alanı/migration/gem, provider runtime değişikliği veya gerçek secret eklenmedi. İnsan/coding agent süresi ölçülmedi; tahmini sayı gerçek süre diye yazılmadı. Gerçek LLM çıktısı, kullanıcı hesabında model erişimi ve canlı browser/Render demosu hâlâ bekliyor.

Son denetimde development'taki altı tablonun satır hash'leri aynı bulundu; ilk prompt ve tarihsel Challenge metni korundu. Yalnız bu çalışma için açılan test PostgreSQL cluster'ı kapatıldı; DB dosyaları silinmedi. Yerel Markdown bağlantıları ve code fence'leri kontrol edildi.
