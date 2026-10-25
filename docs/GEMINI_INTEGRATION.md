# SignFlow Agent — Gemini entegrasyonu

**Sonraki kanıt (25.10.2026):** Kullanıcı model değişikliği sonrasında gerçek yerel Gemini web taslak/gönderim/alıcı imza/signed akışını tamamladığını bildirdi. Bu kullanıcı beyanıdır, Codex veya production doğrulaması değildir. Aşağıdaki çağrısız geliştirme kaydı tarihsel olarak korunur; [güncel final raporu](AI_FINAL_RELEASE_REPORT.md).

**25.10.2026. Kod ve fake testler hazır; gerçek Gemini/Anthropic model çağrısı yapılmadı.** Gerçek key aranmadı/okunmadı; kullanıcı hesabının erişimi, kotası ve billing durumu doğrulanmadı. Production DB, Render, commit/push/deploy veya ücretli kaynak işlemi yok.

Başlangıç yerel SHA: `a0c52436538ae90a4d80ab21807fe9dd7e8c7609` (`feat: add agent credential management and API rate limiting`). Bu rapor yeni uncommitted kodu anlatır; canlı sürüm kanıtı değildir.

## Model seçimi: kamuya açık adaylar, hesap teyidi değil

| Model | Resmî belgeye göre durum | Bu istemcide seçim |
| --- | --- | --- |
| `gemini-2.5-flash` | Function calling destekler; artık geçmiş aktif kullanıcılara erişim kısıtı var. | Önceki erişiminiz varsa açıkça seçebilirsiniz; yeni key/proje için garanti değil. |
| `gemini-2.5-flash-lite` | Düşük maliyetli alternatif; 2.5 erişim kısıtını ayrıca kontrol edin. | İncelenmiş free-mode adaylarından. |
| `gemini-3.5-flash-lite` | Yeni projeler için önerilen güncel alternatiflerden; function calling ve ücretsiz katman listeleniyor. | Yeni proje için önerilen deneme adayı; hesabınızda teyit gerekli. |

