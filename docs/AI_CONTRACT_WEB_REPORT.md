# SignFlow AI — web geliştirme raporu

**Sonraki final kaydı (25.10.2026):** Kullanıcı gerçek Gemini ile yerel web → draft → insan gönderimi → alıcı signed akışını tamamladığını bildirdi; bu kullanıcı beyanıdır, Codex/production doğrulaması değildir. Son otomatik sonuçlar ve push/deploy kapıları [final raporda](AI_FINAL_RELEASE_REPORT.md). Aşağıdaki geliştirme oturumunun “çağrı yapılmadı” kayıtları tarihsel olarak korunur.

25.10.2026. Yerel geliştirme; gerçek model çağrısı, production işlemi, commit, push veya deploy yapılmadı. Bu rapor önceki Gemini entegrasyonunun üzerine eklenen web katmanını anlatır; çalışma başında var olan commit edilmemiş dosyalar korundu. Başlangıç HEAD: `a0c52436538ae90a4d80ab21807fe9dd7e8c7609`.

## Ürün ve doğrulama sınırı

SignFlow AI, kullanıcının doğal dil talebini gerçek bir LLM ile analiz ederek sürümlü şablondan taslak hazırlamayı ve kritik gönderim kararını insana bırakmayı hedefler. Gemini adaptörü sunucuda kullanılabilir; **bu geliştirmede yalnız fake provider/HTTP transport test edildi**. Gerçek doğal dil çıkarım kalitesi, Google hesabı, canlı web/Render ve gerçek tarayıcı görünümü doğrulanmadı. Kullanıcının önceki CLI denemesinde model erişimi ve manifest HTTP 200 sonrası hata bildirmesi, uçtan uca gerçek LLM başarısı değildir.

## Mimari ve yetki sınırı

1. Web sayfası mevcut Authentication/current_user, şifreli session, CSRF ve origin kontrolünü kullanır. `AI_CONTRACTS_ENABLED=true` olmadıkça rotalar kapalıdır. Dış bearer API'nin ayrı flag'i değişmez; web için bearer oluşturulmaz.
2. Kullanıcı yalnız kendi şablonlarını seçer. Kalıcı `AiContractConversation` satırı owner, UUID, sabit TemplateVersion, bir saatlik son tarih ve varsa Document bağlantısını tutar. Tam mesaj, model çıktısı, payload, anahtar veya imza token'ı DB'ye yazılmaz. Kaynak/sahip/son tarih değiştirilemez.
3. Rails `AiContracts::TemplateAccess`, mevcut `Templates::Manage` üzerinden manifesti doğrudan okur. Uygulamanın kendi API'sine HTTP veya gizli credential ile bağlanılmaz. Başlık ve tam sözleşme modele verilmez.
4. Paylaşılan `SignflowAgent::Runner#advance`, Gemini adaptörü ve `Tools#prepare` kullanılır. Doğal dili alanlara çeviren ve eksikleri seçen LLM'dir; regex bir sahte model olarak kullanılmaz. Sunucu doğrulaması yalnız izin, tip, kaynakta bulunma, tam açık TL tutarı ve tarih kurallarını denetler. Modelin yanlış kişiyi/tutarı seçmediği veya hukuki doğruluk garanti edilmez.
5. Model `create_draft` önerdiğinde Runner **yazmadan durur**. Web adaptörü yazma/get_draft yetkisi sunmaz; bu aşamada okunacak belge yoktur. CLI'nin üç aracı, EVET onayı, retry/job/`--resume` ve Anthropic desteği korunur. Web onayından sonra gerçek belge mevcut Documents ekranından okunur; ek model çağrısı gerekmez.
6. Önizleme `Documents::Manage#build_from_template` → `Templates::Renderer` ile kayıtsız üretilir. Modelin serbest hukuki metni kaydedilmez. ERB escaping korunur.
7. Yalnız ayrı **Taslağı Oluştur** POST'u, sunucu belleğindeki doğrulanmış öneriyi tekrar doğrulayıp `AiContracts::CreateDraft` transaction'ına verir. Hidden/client payload kabul edilmez. Conversation satır kilidi + tek receipt satırı + unique UUID/document FK index'leri aynı konuşmayı ikinci belgeye bağlamayı engeller. Belge default draft'tır; status/signed_at/token istemciden alınmaz.
8. Normal sözleşme listesi/düzenleme, insanın gönderim POST'u ve alıcının demo imzası mevcut servis/model kurallarıyla sürer. AI send/sign endpoint'i eklenmedi.

