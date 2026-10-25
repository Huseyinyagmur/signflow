# SignFlow Agent — Aşama 2 teknik raporu

**Sonraki aşama notu:** Bu dosya Aşama 2 kapanışının tarihsel raporudur. Aşama 3'te credential yönetim ekranı ve temel process kotası eklendi; güncel durum [Aşama 3 raporunda](AGENT_STAGE3_REPORT.md). Gerçek LLM çağrısı hâlâ yapılmadı.

**25.10.2026.** Ruby istemcisi ve deterministik testleri tamamlandı. **Gerçek Anthropic çağrısı yapılmadı; canlı LLM başarısı veya 100 puan koşulunun tamamlandığı iddia edilmiyor.** Ortamda ANTHROPIC_API_KEY tanımlı değildi; özel credential depoları aranmadı ve ücretli çağrı izni alınmadı. Sonraki gerçek deneme için [demo rehberi](AGENT_LLM_DEMO.md).

Başlangıç SHA: `d0e747978b13ec55f5cc9edae2c723c4d4fe910b`, 25.10.2026, `feat: add secure agent draft API with idempotency`. Gerçek yerel Git kaydıdır. Bu çalışma commit/push/deploy yapmadı. Aşama 1'in ilk promptu ve tarihsel kayıtları korunmuştur; [Challenge](../CHALLENGE_LOG.md).

## Çalışan ve doğrulanmayan parçalar

| Parça | Gerçek durum |
| --- | --- |
| Ruby agent döngüsü, üç araç, eksik bilgi diyaloğu | Uygulandı; fake provider ile test edildi. Modelin doğal dil anlama kalitesi ölçülmedi. |
| Anthropic Messages ve Models HTTP adaptörü | Uygulandı; istek/yanıt biçimi fake transport ile test edildi. Gerçek hesap/erişim/TLS isteği denenmedi. |
| Sabit şablondan API taslağı ve sorgusu | Fake provider + gerçek Rails integration stack ile doğrulandı. Bu in-process HTTP integration testidir, uzak/tarayıcı demosu değildir. |
| İnsan onayıyla mevcut CSRF gönderimi ve alıcı imzası | Yeni handoff integration testinde signed ile tamamlandı. Gerçek tarayıcı/Render kabul testi yapılmadı. |
| Kalıcı key/payload, retry ve process resume | Yerel dosya ve fake transport testleri; gerçek Rails API'de replay doğrulandı. |
| Gerçek LLM tool seçimi ve canlı kullanıcı diyaloğu | Henüz doğrulanmadı. API anahtarı, bütçe izni ve sentetik gerçek deneme gerekir. |
| Credential UI / API genel kota | Aşama 1'deki eksik devam ediyor. CLI provisioning korunuyor. |

## Mimari ve veri akışı

`script/signflow_agent.rb` Rails boot etmez, veritabanına bağlanmaz. Yeni gem/SDK/agent framework/worker gerekmez. Ruby standart Net::HTTP, JSON, Date, IO.console ve File kullanılır.

