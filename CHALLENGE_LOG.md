# SignFlow Agent — Challenge Log

**Başlangıç tarihi:** 25.10.2026. **Güncel durum:** Güvenli API, Ruby LLM istemcisi ve AI web taslak akışı geliştirildi. Kullanıcı 25.10.2026'da gerçek Gemini ile yerel web talebi → eksik bilgi diyaloğu → taslak → insan gönderimi → alıcı imzası → İmzalandı akışını başarıyla tamamladığını bildirdi. Bu kullanıcı beyanıdır; Codex'in otomatik/bağımsız tarayıcı veya production doğrulaması değildir. Son fake-provider regresyonları ve yayın kapıları [final raporda](docs/AI_FINAL_RELEASE_REPORT.md); [ilk plan](docs/AGENT_FIRST_IMPLEMENTATION_PLAN.md), [Aşama 1](#aşama-1--gerçek-geliştirme-ve-kanıt-25102026), [web geliştirme raporu](docs/AI_CONTRACT_WEB_REPORT.md). Aşağıdaki önceki bölümler tarihsel kayıttır.

## Başlangıç noktası

Başlangıçtaki SignFlow: kullanıcı oturumu, sözleşme taslağı/gönderimi, token bağlantısıyla demo imza; kullanıcıya ait metin şablonları, immutable TemplateVersion, kayıtsız önizleme. Planlama başlangıcında agent API, API credential veya ürün içi LLM yoktu. API/credential için sonraki Aşama 1 kaydı aşağıdadır; LLM hâlâ yok.

Teknik başlangıç: yerel main'deki [fb78d6111ebfb8863b3fa344d62a5f4484bc2fa4](https://github.com/Huseyinyagmur/signflow/commit/fb78d6111ebfb8863b3fa344d62a5f4484bc2fa4), 19.10.2026 12:57:45 +03:00, mesaj `added`. Hash gerçek Git geçmişinden alındı; uzaktaki commit/canlı deployment eşleşmesi ayrıca doğrulanmadı.

“Geçen hafta” 12–18 Ekim takvim haftası olarak isteniyorsa son yerel commit [207901b928d6eb47345576ebf24bc48aad9230a2](https://github.com/Huseyinyagmur/signflow/commit/207901b928d6eb47345576ebf24bc48aad9230a2), 17.10.2026 22:23:27 +03:00. Bu iki anlam ayrıdır; ödevde hangi sınırın istendiği teyit edilene kadar ikisi korunur.

## Acı ve kaynak

Önceki araştırma kaynağı: [Liz Duffié / TrustRadius](https://www.trustradius.com/reviews/docusign-2021-05-20-15-48-31), 25.05.2021, daha esnek şablon düzenleme isteği. [README'nin araştırma bölümü](README.md#gerçek-kullanıcı-problemi-ve-çözümümüz) ve [önceki kanıt raporu](docs/FINAL_EVIDENCE_AUDIT.md) kaynak/erişim sınırlarını koruyor. 25 Ekim bu araçla yeniden açma denemesi erişim hatası verdi; bu hafta yeniden doğrudan doğrulanmış gibi sunulmuyor.

**Yeni acı hipotezi:** Bir otomasyon/agent, aynı alanları insanın tekrar yazması yerine şablondan taslak hazırlayabilsin; yanlış alıcı/metinle kontrolsüz gönderim olmasın. Bu yeni hipotez için henüz kullanıcı görüşmesi veya kullanım ölçümü yok. Eski şablon yorumu agent API talebini, insan onayı ihtiyacının yaygınlığını veya ölçülmüş zaman kaybını doğrudan kanıtlamaz. Hedef: 2–3 potansiyel kullanıcıya mevcut akışı gösterip tekrarlanan veri girişi/inceleme ihtiyacını sormak; izinli, anonimleştirilmiş bulguları ileride eklemek.

## Bu haftanın vaadi

Doğal dil talebini gerçekten LLM ile yorumlayan dar yetkili bir istemci, kullanıcıya ait sabit TemplateVersion üzerinden tek taslak oluşturup sorgulayabilecek. Aynı iş isteği tekrarlandığında mükerrer belge oluşmayacak. Agent imzaya gönderemeyecek; insan mevcut web ekranından inceleyip gönderecek. Gönderim/imza ve eski şablon sürümleri korunacak.

Bu bir hedef, tamamlanmış özellik listesi değil. JSON gönderen smoke script'i tek başına AI zekâsı sayılmayacak. PDF/gerçek e-posta/hukuki görüş/nitelikli imza bu kapsamda yok.

## Yapılanlar ve kanıt

Aşağıdaki tablo ilk planlama anının kaydıdır; tamamlanan geliştirme ve gerçek yeni testler dosyanın sonundaki Aşama 1 bölümünde eklenmiştir.

| İş | Durum | Kanıt / eksik |
| --- | --- | --- |
| Kod, test tanımları, CI ve Render dosyaları incelendi | Yapıldı — statik inceleme | [Planın analiz tablosu](docs/AGENT_FIRST_IMPLEMENTATION_PLAN.md#3-mevcut-kod-analizi-ve-yeniden-kullanım); yeni test çalıştırması değil. |
| Gerçek Git başlangıcı bulundu | Yapıldı — yerel | Üstte iki tarih kapsamı ve hash; remote/canlı SHA teyidi yok. |
| API/kimlik/insan sınırı/idempotency/test/deploy planı | Plan hazır | [Plan](docs/AGENT_FIRST_IMPLEMENTATION_PLAN.md); çalışan uygulama kanıtı değildir. |
| Kimlik doğrulamalı API | Yapılmadı | İleride commit ve HTTP kanıtı eklenecek. |
| LLM agent + gerçek API çağrısı | Yapılmadı | Model ID, güvenli araç metadatası, usage ve hata örnekleri bekliyor. |
| Tekrar isteğinde bir taslak / tenant izolasyonu | Test edilmedi | Çalışan yeni integration ve PG yarış testleri bekliyor. |
| İnsan kontrolü → signed demo | Yeni katmanla yapılmadı | Eski akışın önceki kanıtı yeni API'nin kanıtı sayılmaz. |
| Bu haftanın yerel test / Actions | Çalıştırılmadı | Komut/çıktı, commit SHA, run URL ve job sonuçları henüz yok. |
| Render otomatik deploy / canlı rollout | Kontrol edilmedi / yapılmadı | Dashboard kontrolü ve ayrı yetki gerekli; main'e push yapılmadı. |

İleride her yeni satır için: tarih/saat, gerçek commit, test komutu/çıktısı, demo sonucu, başarısız durum, model/usage ve sır içermeyen kanıt bağlantısı yazılacak. Başarısız denemeler silinip yalnız başarı bırakılmayacak. Şimdiki log bunların yerini doldurmaz.

## Zaman: insan / agent zamanı

| Ölçü | Gerçek kayıt |
| --- | --- |
| İnsan aktif çalışma | Henüz ölçülmedi; tahminle doldurulmadı. |
| Coding agent çalışma | Bu planlama oturumu gerçekleşti; başlama/bitiş süre ölçümü tutulmadı. |
| Üründeki LLM agent çalışma | Henüz çalışmadı; model usage yok. |
| Bekleme / ağ / deploy | Yeni özellik için ölçülmedi. |
| Toplam duvar saati | Ölçülmedi; üstteki paralel süreler toplanmaz. |

[Planın tahmini](docs/AGENT_FIRST_IMPLEMENTATION_PLAN.md#13-tahmini-süre-aşamalar-ve-riskler): 26–42 odaklı saat, belirsizlik payıyla 33–53 saat. Bunlar gerçekleşmiş süre değildir. Önceki proje için kullanıcının bildirdiği 1–2 saat yeni haftanın ölçümü olarak devralınmaz.

## İlk prompt (aynen)

Aşağıda bu yeni ödevin ilk kullanıcı talebi aynen korunmuştur. Bu, ürün içindeki gelecekteki LLM system prompt'u değildir; coding agent'a verilen görevdir.

```text
SignFlow Ruby on Rails 8 projemiz için yeni bir üniversite ödevi başladı.

Ödevin amacı, önceki SaaS klonunu özgünleştirerek agent-first veya gerçek LLM zekâsı içeren çalışan bir fark katmanı eklemek.

Proje: https://github.com/Huseyinyagmur/signflow
Canlı uygulama: https://signflow-k2tg.onrender.com/

ÖNERİLEN ÜRÜN YÖNÜ:
SignFlow Agent — AI agent'ların şablonlardan sözleşme taslağı oluşturabildiği, ancak sözleşmenin imzaya gönderilmesinin insan kontrolünde kaldığı bir sistem.

İLK GÖREVİN: Kod yazmadan önce mevcut projeyi analiz et ve uygulanabilir geliştirme planı hazırla.

1. README.md, AGENT.md, routes, Document modeli, Documents::Manage, Templates::Manage, Templates::Renderer, controller'lar, testler ve Render yapılandırmasını incele.
2. Var olan kodlardan hangilerinin yeniden kullanılabileceğini belirle.
3. Aşağıdaki özelliğin en küçük güvenli uygulamasını tasarla:
   - Agent için kimlik doğrulamalı API.
   - Var olan bir TemplateVersion kullanarak sözleşme taslağı oluşturma.
   - Agent'ın taslağı sorgulayabilmesi.
   - İnsan onayı olmadan imzaya göndermenin yasaklanması.
   - Gerçek agent/otomasyon istemcisinin API'yi çağırdığı çalışan demo.
   - Kullanıcıya ait olmayan şablon ve sözleşmelere erişimin engellenmesi.
   - API kimlik bilgilerinin loglara, GitHub'a veya ekrana sızmaması.
   - Aynı isteğin tekrarlanması durumunda mükerrer sözleşme oluşmasının önlenmesi.
4. Hangi noktada AI agent kullanıldığını netleştir. Basit bir JSON isteğini 'AI zekâsı' olarak adlandırma. Gerçek LLM eklenecekse model sağlayıcısı, maliyet ve güvenlik gereksinimlerini ayrıca belirt.
5. CHALLENGE_LOG.md için ödevde istenen bütün başlıkları içeren bir taslak oluştur:
   - Başlangıç noktası
   - Acı ve kaynak
   - Bu haftanın vaadi
   - Yapılanlar ve kanıt
   - Zaman: insan / agent zamanı
   - İlk prompt (aynen)
   - Karar: devam, pivot veya öldür
6. Geçen haftanın son commit'ini gerçek Git geçmişinden bul. Hash veya URL uydurma.
7. Gerçekte geliştirilmemiş özellikleri 'yapıldı' diye yazma. Kanıt bölümlerini iş ilerledikçe doldur.
8. Yeni özellik için test planını ve GitHub Actions kontrolünü yaz.
9. Render'daki mevcut çalışan sistemi koruyacak deployment planını öner. Otomatik deploy ayarını doğrulamadan değiştirilmiş kodu main dalına gönderme.
10. AGENT.md dosyasındaki mevcut kuralları incele. Coding agent'ın Render dağıtımını nasıl öğrendiğini açıklayabileceğim dosyaları belirle.

ÇIKTILAR:

- docs/AGENT_FIRST_IMPLEMENTATION_PLAN.md
- CHALLENGE_LOG.md (dürüst başlangıç taslağı)
- Önerilen dosya değişiklikleri
- Test senaryoları
- Canlı demo senaryosu
- Tahmini geliştirme süresi ve olası riskler

Bu aşamada uygulama kodunu değiştirme, test sonucu uydurma, commit veya push yapma.

Önce planı sun, ardından kodlamaya geçeceğiz.
```

## Karar: devam, pivot veya öldür

**Başlangıç önerisi: devam — dar kapsamla, henüz geliştirme kararı/başarı sonucu değil.** Mevcut servisler yeniden kullanılabildiği için uygulanabilir görünüyor. Kodlamaya ancak plan görüşü sonrasında geçilecek.

- Devam ölçütü: sahiplik + insan gönderim sınırı + tekrar isteğinde bir kayıt testleri geçer; gerçek LLM sentetik demo tamamlanır; inceleme dahil kullanıcı denemesi anlamlı yarar gösterir.
- Pivot ölçütü: LLM maliyet/erişim/doğruluk engeli çıkarsa dar otomasyon API'si olarak devam seçeneği; bunun gerçek LLM farkı sağlamadığı açık yazılır ve ödev rubriğiyle yeniden karşılaştırılır.
- Öldür/durdur ölçütü: güvenli insan sınırı gösterilemiyor, gerçek veri sızıntısı riski giderilemiyor veya kullanıcı acısı doğrulanamıyorsa yeni katman canlıya açılmaz. Mevcut imzalama sistemi korunur.

Hafta sonu nihai karar, gerçek kullanıcı/teknik kanıt sonrası buraya tarihli ek olarak yazılacak; bugünden başarı ilan edilmiyor.

## Aşama 1 — gerçek geliştirme ve kanıt (25.10.2026)

**Yetki:** Kullanıcının bu konuşmadaki “yalnızca AŞAMA 1” talebi; LLM, commit, push, Render deploy ve ücretli kaynak kapsam dışı. Kodlamadan önce testler yazıldı. İlk prompt konuşmadaki kaynak metinden kontrol edildi: sözcükler korundu, Markdown bağlantı gösterimi düz URL'ye ve satır sonu kaçışları düz satıra dönüştürüldü. Kaynak bilinmiyormuş gibi tahminle prompt yazılmadı.

### Gerçekte yapılan değişiklikler

- AgentCredential: yalnız digest saklanan rastgele bearer token, kullanıcı sahipliği, zorunlu/azami son tarih, geri alınamayan iptal. AgentRequest: owner/operation/key digest unique index'i, document/credential FK'leri ve payload digest. Ek migration dev/test SQLite ve ayrı test PostgreSQL'e uygulandı; production'a uygulanmadı.
- JSON-only üç endpoint: manifest GET, draft POST, agent kaynaklı draft GET. Varsayılan kapalı feature flag; web cookie kimliği API'de kullanılmıyor. Global web CSRF/origin/session ayarları değiştirilmedi.
- Mevcut Templates::Manage, Documents::Manage ve Renderer kullanıldı; sabit sürüm ve bağımsız metin korunuyor. Aynı key/payload bir belge, farklı payload 409. Yeni key semantik mükerrer işi engellemez.
- `script/agent_demo_client.rb` ve güvenli HTTP transport; ayrı operatör provisioning script'i. İstemci **deterministik HTTP smoke**, LLM agent değil. Kullanıcı credential yönetim UI'sı eklenmedi.
- Yeni model/integration/client testleri; ayrı PostgreSQL iki bağlantılı yarış testleri; CI'a agent_postgresql job'ı. Uzak Actions tetiklenmedi/sonucu bilinmiyor.
- [Aşama 1 kullanım/kanıt rehberi](docs/AGENT_API_STAGE1.md), README ve AGENT yönergeleri güncellendi.

### Gerçek komutlar ve sonuçları

| Kontrol | Sonuç |
| --- | --- |
| İlk test yükleme | Başarısız SyntaxError: bloklu `assert_no_difference` çağrısında parantez eksikti; uygulamaya geçmeden düzeltildi. |
| Uygulama öncesi hedefli testler | 16 run, 1 failure, 15 error; AgentCredential henüz geliştirilmemişti. |
| Uygulama sonrası ilk hedefli test | 16 test / 158 assertion, 0 failure/error/skip. |
| `bundle exec rails db:migrate RAILS_ENV=test` | Yeni agent migration'ı test SQLite'ta geçti. |
| `bundle exec rails db:migrate` | Development SQLite'a yalnız yeni tablolar/kısıtlar eklendi. Eski dört tablonun satır hash'leri birebir korundu: 1 kullanıcı, 2 belge, 3 şablon, 3 sürüm. |
| `bundle exec rails test` | 113 test / 1100 assertion, 0 failure/error/skip. Mevcut tüm testler ve yeni insan CSRF → gönderim → alıcı imza → signed testi dahil. |
| Ayrı PostgreSQL 18 migration | Yeni boş loopback `signflow_agent_test` DB'sinde beş migration geçti; mevcut/production DB kullanılmadı. |
| İlk PostgreSQL hedefli testler | 19 test / 178 assertion, 1 failure/0 error. Global sıfır AgentRequest varsayımı diğer testin sentetik kayıtlarını sayıyordu. |
| PostgreSQL düzeltmesi ve tekrar | Kontrol owner.agent_requests kapsamına alındı. 19 test / 178 assertion, 0 failure/error/skip; aynı key ve farklı payload eşzamanlı yarışları geçti. |
| HTTP fixture hazırlığı ilk deneme | Yardımcı geçici script, Manage#create!'a positional hash yerine keyword verdiği için durdu; hash argümanı düzeltilip tekrar başarılı çalıştırıldı. |
| Gerçek yerel HTTP/Puma demo | Ayrı PG test DB'sinde manifest 200, create 201, replay 200, conflict 409, GET 200/draft. İkinci script çalıştırmasında create 200/replay ve aynı document ID; yeni belge oluşmadı. |
| Log kontrolü | Gerçek yerel HTTP demo token'ı test/development log dosyalarında bulunmadı. Render/proxy logları kontrol edilmedi. |
| HTTP iptal ve test kaynakları | Demo credential'ı iptal edildi; aynı token ile gerçek GET 401/unauthorized verdi. Bu çalışma için açılan yerel Puma ve ayrı PostgreSQL cluster'ı kapatıldı; DB dosyaları/kayıtları silinmedi. |
| `bundle exec rubocop` | 82 dosya, 0 ihlal. |
| `bundle exec rails zeitwerk:check` | All is good! |
| `bundle exec rails tailwindcss:build` | Başarılı. |
| `bundle exec ruby bin/brakeman --no-pager` | Çıkış 0; raporda 0 error/0 security warning. Windows Ruby Ractor/fork/forwardable tanılama mesajları görüldü; uzak Linux CI sonucu sayılmadı. |

Windows libvips opsiyonel DLL yükleme, Rack literal string ve Puma Unix signal uyarıları da görüldü; test failure olarak sayılmadı, saklanmadı. Yalnız yerel sentetik PostgreSQL kayıtları ve test kayıtları oluşturuldu. Development'taki eski kayıtlar korunuyor. Yerel HTTP smoke tarayıcı/Render kabul testi değildir.

### İnsan / coding agent / ürün agent zamanı

İnsan aktif süre ve bu geliştirme oturumunun coding-agent süresi güvenilir biçimde ölçülmedi; sayı yazılmadı. Ürün LLM agent'ı çalıştırılmadı, model usage/maliyeti yok. Komutların geçen süreleri bütün mühendislik süresi veya insan kazanımı değildir. Önceki 1–2 saat beyanı bu haftaya taşınmadı.

### Aşama 2 öncesi karar ve eksikler

**Karar: dar API yönüyle devam.** Yerel teknik kabul testleri geçti; bu, kullanıcı acısının veya LLM katmanının doğrulandığı anlamına gelmez. Aşama 2'de gerçek LLM araç döngüsü, sentetik değerlendirme/yanlış alan davranışı, sağlayıcı/veri/maliyet politikası ayrı ele alınmalı. Credential UI/güvenli secret store operasyonu ve API kota/rate-limit henüz yok; genel kullanıma açmadan önce çözülmeli. Render Auto-Deploy ve güncel CI doğrulanmadan main'e push/deploy yapılmayacak. Bu çalışma commit/push/deploy veya ücretli servis oluşturmadı.

## Aşama 2 — Ruby LLM istemcisi, henüz gerçek sağlayıcı kanıtı yok (25.10.2026)

### Başlangıç ve kapsam

Kullanıcının ek dosyadaki Aşama 2 talebi doğrultusunda yalnız yerel istemci, test ve belgeler geliştirildi. Başlangıç yerel SHA: **`d0e747978b13ec55f5cc9edae2c723c4d4fe910b`**, 25.10.2026 08:56:39 +03:00, `feat: add secure agent draft API with idempotency`. Bu SHA Aşama 2 kodunu içermez; yeni kod uncommitted çalışma ağacındadır. Commit/push/deploy yapılmadı. Aşama 1'in ilk prompt bölümü değiştirilmedi, tarihsel kayıtlar silinmedi.

### Yapılanlar ve dosyalar

- `script/signflow_agent.rb`: gerçek sağlayıcı için Ruby CLI, sentetik veri/ücret izni, model preflight, takip soruları, alan onayı, güvenli progress ve sonuç.
- `script/support/signflow_agent.rb`, `script/support/llm/{anthropic_provider,runner,tools,job,secrets}.rb`: provider arayüzü, Anthropic Models/Messages HTTP adaptörü, üç izinli tool, şema/cevap/grounding doğrulama, kalıcı aynı-key/payload recovery, sınırlı retry ve maskeli secret girişi.
- `script/support/agent_http_client.rb`: Aşama 1 transport'una typed HTTP status eklendi; eski deterministik demo istemcisi LLM olarak yeniden adlandırılmadı.
- `.env.example`: yalnız isimler/default; gerçek secret yok, otomatik yüklenmez.
- `test/lib/signflow_agent_test.rb`, `test/lib/anthropic_provider_test.rb`, `test/integration/llm_agent_handoff_test.rb`: fake provider/transport ve gerçek Rails API handoff testleri.
- `.github/workflows/ci.yml`: PG job'ına yeni handoff testi. Uzak job tetiklenmedi/sonucu bilinmiyor.
- `README.md`, `AGENT.md`, bu log; [teknik rapor](docs/AGENT_LLM_STAGE2.md) ve [canlı demo rehberi](docs/AGENT_LLM_DEMO.md).

Agent'a send/sign, session/cookie/CSRF/parola, SQL, terminal veya keyfi HTTP yetkisi eklenmedi. Web/model/route/şema güvenlik kuralları değiştirilmedi. Model tam sözleşme metnini almaz; ham hukuki metin üretemez. Alanlar kullanıcı mesajında bulunmalı; ücret tam açık TL/TRY/₺ ifadesiyle korunur ve yerelde EVET ile doğrulatılır. Bu kontrol, semantik/hukuki doğruluk veya her injection'ın çözüldüğü iddiası değildir.

### Model, gerçek çağrılar ve maliyet

| Alan | Gerçek kayıt |
| --- | --- |
| Yapılandırılan model | `claude-haiku-4-5-20251001`, Anthropic. |
| Kamuya açık erişim/fiyat kontrolü | 25.10.2026 [resmî model sayfası](https://platform.claude.com/docs/en/models/haiku-4-5/overview): Active (legacy), $1/1M input, $5/1M output. Hesap erişim kontrolü değildir. |
| Bu çalışma sırasında gerçek Models/Messages isteği | **0**. Ortamda ANTHROPIC_API_KEY yoktu; özel credential depoları aranmadı, ücretli kullanım izni verilmedi. |
| Gerçekte çalıştırılan model | Yok. Adaptör kodu gerçek key ile henüz sınanmadı. |
| Gerçek input/output token | Ölçüm yok; fake testlerin usage sayıları gerçek değildir. |
| Bu oturumun yaptığı ücretli LLM çağrı maliyeti | 0 $; hesap/fatura denetlenmedi. Coding agent abonelik maliyeti bu alan değildir. |
| Varsayımsal maliyet | 8.000 input + 2.000 output toplamıyla $0,018/iş. Bu ölçüm değil; retry/uzun bağlam/vergiler ayrıca etkiler. |

Gerçek çalıştırma kullanıcı `SIGNFLOW_SYNTHETIC_DATA=true` ve ücret izni için `SIGNFLOW_ALLOW_PAID_LLM=true` açmadan başlamaz. Anahtarlar yalnız env/maskeli console ile alınır; modele/loga verilmez. CLI önce hesapta Models preflight yapar; 401/404 durumunda fake başarı/model fallback yoktur. Bu çalışmada bu bayraklar gerçek sağlayıcı tüketimi için açılmadı.

### Tool çağrısı kanıtı — fake model olduğunu koruyarak

Yeni `LlmAgentHandoffTest` gerçek Rails integration stack'ine üç aracı çağırdı: **get_template_version 200 → create_draft 201 → get_draft 200**. Bu sıralama ve kodlar testte assert edildi. Aynı job'ın resume/replay'inde yeni Document oluşmadı. Ardından ayrı insan web oturumu, gerçek CSRF+Origin formları ve alıcı kabul/ad işlemiyle signed doğrulandı. API credential iptali sonraki araç sorgusunu engelledi.

**Sağlayıcı fake idi.** Bu kanıt gerçek modelin araç seçtiği veya canlı browser/Render demosu yapıldığı anlamına gelmez. Gerçek sağlayıcı tool metadatası, response usage, canlı belge durumu ve fatura sonucu ancak izinli sentetik gerçek denemeden sonra buraya eklenecek. Henüz böyle bir kayıt/video yok.

### Testler, başarısız denemeler ve düzeltmeler

| Adım | Gerçek sonuç |
| --- | --- |
| Test-first ilk çalıştırma | Yeni istemci modülü henüz olmadığından require/load hatası; testler başlamadı. Uygulama bundan sonra eklendi. |
| İlk hedefli core/provider | 13 test / 78 assertion, 0 failure/error/skip. |
| Job/secret kapsamı sonrası | 15 test / 86 assertion, 0 failure/error/skip. |
| İlk handoff integration | 1 test / 15 assertion, başarılı; daha sonra tool/HTTP sırası için iki assertion eklendi. |
| İlk RuboCop | Dört boş lambda aralık ihlali; düzeltildi. Observer eklenince çıkan bir aynı stil ihlali de düzeltildi. |
| Tam SQLite son paketi | `bundle exec rails test`: **130 test, 1212 assertion, 0 failure, 0 error, 0 skip**. Eski testler korunuyor. |
| Ayrı PostgreSQL 18 paketi | Agent credential/API + yeni handoff + iki bağlantılı concurrency: **20 test, 195 assertion, 0 failure/error/skip**. |
| Son RuboCop | `bundle exec rubocop`: **92 dosya, 0 ihlal**. |
| Zeitwerk | `bundle exec rails zeitwerk:check`: All is good! |
| CLI ücret izni reddi | Subprocess testinde ücret izni olmadan çıkış 1; provider/token secret'ı çıktıda yok. Gerçek ağ/sağlayıcı çağrısı yapılmıyor. |

Windows libvips opsiyonel DLL ve Rack literal string uyarıları görüldü; test sonuçlarıyla karıştırılmadı. Normal regresyon SQLite kaldı; yalnız ayrı boş loopback `signflow_agent_test` DB'sine eski beş migration uygulandı. Yeni uygulama migration'ı eklenmedi. Development'taki altı domain/agent tablosunun önce/sonra kayıt hash'leri aynı; mevcut veri silinmedi. Web Document modeli, authentication concern ve session initializer hash'leri değişmedi.

### İnsan / agent zamanı ve karar

İnsan aktif süre ve coding agent süresi güvenilir biçimde ölçülmedi: **bilinmiyor**. Üründeki gerçek LLM agent çalışmadı; fake test süreleri onun yerine yazılmadı. Komut süresi veya önceki projenin 1–2 saat beyanı yeni geliştirme zamanı sayılmadı.

**Karar: kontrollü gerçek sentetik değerlendirmeyle devam.** Kod ve fake testler hazır; gerçek LLM erişimi/kalitesi ve 100 puanlık canlı kanıt henüz açık. İlerlemek için kullanıcı hesabında geçerli workspace key'i, model erişimi ve bütçe izni; ardından gerçek başarı/eksik bilgi/injection denemeleri ve web demosu gerekir. Kullanıcı credential UI'sı/API kotası eksikleri devam ediyor. Render Auto-Deploy/CI/canlı SHA/backup/flag doğrulanmadan push/deploy yok; bu çalışma yeni ücretli altyapı veya gerçek LLM çağrısı yapmadı.

Son kontrol: yalnız bu çalışma için açılan yerel PostgreSQL cluster'ı kapatıldı; kayıt/dosya silinmedi. İlk prompt ve önceki Challenge metni aynen korunuyor; altı development tablosu hash karşılaştırması değişmedi. Son küçük provider wire normalizasyonundan sonra hedefli testler **16 test / 95 assertion, sıfır failure/error/skip** ile geçti. Bu ek test de gerçek modeli çağırmadı.

## Aşama 3 hazırlığı — credential ekranı, kota ve kontrollü yayın (25.10.2026)

Başlangıç yerel SHA: **`7878ea949b75c3bd80f295bd82ca7ed43ee071a5`**, 25.10.2026 09:22:02 +03:00 (`feat: add LLM agent client with safe tool calling`). Bu görevin yeni değişiklikleri commit edilmedi. Üst güncel durum metni düzeltildi: LLM istemcisi geliştirildi ve fake provider ile test edildi; gerçek LLM çağrısı yapılmadı. Önceki tarihsel bölümler ve ilk prompt korunuyor.

### Gerçekte yapılanlar

- Oturum/CSRF/Origin korumalı GET `/agent_credentials`, POST `/agent_credentials`, POST `/agent_credentials/:id/revoke`. Owner kapsamı current_user'dan; süre 1/7/30 gün. Mevcut hash-only AgentCredential modeli kullanıldı, raw token yalnız ilk create POST yanıtında; liste/GET/flash/session/URL saklaması yok. no-store/noindex ve Turbo no-cache korunur.
- API kapalıyken yeni credential engelli; mevcut credential'ların listesi/iptali açık kalır. Bearer token web kimliği sayılmaz; başkasının iptal/liste erişimi engellenir.
- Credential başına 60 saniyede 60 GET/HEAD, 10 POST; replay ve doğrulama başarısızlıkları da sayılır. Auth/iptal kontrolü kotadan önce. 429 + Retry-After; Mutex/MemoryStore tek process demo sınırı. Restart/eviction resetlenir, çok instance ortak kota değildir; DB idempotency/iptal değişmez.
- Dosyalar: `AgentCredentialsController`, `Agents::Credentials`, `Agents::RateLimiter`, iki credential ERB görünümü, API base controller kota callback'i, routes/layout menüsü; yeni UI/kota/thread testleri, test helper ve PG CI job güncellemesi.
- [Aşama 3 raporu ve tam envanter](docs/AGENT_STAGE3_REPORT.md), [kısa gerçek LLM kullanıcı rehberi](docs/REAL_LLM_QUICKSTART.md), [Render kontrol listesi](docs/RENDER_AGENT_RELEASE_CHECKLIST.md). README/AGENT güncellendi; Aşama 2 raporunun tarihsel kapsamı işaretlendi, demo rehberi yeni ekrana yönlendirildi.

### Gerçek test ve hata kaydı

| Kontrol | Sonuç |
| --- | --- |
| Test-first, implementasyon öncesi | 9 test, 75 assertion, 2 failure, 7 error; henüz UI rotaları/kota yoktu. |
| İlk implementasyon sonrası | 9 test, 153 assertion, 3 failure, 2 error. Testte yanlış action'a per-form CSRF token taşınmıştı; global session token ile sahiplik deneyi düzeltildi. 422 sayfasından form okuma, textarea newline ve nested travel_to testleri düzeltildi. CSRF/origin kapatılmadı. |
| İlk düzeltilmiş hedefli paket | 9 test, 190 assertion, sıfır failure/error/skip. Sonra HEAD kotası ve iptalin kota önceliği eklendi. |
| `bundle exec rails test` | **140 test, 1404 assertion, 0 failure, 0 error, 0 skip**. Eski model/şablon/imza/LLM fake testleri dahil. |
| Hedefli API güvenlik/credential/iptal/kota | **27 test, 357 assertion, 0 failure/error/skip**. |
| Ayrı PostgreSQL 18 API/UI/kota/handoff/concurrency | **30 test, 387 assertion, 0 failure/error/skip**. |
| `bundle exec rubocop` | **98 dosya, 0 ihlal**. |
| `bundle exec rails zeitwerk:check` | All is good! |
| `bundle exec rails tailwindcss:build` | Başarılı. |

Windows opsiyonel libvips DLL ve Rack literal string uyarıları çıktı. UI gerçek ERB/formları integration stack'inde test edildi; manuel tarayıcı/görsel veya Render kabul testi yapılmadı. Uzak Actions sonucu bilinmiyor. PostgreSQL için yalnız yeni boş loopback `signflow_agent_test` DB'sinde mevcut beş migration çalıştırıldı; Aşama 3 migration eklemedi ve production DB'ye komut gitmedi.

### Anthropic ve yayın kanıt sınırı

25.10.2026 [resmî model sayfası](https://platform.claude.com/docs/en/models/haiku-4-5/overview) `claude-haiku-4-5-20251001` için Active (legacy), $1/1M input ve $5/1M output gösterdi. Bu, kullanıcı hesabında erişim kanıtı değildir. Mevcut x-api-key/2023-06-01 biçiminin desteklendiği [authentication belgesinden](https://platform.claude.com/docs/en/manage-claude/authentication) kontrol edildi; tek workspace'e scoped key gerekir, multi-workspace header akışı yok.

Gerçek Models/Messages çağrısı **0**; gerçek anahtar istenmedi/okunmadı/kaydedilmedi. Kullanım/fatura ölçümü yok; bu çalışmanın ücretli LLM çağrı gideri 0 $, hesap faturası denetlenmedi. Fake response usage gerçek sayı sayılmadı. Dashboard/Auto-Deploy/canlı SHA/backup/plan/migration durumu doğrulanmadı; kontrol listesi boş kutularla kullanıcıya bırakıldı. Commit, push, deploy veya ücretli servis oluşturma yok.

İnsan ve coding agent süresi ölçülmedi: **bilinmiyor**. Gerçek LLM denemesi için kullanıcı kendi hesabında güvenli anahtar girişi, bütçe izni ve sentetik veriyle preflight/deneme yapmalı. Legacy erişimi, gerçek çıktı kalitesi ve canlı imzalama demosu hâlâ bekliyor; 100 puan koşulunun sağlandığı iddia edilmiyor.

Son denetim: yalnız bu iş için açılan `tmp/agent-stage3/postgres-data` cluster'ı kapatıldı, dosyaları/kayıtları silinmedi. İlk prompt SHA-256 aynı; eski tarihsel metin üst durum satırı hariç birebir korunuyor. Development'taki users/documents/templates/template_versions/agent_credentials/agent_requests satır hash'leri değişmedi. Yeni belge bağlantıları ve Markdown code fence'leri kontrol edildi; yerel bozuk bağlantı bulunmadı.

## Gemini sağlayıcısı — yerel entegrasyon, gerçek çağrı yok (25.10.2026)

Başlangıç yerel SHA: `a0c52436538ae90a4d80ab21807fe9dd7e8c7609`, `feat: add agent credential management and API rate limiting`. Yeni değişiklikler commit edilmedi. Kullanıcının bu görevde ücretsiz çağrıyı da yasaklaması nedeniyle Google/Anthropic model API'sine **hiç gerçek çağrı yapılmadı**, key aranmadı/okunmadı/kullanılmadı. Eski ilk prompt ve tarihsel kayıtlar korunuyor.

### Yapılanlar

- Gemini REST adaptörü, `SIGNFLOW_LLM_PROVIDER=gemini`, zorunlu açık Gemini model ID'si, ücretsiz/ücretli izin ayrımı. Anthropic varsayılanı/ücret izni duruyor; system prompt metni değiştirilmeden ortak Policy modülüne taşındı ve eski metinle karşılaştırıldı.
- Gemini functionCall → Runner tool_use ve tool_result → functionResponse. Opaque thought signature'lar yalnız adaptör belleğinde, raw parts/sıra korunarak geri gönderilir; log/job/Runner'a çıkarılmaz. Üç araç dışı/bozuk/blocked/truncated yanıt ve değiştirilmiş history reddedilir.
- Free modda explicit proje/tier onayı; paid modda ayrıca paid izin. Model/sağlayıcı/anahtar/endpoint fallback yok. URL'de key yok; x-goog-api-key header; maskeli giriş/env. Google key biçimi de source/secret guard'ına eklendi.
- Yeni dosyalar: `script/support/llm/{gemini_provider,provider_config,policy}.rb`, `test/lib/{gemini_provider_test,provider_config_test}.rb`, `test/support/gemini_transport.rb`, `test/integration/gemini_agent_handoff_test.rb`, [docs/GEMINI_INTEGRATION.md](docs/GEMINI_INTEGRATION.md).
- Güncellenenler: CLI/aggregator/Anthropic policy alias, `.env.example`, eski handoff ve CLI test helper'ları, CI PG job'ı, README ve AGENT. Runner/Tools/job ve API/web güvenlik kuralları değişmedi. Yeni gem/migration yok.

### Model ve free tier kanıt sınırı

25.10.2026 [resmî 2.5 model sayfası](https://ai.google.dev/gemini-api/docs/models/gemini-2.5-flash) erişimin geçmiş aktif kullanıcılara sınırlandığını belirtti; yeni API key sahibi için 2.5 erişimi garanti edilmedi. [3.5 Flash-Lite](https://ai.google.dev/gemini-api/docs/models/gemini-3.5-flash-lite) function calling destekli güncel alternatif olarak değerlendirildi; [fiyat tablosunda](https://ai.google.dev/gemini-api/docs/pricing) free tier input/output ücretsiz listeleniyor. Yeni proje için önerilen aday budur; seçimi kullanıcı `SIGNFLOW_LLM_MODEL` ile yapar. Hesabın erişimi/kotası/billing durumu doğrulanmadı.

Free kontrol bayrağı kullanıcının AI Studio'da doğru projenin billing-off/free durumunu kontrol ettiği beyanıdır; istemci billing okuyamaz ve free-only fatura garantisi vermez. 3.5 Flash-Lite / 2.5 Flash standard paid metin fiyatı $0,30 input / $2,50 output (1M token); free ve paid karıştırılmaz. [Unpaid koşullarda](https://ai.google.dev/gemini-api/terms) içerik geliştirme/insan incelemesine konu olabilir; kişisel/gizli veri gönderilmez. Bölge/billing istisnaları kullanıcı tarafından ayrıca kontrol edilir.

Gerçekte çalıştırılmış Gemini modeli yok; modeller yalnız fake transport fixture'larında kullanıldı. Gerçek input/output/usage ölçümü yok, bu çalışmanın gerçek model çağrı gideri 0 $; hesap/fatura incelenmedi. Kullanıcı komutları ve koşullar entegrasyon belgesindedir; bu çalışma sırasında çalıştırılmadı.

### Gerçek test kaydı

| Kontrol | Sonuç |
| --- | --- |
| İlk test-first Gemini koşusu | 6 test / 2 assertion, 2 failure, 4 error; henüz GeminiProvider yoktu. |
| İlk adaptör/core/Anthropic paketi | 22 test / 159 assertion, hata yok. |
| Genişletilmiş hedefli ara paket | 28 test / 206 assertion, sıfır failure/error/skip. Sonra generation-timeout aynı-body retry testi eklendi. |
| Tam `bundle exec rails test` | **152 test / 1501 assertion, 0 failure/error/skip**. |
| Ayrı PostgreSQL 18 | **31 test / 404 assertion, 0 failure/error/skip**. Concurrency, UI/kota, eski ve fake Gemini handoff → insan CSRF → signed dahil. |
| `bundle exec rubocop` | **105 dosya, 0 ihlal**. Ek testteki bir tek tırnak stil ihlali düzeltildi. |
| `bundle exec rails zeitwerk:check` | All is good! |

Fake Gemini protokolüyle eksik bilgi, uydurulmuş e-posta reddi, mevcut ücret/tarih guard'ları, bilinmeyen araç, malformed/blocked/truncated JSON, 401/403/404/429/timeout, aynı generation body ile retry, kalıcı job resume, raw signature/wire ID dönüşümü ve secret sızıntısı kontrolleri test edildi. Fake sağlayıcı + gerçek Rails stack'i model zekâsının veya canlı LLM demosunun kanıtı değildir. Uzak Actions/Render/browser/Google hesap denemesi yapılmadı. Windows opsiyonel libvips/Rack uyarıları görüldü.

### Süre ve karar

İnsan ve coding-agent süreleri ölçülmedi: **bilinmiyor**. Devam kararı, kullanıcının kendi ücretsiz proje/billing teyidi ve sentetik gerçek denemesine bağlı. Gerçek doğal dil kalitesi ve hesap erişimi açık. Ücretli servis, production DB değişikliği, commit/push/deploy yapılmadı.

Son kontrol ilk prompt hash'inin, önceki Challenge içeriğinin ve altı development tablosunun satır hash'lerinin korunduğunu doğruladı. Ayrı yerel PostgreSQL test cluster'ı kapatıldı, dosyaları/kayıtları silinmedi. Belge bağlantıları/code fence'leri ve diff whitespace kontrolü geçti.

## SignFlow AI — web arayüzü (25.10.2026)

### Bu haftanın vaadi ve yapılanlar

SignFlow AI, kullanıcının doğal dilde verdiği talebi gerçek bir LLM ile analiz ederek mevcut sürümlü sözleşme şablonlarından taslak hazırlamayı ve kritik gönderim kararını insana bırakmayı hedefler. Web arayüzü ve backend geliştirildi; bu çalışmada gerçek model/manuel tarayıcı/Render testi yapılmadı. Fake test sonuçları gerçek model zekâsı veya canlı demo kanıtı olarak sunulmaz.

Session/CSRF korumalı `/ai_contracts/new` şablon seçimi, kullanıcıya ait sabit TemplateVersion, diyalog/eksik alanlar, güvenilir kayıtsız önizleme ve ayrı **Taslağı Oluştur** POST'u eklendi. Ortak Runner/GeminiProvider/Tools/Manage/Renderer kullanılır; iç bearer/self-HTTP yoktur. Model önerisi yazma yetkisi değildir. Gönderim ve imza mevcut insan/alıcı akışında kalır. `AI_CONTRACTS_ENABLED` varsayılan kapalıdır.

Yeni conversation tablosu yalnız owner/version/UUID/TTL/document receipt saklar; konuşmalar/model çıktıları/anahtar DB'ye yazılmaz. Diyalog en fazla 64 konuşma/süreç belleğinde; bir saat mantıksal TTL, erişimde temizlik, restart/reload'da kayıp açıkça belirtilir. Aynı step+mesaj replay model çağırmaz; farklı mesaj 409. Taslak transaction/satır kilidi/unique index ile tekilleştirilir. Kullanıcı kotası 10 dakikada 5 start/24 provider işlemi; tek süreç sınırı, fatura garantisi olmaması ve senkron timeout/proxy riskleri belgelenmiştir.

Dosya envanteri, sınırlar, hata analizi ve gerçek sonuçlar: [AI_CONTRACT_WEB_REPORT](docs/AI_CONTRACT_WEB_REPORT.md). Maskeli anahtar girişi, environment ve sentetik canlı deneme adımları: [AI_CONTRACT_WEB_DEMO](docs/AI_CONTRACT_WEB_DEMO.md). README/AGENT/env örneği/PG CI hedefleri güncellendi. Commit oluşturulmadığından yeni commit bağlantısı yoktur; başlangıç HEAD önceki `a0c52436538ae90a4d80ab21807fe9dd7e8c7609` kaydıdır.

### Önceki gerçek Gemini hatası ve başarısız yerel testler

Kullanıcı beyanı: önceki gerçek CLI denemesinde model erişimi ve get_template_version HTTP 200 başarılı, ardından invalid_model_response. Gerçek ham yanıt veya secret aranmadı. HEAD'teki eski Runner, sentetik manifest → fenced soru JSON'unda aynı **invalid_model_response** hatasını verdi; bu somut parser yolu doğrulandı, gerçek olayın kesin aynı yoldan geldiği kanıtlanmadı. Yeni Runner fenced/split soru metnini normalize eder; prose yanıt için bir bounded JSON onarımı, devam ederse güvenli özel hata üretir. Signature/functionResponse akışı fake Gemini protokol testleriyle korunur; STOP dışı/bozuk yanıtlar reddedilir. Ham response/signature/key loglanmaz.

Test-first Runner başlangıcı 3 test/1 assertion: 1 failure/2 error (advance eksik). Web başlangıcı 5 test/4 assertion: 5 error (rotalar eksik). İlk uygulamada test yardımcısı `message`, Minitest yöntemiyle çakıştı: 5 error; `post_message` ile düzeltildi. Sonraki hedefli pakette `ReadOnlyAttributeError` yanlış constant'ı 1 error verdi; Rails'in `ReadonlyAttributeError` adı kullanıldı. RuboCop'ta bir trailing newline düzeltildi. CSRF veya başka güvenlik kontrolü kapatılmadı.

Son test yardımcısı gerçek hidden form token'larına geçirilince tam pakette 2 failure görüldü: farklı action'ın per-form token'ı yabancı taslak POST'unda 404 sahiplik denetimine ulaşmadan 422 üretti. Bu özel sahiplik testinde aynı oturumun global meta token'ı kullanıldı; normal formlarda kendi hidden token'ı korunuyor. Testler tekrar çalıştırıldı; koruma gevşetilmedi.

### Gerçek testler ve kanıt

| Komut/kontrol | Sonuç |
| --- | --- |
| `bundle exec rails test` | **180 test / 1846 assertion; 0 failure/error/skip**, exit 0. |
| İzole PostgreSQL 18 hedefli paket | **55 test / 739 assertion; 0 failure/error/skip**, exit 0. API concurrency ve iki bağımsız web onayı tek draft; belleksiz receipt recovery dahil. |
| `bundle exec rubocop` | **120 dosya; ihlal yok**, exit 0. |
| `bundle exec rails zeitwerk:check` | **All is good!**, exit 0. |
| `bundle exec rails tailwindcss:build` | Başarılı, exit 0. |
| Development/test/ayrı loopback PG `db:migrate` | Yeni tablo/FK/index'ler eklendi; eski kayıt silme/dönüştürme yok. |
| Gerçek Gemini / manuel tarayıcı / Render / uzak Actions | **Yapılmadı; tamamlandı sayılmaz.** |

Testler hem nötr fake provider hem gerçek Gemini adaptörü/fake transport ile eksik bilgi → escaped önizleme → insan onayı → gerçek Document draft → normal liste → insan gönderimi → alıcı signed akışını kapsar. Sahiplik, oturum, gerçek form token+origin, bearer izolasyonu, sentetik onay, grounding/tarih/tutar, bilinmeyen tool, secret/oversize, quota/TTL, mesaj replay/conflict ve çift onay test edildi. Windows opsiyonel libvips DLL/Rack uyarıları görüldü; başarısızlık gizlenmedi. Development'taki mevcut altı tablonun satır hash'leri aynı kaldı. Production'a bağlanılmadı.

### Süre, gerçek LLM maliyeti ve karar

İnsan/coding-agent süreleri ölçülmedi: bilinmiyor. Bu geliştirmede gerçek model çağrısı sıfır; gerçek token/usage/fatura ölçümü yok. Kullanıcının önceki gerçek CLI denemesinin maliyeti bilinmiyor. Ücretsiz katman uygunluğu ve hesabın erişimi kullanıcı tarafından teyit edilmelidir; free/paid izinleri ayrı, gerçek müşteri verisi yasak. Yeni ücretli servis, commit, push veya deploy yapılmadı.

**Karar: devam**, koşullu gerçek sentetik model ve manuel web kabul testine geç. İş gerekçesi: çalışan sürümlü sözleşme/imza akışına daha kolay veri girişi eklemek, AI'ye gönderim/imza yetkisi vermeden taslak hazırlama işini azaltmak. Gerçek model kalitesi ve kullanım maliyeti ölçülmeden fayda kanıtlanmış değildir. Sunum: oturum → AI menüsü → kendi şablonu → eksik bilgi diyaloğu → alan/önizleme → Taslağı Oluştur → normal belge → insan gönderimi → alıcı demo imzası. Ayrıntılar demo rehberinde; bu son gerçek demo kullanıcıya kalan iştir.

Son denetim: ilk prompt SHA-256 aynı ve önceki tarihsel metin birebir korundu (yalnız üst güncel durum satırı güncellendi). Yeni belge bağlantıları/code fence'leri, diff whitespace ve altı mevcut development tablosunun hash'leri kontrol edildi. Yalnız bu görev için açılan `tmp/ai-contract-web/postgres-data` cluster'ı kapatıldı; dosyaları/kayıtları silinmedi. Mevcut kullanıcı web sunucusu/production veritabanında işlem yapılmadı.

## Son testler, kullanıcı demosu ve yayın hazırlığı — 25.10.2026

### Başlangıç, acı ve continue kararı

Önceki ürün; oturum, normal sözleşme, sürümlü metin şablonları, insan gönderimi ve demo imzaydı. Yerel başlangıç HEAD `a0c52436538ae90a4d80ab21807fe9dd7e8c7609`, branch `main`, remote `https://github.com/Huseyinyagmur/signflow.git`. Önceden commit edilmemiş Gemini/web/dotenv/tanılama çalışmaları korundu; bunlar yeni fark katmanının birbirine bağlı kapsamıdır. Veritabanı dosyaları, `.env`, loglar veya geçici kanıt dosyaları commit kapsamına alınmaz.

**Continue:** Mevcut güvenilir şablon/imza sürecini kullanarak tekrar eden alan girişini doğal dille kolaylaştırmak, kritik gönderim kararını insanda tutmak. [Önceki TrustRadius kaynağı](https://www.trustradius.com/reviews/docusign-2021-05-20-15-48-31) şablon düzenleme ihtiyacına bağlam sağlar; [README](README.md#gerçek-kullanıcı-problemi-ve-çözümümüz) erişim/araştırma sınırlarını korur. Yeni AI/agent ihtiyacı için bağımsız müşteri görüşmesi, yaygınlık ölçümü veya zaman tasarrufu deneyi yapılmadı. Geliştiricinin manuel demosu müşteri araştırması değildir.

### Bu haftanın vaadi ve farklılaştırıcı

Gerçek LLM doğal dil talebini yorumlar, izinli araçları seçer, eksikleri sorar ve kullanıcıya ait sabit TemplateVersion için alan önerir. `get_template_version`, `create_draft`, `get_draft` ortak agent araçlarıdır. Web katmanında `create_draft` bir öneri olarak durur; Document yalnız session/CSRF korumalı **Taslağı Oluştur** onayıyla yazılır. Önizleme ve gerçek içerik Manage/Renderer ile şablondan gelir; serbest LLM hukuki metni kaydedilmez. Modelde send/sign yetkisi yoktur. Kullanıcı normal belge ekranında inceleyip gönderir, alıcı mevcut demo imzayı tamamlar. Anthropic ve dış bearer API/CLI işlevleri korunur.

### Gerçek yerel demo — yalnız kullanıcı beyanı

Kullanıcı 25.10.2026'da şu akışı yerel tarayıcıda tamamladığını bildirdi:

1. Web üzerinden doğal dil sözleşme talebi girdi.
2. Gemini'nin eksik bilgi sorularını yanıtladı.
3. Şablondan gerçek taslak oluşturup SignFlow'da görüntüledi.
4. Kendisi imzaya gönderip paylaşım bağlantısı oluşturdu.
5. Gizli tarayıcı sekmesinde alıcı olarak demo imzaladı.
6. Uygulamada **İmzalandı** durumunu gördü.

Önceki `gemini_http_404` sonrasında model yapılandırmasını değiştirerek başarılı oldu. Başarılı modelin ID'si bildirilmedi; tahmin edilmedi veya `.env`/secret aranmadı. Bu kayıt otomatik test, Codex tarafından bağımsız server/browser doğrulaması, Google faturası veya production başarısı değildir. Yeni gerçek Gemini çağrısı yapılmadı.

### Testler, başarısızlık ve düzeltme

Mevcut tekrar onayı/sürüm/sahiplik/CSRF/grounding/API/CLI/imza testleri incelendi. Var olan pozitif akışa sahte browser owner/status/content/version parametrelerinin dikkate alınmadığı ve yenilemede belge bağlantısının gösterildiği kontroller eklendi. İki yeni test (nötr fake ve Gemini wire ile tekrar çalışır), tüm oturumsuz POST'ları ve modelin imza aracı/secret sızıntısı girişimini kapsar. Gereksiz yeni iş kuralı/ürün özelliği yazılmadı.

İlk hedefli çalışma **22 test / 344 assertion, 2 failure** verdi: oturumsuz istek Authentication tarafından session reset edildiğinde eski global CSRF token'ı sonraki istekte 422 üretiyordu. Her bağımsız anonim istek öncesinde güncel token alındı; uygulama koruması değiştirilmedi. Önceki `invalid_model_response`, `gemini_http_404` ve test fixture başarısızlıklarının tarihsel kayıtları korunur.

| Son gerçek kontrol | Sonuç |
| --- | --- |
| `RAILS_ENV=test` / `bundle exec rails test` | **190 test / 1978 assertion; 0 failure/error/skip**, exit 0. |
| İzole PostgreSQL 18 API/web/concurrency paketi | **59 test / 813 assertion; 0 failure/error/skip**, exit 0. |
| `bundle exec rubocop` | **123 dosya; ihlal yok**, exit 0. |
| `bundle exec rails zeitwerk:check` (test ortamı) | **All is good!**, exit 0. |
| `bundle exec rails tailwindcss:build` (test ortamı) | Başarılı, exit 0. |

PostgreSQL yalnız `127.0.0.1:55443/signflow_agent_test` izole test veritabanıdır; yeni dump ignored `tmp/ai-final` altındadır. İki bağımsız bağlantının aynı konuşma onayında tek belge commit etmesi ve bellek kaybı sonrası receipt recovery tekrar geçti. Production bağlantısı, kullanıcı/belge oluşturma veya migration yapılmadı. Windows opsiyonel libvips DLL ve Rack uyarıları test hatası üretmedi.

### Git kanıtı ve kontrollü yayın

Bu final görevi yerel AI commit'ini yetkilendirir; önceki commit yasağının bu görev için yerini alır. Commit SHA gerçek oluşturma sonrasında son raporda ve `git log -1` ile bildirilir; aynı commit'in kendi içeriğine kendine referans veren SHA uydurulmaz. Önceki API/LLM/credential commit'leri gerçek Git geçmişinde yukarıda kayıtlıdır. Push yalnız Render bağlı branch/Auto-Deploy durumu doğrulanırsa yapılabilir.

25.10.2026 public GitHub Actions okumasında [39549285447](https://github.com/Huseyinyagmur/signflow/actions/runs/39549285447) dahil görülen başarılar eski **`fb78d6111ebfb8863b3fa344d62a5f4484bc2fa4`** SHA'sına aittir. Bunlar yeni AI commit'inin CI kanıtı değildir. Doğrudan GitHub/Render connector ve kullanılabilir browser oturumu bulunmadı; Render Auto-Deploy/branch/backup/DB/environment ayarları doğrulanmadı. Bu durumda kullanıcının açık push koşulu nedeniyle push yapılmaz, production deploy başlatılmaz.

### Sınırlar, süre, maliyet ve sonraki adım

İnsan ve coding-agent süreleri ölçülmedi: **bilinmiyor**. Gerçek yerel LLM demo süresi, model ID, token sayıları, fatura/maliyet ve araştırma ölçümleri bildirilmedi; sayı uydurulmadı. Free teyit bayrağı ücretsiz fatura garantisi değildir. Konuşma/kota tek süreçlidir; çok worker/instance ortak durum desteği yoktur. TTL/restart konuşmayı kaybettirebilir; belge/idempotency receipt PostgreSQL'de kalır. Senkron model çağrısı proxy timeout/thread riski taşır. Gerçek kişi/müşteri verisi gönderilmez; nitelikli imza veya hukuki görüş iddiası yoktur.

Production öncesi bağlı branch ve Auto-Deploy Off, kurtarılabilir backup/restore, mevcut kalıcı PostgreSQL, additive migration, tek süreç/instance, backend-only environment ve production projesinde model/free/billing erişimi ayrıca doğrulanmalı. `.env` production'da yüklenmez. Ayrı son kullanıcı deploy onayı gerekir. [Final rapor ve checklist](docs/AI_FINAL_RELEASE_REPORT.md) bu açık kapıları ve değişken isimlerini listeler.

Commit öncesi açık kapsam denetimi: ilgili 51 kaynak/belge dosyasında Google/Anthropic/GitHub/agent token, private key, literal imza token'ı ve sentetik olmayan e-posta desenleri değerler yazdırılmadan tarandı; şüpheli eşleşme bulunmadı. Bu tarama mutlak gizli veri/DLP garantisi değildir. `.env` ignored ve izlenmiyor; storage/log/tmp/credentials stage kapsamı dışında. İlk prompt hash'i, önceki tarihsel metin, yerel Markdown link/fence kontrolleri ve `git diff --check` geçti. Remote main public API'de `fb78d6111ebfb8863b3fa344d62a5f4484bc2fa4` olarak doğrulandı; üç yerel öncül agent commit'i henüz uzakta görünmüyor. Yeni commit'in gerçek SHA'sı oluşturma sonrasında son yanıtta verilir; Auto-Deploy doğrulanmadıkça push yapılmaz.

## Kullanıcı Auto-Deploy teyidi, push ve CI düzeltmesi — 25.10.2026

Kullanıcı Render Settings için **“main / Auto-Deploy Off olarak doğruladım”** yanıtını verdi. Bu, kullanıcının Dashboard teyididir; Codex'in bağımsız Render hesabı incelemesi değildir. Önceki push engeli bu yeni bilgiyle kalktı. Production deploy izni verilmedi; deploy başlatılmadı, Render/production DB/environment değiştirilmedi.

Gerçek AI commit'i [0b088dd789a2ed4aa764fb8a99dc42cc11982d60](https://github.com/Huseyinyagmur/signflow/commit/0b088dd789a2ed4aa764fb8a99dc42cc11982d60), `feat: integrate Gemini AI contract creation into SignFlow web`, main'e normal push ile gönderildi. Uzak SHA önce `git ls-remote` ile eski `fb78d61` olarak doğrulandı; force push/merge yapılmadı. Önceki üç bağımlı agent commit'i de normal atalar olarak yayınlandı.

[Gerçek ilk AI CI çalışması 40177476290](https://github.com/Huseyinyagmur/signflow/actions/runs/40177476290): `scan_js`, `lint`, `test`, `agent_postgresql` **success**, `scan_ruby` **failure**. Brakeman adımı başarılı; gem audit adımı exit 1 verdi. Public job loglarına erişim yoktu; hata yerelde aynı `bundle exec ruby bin/bundler-audit` komutuyla yeniden üretildi: crass 1.0.7 için [GHSA-pq4g-8rxf-4g29](https://github.com/rgrove/crass/security/advisories/GHSA-pq4g-8rxf-4g29). Advisory 1.0.8'de düzeltme olduğunu belirtiyor. Uyarı ignore edilmedi, tarama kapatılmadı.

`bundle update crass --conservative` ile yalnız lockfile'daki **crass 1.0.7 → 1.0.8** değişti. Gerçek tekrar kontrolleri: Rails **190 test / 1978 assertion, 0 failure/error/skip**; RuboCop **123 dosya/0 ihlal**; bundler-audit **No vulnerabilities found**, exit 0; Brakeman **Errors 0 / Security Warnings 0**, exit 0. Windows'ta Brakeman Ractor/fork/forwardable tanılama mesajları da görüldü; son scanner raporu ve exit kodu ayrıca kontrol edildi. Ruby/Rails sürümü, uygulama iş kuralları ve güvenlik ayarları değiştirilmedi.

Güvenlik düzeltmesi ayrı commit/push olarak hazırlanıyor; yeni SHA için CI sonucu ancak gerçek run tamamlandıktan sonra son yanıtta bildirilir. Bu paragraf sonraki run'ı başarılı varsaymaz. Kullanıcı Auto-Deploy Off teyidi, production backup/restore/env/model erişiminin doğrulandığı veya deploy yetkisi verildiği anlamına gelmez.