## Konuşma, tekrarlar ve maliyet

- En fazla 64 konuşma/süreç. Konuşma durumuna erişim bir saat sonra kesilir; süresi dolan bellek girdileri sonraki start/state isteğinde temizlenir. Fiziksel bellek temizleme için arka plan zamanlayıcısı yoktur; boşta kalan süreçte girdiler sonraki temizlemeye kadar bulunabilir. DB receipt'leri idempotency için korunur; otomatik silinmez.
- Süreç belleğindeki diyalog, Gemini opaque signature/history ve öneri diske otomatik yazılmaz. Restart, Rails reload veya farklı worker'da durum kaybolursa otomatik model replay yapılmaz; açık hata ve yeni konuşma gerekir. Oluşturulmuş belge kalıcı receipt üzerinden bellek olmadan tekrar bulunur.
- Formun monoton `step` değeri + prompt SHA-256, aynı mesajın retry/refresh'ini ücretsiz replay yapar. Aynı step/farklı mesaj 409'dur. Başarısız model mesajı yeniden ücretli denenmez; konuşma kapatılır. Aynı konuşmadaki istekler Mutex ile seri çalışır. Ağ kopmasında önce aynı sayfayı yenileyin; yazma tamamlandıysa belge bağlantısı/normal sözleşme listesi üzerinden bulunur.
- Kullanıcı başına fixed 10 dakika penceresinde 5 yeni konuşma, 24 provider işlemi (model metadata preflight dahil). Başarısız provider denemesi sayılır; 429/Retry-After vardır. Runner konuşma boyunca toplam 8 mantıksal model turu, 10 araç ve 3 soru; tek format düzeltmesi de 8 tura dahildir. HTTP transport en fazla iki deneme yapar. Mesaj 8000, toplam kullanıcı metni 20000 karakter; provider context 64 KB ve output 2048 token sınırı korunur.
- Kotalar **tek süreçlidir**, restart/cache eviction ile sıfırlanır; çok worker/instance'da ortak harcama sınırı değildir. Sabit dolar bütçesi veya Google faturası garantisi yoktur. Paid kullanım ayrı operatör izni ister. Gerçek kullanım/token/fatura ölçülmedi; fixture sayıları gerçek tüketim değildir. Bu çalışmada model isteği sıfırdır.
- Senkron Net::HTTP preflight ve model turları Puma thread'ini tutar. Open/read/write timeout 5/30/10 saniye; çok tur/retry isteği proxy timeout'unu aşabilir. Bu demo için tek süreç gerekir; çok kullanıcı/uzun işler için kuyruk, ortak güvenli durum ve ortak kota ayrıca tasarlanmalıdır. Bu çalışmada yeni altyapı/ücretli servis açılmadı.

## Önceki `invalid_model_response` incelemesi

Kesin bulgu: eski Runner, tool sonucu sonrasındaki metni doğrudan `JSON.parse` ediyordu. Sentetik manifest → fenced soru JSON'u, HEAD'teki eski Runner ile **invalid_model_response** olarak yeniden üretildi (`tmp/ai-contract-web/reproduce_original.rb`, ignored tanılama). Düz metin soru da aynı parser yolunda hata oluşturabilir. Kullanıcının gerçek yanıtı güvenli kaydıyla mevcut olmadığından **önceki gerçek olayın kesin kök nedeni kanıtlanmadı**; ham model yanıtı/anahtar aranmadı veya loglanmadı.

Düzeltme: tek soru JSON'unun Markdown code fence'i normalize edilir; birden çok text part birleştirilir. JSON olmayan metin, bir kez sabit yapılandırılmış soru isteğiyle onarılır; yine geçersizse `invalid_model_question_json` ile durur. Serbest model metni başarı veya kullanıcı sorusu olarak doğrudan gösterilmez. Sorulabilecek alanlar yine manifest allowlist'inden doğrulanır. İzin, grounding, insan onayı veya durum kuralları gevşetilmedi.