1. Kullanıcı güvenilir config'te base URL, template ID ve version ID'yi seçer. Model bu değerleri, owner'ı, header'ı veya endpoint'i belirlemez.
2. Model `get_template_version({})` önerir. İstemci gerçek Aşama 1 manifest endpoint'ini çağırır; tam sözleşme ve şablon başlığı model context'ine verilmez, yalnız ID/sürüm/değişkenler gider.
3. Model, doğal dildeki eksik alanları `{"type":"question","fields":[...]}` metniyle belirtir. Alan adları doğrulanır; CLI bunları sabit Türkçe etiketlerle sorar. Modelin serbest metni terminale basılmaz; sahte başarı mesajı üretilemez.
4. Model `create_draft` ile values ve üç document alanını önerir. Kullanıcı mesajında birebir bulunmayan değer, eksik alan, keyfi alan, bozuk e-posta, geçmiş/offsetsiz imza tarihi reddedilir. Şablonda varsa hizmet tarihleri YYYY-MM-DD olmalı.
5. Ücret bu dar MVP'de açık **TL/TRY/₺** ifadesinin tamamı olarak korunur: “25 bin TL” → “25 bin TL”. 25, TL, farklı tutar veya başka para birimine sessiz dönüşüm yoktur. Diğer para birimleri/karmaşık fiyat sözleşmeleri için genişletme ve yeni test gerekir.
6. Çıkarılan sentetik alanlar kullanıcıya gösterilir, **EVET** onayı olmadan draft POST yapılmaz. Bu yerel alan kontrolüdür; imzaya gönderme onayı değildir.
7. Sabit başlık `Agent sözleşme taslağı` ve kaynak sürüm eklenir; mevcut API/Manage/Renderer gerçek metni üretir. Model raw content veya hukuki hüküm gönderemez.
8. Model `get_draft({})` çağırmalıdır. Yalnız bu job'ın oluşturduğu belge sorgulanır. Başarı, model metninden değil doğrulanan API metadatasından çıkar: ID, başlık, kaynak sürüm, güncel durum ve login gerektiren `/documents/:id` yolu. Tam içerik modele gönderilmez.

Üç aracın JSON Schema tanımları `Tools#definitions`, runtime doğrulamaları `Tools` içindedir. Get araçları yalnız boş nesne kabul eder. Create aracı sadece `values` ve `document` içinde recipient_name/recipient_email/expires_at kabul eder. ID, URL, owner, status, token, imza veya shell parametresi yoktur. Bilinmeyen araç/alanlar fail-closed durur. API yanıtlarının izinli anahtarları, tipleri, kaynak sürümü, belge ID'si, review path'i ve replay boolean'ı kontrol edilir. Metadata yerine keyfi JSON başarı sayılmaz.

`Runner` yalnız `provider.reply(messages:, tools:)` arayüzüne bağlıdır; sağlayıcı değiştirilirse yalnız adaptör ve ilgili testler değişir. Model HTTP transport'u da enjekte edilebilir; testler gerçek modele çıkmaz. Normal ürün başlangıcında fake provider seçeneği yoktur: ayrı fake sınıfları yalnız test dosyalarındadır.

## Halüsinasyon ve injection sınırı

İstemci ücretin korunmasını ve kaynak mesajda bulunmayı mekanik olarak kontrol eder; modelin her değeri doğru role eşleştirdiğini veya hukuki doğruluk sağladığını garanti etmez. Kullanıcı mesajında birden fazla isim/tutar varsa model yanlışını seçebilir. Bu yüzden çıkarılan alanlar yerelde doğrulatılır; web'de sözleşmenin son incelemesi de ayrıca yapılır. Doğal dilde “yarın” veya yalnız “25 bin” varsa modelden offsetli tarih/açık para birimi istenir; sessiz hesaplama yoktur.

Injection testi, izinli araçları genişletemez: send/sign/terminal/keyfi HTTP/SQL yok. Manifest başlığı ve sözleşme metni modele taşınmaz. Model `max_tokens` nedeniyle yarıda kalırsa veya serbest başarı paragrafı döndürürse sonuç kabul edilmez. İstek bilgisi uydurularak eksik alan doldurulursa istemci API yazımı yapmadan durur. Gerçek LLM'in bu politikalara ne sıklıkla uyduğu henüz ölçülmedi.

## Sağlayıcı ve model doğrulaması

