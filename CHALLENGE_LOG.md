# SignFlow Agent — Challenge Log

**Başlangıç tarihi:** 25.10.2026. **Durum:** Aşama 1 API yerelde uygulandı ve test edildi; LLM entegrasyonu henüz yok. [Geliştirme planı](docs/AGENT_FIRST_IMPLEMENTATION_PLAN.md), [gerçek Aşama 1 kaydı](#aşama-1--gerçek-geliştirme-ve-kanıt-25102026).

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
