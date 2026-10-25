# SignFlow AI — final kanıt ve kontrollü yayın raporu

25.10.2026. [Challenge kaydı](../CHALLENGE_LOG.md), [web mimarisi](AI_CONTRACT_WEB_REPORT.md), [güvenli demo](AI_CONTRACT_WEB_DEMO.md). Bu görev yerel commit'i ve ancak Render Auto-Deploy güvenliği doğrulanırsa push'u yetkilendirir; production deploy için ayrıca son kullanıcı onayı gerekir. Yeni gerçek Gemini çağrısı yapılmadı.

## Kanıt düzeyleri

| Kanıt | Gerçek durum |
| --- | --- |
| Gerçek yerel Gemini/web demosu | **Kullanıcı beyanı, 25.10.2026:** doğal dil talebi, eksik bilgi diyaloğu, şablon taslağı, belgeyi görüntüleme, insan gönderimi, gizli sekmede alıcı imzası, uygulamada İmzalandı. |
| Model değişikliği | Kullanıcı önceki 404 sonrası model yapılandırmasını değiştirip başarılı olduğunu bildirdi. Başarılı ID bildirilmedi; tahmin edilmedi. |
| Codex otomatik doğrulama | Aşağıdaki Rails/fake-provider, PostgreSQL, lint/derleme kontrolleri. Gerçek LLM çağrısı veya bağımsız tarayıcı testi değildir. |
| Production/Render kabulü | **Yapılmadı.** Mevcut canlı URL yeni AI sürümünün çalıştığına kanıt sayılmaz. |
| Usage/maliyet/süre | Gerçek demo token/fatura/süre ve insan/coding-agent aktif zamanı bilinmiyor; ölçüm uydurulmadı. |
| Yeni kullanıcı araştırması | Yapılmadı. Eski README yorum kaynakları şablon ihtiyacına bağlamdır; agent talebini veya ölçülmüş zaman tasarrufunu kanıtlamaz. |

## Güvenlik ve regresyon

| Gereksinim | Kod / gerçekten çalıştırılan test |
| --- | --- |
| Aynı konuşma/retry/çift tıklamada tek Document | `AiContracts::CreateDraft`: conversation satır kilidi/transaction, unique UUID/document bağlantıları. Web integration'da iki onayda tek kayıt; PG'de iki bağımsız eşzamanlı bağlantı tek belge. |
| Refresh/bellek kaybı sonrası belge | Web GET mevcut belge linkini gösterir; completed DB receipt cache olmadan da aynı belgeyi döndürür. |
| Mesaj replay/conflict | Step+digest aynıysa yeni model çağrısı yok; eski step/farklı payload 409. Başarısız model isteği otomatik ücretli replay yapmaz. |
| Tenant izolasyonu | Owner kapsamlı şablon/sürüm/conversation/document sorguları. Yabancı GET ve onay reddedilir. Sahte browser `user_id`, status/content/version parametreleri server-side öneriyi değiştirmez. |
| Oturum ve CSRF | Oturumsuz tüm AI POST'ları güncel anonim CSRF ile bile girişe yönlenir. Bearer web oturumu değildir. Geçerli session'da eksik token veya yanlış/null Origin reddedilir. |
| İnsan onayı | Model create_draft önerisi önizlemede durur; onay öncesi Document sayısı değişmez. Yalnız kullanıcı form POST'u kayıt oluşturur. |
| Send/sign yasağı | Modelin send/sign tool girişimi reddedilir; API'de send/sign/edit route'u yok. Normal insan gönderimi ve alıcı imzası ayrı kalır. |
| Uydurma alan ve XSS | Ortak Tools grounding/fee/deadline/allowlist, Renderer ve ERB escaping kontrolleri. Şablon sürümü sabittir; serbest LLM content kabul edilmez. |
| Secret güvenliği | API/header/body sınırları, web HTML ve log testi, Rails parametre filtresi. `.env`/anahtar/token değerleri kaynak veya kanıt dosyalarına alınmaz. |
| Eski akışlar | Normal sözleşme/şablon/gönderim/imza, dış Agent API, Anthropic ve Gemini CLI fake-protocol, retry/EVET/--resume regresyonları tam pakette. |