Yapılandırılan varsayılan model: **`claude-haiku-4-5-20251001`**. Bu bir gerçek model ID'sidir, “bu oturumda çalıştırılan model” değildir. 25.10.2026'da açılan [resmî model sayfası](https://platform.claude.com/docs/en/models/haiku-4-5/overview) Active (legacy) durumunu, $1 / 1M input ve $5 / 1M output fiyatını gösteriyordu. Yeni bir modelin daha iyi olduğu veya bu modelin kullanıcının hesabında açık olduğu varsayılmadı; legacy modelin yaşam döngüsü gerçek demo öncesinde yeniden kontrol edilmeli.

CLI gerçek çalıştırmada önce [GET /v1/models/{model_id}](https://platform.claude.com/docs/en/api/models/retrieve) yapar. Dönen ID seçilen sabit ID ile uyuşmazsa durur; sessiz alias/model fallback yoktur. Sonra `/v1/messages` kullanır. `anthropic-version: 2023-06-01` ve `x-api-key` [resmî authentication açıklamasında](https://platform.claude.com/docs/en/manage-claude/authentication) desteklenen biçimdir. Bu MVP için workspace'e bağlı API key kullanın; multi-workspace header akışı eklenmedi. [Tool tanımı](https://platform.claude.com/docs/en/agents-and-tools/tool-use/define-tools) ve [tool_result döngüsü](https://platform.claude.com/docs/en/agents-and-tools/tool-use/handle-tool-calls) resmî referansları incelendi.

Kaynak okuma, hesapta erişim veya gerçek response uyumluluğu kanıtı değildir. 401/404 model hatasında fake cevap veya başka sağlayıcıya sessiz geçiş yapılmaz.

## Sırlar ve ücret izni

- LLM key'i sadece sabit `api.anthropic.com` HTTPS transport'una; SignFlow token'ı sadece kullanıcı config'indeki doğrulanmış API base host'una gönderilir. Auth header'ları model mesajlarına, araç tanımlarına veya job dosyasına girmez.
- Env boşsa key/token yalnız `IO.console.getpass` ile maskeli istenir; etkileşimli güvenli console yoksa durur. Anahtar sohbetten istenmez. Gerçek `.env` ignored; `.env.example` yalnız isim/default içerir ve otomatik yüklenmez.
- Bilinen key değerleri ve API key/token biçimleri kullanıcı/model/API verisinde yakalanırsa reddedilir. Ham request/response, prompt, exception body veya header dump yoktur. Bu, bütün kişisel verileri otomatik sınıflandıran DLP değildir; sentetik veri sorumluluğu kullanıcıdadır.
- Yeni LLM çalıştırması hem `SIGNFLOW_SYNTHETIC_DATA=true` hem `SIGNFLOW_ALLOW_PAID_LLM=true` ister. İkinci değişkeni açmak kullanıcı bütçe iznidir; coding agent gerçek deneme yapmak için kendiliğinden açmadı. **Bu çalışmada sağlayıcı çağrısı sayısı 0.**
- Job dosyası secret içermez fakat sentetik alıcı/payload içerir; ignored `tmp/llm-jobs` altında 0600 dosya/0700 klasör ile oluşturulur. Windows NTFS ACL ayrıca doğrulanmalı; Unix mod sayısı ACL garantisi değildir. Job dosyaları shared/senkronize dizinde tutulmamalı.

## Retry ve kalıcı idempotency

Job ID'yi kullanıcı seçer; disk kaydı base URL, sabit template/version, tek rastgele Idempotency-Key, payload ve varsa document ID tutar. Aynı job için exclusive dosya kilidi vardır; binding değişikliği veya mevcut payload'ın değiştirilmesi reddedilir. Model prompt geçmişi, secret ve chain-of-thought saklanmaz. Dosya atomik rename ile, POST'tan **önce** flush/fsync edilerek yazılır.

Network hatası/429/500/502/503/504 için API çağrısında en fazla iki deneme, 0,5 sn backoff; body/key aynıdır. 401/409/422 tekrar edilmez. Sağlayıcıda 529 da geçici sayılır; provider isteği en fazla iki kez denenir. Redirect izlenmez; proxy env devralınmaz; TLS sertifika doğrulaması kapatılmaz.

İşlem POST'tan sonra kesilirse `--resume` disk kaydındaki **aynı** payload/key ile replay ve GET yapar; yeni LLM çıkarımı veya yeni key yoktur. Bu kurtarma deterministiktir ve yeni LLM çağrısı diye gösterilmez. Dosya kaybolursa aynı işi yeni job ile tekrarlamak mükerrer kayıt oluşturabilir; hata varken yeni job açmayın. İmzalanmış belge replay sonucu signed olabilir; geri draft yapılmaz. Yeni kaynak sürümüyle yeni iş için ayrı job gerekir.

Limitler: 8 mantıksal model turu, 10 tool, 3 takip sorusu, tur başına 1024 output token; mesaj geçmişi en fazla 30 mesaj/64 KB. Retry ile en fazla 16 Messages HTTP denemesi oluşabilir; model timeout'u tüketimi kesin sıfır yapmaz. API timeout'ları 5/20/10 sn, sağlayıcı 5/30/10 sn (connect/read/write). Bu limitler duvar saati/para hard cap'i veya dağıtık exactly-once garantisi değildir.

Başarısızlıkta CLI genel hata koduyla çıkar ve “başarı doğrulanmadı” der. Önceki POST commit olmuş olabilir; aynı job'ı koruyup recovery kullanın. Modelin başarısız olmasını belgenin hiç oluşmadığı şeklinde de sunmayın.

## Maliyet: tahmin / gerçek ayrımı

Bu oturumda Messages/Models API çağrısı yok; gerçek input/output token ölçümü yok. Fake provider sayıları test fixture'ıdır, gerçek usage/maliyet sayılmaz. Bu oturumun yaptığı ücretli çağrı maliyeti **0 $**; sağlayıcı hesabı/faturası incelenmedi.

Varsayımsal bir tamamlanmış işte toplam 8.000 input + 2.000 output: `8000/1M × $1 + 2000/1M × $5 = $0,018`. 50 böyle iş yaklaşık $0,90. Retry, uzun mesajlar ve başarısız response tüketimi artırabilir. Bu bütçe garantisi veya gerçekleşmiş gider değildir; cache/batch indirimi, vergi/kur/hosting dahil değil. Model değişirse fiyat hesabı yeniden yapılmalı. Gerçek çalışmada CLI yalnız başarılı response'ların usage toplamını ve HTTP attempt sayısını gösterir; kayıp timeout response'larının tüketimini bilmez, kesin fatura için provider usage/billing gerekir.

## Testler ve gerçek sonuçlar

Önce test dosyası yazılıp çalıştırıldı; istemci modülü henüz olmadığı için yükleme hatası alındı. Sonra uygulandı. RuboCop ilk çalışmada testlerde dört, observer eklendikten sonra bir boş lambda aralık hatası buldu; düzeltildi. Güvenlik koşulları test geçirmek için kaldırılmadı.

| Kontrol | Sonuç |
| --- | --- |
| İlk hedefli core/provider testleri | 13 test / 78 assertion, hata yok. |
| Job/secret testleri eklendikten sonra | 15 test / 86 assertion, hata yok. |
| İlk yeni handoff testi | 1 test / 15 assertion; sahte model + gerçek Rails API/CSRF/signed. Sonradan tool/HTTP kodu assert'leri de eklendi. |
| Tam SQLite regresyonu | 130 test / 1212 assertion, 0 failure/error/skip. Mevcut Aşama 1 ve önceki bütün testler korunuyor; fake provider testleri gerçek model çağırmıyor. |
| RuboCop | 92 dosya; son çalışmada ihlal yok. |
| Zeitwerk | `bundle exec rails zeitwerk:check`: All is good! |
| Ayrı PostgreSQL 18 | 20 test / 195 assertion, 0 failure/error/skip. Yeni boş loopback test DB'sinde migration; API, concurrency ve yeni handoff testi. |

Kapsam: eksik bilgi, doğru hazırlanmış model alanlarını işleme, uydurma e-posta/tarih/ücret ve kısmi tutar reddi, bilinmeyen araç/alan, injection/send denemesi, model/API response biçimi, timeout/429/401/422/500, bounded loop, secret redaksiyon, job kilidi/binding, restart replay ve insan imzası. Bunlar gerçek doğal dil çıkarım doğruluğu için model evaluation değildir.

CI mevcut SQLite job'ında yeni testleri toplar. `agent_postgresql` job'ına yeni handoff dosyası eklendi; gerçek key/model çağrısı eklenmedi. Uzak CI tetiklenmedi, başarı varsayılmadı. Bu oturumda PostgreSQL testleri için ayrı `tmp/agent-stage2/postgres-data` cluster'ı ve 127.0.0.1:55440 kullanıldı; mevcut PostgreSQL hizmetlerine veya production DB'ye dokunulmadı. Yerel test trust auth'u production önerisi değildir.

Test sonunda yalnız bu çalışma için açılan cluster kapatıldı; DB dosyaları ve mevcut kullanıcı kayıtları silinmedi. Son yerel kontrol ilk prompt/tarihsel Challenge içeriğinin ve development'taki altı tablonun hash'lerinin korunduğunu doğruladı. Son provider normalizasyon değişikliği sonrası hedefli testler de 16 test / 95 assertion ile geçti; gerçek sağlayıcı çağrısı yoktur.

## Dosyalar

| Dosya | İşlev |
| --- | --- |
| `script/signflow_agent.rb` | Gerçek sağlayıcı CLI, izin/secret/model preflight, diyalog, alan onayı, resume, güvenli progress/sonuç. |
| `script/support/signflow_agent.rb` | Modüller ve ortak yapı/secret guard'ları. |
| `script/support/llm/anthropic_provider.rb` | Sabit HTTPS Models/Messages transport, provider adaptörü, system prompt ve limitler. |
| `script/support/llm/runner.rb` | Sağlayıcıdan bağımsız üç araç döngüsü ve soru/sonuç doğrulaması. |
| `script/support/llm/tools.rb` | Schema, source grounding, API sahiplik sınırına devir, response kontrolü ve retry. |
| `script/support/llm/job.rb` | Özel/atomik iş kaydı, kilit, key/payload/id kalıcılığı. |
| `script/support/llm/secrets.rb` | Env veya maskeli console secret okuma. |
| `script/support/agent_http_client.rb` | Mevcut güvenli transport'a yalnız typed HTTP status eklendi; eski deterministik istemci korunuyor. |
| `.env.example` | Gerçek secret olmayan yapılandırma isimleri ve kapalı izinler. |
| `test/lib/signflow_agent_test.rb`, `test/lib/anthropic_provider_test.rb` | Fake provider/transport, güvenlik, grounding, retry ve CLI izni testleri. |
| `test/integration/llm_agent_handoff_test.rb` | Gerçek Rails API + fake model + insan CSRF → signed regresyonu. |
| `.github/workflows/ci.yml` | PG job'ına yeni integration testi. |
| `AGENT.md`, `README.md`, `CHALLENGE_LOG.md` | Kapsam, kullanım ve dürüst kanıt kaydı. |
| `docs/AGENT_LLM_STAGE2.md`, `docs/AGENT_LLM_DEMO.md` | Bu rapor ve canlı demo rehberi. |

Uygulama controller/model/route güvenlik kodları ve şema değiştirilmedi; migration eklenmedi. Web session/cookie/CSRF/origin, şablon/Document kuralları yeniden yazılmadı.

## Render ve tamamlanması gerekenler

LLM istemcisi yerel çalışır; Anthropic key'ini Render'a eklemek gerekmez. Rails Aşama 1 API'si canlıya ayrı kontrollü deployment ile çıkmalı. Önce bağlı branch/Auto-Deploy/canlı SHA, mevcut CI, PostgreSQL süre/backup ve feature flag doğrulanmalı. Yeni runtime/worker/ücretli servis gerekmiyor. Kodda Render ayarı değiştirilmedi, commit/push/deploy yapılmadı.

Tamamlanmayanlar: gerçek hesap erişimi/model output uyumluluğu; gerçek LLM sentetik başarı/eksik bilgi/injection değerlendirmesi; canlı browser ve signed demosu; gerçek usage/fatura; API kota ve kullanıcı credential UI'sı. Legacy modelin erişimi değişirse gerçek preflight sonucuyla model/ücret kararı yeniden alınmalı. Gerçek müşteri verisi için sağlayıcı retention/eğitim/bölge/hukuki koşullar ayrıca incelenmeden sentetik sınırı kaldırılmamalı.