GeminiProvider'daki orijinal model parts/thoughtSignature saklama ve functionResponse name/id eşlemesi korundu; fake Gemini web/handoff testleri bunları çok turda kullanır. Eksik/yarım veya STOP dışı yanıtlar hâlâ `gemini_generation_incomplete`, bozuk wire yanıtı `invalid_gemini_response`, HTTP ve transport hataları ayrı güvenli kategorilerdedir. Signature, ham yanıt ve secret kullanıcıya/loga yazılmaz.

Resmî [generateContent REST referansı](https://ai.google.dev/api/generate-content) ve [thinking rehberi](https://ai.google.dev/gemini-api/docs/thinking) 25.10.2026'da incelendi. Güncel genel function calling rehberi Interactions API örneklerine taşınmış olsa da uygulamanın mevcut generateContent protokolü korundu. Kamuya açık belgeyi okumak gerçek hesap/servis doğrulaması değildir.

## Test kaydı

Testler önce yazıldı. Runner başlangıcı: 3 test/1 assertion, 1 failure/2 error (advance henüz yok). Web başlangıcı: 5 test/4 assertion, 5 error (rotalar henüz yok). İlk uygulamada test yardımcısının `message` adının Minitest ile çakışması 5 error üretti; `post_message` olarak düzeltildi. Sonraki hedefli pakette hatalı Rails exception constant'ı 1 error üretti; `ReadonlyAttributeError` düzeltildi. İlk RuboCop'ta tek trailing newline ihlali düzeltildi. Hatalar gizlenmedi, CSRF kapatılmadı.

CSRF test yardımcısı gerçek hidden form token'ı kullanacak şekilde güçlendirildikten sonraki tam çalışmada 2 failure oluştu: yabancı kaynak için yetkili draft formu bulunmadığından create formuna bağlı token farklı draft POST'unda 422 üretiyordu; test 404 bekliyordu. Sahiplik testinde aynı oturumun global meta token'ı açıkça seçilerek yetkilendirme katmanına ulaşılması sağlandı. Normal formlarda kendi action'ına ait hidden token kullanılır. Güvenlik yapılandırması değiştirilmedi; paketler tekrar çalıştırıldı.

İlk tam paket: 179 test / 1829 assertion, 0 failure/error/skip. Son test sonuçları ve komutlar [Challenge güncellemesinde](../CHALLENGE_LOG.md#signflow-ai--web-arayüzü-25102026) kaydedilir. PostgreSQL için yalnız bu işe açılan loopback `127.0.0.1:55443/signflow_agent_test` kullanıldı; production URL'si kullanılmadı. SQLite ve PostgreSQL migration'ları additive çalıştırıldı; mevcut development altı tablonun satır hash'leri aynı kaldı.

| Son kontrol | Gerçek sonuç |
| --- | --- |
| `bundle exec rails test` | **180 test / 1846 assertion; 0 failure/error/skip**, exit 0. |
| Ayrı PostgreSQL 18 hedefli paket | **55 test / 739 assertion; 0 failure/error/skip**, exit 0; eski API ve yeni web çift bağlantı yarışları dahil. |
| `bundle exec rubocop` | **120 dosya, ihlal yok**, exit 0. |
| `bundle exec rails zeitwerk:check` | **All is good!**, exit 0. |
| `bundle exec rails tailwindcss:build` | **Başarılı**, exit 0. |
| Development/test + ayrı PostgreSQL `db:migrate` | Additive migration başarılı, exit 0. |
| Gerçek model / manuel browser / Render / uzak Actions | **Çalıştırılmadı.** |

Windows'ta opsiyonel libvips HEIF/JXL/ImageMagick/Poppler DLL ve Rack literal string uyarıları görüldü; test/derleme başarısızlığı üretmedi. Kayıtları değiştirmeden yapılan SQLite hash karşılaştırması yalnız mevcut altı tablonun korunmasını kanıtlar; production kontrolü değildir.

Test kapsamı: oturum/owner izolasyonu; yabancı version/conversation; gerçek CSRF token ve origin; bearer'ın web yetkisi olmaması; eksik bilgi; uydurulmuş e-posta/ücret/tarih; bilinmeyen tool/key; secret/oversize; sentetik onay; quota/TTL; sürüm sabitliği; kayıtsız escaped önizleme; erken onay; mesaj replay/conflict; çift onay; gerçek document listesi; normal gönderim ve alıcı signed; eski API/CLI/Anthropic regresyonları; bağımsız PostgreSQL bağlantılarıyla çift onay ve mevcut API concurrency. Gerçek tarayıcı/JS yükleniyor davranışı manuel denenmedi.

## Dosya envanteri (bu web görevi)

| Dosya | İşlev |
| --- | --- |
| `app/models/ai_contract_conversation.rb`, `db/migrate/20261025000200_create_ai_contract_conversations.rb`, `db/schema.rb`, `app/models/user.rb` | Minimal owner/version/document receipt, FK ve unique index, ilişki. |
| `app/services/ai_contracts/conversations.rb` | Kısa ömürlü diyalog, ortak Runner, mesaj replay, alan doğrulaması/önizleme/onay orkestrasyonu. |
| `app/services/ai_contracts/template_access.rb` | Sahiplik kontrollü doğrudan servis manifest adaptörü. |
| `app/services/ai_contracts/create_draft.rb` | Kilitli, atomik ve tekrar güvenli draft yazımı. |
| `app/services/ai_contracts/provider_factory.rb`, `quota.rb` | Runtime-only Gemini secret/config ve kullanıcı kotası. |
| `config/initializers/signflow_agent.rb` | Aynı Ruby agent kütüphanesini Rails'te ağ/secret okuması olmadan yükler. |
| `script/support/llm/runner.rb` | Shared pause/resume ve bounded soru biçimi onarımı; CLI run arayüzü korunur. |
| `app/controllers/ai_contracts_controller.rb`, `config/routes.rb` | Session/CSRF korumalı web rotaları, güvenli hata/no-store. |
| `app/views/ai_contracts/new.html.erb`, `show.html.erb`, `app/views/layouts/application.html.erb` | Menü, şablon seçimi, responsive diyalog/alanlar/önizleme/onay. |
| `app/javascript/controllers/ai_message_controller.js` | Submit sırasında tekrar tıklamayı önler, yükleniyor bildirimi. Sunucu idempotency ayrıca korunur. |
| `test/lib/runner_conversation_test.rb` | Fenced/prose soru/CLI regresyonu. |
| `test/integration/ai_contracts_test.rb`, `gemini_web_contracts_test.rb` | Web güvenliği ve uçtan uca signed; nötr fake ve gerçek Gemini adaptörü/fake HTTP. |
| `test/services/ai_contracts_test.rb`, `ai_provider_factory_test.rb` | TTL/kota/şema/sürüm/input/secret/izin sınırları. |
| `test/postgresql/ai_contract_concurrency_test.rb` | İki bağlantılı tek draft onayı ve bellek olmadan recovery. |
| `.github/workflows/ci.yml` | Mevcut PG job'ına yeni web ve concurrency testleri; uzakta çalıştırılmadı. |
| `.env.example`, `README.md`, `AGENT.md`, `CHALLENGE_LOG.md`, bu rapor ve demo rehberi | Secret içermeyen ayarlar, sınırlar ve gerçek kanıt. |

## Açık kalanlar ve dağıtım

- [Güvenli yerel demo](AI_CONTRACT_WEB_DEMO.md) kullanıcı tarafından gerçek Gemini ile çalıştırılmalı. Google free/billing, model erişimi ve data-use koşulları kullanıcı tarafından teyit edilmeli; gerçek veri kullanılmamalı. Serbest metindeki tarihleri otomatik tahmin yerine açık YYYY-MM-DD ve offset'li ISO8601 ile tamamlamak gerekebilir.
- Render dashboard/Auto-Deploy/canlı SHA doğrulanmadı; flag kapalı kalmalı. Bu çalışma deploy yapmaz. Gelecekte mevcut checklist'e ek olarak backup, additive migration, tek süreç (`WEB_CONCURRENCY=0`), backend-only key, provider/free izinleri, proxy timeout ve sentetik manuel kabul kontrol edilmelidir. Rollback'te önce flag kapatılır; yeni tablo/data drop edilmez.
- İlk prompt ve önceki tarihsel Challenge kayıtları korunur. İnsan ve coding-agent süreleri ölçülmedi; gerçek model usage/token/maliyet bilinmiyor. Yeni commit URL'si yok; oluşturulmadı. Devam kararı: aynı güvenilir iş akışına doğal dil girişi ekler, kritik gönderim yetkisini modelden uzak tutar. Gerçek model/demo kabulü tamamlanmadan canlı başarı iddia edilmez.