Bu finalde uygulama iş kuralları değiştirilmedi. Mevcut testlere browser parametre sahteciliği ve refresh assertions eklendi; oturumsuz POST/sign/secret testleri hem nötr fake hem Gemini wire üzerinden çalışır. İlk yeni hedefli test **22/344, 2 failure** verdi: Authentication reset_session sonrası önceki anonim CSRF token'ı tekrar kullanılmıştı. Test her istek için yeni anonim token alacak şekilde düzeltildi; güvenlik kapatılmadı.

| Kontrol | Sonuç |
| --- | --- |
| `$env:RAILS_ENV='test'; bundle exec rails test` | **190 test / 1978 assertion; 0 failure/error/skip**, exit 0. |
| İzole PG18 API/web/service/concurrency | **59 test / 813 assertion; 0 failure/error/skip**, exit 0. |
| `bundle exec rubocop` | **123 dosya, ihlal yok**, exit 0. |
| `bundle exec rails zeitwerk:check` — test ortamı | **All is good!**, exit 0. |
| `bundle exec rails tailwindcss:build` — test ortamı | Başarılı, exit 0. |
| `git diff --check` ve açık commit kapsamı incelemesi | Başarılı. 51 ilgili kaynak/belge dosyasında secret-pattern ve sentetik e-posta taraması geçti; mutlak DLP garantisi değildir. `.env` ignored/izlenmiyor. |
| İlk prompt / tarihsel Challenge / Markdown | İlk prompt hash'i aynı, önceki tarihsel metin birebir korunuyor; yerel Markdown link ve code fence kontrolleri geçti. |

PG komutu mevcut CI `agent_postgresql` job'ındaki 12 dosyalık hedefli pakettir. Yalnız loopback `127.0.0.1:55443/signflow_agent_test` kullanıldı; `SCHEMA` ignored `tmp/ai-final/postgresql-schema.rb` yoluna yönlendirildi. Start sonrası yalnız izole test DB'de db:migrate çalıştırıldı. Production/development veritabanına migration veya test kaydı yazılmadı. Windows opsiyonel libvips/Rack uyarıları sonuçları başarısız yapmadı.

## Git ve GitHub

