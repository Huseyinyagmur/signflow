# SignFlow Agent — uygulanabilir geliştirme planı

**Tarih:** 25.10.2026, Europe/Istanbul. **Durum:** yalnız analiz ve öneri; uygulama/API/agent henüz geliştirilmedi. Bu dosya bir test veya deploy başarı raporu değildir. [Challenge kaydı](../CHALLENGE_LOG.md).

## 1. Ürün kararı ve bu haftanın vaadi

Öneri: mevcut SignFlow'a dar yetkili bir agent arayüzü eklemek. Gerçek bir LLM istemcisi, kullanıcının doğal dil talebinden izinli şablon değişkenlerini çıkarır; eksik bilgi varsa soru sorar; sabit bir TemplateVersion üzerinden taslak oluşturur ve sonucu sorgular. İnsan mevcut web ekranında metni, alıcıyı ve son tarihi inceler; ancak kendisi “İmzaya gönder” düğmesine bastığında imzalama bağlantısı üretilir.

**Ölçülebilir vaat:** Aynı iş talebinden, tekrar denemelerde de yalnız bir taslak oluşur; agent hiçbir erişim yoluyla kendi API kimliğiyle belgeyi pending yapamaz. İnsan kontrolünden sonra mevcut alıcı imza akışı signed ile tamamlanabilir. Bu, hukuki görüş, kimlik doğrulama veya nitelikli elektronik imza değildir.

Özgün fark yalnız “yeni JSON endpoint” değildir: kısıtlı agent araçları + sürümü sabit taslak + mükerrer kaydı engelleme + insan gönderim sınırı. API altyapısı otomasyondur; doğal dil yorumlama, eksik bilgi saptama ve araç seçimi gerçekten model tarafından yapılırsa LLM farkı gösterilmiş olur. Agent-first ödevinin tam değerlendirme rubriği verilmedi; bu öneri alınan görevdeki koşulları karşılamayı hedefler, not garantisi değildir.

## 2. Başlangıç noktası ve kanıt sınırı

Yerel çalışma ağacı inceleme başında temizdi. `git log`, `git branch -vv`, `git remote -v` okundu; fetch/push yapılmadı. Yerelde main ve önbellekteki origin/main aynı commit'i gösteriyor. Bu bilgi GitHub'ın şu anki durumu veya Render'daki canlı SHA değildir.

