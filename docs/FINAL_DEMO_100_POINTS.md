# SignFlow AI — 100 puan kriteri için canlı demo rehberi

**Denetim tarihi: 25.10.2026 (Europe/Istanbul).** Bu belge 3–5 dakikalık sunum planıdır; gösterim henüz yapılmış gibi yazılmaz ve not garantisi vermez. [Final Challenge kanıtları](../CHALLENGE_LOG.md#final-canlı-kabul-ve-ödev-kanıtları--25102026). Yalnız belgeleme yapıldı; bu denetimde model çağrısı, production yazımı, commit/push/deploy yok.

## Tek cümlelik fark

“Bu hafta SignFlow'a, doğal dil talebinden alanları çıkaran ve eksikleri soran gerçek Gemini agent akışı ekledik. Agent sabit bir şablon sürümünden taslak hazırlanmasına katkı veriyor; gerçek belgeyi oluşturma ve imzaya gönderme kararı kullanıcıda kalıyor.”

Eski kayıt/dashboard/imzalama sistemini baştan anlatmayın. Bu sistem, yeni farkın çalıştığı mevcut altyapıdır. Üründeki Gemini agent ile kodu geliştiren Codex'i ayırın. `script/agent_demo_client.rb` deterministik HTTP istemcisidir; AI zekâsının kanıtı olarak sunulmaz.

## Sunumdan önce — öğrenci hazırlığı

- Canlı adres: **https://signflow-k2tg.onrender.com/**. Giriş yapılmış, tamamen sentetik bir demo hesabı ve ona ait Yazılım Geliştirme Hizmet Sözleşmesi hazır olsun. Yeni hesaptaki üç başlangıç şablonunu ana gösterimde uzun kayıt akışıyla anlatmayın; sorulursa gösterin.
- Sunumu yalnız kendi yetkili demo hesabınızda planlayın. Aşağıdaki adımlar gerçek model isteği ve yeni draft kaydı oluşturur; bu belgeleme denetiminde uygulanmadı. Free proje/model erişimi ve veri kullanımı koşullarını siz doğrulayın. Ücretsiz bayraklar fatura garantisi değildir; ücretli kullanım izni varsaymayın.
- Dört sekme hazırlayın: canlı uygulama, **güncel CHALLENGE_LOG**, GitHub commit geçmişi/CI, AGENT.md + build/start dosyaları. Belge teslim commit'i GitHub'a gönderildiyse o sürümü açın; gönderilmemiş yerel değişiklikler varsa bunları uzak sürümle karıştırmayın.
- `.env`, Render Environment değerleri, credential ekranı, dump, raw model/log yanıtı veya imza bağlantısı göstermeyin. Tarayıcı otomatik doldurma gerçek isim/e-posta getirmesin.
- Kaynak şablon ve sürümün doğru hesaba ait olduğunu, seçilen sürümdeki alanları önceden okuyun. Deploy/restart sırasında konuşma kaybolabilir; sunum ortasında deploy yapmayın. Model gecikmesi için kısa pay bırakın; 3–5 dakika bir plan, servis SLA'sı değildir.

## Kesin sıra — yaklaşık 4 dakika 40 saniye

| Zaman | Ekran / işlem | Söylenecek veya gösterilecek kanıt |
| --- | --- | --- |
| 0:00–0:20 | **Canlı URL → AI ile Sözleşme Oluştur** | Adres çubuğunu ve yeni özelliği gösterin. “Önceki uygulamaya bu hafta eklediğimiz farkı göstereceğim.” Eski landing page anlatımında kalmayın. |
| 0:20–0:50 | Kendi yazılım şablonunu seçin, sentetik veri onayını verin, konuşmayı başlatın | Hesaba ait sabit TemplateVersion kullanıldığını belirtin. Aşağıdaki kısa eksik talebi gönderin. |
| 0:50–1:50 | Gemini'nin eksik alan sorularını görün, eksikleri tamamlayın | “Model alıcı/hizmet/tutarı doğal dilden çıkarıyor; eksik e-posta ve tarihleri uydurmak yerine soruyor.” Gerçek çıkan soruları gösterin; önceden yazılmış soru çıkmış gibi davranmayın. |
| 1:50–2:30 | Sağ panel alanlar, sürüm ve önizleme → **Taslağı Oluştur** | Önizleme aşamasında henüz Document yok. Alanları gerçekten inceleyin, sonra düğmeye basın. Normal Document ekranında draft durumunu gösterin. Bu onay imzaya göndermez. |
| 2:30–3:20 | **CHALLENGE_LOG → Final Canlı Kabul ve Ödev Kanıtları** | Continue gerekçesi, problem/kaynak sınırı, ilk prompt konumu, kanıt kapsamları ve başarısızlıkları gösterin. “Yerel gerçek model kabulü kullanıcı beyanı; testler fake; canlı denemeyi şimdi yapıyoruz.” |
| 3:20–3:55 | **Git commit geçmişi → SHA'ya bağlı CI** | `0b088dd` farkı, `cd8919f` güvenlik düzeltmesi, `27dd021` yeni kullanıcı seti. Son CI'daki beş success'i ve SHA'yı birlikte gösterin. |
| 3:55–4:40 | Render/AGENT.md soruları | Aşağıdaki kısa cevapları kullanın. Özellikle build → start/migrate → Puma, secret yönetimi, tek süreç ve insan gönderim sınırı. |

Alıcı imza akışını ana 3–5 dakikaya tekrar sığdırmak zorunda değilsiniz: eski iş akışına katkıyı yeni draft ile gösterin. Hocanız isterse ayrıca, yalnız sentetik ve yetkili oturumla insan gönderimi/alıcı demo imzası adımlarını tamamlayın. Bu ek gösterim yapılmadan “production'da imzaya kadar şimdi doğruladım” demeyin; imza token'ını projeksiyona yansıtmayın.

## Kullanılacak sentetik metinler

İlk talep — e-posta ve tarihleri özellikle eksik bırakın:

```text
Demo Deniz için 25 bin TL tutarında web sitesi geliştirme sözleşmesi hazırla.
```

Model sorunca gereken alanları tek açık yanıtta tamamlayabilirsiniz:

```text
Alıcı adı Demo Deniz. Hizmet web sitesi geliştirme.
Alıcı e-postası demo.deniz@example.com.
Başlangıç tarihi 2026-11-01, bitiş tarihi 2026-12-01.
Son imza tarihi 2026-10-31T18:00:00+03:00.
Ücret 25 bin TL.
```

Bu tarihler 25.10.2026 için örnektir; sunumda son imza tarihi gelecekte olmalı. Tarih geçmişse kendiniz açıkça güncelleyin. Mevcut doğrulama hizmet tarihleri için YYYY-MM-DD, imza son tarihi için offset'li ISO8601 ve alanların kullanıcı mesajında birebir bulunmasını ister. “Yarın”ı otomatik hesaplıyor veya “25 bin TL”yi sessizce başka tutara çeviriyor diye anlatmayın. Bu sınırlar gerçek LLM'in alan çıkarma/araç seçimi katkısını kaldırmaz; riskli tahmini engeller.

Önizlemede alıcı/e-posta/tutar/tarihler ve sabit şablon sürümünü kontrol edin. İçerik Gemini'nin serbest hukuki metni değildir; mevcut `Documents::Manage` ve `Templates::Renderer` ile seçilen şablondan hazırlanır. Nitelikli e-imza veya hukuki görüş iddiası yoktur.

## “Gerçek agent burada nerede?”

Gemini doğal dildeki veriyi izinli alanlara eşler, hangi bilgilerin eksik olduğunu seçer ve izinli function call önerir. Sunucu bu öneriyi sahiplik, allowlist, grounding, tutar/tarih ve boyut kurallarıyla denetler. Ekrandaki soru metni, modelin seçtiği eksik alanların güvenli Türkçe etiketleridir; ham model paragrafı doğrudan basılmaz. Başarı kararı modelin “tamamlandı” demesinden çıkarılmaz.

Ortak Runner/Tools üç araç tanımlar: `get_template_version`, `create_draft`, `get_draft`. CLI/API akışında bunlar şablonu okuma, EVET onayı sonrası taslak ve o işin taslağını doğrulama içindir. **Web'de** şablon okuma `AiContracts::TemplateAccess` ile doğrudan owner servisinden yapılır; kendine bearer HTTP çağrısı yoktur. `create_draft` önerisinde `Runner#advance` durur. Ayrı browser onayı `AiContracts::CreateDraft` ile yazar; sonuç normal owner belge ekranında görülür. Web demosunda modelin üç aracı da otomatik çalıştırdığını veya keyfi belge okuyabildiğini iddia etmeyin.

Kod kanıtı gerekirse yalnız kaynak dosyaları açın: [ProviderFactory](../app/services/ai_contracts/provider_factory.rb), [Runner](../script/support/llm/runner.rb), [Conversations](../app/services/ai_contracts/conversations.rb), [CreateDraft](../app/services/ai_contracts/create_draft.rb). Fake sağlayıcı yalnız testlerde enjekte edilir; test başarısı gerçek model erişiminin yerine geçmez.

## Mevcut kanıtların kapsamı

| Kanıt | Kullanılabilecek ifade | Kullanılamayacak çıkarım |
| --- | --- | --- |
| Yerel gerçek Gemini akışı | Kullanıcı doğal dil/eksik bilgi/draft/gönderim/alıcı imza/signed tamamladığını bildirdi. | Codex bağımsız production testi yaptı. |
| Render AI sayfası/şablonlar | Kullanıcı canlı UI'yı gördüğünü bildirdi. | Sadece ekranın açılması canlı model çağrısını kanıtlar. |
| Yeni hesap canlı düzeltmesi | Kullanıcı başlangıç şablonlarının canlıda düzeldiğini bildirdi. | Yeni hesabın production'da gerçek modelden imzaya kadar bağımsız testi yapıldı. |
| Yerel otomatik paket | Son gönderim oturumunda Rails 197/2111, ayrı PG 86/1226; hata/atlama yok. | Bu belge denetiminde tekrar çalıştırıldı veya fake model zekâsı kanıtlandı. |
| Güncel CI | Son iki SHA için beş gerçek iş success; bu denetimde public API ile yeniden sorgulandı. | CI production deploy SHA'sını, Google hesabını veya browser kabulünü doğrular. |

Bu denetimde anonim canlı ana sayfa erişimi web aracı ve HTTP GET ile doğrulanamadı. Bu durumun uygulamanın kapalı olduğunu kanıtladığı söylenmez; kullanıcı beyanı ayrı tutulur. **Production'da bağımsız yeni LLM → draft uçtan uca kanıtı hâlâ açık.** Öğrencinin canlı gösterimi bu açığı hedefler; başarısız olursa mevcut yerel kabul ve CI'yı dürüstçe gösterin, 100 puan canlı koşulu tamamlandı demeyin.

## Git ve CI sekmesinde açılacak gerçek bağlantılar

| Commit | Fark | CI |
| --- | --- | --- |
| [fb78d61](https://github.com/Huseyinyagmur/signflow/commit/fb78d6111ebfb8863b3fa344d62a5f4484bc2fa4) | Önceki uygulama başlangıcı, 19.10.2026 | Yeni AI kanıtı olarak kullanmayın. |
| [0b088dd](https://github.com/Huseyinyagmur/signflow/commit/0b088dd789a2ed4aa764fb8a99dc42cc11982d60) | Gemini web entegrasyonu | [40177476290: failure](https://github.com/Huseyinyagmur/signflow/actions/runs/40177476290), crass audit. |
| [cd8919f](https://github.com/Huseyinyagmur/signflow/commit/cd8919f3e1273629b46a1ba711ee2e7ecf794948) | crass 1.0.8 güvenlik düzeltmesi | [40177690107: success](https://github.com/Huseyinyagmur/signflow/actions/runs/40177690107). |
| [27dd021](https://github.com/Huseyinyagmur/signflow/commit/27dd021a5c0403a229b09679a9657f585988aa93) | Yeni kullanıcı başlangıç seti | [40181904712: success](https://github.com/Huseyinyagmur/signflow/actions/runs/40181904712). |

Başarılı son iki CI'da `scan_ruby`, `scan_js`, `lint`, `test`, `agent_postgresql` ayrı ayrı success. `0b088dd` SHA'sındaki Dependabot başarıları başarısız tam CI yerine konmaz. Ara commit'ler: `d0e7479` Agent API, `7878ea9` LLM istemcisi, `a0c5243` credential/kota; tam bağlantılar Challenge final bölümünde. Takvim olarak geçen hafta 12–18 Ekim istenirse gerçek son commit [207901b](https://github.com/Huseyinyagmur/signflow/commit/207901b928d6eb47345576ebf24bc48aad9230a2); 19 Ekim baseline'ını bu tarihle karıştırmayın.

Yerel salt okunur kontrol: `git log -8 --oneline`. Geçmiş başarısızlıkları saklamayın. Belge tesliminin gerçek commit SHA ve CI bağlantısını teslim sonucundan kontrol edin; belge commit'inin CI sonucu uygulama sürümünün production'da dağıtıldığı anlamına gelmez.

## Render ve AGENT.md için kısa cevaplar

| Soru | Söylenecek kısa ve doğru cevap / dosya |
| --- | --- |
| Codex deploy'u nereden öğrendi? | Kullanıcı talimatları, [AGENT.md](../AGENT.md), [README](../README.md), [Render rehberi](RENDER_DEPLOYMENT.md), gerçek build/start/Puma/database dosyalarını okuyarak. Render hesabındaki ayarları kendiliğinden bilmiyor. |
| AGENT.md ne yapıyor? | Projenin amacı, mimari/güvenlik kararları, test/deploy komutları ve ajanların yapmaması gereken işlemleri kaydeder. Çalışan uygulama kodu, secret deposu veya otomatik deploy izni değildir; kullanıcı talimatları önceliklidir. |
| Build aşaması? | [render-build.sh](../bin/render-build.sh): production, bundle install, komuta özel dummy secret ile assets:precompile; Tailwind hook'u dahil. Migration/seed/model çağrısı çalıştırmaz. |
| Start aşaması? | [render-start.sh](../bin/render-start.sh): DATABASE_URL/master key guard, runtime dummy key yasağı, db:migrate, başarılıysa exec Puma. Hata varsa yeni süreç başlamaz. |
| PostgreSQL migration nasıl? | [database.yml](../config/database.yml) production'da PG URL kullanır; Rails bekleyen migration'ları start sırasında uygular. [Conversation migration'ı](../db/migrate/20261025000200_create_ai_contract_conversations.rb) yeni tablo/FK/index ekler, eski kullanıcı/belge/imzayı güncellemez. Başlangıç şablonu düzeltmesi yeni migration istemez; kayıt transaction'ında çalışır. |
| Auto-Deploy neden Off? | Push'un kontrolsüz production yayını başlatmasını önlemek, CI/backup ve insan yayın kararını ayırmak. Kullanıcı Off teyidi verdi; gelecekteki durum için yeniden kontrol gerekir. Auto-Deploy Off, modeli veya insan onayını kapatan bir ayar değildir. |
| Neden pg_dump/restore? | Production verisini korumak ve yedeğin geri yüklenebilirliğini sınamak için. Kullanıcının 25.10.2026 terminal kanıtına göre custom dump ve --list başarılı; ayrı yerel signflow_restore_test üzerinde pg_restore --single-transaction --exit-on-error hatasız, altı tablo geri yüklendi. Bu kullanıcı kanıtıdır; Codex'in bağımsız testi veya tam uygulama felaket kurtarma kabulü değildir. |
| Gemini key neden env'de? | Yerelde gitignored .env yalnız Rails development'ta dotenv ile yüklenir; production Render Environment kullanır. Key backend'de kalır, modele/HTML'e/URL'ye gönderilmez; mevcut process ENV önceliklidir. Key'i göstermek kanıt değildir. |
| Neden WEB_CONCURRENCY=0? | [puma.rb](../config/puma.rb) için worker çatallamadan tek uygulama süreci. Konuşma/kota bellekte; çok worker/instance ortak durum sağlamaz. Restart'ta konuşma/kota kaybolabilir; PG'deki belge/receipt kalır. |
| Agent neden otomatik gönderemez? | Tools allowlist'inde send/sign yok; web model önerisi yazmadan durur. Taslak için ayrı kullanıcı POST'u, gönderim için owner session/CSRF ve Document durum kuralları gerekir. Bu sınır bir system prompt vaadine bırakılmamıştır. |

Teknik referanslar: [Render deploy/Auto-Deploy](https://render.com/docs/deploys), [rollback](https://render.com/docs/rollbacks), [PostgreSQL pg_restore](https://www.postgresql.org/docs/current/app-pgrestore.html). Kod rollback'i DB restore'u değildir. Dosya boyutu/--list tek başına restore kanıtı olmaz; burada ayrıca başarılı gerçek yerel restore için kullanıcı terminal çıktısı vardır. Free PostgreSQL'in ömür/backup sınırları ve free Gemini kullanımının fatura garantisi olmaması ayrıca devam eder.

### Kullanıcının restore kanıtı — 25.10.2026

| Bildirilen işlem / ölçü | Kullanıcının sağladığı sonuç |
| --- | --- |
| Kaynak | Gerçek Render production yedeği: `signflow-20261025-115841.dump`, PostgreSQL custom, 21.039 byte. Dosya bu denetimde açılmadı veya Git'e alınmadı. |
| Dump ve liste | `pg_dump` başarılı; `pg_restore --list` başarılı. |
| İzole hedef ve restore | Ayrı yerel `signflow_restore_test`; `pg_restore --single-transaction --exit-on-error` hatasız. |
| Geri yüklenen tablolar | Altı tablo. Diğer iki tablonun adları/sayıları verilmedi; burada tahmin edilmiyor. |
| Kullanıcı ve belge | **1 user, 8 documents**; belge durumları **2 draft, 6 signed**. |
| Şablonlar | **3 templates, 7 template_versions**. |
| Kanıtın kapsamı | Kullanıcının terminal çıktılarından bildirilen başarılı yerel PostgreSQL restore testi. Codex'in bağımsız yürüttüğü test veya yeniden çalışan uygulama üzerinden tam felaket kurtarma doğrulaması değil. |

Sunum cümlesi: “Production yedeğimi ayrı yerel veritabanına hatasız geri yükledim; kayıt sayılarını terminalde kontrol ettim. Bu yerel DB restore testidir, uygulama seviyesinde tam felaket kurtarma provası yaptığımı söylemiyorum.” Bu cümle öğrenci/kullanıcı içindir; Codex'in yaptığı bir işlem gibi aktarılmaz. Dump içeriği veya gerçek kişi/belge verileri gösterilmez.

## 85 puan için teslim kontrolü

- [x] Fark, haftanın vaadi ve gerekçeli Continue açık; eski SaaS anlatımı ana sunumdan çıkarıldı.
- [x] Challenge'ın dokuz başlığı, gerçek commit geçmişi, başarısızlıklar ve test/CI bağlantıları mevcut.
- [x] İnsan/coding-agent zamanı, model/token/maliyet ve yeni kullanıcı araştırması bilinmiyorsa açıkça bilinmiyor; tahmin gerçek veri yerine geçirilmedi.
- [x] İlk prompt bloğu korunuyor; önceki kayıtta link/satır sonu normalizasyonu notu var. Bu denetim arşivdeki ham kaynakla yeni byte-birebir karşılaştırma iddiasında bulunmaz.
- [x] Yerel kullanıcı kabulü, canlı UI/kullanıcı beyanı ve otomatik/CI kanıtları ayrılmış.
- [ ] Öğretmen önünde canlı hedefin o anda çalıştığı gösterildi; bu gelecekteki kabul henüz işaretlenmez.

## 100 puan için ek canlı kontrol

- [x] Gerçek Gemini adaptörü/function calling, dar araçlar, server validation ve insan onayı kodda; fake testler ayrıca etiketli.
- [x] Kullanıcıdan yerel gerçek LLM uçtan uca kabul beyanı var; canlı UI ve yeni kullanıcı düzeltmesi beyanı var.
- [ ] Canlı URL'de yeni bir sentetik talep gerçek Gemini ile işlendi; hazır ekran veya fake yanıt kullanılmadı.
- [ ] Eksik alan diyaloğu, şablon önizlemesi ve açık onay sonrası gerçek production draft aynı oturumda gösterildi.
- [ ] Önerilen ek kanıt kaydı alındı: tarih, görülen sürüm/SHA teyidinin kaynağı, model ID (gizli olmayan), sonuç; varsa gerçek usage ayrı kaydedildi. Key/token/ham müşteri verisi kaydedilmedi. Bu kayıt önerisi hocanın bildirmediği yeni bir zorunlu puan kriteri değildir.

100 puan ek kapısı bu gerçek gösterimle değerlendirilir; ekranın açılması, GitHub'ın yeşil olması veya eski yerel başarı canlı işleme/gösterim kutularını tek başına doldurmaz. Yeni müşteri görüşmesi, ölçülmüş zaman kazancı ve gerçek aktif süre/token/maliyet hâlâ eksik kanıtlardır. Yerel PostgreSQL restore testi kullanıcı terminal kanıtıyla başarılıdır; uygulama seviyesinde tam felaket kurtarma doğrulaması ayrıca kanıtlanmış değildir. Rubrikteki ağırlıkları öğretmen belirler.

## Demo aksarsa

Hata kodunu sır içermeden gösterin; sahte başarı veya fake provider'a sessiz geçiş yapmayın. Yanıt geciktiğinde art arda yeni konuşmalar açmayın; önce mevcut sayfa/normal belge listesini kontrol edin. Ücret/kota/model erişimi hatasında ücretli moda kendiliğinden geçmeyin. Restart/TTL ile konuşma kaybolduysa açıkça söyleyin. Önceki kullanıcı kabulü ve CI'yı yedek kanıt olarak sunabilirsiniz; o günkü canlı LLM hedefi tamamlandı demeyin.