[2.5 modelinin güncel erişim notu](https://ai.google.dev/gemini-api/docs/models/gemini-2.5-flash), [3.5 Flash-Lite özellikleri](https://ai.google.dev/gemini-api/docs/models/gemini-3.5-flash-lite), [resmî fiyat tablosu](https://ai.google.dev/gemini-api/docs/pricing) 25.10.2026'da kontrol edildi. Eski indekslenmiş sayfada “free” yazması yeni hesabın 2.5 erişimi olduğu anlamına gelmiyor. Daha yeni 3.8 Flash da değerlendirildi; bu dar demo için 3.5 Flash-Lite seçeneği yeterli görüldü, sessiz yükseltme yapılmaz.

Gemini'de **varsayılan model yok**: `SIGNFLOW_LLM_MODEL` zorunludur; model REST path'ine güvenli ID biçimiyle bağlanır. Free modunda yukarıdaki üç model kamuya açık belgelerle incelenmiş allowlist'tir; bu hardcoded model seçimi veya hesap izni değildir. Başka modeli free moduna eklemek ayrıca güncel ücretsiz fiyat/capability incelemesi ister. Paid modunda güvenli biçimde belirtilen başka model ID'si seçilebilir; erişilemiyorsa durur, fallback yoktur.

Gerçek çalıştırmada seçilen model için GET `/v1beta/models/:model` yapılıp isim ve `generateContent` desteği kontrol edilir. Bu kontrol modelin **billing tier'ını** veya free kota miktarını kanıtlamaz. Function calling desteği public capability belgeleriyle incelendi; gerçek protokol/kalite uyumluluğu gerçek denemeyle ayrıca doğrulanacak.

## Ücretsiz / ücretli kullanım sınırı

- `SIGNFLOW_GEMINI_TIER=free` varsayılan. `SIGNFLOW_GEMINI_FREE_TIER_CONFIRMED=true` yoksa key okunmadan/model çağrısından önce program durur. Bu bayrak, AI Studio'da seçilen key'in **doğru projesinin** free tier olduğunu, aktif billing ile ücretli tüketime bağlanmadığını ve koşulları bizzat kontrol ettiğinizi ifade eder.
- REST generateContent için billing'i kapatan bir “free-only” güvenlik parametresine dayanmıyoruz. İstemci Cloud Billing durumunu okuyamaz. Yanlış proje/yanlış beyan ücret yaratabilir; yalnız free istiyorsanız ödeme hesabıyla ilişkili proje kullanmayın. Projenin tier ve limitlerini AI Studio'da doğrulamadan onay bayrağını açmayın.
- Paid moduna otomatik geçilmez. `SIGNFLOW_GEMINI_TIER=paid` için ayrıca `SIGNFLOW_ALLOW_PAID_LLM=true` gerekir. 403/404/429 hata veya kota bittiğinde ücretli modele/projeye/farklı key'e fallback yoktur.
- RPM/TPM/RPD limitlerini kendi projenizin AI Studio limit ekranında görün; burada hesaba özel sayı uydurulmadı. Kota aşımı 429 ile durabilir. SignFlow'un credential başına 60 read / 10 POST kotası ise ayrı bir uygulama sınırıdır.

25.10.2026 fiyat tablosunda 3.5 Flash-Lite ve 2.5 Flash standard metin free tier input/output ücretsiz; paid standard input **$0,30 / 1M**, output (thinking dahil) **$2,50 / 1M** idi. 2.5 Flash-Lite paid standard **$0,10 / $0,40**. Gerçek maliyet ölçümü yok; bu çalışmada model çağrısı 0, uygulamanın yaptığı model tüketim gideri 0 $. Hesap faturası denetlenmedi. Search/Maps/grounding, cache, audio veya batch araçları eklenmedi.

## Free tier veri koşulları

[Google ek koşullarına](https://ai.google.dev/gemini-api/terms) göre unpaid girdiler/çıktılar ürün ve ML geliştirmesinde kullanılabilir, insan incelemesi yapılabilir; kişisel/gizli veri gönderilmemeli. EEA/İsviçre/UK veri koşulları ve aktif billing'li projeler için farklı hükümler var. Paid hizmetlerde içerik ürün geliştirmesinde kullanılmaz; sınırlı güvenlik/uyum logları tutulabilir. Hesabınızın konumu/projesine uygulanan güncel koşulları kendiniz kontrol edin. Bu entegrasyon yalnız sentetik demo verisi içindir; müşterinin gerçek sözleşmesi/kişisel bilgisi veya tam şablon metni gönderilmez.

## Mimari ve korunan davranışlar

`SIGNFLOW_LLM_PROVIDER=gemini` yeni `GeminiProvider` adaptörünü seçer. Belirtilmezse önceki Anthropic varsayılanı sürer; Anthropic paid consent ve mevcut model varsayılanı korunur. Ortak system policy aynı metinle ayrı `Policy` modülüne alındı; model/araç güvenlik kuralı değiştirilmedi.

Sabit REST host: `generativelanguage.googleapis.com`, TLS doğrulaması açık, proxy env devralınmaz, redirect izlenmez. Key yalnız `x-goog-api-key` header'ında; URL/query/job/model context/loga yazılmaz. Sağlayıcı key'i env veya IO.console.getpass; bağımsız CLI .env dosyasını otomatik yüklemez. Sonraki web yapılandırmasında Rails development için dotenv-rails eklendi; test/production yerel dosyaları yüklemez, Render Environment Variables kullanır. SignFlow token'ı yalnız SignFlow transport'undadır.

Üç function declaration `parametersJsonSchema` ile mevcut strict tool şemalarından üretilir. [REST FunctionDeclaration referansı](https://ai.google.dev/api/generate-content?authuser=01&hl=en#FunctionDeclaration), [function calling rehberi](https://ai.google.dev/gemini-api/docs/function-calling). Modelin `functionCall` yanıtı Runner'ın tool_use biçimine, tool_result cevabı Gemini `functionResponse` nesnesine çevrilir. Model/endpoint/key/owner parametresi araçlarda yoktur. Bilinmeyen araç, code execution/medya part'ı, bozuk args, blocked/truncated yanıt, kaynak model uyuşmazlığı ve geçersiz usage reddedilir.

Gemini [thought signature'ları](https://ai.google.dev/gemini-api/docs/generate-content/thought-signatures) değiştirilmeden, orijinal model parts sırasıyla yalnız adaptör belleğinde tutulup sonraki isteğe döndürülür. Runner'a, stdout'a ve job dosyasına verilmez; raw chain-of-thought istenmez. İç normalized call ID'si wire ID'ye eşlenir; provider history ile oynanması reddedilir. Provider değişirse adaptör yeni bellekte başlar; kaydedilmiş payload'lı job yalnız deterministic `--resume` ile kurtarılır.

Runner aynı kalır: eksik alanlar sorulur, kullanıcı mesajında bulunmayan e-posta/tarih/tutar reddedilir; açık TL/TRY/₺ tutarı korunur. TemplateVersion sabit; yerel EVET onayı; renderer metni sunucuda üretir. Gönderim yalnız web oturumu/CSRF ile insan tarafından yapılır. Gemini'ye cookie/parola/CSRF/imza token'ı verilmez.

401/403/404 tekrar edilmez; 429/500/502/503/504 ve timeout için en fazla iki deneme/0,5 sn backoff. Sağlayıcı HTTP hata gövdesi loglanmaz. API draft retry/key/payload ve `--resume` davranışı değişmez. Gemini candidate output + thoughts token sayısı Runner output usage alanına toplanır; yalnız başarılı response sayılarıdır, kesin fatura değildir. Mantıksal 8 model turu/10 tool/3 soru sınırları ve response/history boyut sınırları korunur; Gemini max output 2048'dir. 2.5'te desteklenen thinkingBudget=0 kullanılır; yeni modellerde sürüme özgü thinking ayarı varsayılmaz.

## Kullanıcının kendi terminalinde gerçek deneme

**Aşağıdaki komutlar bu çalışma sırasında çalıştırılmadı.** Ücretli/ücretsiz gerçek çağrıyı yalnız siz, proje/tier ve veri koşullarını kontrol ettikten sonra başlatın.

Birinci PowerShell, yalnız yerel sunucu:

```powershell
$env:AGENT_API_ENABLED='true'
bundle exec rails server
```

Web'de kendi sentetik hesabınız → **Agent erişimi** → credential oluşturun. Token ilk yanıtta gösterilir; ekranı projeksiyona yansıtmayın. Kendi şablon/sürüm ID'lerinizi belirleyin.

İkinci, etkileşimli PowerShell; 12/28 yer tutucudur:

```powershell
$env:SIGNFLOW_LLM_PROVIDER='gemini'
$env:SIGNFLOW_LLM_MODEL='gemini-3.5-flash-lite'
$env:SIGNFLOW_GEMINI_TIER='free'
$env:SIGNFLOW_ALLOW_PAID_LLM='false'
$env:SIGNFLOW_SYNTHETIC_DATA='true'
$env:SIGNFLOW_BASE_URL='http://127.0.0.1:3000'
$env:SIGNFLOW_ALLOW_LOOPBACK_HTTP='true'
$env:SIGNFLOW_TEMPLATE_ID='12'
$env:SIGNFLOW_TEMPLATE_VERSION_ID='28'
```

**Ancak doğru projenin free/billing-off durumunu bizzat doğruladıktan sonra:**

```powershell
$env:SIGNFLOW_GEMINI_FREE_TIER_CONFIRMED='true'
ruby script/signflow_agent.rb --job gemini-ders-001
```

Env'de key/token yoksa istemci `SIGNFLOW_API_TOKEN` ve `GEMINI_API_KEY` için maskeli giriş ister. Gerçek değerleri komut satırına yazmayın, sohbete yapıştırmayın; terminal kaydı kapalı olsun. Key okumayan bir terminale pipe/redirect kullanmayın. Program ücretsiz hesapta erişim bulamazsa hata verir; bunu başarı saymayın. 2.5 erişiminiz varsa yalnız model değişkenini kendiniz `gemini-2.5-flash` olarak seçebilirsiniz; otomatik fallback yapılmaz.

Sentetik talep: “Ahmet için 25 bin TL'lik yazılım sözleşmesi hazırla.” Eksik e-posta ve açık, gelecekteki ISO8601 son tarihini tamamlayın; şablonda varsa hizmet tarihlerini de verin. Alanları kontrol edip EVET yazın. Araç/HTTP kodu ve doğrulanan draft metadata'sını gösterin. Aynı iş/retry:

```powershell
ruby script/signflow_agent.rb --job gemini-ders-001 --resume
```

Resume yeni Gemini çağrısı yapmaz; aynı payload/key ile API replay ve GET'tir. 429'da bekleyin; yeni job/key açmayın. Web'de taslağı inceleyip kendiniz gönderin; alıcı demo imzalasın. Agent imzaya gönderemez. İş bitince credential'ı web'den iptal edin, terminali kapatın. [Mevcut tam demo akışı](AGENT_LLM_DEMO.md).

Anthropic'e dönüş için `SIGNFLOW_LLM_PROVIDER=anthropic` ve Anthropic model ID'si seçilir; önceki paid izin mekanizması aynen geçerlidir. Gemini free beyanı Anthropic veya Gemini paid kullanım izni sayılmaz.

## Gerçek yerel test sonuçları

| Kontrol | Sonuç |
| --- | --- |
| Test-first Gemini adaptörü henüz yokken | 6 test / 2 assertion; 2 failure, 4 error (eksik GeminiProvider). |
| İlk adaptör + mevcut core/Anthropic testleri | 22 test / 159 assertion; hata yok. |
| Genişletilmiş provider/core/handoff hedefli paket | 28 test / 206 assertion; 0 failure/error/skip. |
| Tam Rails paketi | **152 test / 1501 assertion; 0 failure/error/skip**. |
| Ayrı PostgreSQL 18 | **31 test / 404 assertion; 0 failure/error/skip**. İki bağlantılı idempotency, credential/kota ve fake Gemini → gerçek Rails API → insan CSRF → signed dahil. |
| RuboCop | **105 dosya; ihlal yok**. Bir ek testte tek tırnak stil ihlali düzeltildi. |
| Zeitwerk | All is good! |

Windows opsiyonel libvips DLL/Rack uyarıları görüldü. Testler fake model/transport kullanır; Google/Anthropic hesabınızın başarısı değildir. Uzak CI, gerçek browser, Google hesabı ve Render doğrulanmadı. CI PG job'ına Gemini handoff testi eklendi; yeni key veya ücretli job yoktur.

## Değişen dosyalar ve sınırlar

- Yeni: `script/support/llm/gemini_provider.rb`, `provider_config.rb`, `policy.rb`; `test/lib/gemini_provider_test.rb`, `provider_config_test.rb`; `test/support/gemini_transport.rb`; `test/integration/gemini_agent_handoff_test.rb`; bu belge.
- Güncellenen: `script/signflow_agent.rb`, `script/support/signflow_agent.rb`, `script/support/llm/anthropic_provider.rb`, `.env.example`; `test/lib/signflow_agent_test.rb`, `test/integration/llm_agent_handoff_test.rb`; `.github/workflows/ci.yml`; README/AGENT/CHALLENGE.
- Core Runner, Tools, kalıcı job/DB idempotency, API controller/model/credential/kota ve web CSRF/session kuralları değiştirilmedi. Anthropic system prompt metni korunarak ortak Policy'ye taşındı. Yeni gem/migration yok.

İlk prompt korunuyor. Mevcut development kayıtları/production DB değiştirilmedi. Gerçek LLM çağrısı/usage ölçümü yok; fake fixture sayılarını gerçek tüketim saymayın. İnsan ve coding-agent süreleri ölçülmedi. Legacy model/proje erişimi, free billing teyidi ve gerçek model çıkarım kalitesi kullanıcı denemesinde açık kalan konulardır.

Son denetim: ilk prompt hash'i ve önceki Challenge içeriği aynı; altı development tablosunun satır hash'leri değişmedi. Yalnız bu iş için açılan `tmp/gemini-integration/postgres-data` cluster'ı kapatıldı; dosyaları/verileri silinmedi. Yerel Markdown bağlantıları ve code fence'leri kontrol edildi.