| Kapsam | Gerçek Git kaydı | Yorum |
| --- | --- | --- |
| Mevcut son proje durumu | [fb78d6111ebfb8863b3fa344d62a5f4484bc2fa4](https://github.com/Huseyinyagmur/signflow/commit/fb78d6111ebfb8863b3fa344d62a5f4484bc2fa4), 19.10.2026 12:57:45 +03:00, `added` | Yeni çalışma için önerilen teknik başlangıç; geçen teslimden sonraki son yerel kayıt. |
| “Geçen hafta” takvim anlamıyla, 12–18 Ekim | [207901b928d6eb47345576ebf24bc48aad9230a2](https://github.com/Huseyinyagmur/signflow/commit/207901b928d6eb47345576ebf24bc48aad9230a2), 17.10.2026 22:23:27 +03:00 | O kapalı takvim haftasının yerel geçmişteki son commit'i. |

25 Ekim Pazar günü içinde bulunulan hafta 19–25 Ekim'dir. “Geçen haftanın son commit'i” ifadesini sessizce 19 Ekim olarak değiştirmiyoruz; iki kapsam yukarıda ayrılmıştır. Hash'ler gerçek yerel Git nesnelerinden alındı; bağlantılar bu hash'lerden üretildi, uzaktaki nesneler ayrıca doğrulanmadı.

Tekrar kontrol için salt okunur PowerShell komutları:

```powershell
git log -1 --format="%H %aI %cI %s"
git log --all --since="2026-10-12T00:00:00+03:00" --until="2026-10-19T00:00:00+03:00" -1 --format="%H %cI %s"
git branch -vv
```

Önceki konuşmada 19 Ekim düzeltmesinin son yerel sonucu 94 test / 928 assertion, sıfır hata olarak kayıtlıdır. README'nin 17 Ekim kaydı 92/900'dür; tarihleri farklıdır. **Bu analizde testler yeniden çalıştırılmadı.** Canlı URL, hesaplar, Render ayarları ve güncel Actions sonucu denetlenmedi.

## 3. Mevcut kod analizi ve yeniden kullanım

| İncelenen parça | Mevcut davranış | Yeni işte kullanım / sınır |
| --- | --- | --- |
| [README](../README.md), [AGENT](../AGENT.md) | İş akışı, araştırma, güvenlik ve dağıtım yönergeleri; eski tarihli doğrulamalar | Kanıtları tarihleriyle koru. AGENT'taki önceki “AI eklemeyin” kapsamı bu görevin planlama talebiyle genişliyor; kodlama henüz yetkilendirilmedi. |
| [routes](../config/routes.rb) | HTML sahip ekranları, gönderim, şablon önizleme ve alıcı imzası; agent API yok | Yeni `/api/v1` namespace; mevcut rotaları agent'a açma. |
| [Document](../app/models/document.rb) | draft → pending → signed / pending → expired; kilitli geçiş; gönderilmiş metin değişmez; optional kaynak sürüm; sahip değişmez | Modeli yeniden yazma. API belgeyi yalnız draft oluşturur. Bu model tek başına “insan”ı tanımaz; insan sınırı authentication ve API yetkilerinde kurulmalı. |
| [Documents::Manage](../app/services/documents/manage.rb) | Kullanıcı kapsamı; `build_from_template` sahipliği doğrular, renderer kullanır, bağımsız metin `.build` eder | Aynı metot + `.save!`, yeni idempotent transaction içinde. `create!` tek başına kullanılırsa kaynak sürümü/renderer yolu atlanır. `send_for_signature!` API'ye bağlanmaz. |
| [Templates::Manage](../app/services/templates/manage.rb) | Kullanıcıya ait liste/sürüm seçimi; değişiklik yeni sürüm oluşturur | `version(template_id, version_id)` ile kapsamlı seçim. Global TemplateVersion.find kullanma. Agent şablon düzenleyemez. |
| [TemplateVersion](../app/models/template_version.rb) | Kayıt sonrası readonly; algılanan değişkenler | API tam sürüm ID'si ister, “latest”e sessiz geçmez. |
| [Renderer](../app/services/templates/renderer.rb) | Beş izinli değişken; eksik/fazla/bozuk girdiyi reddeder; tek geçişli düz metin | Sunucuda aynen kullan. Agent metin veya eval/ERB göndermez. Tarih ve ücret semantiği burada doğrulanmıyor; modelin biçim doğrulamasını semantik doğruluk sanma. |
| [TemplateDocumentsController](../app/controllers/template_documents_controller.rb) | Kayıtsız önizleme / ayrı save; sabit sürüm | Yeni API controller'ı bu controller'ı çağırmaz; ortak servis kullanır. HTML önizleme davranışı korunur. |
| [DocumentsController](../app/controllers/documents_controller.rb) | Sahip kapsamı, mevcut insan gönderim ekranı | İnsan incelemesi/gönderimi burada kalır; API token'ı bu rotalarda oturum sayılmaz. |
| [Authentication](../app/controllers/concerns/authentication.rb), [ApplicationController](../app/controllers/application_controller.rb) | Cookie oturumu, 12 saatlik kontrol; browser kuralı | Web aynen korunur. API ayrı controller tabanı kullanır; cookie ile kimlik kabul etmez ve kullanıcı oturumu üretmez. |
| [SigningController](../app/controllers/signing_controller.rb) ve Documents::Signing | İmza token'ıyla alıcı erişimi, açık kabul ve ad | Agent'ın imza araçları yok. Taslak sorgusu imza linki/token/digest içermez. |
| [Log filtreleri](../config/initializers/filter_parameter_logging.rb) | token, secret, _key, content, values vb. filtreleniyor | Yeni Authorization/header ve istemci logları ayrıca test edilmeli; mevcut parametre filtresi bütün proxy/exception logları için garanti değildir. |
| [Şema](../db/schema.rb) | User, Document, Template, TemplateVersion; agent kimliği/idempotency yok | Yalnız ek tablolar öneriliyor; mevcut kayıtları dönüştürme/silme yok. |
| [CI](../.github/workflows/ci.yml) | main push / main hedefli PR; Ubuntu 24.04, Ruby 3.4.11, scan_ruby, scan_js, lint, SQLite test + zeitwerk | Mevcut işler korunur; yeni testler aynı pakete girer. Ayrı PostgreSQL yarış testi kontrolü eklenir. |

İncelenen testler: Document geçişleri ve travel_to sınırları; belge servisi sahiplik/token replay; template renderer; templates manage/snapshot; integration kayıt → gönder → imza, template workflow, CSRF origin ve fiziksel SQLite şema regresyonu. API/LLM/idempotency testi bugün yok. Mevcut `test/integration/template_schema_regression_test.rb` içindeki PRAGMA doğrudan SQLite'a özgüdür; tüm paketi PostgreSQL'e yönlendirmek mevcut testleri bozabilir.

## 4. En küçük API sözleşmesi — öneri, mevcut rota değil

| Metot ve önerilen yol | Yetki ve cevap |
| --- | --- |
| GET `/api/v1/templates/:template_id/versions/:id` | Sahibinin sabit sürüm manifesti: kimlik, başlık, sürüm numarası, izinli değişken adları. Tam metin ilk aşamada LLM'e gerekmez. |
| POST `/api/v1/drafts` | Yalnız `template_id`, `template_version_id`, `values`, `document` içinde title/recipient_name/recipient_email/expires_at. Header'da zorunlu Idempotency-Key. İlk başarılı oluşturma 201. |
| GET `/api/v1/drafts/:id` | Yalnız aynı kullanıcının agent üzerinden oluşturulmuş belgeleri; draft/pending/signed/expired güncel durumu sorgulanabilir. Güvenli, açık alan listesi; sorgu mevcut kullanıcı kapsamlı Manage.find ile expiration davranışını korur. |

“Drafts” adı oluşturma yetkisidir; insan gönderdikten sonra aynı kaynak GET ile güncel durumu gösterebilir. Kaynak bulma ayrıca AgentRequest ilişkisiyle sınırlandırılır; aynı kullanıcının diğer manuel belgelerine agent varsayılan erişmez.

Örnek sözleşme (çalıştırılmış istek değildir; kimlik bilgisi içermez):

```json
{
  "template_id": 12,
  "template_version_id": 28,
  "values": {"alici_adi": "Deniz", "hizmet": "Tasarım danışmanlığı", "ucret": "1000 TRY"},
  "document": {"title": "Agent demo taslağı", "recipient_email": "deniz@example.com", "expires_at": "2026-10-30T18:00:00+03:00"}
}
```

Örnekteki ID'ler yer tutucudur; sürümde yalnız bu üç değişken varsa geçerlidir. Diğer iki tarih alanı şablonda varsa ayrıca doldurulmalıdır. İmza son tarihi ile şablonun hizmet başlangıç/bitiş tarihi farklı alanlardır. Sabit tarihe güvenmek yerine demo sırasında gelecekteki tarihi insan doğrular.

İzin verilmeyen `user_id`, `status`, `content`, `signed_at`, `signer_name`, `signing_token_digest`, `send`, `approved` vb. alanlar API'de 422 ile açıkça reddedilir. Sadece strong params ile sessizce düşürme, agent'ın yanlış başarı varsaymasına neden olabilir. Bozuk JSON 400, JSON olmayan içerik 415, eksik key 400, gövde >64 KiB 413, bilinmeyen/kapsam dışı kaynak 404, geçersiz credential 401, limit aşımı 429, geçerli olmayan değerler 422, beklenmeyen hata genel 500. JSON nesnesi dışındaki gövdeler de reddedilir. API seri hale getirmede `attributes/as_json` topluca kullanılmaz.

POST/GET yanıtı izinli kimlik, kaynak sürüm, başlık, içerik ve güncel status ile insanın açabileceği göreli `/documents/:id` adresini içerebilir; bu adres oturum gerektirir, bearer link değildir. İmza token'ı/hash'i, kullanıcı email'i ve diğer iç alanlar cevaplanmaz. Yanıtlar no-store; doğrulama hataları ham değer/anahtar veya Ruby exception metnini yansıtmaz. Gövde/parola/header hataları güvenli hata koduyla döner.

## 5. Kimlik, insan kontrolü ve gizli bilgiler

### Kimlik bilgisi yaşam döngüsü

- Yeni AgentCredential: `user_id` FK, label (kısa ve uzunluğu sınırlı), benzersiz `token_digest`, `expires_at` zorunlu, `revoked_at`, timestamps. İzinler sabit: manifest oku / taslak oluştur / kendi agent taslağını oku; kullanıcı tarafından artırılamaz.
- 32 rastgele baytlık bearer secret; DB'de yalnız SHA-256 digest ve benzersiz index. API sadece `Authorization: Bearer ...` kabul eder; URL/query/body/cookie kimliği kabul etmez. Anahtarın tamamı modele verilmez.
- Mevcut oturum + CSRF ile küçük bir “Agent erişimi” ekranından oluşturma/iptal. Varsayılan 7 günlük ömür, en fazla 30 gün önerisi; bu yeni credential politikasıdır, mevcut belge varsayılanı değildir. Tam sona eşit anda erişim reddi travel_to ile test edilir.
- Secret zorunlu ilk teslimde yalnız bir kez güvenli kullanıcıya gösterilir; no-store/no-cache, Turbo snapshot kapalı; tekrar açıldığında yalnız label/son tarih/iptal görünür. Bu tek teslim ekranı kaydedilmez/projeksiyona verilmez. Genel demo ekranına, CLI çıktısına ve dosya artefaktına secret yazılmaz. Kullanıcıdan secret'ı gizli istemci deposuna alma işi sunumdan önce yapılır. Sızma şüphesinde iptal ve yenileme; ham secret kurtarma yok.
- İstemci secret'ı güvenli prompt/getpass veya işletim sistemi secret deposundan alır; komut satırı argümanı/shell history'ye koymaz. Önerilen env adları `SIGNFLOW_API_TOKEN`, `SIGNFLOW_BASE_URL`, `ANTHROPIC_API_KEY`, `SIGNFLOW_LLM_MODEL`; değerler Git'e veya ödev dosyalarına girmez. `.env.example` yalnız isimler içerir; `.env` ignored olur. LLM key'i Render'a gerekmez, yerel agent istemcisinde kalır.
- Credential üretimi/iptali yalnız web oturumuna açık; API token'ı bu ekranlardan yeni yetki elde edemez. Token iptali/idempotent replay dahil her istekte yeniden doğrulanır.

### Web güvenliğini koruma

Önerilen `Api::V1::BaseController < ActionController::API`, mevcut ApplicationController'dan ayrı olmalı. Web Authentication concern'i, session ve CSRF ayarları değişmez; `skip_forgery_protection`, origin-check kapatma veya web route'una bearer kabul etme yok. API tabanı cookie'den current_user üretmez; farklı kullanıcı cookie'si ve bearer birlikte gelirse yalnız bearer sahibi geçerlidir. Form/multipart/text istekler reddedilir, geniş CORS açılmaz. CLI aynı origin CORS'una ihtiyaç duymaz.

API'de gönderim/güncelleme/imzalama aracı veya action yok; `/api/v1/.../send_for_signature` gibi istek 404 ve durum değişmez. Web `/documents/:id/send_for_signature` yoluna yalnız API credential ile yapılan POST, geçerli web oturumu ve CSRF sağlamaz; yetki kazanamaz. Oturum cookie'sinin çalınması ayrı tehdittir: “insan onayı” mevcut oturum sahibinin web eylemi anlamındadır, biyometrik/kriptografik insan kanıtı değildir. Agent istemcisine kullanıcı parolası, cookie, CSRF token'ı veya imza linki verilmez.

Loglar yalnız request ID, credential iç kimliği, işlem adı, sonuç kodu, document ID ve süre gibi izinli metadataları içerir. Authorization/Idempotency-Key/header debug dump, request body, prompt ve ham model cevabı kaydı kapalı olur. Parametre filtresine `authorization`, `idempotency_key`, `prompt` gibi ekler ve error-reporting/proxy ayar kontrolü planlanır. Testte sahte secret logda aratılır. Render/proxy günlüklerinin key saklamadığı hesap üzerinden ayrıca kontrol edilmeli; yerel test bunun yerine geçmez.

Başlangıç kotası önerisi: credential başına dakikada 10 oluşturma/60 okuma ve aktif credential sayısı sınırı. Mevcut memory cache restart'ta sıfırlanır, çok süreçte ortak değildir; tek süreç demo sınırı olarak açıkça belirtilir. Güçlü üretim kotası gerekiyorsa DB/ortak depo ayrıca tasarlanır. Secret ve idempotency güvencesi memory cache'e dayanmaz.

## 6. Mükerrer taslağı önleme tasarımı

Yeni AgentRequest: `user_id` FK, oluşturan `agent_credential_id` FK, sabit operation, `idempotency_key_digest`, `payload_digest`, benzersiz `document_id` FK ve timestamps. **DB unique index: `(user_id, operation, idempotency_key_digest)`**. Credential değişse bile aynı sahibin aynı key'i aynı işlemdir. document_id için FK + not-null; kayıtlar belgeyle aynı transaction içinde tamamlanır. Document'a migration ile zorunlu yeni alan eklenmez; manuel eski belgeler çalışır.

1. Key istemci tarafından bir iş talebi için rastgele oluşturulur (16–128 ASCII karakter); LLM oluşturmaz. Aynı talebin belirsiz timeout/restart denemesinde **aynı key ve aynı kanonik payload** kullanılır. Yeni işte yeni key. Gizli olmayan key tek başına belgeye erişim sağlamaz; yine de raw header loglanmaz.
2. İstemci bir iş makbuzunu yerelde, ignored ve erişimi sınırlı dosyada tutar: iş ID'si/key ve sentetik payload. Payload'ı her retry'da LLM ile yeniden üretmez. Üretim PII saklama politikası ayrıca gerekir.
3. Auth, sınırlı JSON şekli ve anahtar doğrulamasından sonra izinli alanlardan deterministik kanonik JSON ve SHA-256 payload özeti hesaplanır. İç içe hash anahtar sırası farkı aynı sayılır; değer/tarih metni değişirse farklı payload sayılır. `user_id`/operation özete sunucu tarafından bağlanır; bilinmeyen alanlar özete girmeden reddedilir.
4. `user.with_lock` transaction'ında credential'ın sahipliği/iptali/süresi yeniden doğrulanır; mevcut AgentRequest aranır. İptal işlemi de aynı kullanıcı kilidi düzenini izler; bu, yarış sırasında yeni create'in iptal kontrolünü atlamasını önler.
5. Aynı key ve payload: yeni belge yok, 200 + `replayed: true`, aynı document_id ve güncel durum. İnsan o arada gönderdiyse pending/signed dönebilir; draft'a geri dönmez. Farklı payload: 409, eski kayıt dokunulmaz. Geçersiz/eski credential ile replay de 401.
6. İlk istek: Templates::Manage.version ile kaynak doğrulanır; Documents::Manage.build_from_template + save!; AgentRequest aynı transaction'da eklenir. Başarı 201 + `replayed: false`. Herhangi bir hata iki kaydı da rollback eder; cache başarı yazmaz.
7. DB unique index son savunmadır. RecordNotUnique sonrası aynı başarısız PostgreSQL transaction'ında sorgu yapılmaz; dışarı çıkılıp yeni transaction'da scoped kayıt okunur ve payload karşılaştırılır. SQLite busy/deadlock için sınırlı retry; hala meşgulse güvenli 503 ve aynı key ile retry yönergesi. Yarış testleri PostgreSQL'de de çalışmalı.

MVP'de idempotency kayıtları otomatik silinmez; süre dolunca eski talebin tekrar yeni belge oluşturması istenmiyor. İleride temizlik yapılırsa tekrar süresi sözleşmesi açıkça değişir. Bu sistem farklı key ile yinelenen semantik talebi veya iki kere açılmış ayrı iş ID'sini tespit etmez; tam “exactly once” dağıtık garanti iddiası yoktur. Network retry ve aynı iş kimliği kapsamı korunur.

## 7. Gerçek LLM agent nerede olacak?

Rails web isteği içinde LLM bekletmek yerine yerel Ruby CLI önerilir: `script/signflow_agent.rb`. Üç allowlist araç: `get_template_version`, `create_draft`, `get_draft`. Ağ istemcisi host'u başlangıçta sabitler; model key/URL/header/method belirleyemez. Shell, genel HTTP, SQL, dosya, browser veya send/sign aracı yok. TLS zorunlu; HTTP yalnız açık local geliştirme kipinde loopback'e izinli. Yönlendirme ve farklı host'a credential gönderme kapalı.

Akış: insan sentetik doğal dil iş talebini ve kullanacağı şablon/sürümü belirler → model manifest aracını seçer → izinli alanları çıkarır → eksik zorunlu değer için soru sorar → istemci JSON şema/alan doğrulamasından geçirir → create_draft → get_draft → insan ekranına geçiş. İlk MVP'de otomatik şablon arama/seçme veya yeni şablon yazma yoktur. Gerçek bir dar araç kullanan agent'tır; kapsamlı otonom hukuk asistanı değildir. Eksik ücret/tarih/e-posta tahmin edilmez; istemcide minimum gerekli giriş kontrolü ve insan incelemesi birlikte kullanılır. Model yine yanlış değer çıkarabilir, bu yüzden gönderim insandadır.

Önerilen sağlayıcı **Anthropic API**, somut aday `claude-haiku-4-5-20251001`; tek model çağrı döngüsü için ayrıca agent framework/MCP/vektör DB gerekmez. [Resmî model sayfası](https://platform.claude.com/docs/en/models/haiku-4-5/overview), erişim 25.10.2026: input $1/1M, output $5/1M token. Sayfa bu modeli artık legacy olarak işaretliyor; uygulama öncesi hesapta erişim/deprecation ve fiyat tekrar kontrol edilmeli. Bu bir öneridir, bu çalışmada model çağrısı/hesap/ücretli kaynak oluşturulmadı. Kullanıcı sağlayıcı seçimini kodlamada değiştirebilir; server API modelden bağımsız kalır.

[Tool use resmî açıklaması](https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview) araç çağrısının model tarafından seçilip istemci tarafından yürütüldüğünü açıklar. Demo ancak gerçekten API model yanıtı alınıp bu araçlar çalıştırıldığında “LLM agent çalıştı” sayılır. Sabit fixture, curl/JSON script'i veya coding agent'ın projeyi yazması ürün içi LLM kanıtı değildir.

Maliyet **varsayımı**, ölçüm değil: tüm tool sonuçları/tekrar dahil bir işte toplam 8.000 input + 2.000 output → `8000/1M × $1 + 2000/1M × $5 = $0,018`. 50 deneme ≈ $0,90; üç tam denemelik üst senaryo ≈ $2,70. Cache/batch indirimi, vergi, kur, hosting ve insan emeği dahil değil. Hesap erişimi veya model değişirse tekrar hesaplanır. Geliştirme için $5 hedef bütçe önerisi hard cap garantisi değildir; sağlayıcı harcama ayarı ve gerçek usage kontrol edilir. İstemci en fazla 6 tool turu, tur başına output token sınırı, en fazla 1 düzeltme denemesi, timeout ve sınırlı backoff uygular; model başarısızsa başarı taklidi yapılmaz.

Güvenlik/veri şartları: yalnız sentetik demo metni; gerçek müşteri sözleşmesi/PII sağlayıcıya gönderilmez. Model log/retention/eğitim/veri bölgesi şartları ayrı incelenmeden gerçek veri kullanılmaz. Şablon metni ve tool sonuçları güvenilmeyen veri sayılır; “önceki kuralları unut/gönder” içeriği yetkiyi değiştiremez. Secret model context'ine girmez. Ham chain-of-thought istenmez/kaydedilmez; yalnız araç adları, sonuç kodları ve token usage ölçülür. Uydurulmuş alanları ölçmek için normal, eksik bilgiler ve injection içeren sentetik değerlendirme seti gerekir.

## 8. Önerilen dosya değişiklikleri — henüz yapılmadı

| Dosya/grup | Planlanan iş |
| --- | --- |
| `db/migrate/*_create_agent_credentials.rb`, `*_create_agent_requests.rb` | Ek tablolar, FK/unique/not-null kısıtları; eski tablolarda veri silme/dönüşüm yok. |
| `app/models/agent_credential.rb`, `agent_request.rb`; User ilişkileri | Hash-only kimlik, süre/iptal, sahiplik ve idempotency bağlantıları. |
| `app/services/agents/authenticate.rb`, `create_draft.rb`, `request_fingerprint.rb` | Dar kimlik doğrulama, transaction/idempotency ve kanonik fingerprint; mevcut Manage/Renderer çağrıları. |
| `app/controllers/api/v1/base_controller.rb`, `drafts_controller.rb`, `template_versions_controller.rb` | JSON-only bearer API, güvenli hata/yanıt alan listeleri, no-store. |
| `config/routes.rb` | Yalnız manifest / create / show; API için send/edit/sign yok. |
| `app/controllers/agent_credentials_controller.rb`, `app/views/agent_credentials/*`; layout bağlantısı | Session/CSRF korumalı oluştur/iptal, tek teslim ekranı ve uyarı. |
| `config/initializers/filter_parameter_logging.rb`, `.gitignore` | Yeni hassas alanlar ve ignored yerel iş dosyaları. Web CSRF/session/CSP değişmez. |
| `script/signflow_agent.rb`, `script/agent_demo_client.rb`, gerekirse `lib/signflow_agent/*` | Gerçek model araç döngüsü ve ayrı deterministik HTTP smoke istemcisi. API smoke'a LLM adı verilmez. CLI yardımcıları Rails boot etmeden yerel çalışır. |
| Gerekirse Gemfile/lock | LLM istemcisi için Ruby standart Net::HTTP/JSON yeterliyse yeni runtime gem'i ekleme. SDK seçilirse minimal bağımlılık, platform ve audit değerlendirmesi. |
| `test/models/agent_*`, `test/services/agents/*`, `test/integration/agent_api_test.rb`, `agent_human_handoff_test.rb`, `test/agent_client/*` | Aşağıdaki yeni testler; mevcut testleri kaldırma/gevşetme yok. |
| `.github/workflows/ci.yml`, `config/database.yml` için ayrı opt-in test bağlantısı | PostgreSQL 18 servisinde yalnız adapter bağımsız agent/yarış testleri; dev/test SQLite varsayılanı korunur. |
| `AGENT.md`, `README.md`, `docs/RENDER_DEPLOYMENT.md`, `CHALLENGE_LOG.md` | Onaylı yeni kapsam, gerçek komut/kanıt, rollout ve ölçülen süreler. Bu analizde mevcut belgeler değiştirilmedi. |

Feature flag önerisi `AGENT_API_ENABLED=false` varsayılan: hem API hem credential yönetimi kapalı/404. Flag API credential veya LLM key değildir. İzinli deneme ortamında açılır. Web imza akışına flag kontrolü eklenmez.

## 9. Test ve kanıt planı

| Test grubu | Kabul kriterleri |
| --- | --- |
| Credential model/service | Ham secret DB'ye yazılmaz; digest input credential olamaz; eksik/bozuk/yanlış/iptal token 401; travel_to son tarihten önce/eşit/sonra; iptal sonraki GET/create/replay'i engeller; yanlış kullanıcı credential yönetemez. |
| API biçimi | Cookie-only 401; HTML/yanlış tip/bozuk JSON/büyük gövde reddi; bilinmeyen alan/status/content/owner injection reddi; güvenli hata JSON'u; no-store. |
| Şablon ve sahiplik | A sahibinin token'ıyla B'nin template/version/document 404; aynı sahibin yanlış template-version eşleşmesi 404; manuel belgeler okunamaz; eski v1 seçimi v2 çıksa bile sabit; kaynak sürüm kaydı korunur. |
| Draft üretimi | Renderer'ın beş alan sınırı, nested/eksik/fazla/boş/uzun değer reddi; HTML/ERB inert; durum draft, signed_at/hash boş; belgenin metni LLM/raw content'ten değil renderer'dan gelir; validation hata verince sıfır kayıt. |
| İdempotency | Aynı key+payload ardışık ve eşzamanlı → bir Document/AgentRequest; hash sırası aynı sayılır; aynı key farklı payload 409; iki farklı kullanıcı aynı key kullanabilir; credential rotation aynı sahibi korur; server crash/timeout sonrası aynı key; failure rollback; replay sonrasında signed belgeyi draft'a çevirmez. |
| İnsan sınırı / regresyon | API bearer ile web send başarısız; API namespace'de send/edit/sign yok; model status doğrudan yazımı yasak. Gerçek HTML CSRF+Origin ile sahibi taslağı görür/düzenler/gönderir; alıcı fragment linkiyle imzalar → signed. Tokensız/yanlış origin web reddi korunur. |
| Zaman ve değişmezlik | Mevcut travel_to deadline/replay testleri korunur; agent taslağı da aynı modele tabidir; gönderilmiş metin ve TemplateVersion değişmez. |
| Sızıntı | Sahte Authorization/key/model key/prompt/value raw logda ve yanıtta yok; bir kez teslim sonrası secret tekrar görünmez; no Turbo cache; client stderr/timeout traceback secret içermez; yönlendirme/farklı host token sızdıramaz. |
| Agent istemcisi | Fake provider ile deterministik schema/tool allowlist, eksik bilgi, injection, timeout/429, redirection, sınırlı döngü, aynı idempotency key ile retry. Bu testler gerçek LLM kanıtı diye sunulmaz. |
| Gerçek LLM kabul | Ayrı opt-in manuel 5–10 sentetik deneme: doğal dil, eksik ücret/tarih, injection, retry; model ID/usage/araç sonucu ve başarısız örnekler kaydedilir. Anahtar/prompt gövdesi kaydedilmez. |
| Production davranışı | Ayrı PostgreSQL test DB'sinde iki bağlantıyla yarış; deploy sonrası restart'ta credential/replay devam; smoke + web gönderim/imza. /up tek başına kabul değildir. |

Uygulama sonrası yerel komutlar (bu aşamada çalıştırılmadı):

```powershell
bundle exec rails test
bundle exec rubocop
bundle exec rails zeitwerk:check
bundle exec rails tailwindcss:build
```

CI: dört mevcut job korunur. Yeni model/service/integration testleri mevcut `rails test` içine girer. Gerçek model API'si zorunlu CI'da çağrılmaz; LLM key repo/PR job'larına konmaz. PostgreSQL concurrency için ek job: aynı Ruby/Bundler setup, test-only pg erişimi, PostgreSQL 18 servis health kontrolü, ayrı boş test DB migration ve yalnız agent adapter-bağımsız test dosyaları. SQLite PRAGMA regresyonunu PostgreSQL'de çalıştırmak yerine SQLite job'ında tut. Önerilen `SIGNFLOW_TEST_DATABASE_URL` gibi opt-in bağlantı yalnız test ortamında doğrulanmalı; production/development bağlantısına geçemez. Gerekli test job'ları başarısız/skipped ise merge yapılmaz; continue-on-error yok. Gerçek Actions run URL/SHA/dört job + yeni PG job sonucu Challenge'a ancak çalıştıktan sonra eklenir.

## 10. Gerçek demo — geliştirildikten sonra

1. Ön hazırlık: sentetik demo kullanıcısı, mevcut şablon/sabit sürüm; gerçek secret'lar güvenli yerel depoda; credential teslim ekranı kapalı. Render uyanık, geçerli DB, uygun quota. Demo kaydı henüz yapılmış değildir.
2. Doğal dil: “Deniz için tasarım danışmanlığı taslağı hazırla; ücret 1000 TRY; hizmet dönemi …; alıcı …; imza son tarihi …”. Kimlik bilgisi talep metnine yazılmaz.
3. LLM manifest aracını çağırır; istemci sadece araç adı/sonuç gösterir. Ayrı eksik veri denemesinde model bilgi ister, taslak oluşturmaz.
4. create_draft 201 → get_draft 200/draft; document ID ve insanın göreli inceleme adresi görülür. İnsan henüz gönderim yapmadı; signing_token yok.
5. Aynı iş kimliği+aynı payload tekrar: 200/replayed, aynı ID; DB'de artış yok. Değişen payload aynı key ile 409.
6. A sahibinin kimliğiyle B'nin kaynağına erişim 404. API gönderim denemesi başarısız, belge draft kalır. Bu deneme deterministik HTTP smoke istemcisiyle yapılabilir; LLM başarısı diye etiketlenmez.
7. İnsan oturum açar; taslağı inceler, gerekirse düzenler; kendi CSRF formuyla gönderir. Alıcı ayrı pencerede mevcut kabul+ad ile demo imzalar. Sahip signed görür; agent get_draft da güncel signed döndürür, link göremez.
8. Credential iptal edilir; sonraki sorgu 401. Evidence: SHA, model ID, sentetik iş ID'si, HTTP kodları, tool metadata, görünür state ve hata denemeleri; secret/ham token içermeyen kısa kayıt. Ekran/video yalnız gerçekten çekilince kanıt sayılır.

Ölçüm: aynı sentetik iş setinde manuel alan doldurma ile agent+insan incelemesi ayrı sürelenir. Hatalı alan sayısı, soru sayısı, yaratılan belge sayısı ve model gideri raporlanır. LLM hızı tek başına kazanım değildir. Bugün yüzde/saniye tasarruf iddiası yok.

## 11. Render'ı koruyan dağıtım planı

Mevcut native build `bash bin/render-build.sh`: bundle + assets. Start `bash bin/render-start.sh`: production değişken kontrolü → db:migrate → Puma. [database.yml](../config/database.yml) dev/test SQLite, production PostgreSQL; [puma.rb](../config/puma.rb) PORT dinler. [production.rb](../config/environments/production.rb) TLS, host listesi, STDOUT, memory cache, async job kullanıyor. LLM'i dış CLI'da tutmak web thread'lerini model beklemesinden ve kalıcı worker ihtiyacından korur.

1. Kodlamada feature branch ve PR kullan; henüz branch/commit oluşturulmadı. main'e doğrudan push yok. Önce Render Dashboard'da bağlı repo/dal, canlı SHA, Auto-Deploy değeri, plan, DB süresi/backup ve build/start doğrulanıp gizli değerler olmadan kaydedilir. Yerel config veya CI rozeti Auto-Deploy ayarını kanıtlamaz.
2. [Render deploy belgeleri](https://render.com/docs/deploys), erişim 25.10.2026: On Commit / After CI Checks Pass / Off seçenekleri var. Hangisinin açık olduğu bilinmiyor. Kullanıcı kontrolünde Off veya gerekli kontrollerin gerçekten geçtiği After CI Checks Pass ile kontrollü rollout önerilir; ayar kendiliğinden değiştirilmez. Render skipped/neutral checks'i de geçerli sayabildiğinden kritik job'ın gerçekten success olduğunu ayrıca doğrula.
3. Lokal SQLite ve ayrı PostgreSQL doğrulaması; CI; mümkünse mevcut production DB'ye bağlanmayan ayrı staging web+Postgres. Ücretli kaynak kullanıcı kararıdır, bu aşamada yaratılmaz. Ayrı servis yoksa yerel PostgreSQL hazırlığı yap, production flag kapalı ilk dağıtım ve bakım penceresiyle ilerle.
4. Önce erişilebilir backup/restore planı, mevcut canlı SHA ve eski verilerin sayısal kontrolü. Migration yalnız ek agent tabloları; mevcut tablolar/seed'ler değişmez. Eski sürüm yeni tabloları görmezden gelebilir. Start migration mevcut ücretsiz-servis yolu olarak kalır; ücretli pre-deploy varsayılmaz. Uzun tablo değişikliği/eşzamanlı deploy yok.
5. Ancak kullanıcı kodlama ve daha sonra push/deploy yetkisini verdiğinde, Auto-Deploy kontrolünden sonra onaylanan SHA yayınlanır. Flag kapalı normal kayıt/sözleşme/şablon/imza smoke yapılır. Sonra kontrollü açılır, yalnız demo kullanıcısıyla agent kabulü yapılır. LLM secret web ortamına konmaz. Her production kaydı açıkça sentetik test kaydı olarak işaretlenir; eski kayıtlar silinmez.
6. Sorunda önce API flag kapat, sızan credential'ı iptal et; uygun eski build'e kod rollback. [Render rollback belgeleri](https://render.com/docs/rollbacks) build geri dönüşünü anlatır; bu DB rollback değildir. Ek tabloları canlıda drop etme; yeni credential'lar eski kodda kullanılmaz. Rollback sonrası environment/auto-deploy ayarları ve web akışı yeniden doğrulanır.
7. Restart sonrası idempotency/credential DB'de korunmalı; memory limit/cache'in sıfırlandığı açıkça belirtilir. PostgreSQL'in Free süre/backup koşulu kullanıcı hesabından tekrar kontrol edilir; mevcut “kalıcı” hedef için geçici diske veya memory'ye geçilmez.

## 12. Coding agent Render'ı nereden öğreniyor?

Hocaya verilecek açıklama: “Coding agent özel Render hesabımı bildiğini varsaymıyor. İsteğimdeki ortamı ve repodaki yönergeleri okuyor. Hesap ayarları için ayrıca gerçek Dashboard kanıtı gerekiyor.”

Okuma sırası ve kanıt dosyaları:

1. [AGENT.md](../AGENT.md): Render production hazırlığı, güvenlik sınırları, çalıştırılacak komutlar ve yapılmaması gereken işlemler.
2. [README.md](../README.md): canlı URL, teknoloji ve deployment rehberine bağlantı; eski tarihli kullanıcı/test beyanları.
3. [docs/RENDER_DEPLOYMENT.md](RENDER_DEPLOYMENT.md): native Ruby, plan/env, migration, manual deploy ve sorun giderme.
4. [bin/render-build.sh](../bin/render-build.sh) ve [bin/render-start.sh](../bin/render-start.sh): gerçekten çalıştırılacak komutlar; gizli değerler yok, env isimleri var.
5. [config/database.yml](../config/database.yml), [config/puma.rb](../config/puma.rb), [config/environments/production.rb](../config/environments/production.rb), [.gitattributes](../.gitattributes): PostgreSQL/TLS/host/PORT/LF uygulaması.
6. [.github/workflows/ci.yml](../.github/workflows/ci.yml): CI tetikleri ve kontroller; Render otomatik deploy durumunu göstermez. config/deploy.yml Kamal iskeletidir; Render yolu diye gösterilmez. render.yaml mevcut değil.

## 13. Tahmini süre, aşamalar ve riskler

Bir Rails geliştiricisi + coding agent, mevcut proje ve testler üzerinden; 1 iş günü = 6 odaklı saat. Bekleme ve hesap/bütçe onayı hariç mühendislik tahmini; insan ve agent'ın eşzamanlı süreleri toplanıp gerçek duvar saati diye sunulmaz.

| Aşama | Tahmini odaklı saat | Çıkış ölçütü |
| --- | ---: | --- |
| API sözleşmesi/credential/insan sınırı | 5–8 | Kimlik ve yetki testleri |
| Taslak endpoint + DB idempotency | 6–9 | Aynı key → bir kayıt; hata rollback |
| Credential yönetim ekranı + güvenli client | 3–5 | Tek teslim/iptal + HTTP smoke |
| Gerçek LLM araç döngüsü ve değerlendirme | 4–7 | Gerçek sentetik LLM demosu; eksik veri/injection kontrolü |
| Regresyon, PG yarışı, CI | 5–8 | SQLite + ayrı PostgreSQL ve mevcut kontroller |
| Kontrollü rollout/prova/Challenge kanıtı | 3–5 | Yetkili deploy sonrası gerçek kanıt |
| Toplam | **26–42 saat** | **5–7 odaklı iş günü**, yuvarlanmış |

%25 belirsizlikle yaklaşık **33–53 saat / 6–9 iş günü**. Sadece agent-first deterministik API prototipi LLM aşaması olmadan daha kısa olabilir, fakat gerçek LLM şartı varsa tamamlanmış sayılmaz. İnsan aktif çalışma / agent çalışma / bekleme / toplam duvar saati Challenge'da ayrı tutulmalı; bugün ölçülmüş süre yok.

Başlıca riskler: LLM'in alıcı/tarih/ücret uydurması; prompt injection; credential sızıntısı; HTTP tekrarlarında farklı iş key'i; PostgreSQL yarışları; SQLite lock; gönderilmiş metne müdahale; sağlayıcı erişimi/maliyet/model ömrü; Render cold start/DB süresi/Auto-Deploy; global “exactly once” veya kimlik doğrulama iddiası. Karşılıkları üstteki dar yetki, insan sınırı, DB unique+transaction, testler ve kontrollü rollout'tur. Bunlar riski azaltır; genel kurumsal güvenlik garantisi değildir.

## 14. Bu aşamanın gerçek çıktısı

Yalnız bu plan ve CHALLENGE_LOG başlangıç taslağı oluşturuldu. Uygulama kodu, mevcut AGENT/README, Gemfile/lock, workflow, veritabanı veya Render ayarları değiştirilmedi. Yeni API, agent, credential, migration, test veya demo henüz yok. Rails testleri çalıştırılmadı; commit/push/deploy/model çağrısı yapılmadı. Sonraki adım, bu dar kapsam onaylandıktan sonra önce kimlik/insan sınırı ve idempotency testleriyle kodlamaktır.