- Başlangıç HEAD `a0c52436538ae90a4d80ab21807fe9dd7e8c7609`, branch `main`, origin `https://github.com/Huseyinyagmur/signflow.git` olarak doğrulandı. Önceden commit edilmemiş ilgili Gemini/web/dotenv çalışmaları korundu; yeni Gemini ve web katmanının bağımlılıkları oldukları için aynı AI commit kapsamındadır.
- Yalnız açık dosya allowlist'i stage edilir; `.env`, `.bundle`, key/credentials, storage/DB, log, tmp veya build çıktıları stage edilmez. Gerçek kullanıcı kayıtları veya yerel model ayarları commit'e alınmaz. Testler `example.com` ve açık sentetik değerler kullanır. README'deki eski kamuya açık araştırma kaynakları özel müşteri verisi değildir.
- Mevcut yerel API/LLM/credential commit'leri yeni web katmanının öncülleridir; ileride push yalnız son commit'i değil uzakta bulunmayan bu ataları da yayınlayabilir. Zorlayıcı push/merge yapılmaz; uzak branch değişmişse yeniden değerlendirilir.
- Yerel commit gerçek oluşturulmadan SHA yazılmaz. Oluşturulduğunda son kullanıcı raporunda bildirilir; aynı commit'in kendi dosyasına kendi SHA'sı uydurulmaz. Tekrar kanıt: `git log -1 --format="%H %aI %s"`, `git show --stat HEAD`.
- Public GitHub API ile görülen [Actions run 39549285447](https://github.com/Huseyinyagmur/signflow/actions/runs/39549285447), eski `fb78d6111ebfb8863b3fa344d62a5f4484bc2fa4` SHA'sında completed/success. Yeni AI commit'i için başarı değildir.
- Browser runtime kullanılabilir tarayıcı bulamadı; GitHub/Render connector veya gh CLI erişimi yok. Public GitHub Actions salt okunur sorgulandı; Render hesabı/secret/ayarlar okunmadı.
- **Push kapısı:** Render bağlı branch/Auto-Deploy bilinmiyorsa push yoktur. `[skip render]` gibi bir commit ibaresi bu açık kullanıcı şartını atlamak için kullanılmaz. Kullanıcıdan yalnız bağlı branch/Auto-Deploy bilgisi istendi; gizli değer istenmedi. Yeni SHA push edilmeden Actions başlamış/başarılı sayılmaz.

## Render — doğrulanan dosyalar ve açık kapılar

| Başlık | Kaynak koddan bilinen | Dashboard/production durumu |
| --- | --- | --- |
| Repo/branch/Auto-Deploy | Yerel Git main/origin doğru. | Bağlı Render branch ve Auto-Deploy **bilinmiyor**. Push öncesi doğrulanmalı. |
| PostgreSQL | Production database.yml DATABASE_URL ile PG kullanır, SQLite fallback yok. | Mevcut bağlantı/DB planı/ömrü/depolama/erişim **doğrulanmadı**. |
| Build | `bash bin/render-build.sh`: bundle install ve dummy key ile assets precompile. | Servisin gerçek komutu doğrulanmadı. |
| Start/migration | `bash bin/render-start.sh`: env guard → db:migrate → exec Puma. Hata start'ı durdurur; pre-deploy desteği varsayılmaz. | Son canlı migration durumu bilinmiyor. |
| Yeni migration | `20261025000200_create_ai_contract_conversations`: yalnız yeni tablo, index ve eski owner/version/document tablolara FK. Additive; eski kayıtlarda update/delete yok. | Production'a uygulanmadı. Agent access öncül migration'ı da canlıda eksik olabilir. |
| Geri dönüş | Kod/flag geri dönüşü mümkün tasarım; migration eski tablo verilerini dönüştürmez. | Backup/restore denemesi, eski başarılı artifact ve rollback yetkisi **doğrulanmadı**. |
| Güvenlik | HTTPS/secure cookie/host/CSRF/origin korunur. Dotenv yalnız development'ta yüklenir. | Gerçek domain/env/provider/account uygunluğu ayrıca kontrol edilmeli. |

### Environment isimleri — değerler paylaşılmaz

Mevcut production temeli: `DATABASE_URL`, `RAILS_MASTER_KEY`, `RAILS_ENV`, `RUBY_VERSION`, `BUNDLE_WITHOUT`, `RAILS_LOG_TO_STDOUT`, `WEB_CONCURRENCY`, `RAILS_MAX_THREADS`. Host/operasyon için `APP_HOST`, `PGSSLMODE`, `RAILS_LOG_LEVEL` gerektiğinde kontrol edilir. `PORT`, `RENDER_EXTERNAL_HOSTNAME` Render tarafından sağlanır; gerçek değerler bu dosyaya yazılmaz.

AI katmanı: `AI_CONTRACTS_ENABLED`, `GEMINI_API_KEY`, `SIGNFLOW_LLM_PROVIDER`, `SIGNFLOW_LLM_MODEL`, `SIGNFLOW_GEMINI_TIER`, `SIGNFLOW_GEMINI_FREE_TIER_CONFIRMED`, `SIGNFLOW_ALLOW_PAID_LLM`, `SIGNFLOW_SYNTHETIC_DATA`.

`AGENT_API_ENABLED` yalnız dış bearer API ayrıca açılacaksa gerekir; web AI bunu/SignFlow bearer token'ını istemez. Production `.env` kopyalanmaz. Anthropic kullanılmıyorsa Anthropic key'i eklemek gerekmez. `SECRET_KEY_BASE_DUMMY` runtime'a taşınmaz. Gerçek başarılı model ID'si ve free/billing koşulları production projesi/anahtarı için operatör tarafından ayrıca doğrulanır; yerel başarı bu hesabı doğrulamaz. Free bayrakları fatura garantisi veya paid izin değildir.

### Kullanıcı onayından önce tamamlanacak kontrol listesi

- [ ] Dashboard'da servis, bağlı repo/branch, canlı SHA ve Auto-Deploy gerçekten görüldü; kontrolsüz yayını önleyecek durum doğrulandı.
- [ ] Doğru mevcut kalıcı PG, plan/son tarih ve geri getirilebilir backup/restore yolu doğrulandı. Free planda otomatik backup/PITR var sayılmadı; operatörün özel backup'ı ve restore doğrulaması ayrıca hazır.
- [ ] Bekleyen migration'lar ve yeni tablo/FK/index'lerin additive niteliği incelendi; eski DB/record'lar sıfırlanmaz. Production db:reset/drop/schema:load/seed yok.
- [ ] Hedef SHA'nın bütün ilgili GitHub Actions işleri gerçekten success; eski run'lar yerine yeni SHA eşleşmesi kontrol edildi.
- [ ] Tek web instance ve tek Puma süreci doğrulandı; mevcut dosya için `WEB_CONCURRENCY=0`. Shared quota/conversation desteği var sayılmadı.
- [ ] Backend secret/env ve production model/proje/free/koşullar güvenli biçimde operatörce kontrol edildi; ilk kontrollü sürümde AI ve dış API flag'leri kapalı tutulacak.
- [ ] Önce deploy için son kullanıcı onayı alındı; bu görevde deploy başlatılmaz. Yayın sonrası test için production'da yeni sözleşme/imza üretimi ayrıca izinli değilse yapılmaz; sentetik gerçek model denemesi yerel/ayrı izinli staging'de kalır.
- [ ] Rollback için başarılı eski SHA/artifact, flag kapatma ve mevcut kayıtları koruma planı var. Kod rollback'i DB restore/rollback anlamına gelmez; yeni receipt tablosu drop edilmez.

Render'ın [deploy belgesi](https://render.com/docs/deploys) On Commit/After CI Checks Pass/Off farkını açıklar; After CI tek başına bu görevde production deploy izni sayılmaz. [Backup belgesi](https://render.com/docs/postgresql-backups) Free planda managed recovery/logical backup sağlamadığını belirtir. [Rollback belgesi](https://render.com/docs/rollbacks) Dashboard/API Auto-Deploy farkını ve artifact/config sınırlarını açıklar. Belgelerin okunması hesap ayarlarının doğrulandığı anlamına gelmez. Yeni ücretli kaynak açılmadı.

## Bilinen ürün sınırları

Konuşma belleği ve kota süreç içidir. Çok worker/instance'da konuşma kaybı ve ayrı kota sayaçları oluşabilir. En fazla bir saat erişim; sonraki erişimde bellek temizliği, restart/reload'da kayıp mümkündür. Kalıcı belge/receipt PG'de korunur; fakat yeni konuşma ayrı iştir ve ayrı taslak oluşturabilir. Tek süreçte dahi cache eviction/restart kotayı sıfırlar; kullanıcı/süreç sınırı dolar bütçesi değildir. Senkron provider çağrıları thread/proxy timeout riski taşır.

Üretimde daha çok yük için ortak güvenli kısa ömürlü durum/kota (ör. Redis), durable job queue ve maliyet/abuse sınırları ayrı tasarlanmalı. Bunlar **henüz yapılmadı**, ücretli servis oluşturulmadı. LLM grounding mekanik kontrolü yanlış alanı seçme veya hukuki doğruluk garantisi değildir. Taslak inceleme ve gönderim kararı insanda kalır. Gerçek e-imza/kimlik doğrulama, PDF ve gerçek e-posta bu katmanla eklenmedi.
