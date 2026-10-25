# SignFlow Agent — güvenli canlı LLM demo rehberi

Bu rehber **henüz gerçekleştirilmemiş** gerçek LLM demosu içindir. Kod/fake testler hazır; gerçek Anthropic hesabında çağrı yapılmadı. Teknik sonuçlar: [Aşama 2 raporu](AGENT_LLM_STAGE2.md). Credential teslimi: [Aşama 1](AGENT_API_STAGE1.md).

## Ön hazırlık — projeksiyon kapalı

1. Sentetik bir SignFlow hesabında mevcut bir şablon ve sabit sürüm seçin. Şablon değişkenlerini arayüzden doğrulayın; demo için `alici_adi`, `hizmet`, `ucret` içeren kısa bir şablon yeterlidir. Hizmet başlangıç/bitiş değişkenleri varsa takip cevabına onların tarihlerini de ekleyin. İsim/e-posta gerçek müşteri olmasın.
2. Yerel Rails sunucusunda `AGENT_API_ENABLED=true` ile Aşama 1 API'sini açın; mevcut oturum/CSRF ayarlarına dokunmayın. Render kullanacaksanız önce ayrı deploy yetkisi/Auto-Deploy/CI/flag kontrolü gerekir; bu çalışma onu yapmadı.
3. Owner kapsamlı güvenli CLI provisioning ile SignFlow credential'ı hazırlayın. Teslim dosyasını/env'yi/anahtar sayfasını projeksiyona yansıtmayın; NTFS ACL'yi kontrol edin. Credential yönetim ekranı henüz yok.
4. Anthropic hesabında workspace'e bağlı key, seçilen modele erişim, kredi ve bütçe koşullarını kendiniz kontrol edin. Sağlayıcı key'ini sohbete veya terminal komutuna yapıştırmayın; istemcinin maskeli girişini veya güvenli process env kullanın. Bu istemci gerçek sağlayıcı maliyetini doğurabilir.
5. Aşağıdaki ayarlarda ID'ler örnektir. Kendi **size ait** sabit sürüm ID'lerinizi girin. `.env.example` otomatik yüklenmez.

```powershell
$env:SIGNFLOW_BASE_URL='http://127.0.0.1:3000'
$env:SIGNFLOW_ALLOW_LOOPBACK_HTTP='true'
$env:SIGNFLOW_TEMPLATE_ID='12'
$env:SIGNFLOW_TEMPLATE_VERSION_ID='28'
$env:SIGNFLOW_LLM_MODEL='claude-haiku-4-5-20251001'
$env:SIGNFLOW_SYNTHETIC_DATA='true'
```

Anahtarlar env'de yoksa etkileşimli console maskeli sorar; stdout/history'ye yazdırmayın. Gerçek `.env` Git tarafından ignored olsa da güvenli secret store yerine geçmez. CLI bunu kendiliğinden okumaz.

**Yalnız sağlayıcı ücretini ve sentetik veri gönderimini kendiniz onayladığınızda:**

```powershell
$env:SIGNFLOW_ALLOW_PAID_LLM='true'
ruby script/signflow_agent.rb --job ders-demosu-001
```

Coding agent bu izni gerçek çağrı için açmadı. Anahtar yoksa güvenli giriş sağlanmadan; model erişilemiyorsa Models preflight geçmeden program devam etmez. Anahtar/bütçe sorunu fake başarıyla aşılmaz. Daha yeni modele sessiz fallback yoktur; gerekirse modeli seçip fiyatı/uyumluluğu yeniden doğrulayın.

## Canlı akış

1. Model erişimi kontrolü başarıyla geçerse doğal dil talebini girin: **“Ahmet için 25 bin TL'lik yazılım sözleşmesi hazırla.”** Bu talepte e-posta ve son tarih yoktur.
2. `get_template_version` aracı ve HTTP sonucu görünür. Modelin eksik alan sorusunu bekleyin. Ücret veya tarih uydurursa istemci durabilir; bu başarısız denemeyi saklayın, tamamlandı demeyin.
3. Takip cevabına sentetik adres ve **gerçekten gelecekteki offsetli ISO8601 tarihini** yazın. Örnek (30 Ekim'den sonra güncelleyin): **“Alıcı Ahmet, e-postası ahmet@example.com, hizmet yazılım, ücret 25 bin TL, son imza tarihi 2026-10-30T18:00:00+03:00.”** Şablonda varsa dönem için `2026-10-26` ve `2026-10-29` gibi açık tarihleri, geleceklik/dönem uygunluğunu kontrol ederek ayrıca girin.
4. Modelin çıkardığı alanları JSON olarak inceleyin. Özellikle e-posta, ücret ve zaman farkı doğru değilse **EVET yazmayın**. Doğruysa EVET ile yalnız taslak oluşturmayı onaylayın.
5. `create_draft` ve `get_draft` araçlarının gerçek HTTP sonuçları görünür. Başarı satırındaki belge ID/başlık/kaynak sürüm/status ve göreli `/documents/:id` yolunu gösterin. Modelin serbest başarı paragrafı yerine API doğrulanmış sonuç gösterilir.
6. Aynı işi tekrar etmek için **yeni job açmayın**. Kaydı koruyarak:

```powershell
ruby script/signflow_agent.rb --job ders-demosu-001 --resume
```

Bu adım model çağırmaz: disk kaydındaki aynı key/payload ile API replay ve GET yapar. Aynı ID ve mevcut durum beklenir. `deterministic_job_recovery_not_new_llm_call` etiketi görünür; bunu ikinci LLM başarısı diye anlatmayın. CLI'da API event'leri görünür, secret/key/payload tekrar yazdırılmaz.

7. SignFlow web hesabına kendiniz giriş yapın; gösterilen inceleme yolunu **aynı host üzerinde** açın. İçeriği, alıcıyı ve gelecekteki son tarihi inceleyin; gerekiyorsa taslakta düzeltin. Bu kez web'deki **İmzaya gönder** düğmesini insan kullanır.
8. Oluşan imza bağlantısını gizli pencerede açın; adı/kabulü girip demo imzayı tamamlayın. Agent bu linki, session cookie'sini, parolayı veya CSRF token'ını almaz.
9. Sahip detayında signed/İmzalandı durumunu gösterin. Aynı job'ın `--resume` sorgusu da güncel signed durumunu gösterebilir; key/payload korunur, yeni taslak oluşturulmaz.
10. Demo bitince API credential'ını owner kapsamlı iptal edin; env secret'larını kaldırın/console'u kapatın. Gelecekte erişilebilecek geçerli key'leri projeksiyona koymayın. Sızıntı şüphesinde sağlayıcı key'ini de iptal/yenileyin.

## Aksama davranışı

| Durum | İşlem |
| --- | --- |
| `paid_calls_not_authorized` | Kullanıcı bütçe izni henüz yok; kendi kararınız olmadan bayrağı açmayın. |
| `provider_http_401` / model 404 | Hesap/key/model erişimini özel olarak kontrol edin. Model çalıştı demeyin. |
| `api_http_401` | SignFlow credential süre/iptal/owner; yeni key'i projeksiyon dışında teslim edin. Job/payload/key kaydını koruyun. |
| `api_http_409` / job payload conflict | Aynı key'in payload'ı değişmiş; yeni key ile kör tekrar yapmayın. Mevcut belgeyi inceleyin. |
| `api_http_422` / grounding/date/fee hatası | Eksik/uygunsuz veri. Model tarafından uydurulmuş bilgiyi onaylamayın; düzeltme için doğru sentetik bilgiyi verin. Kaydedilmiş payload varsa resume bunu değiştirmez. |
| 429 / timeout / 500 | En fazla iki transport denemesi var. POST commit olmuş olabilir; aynı job ile resume kullanın. Sağlayıcı timeout'u ücret oluşmadığı anlamına gelmez. |
| Model malformed output / loop limit | Program başarısızdır; gerçek değerlendirmeye kaydedin. Deterministik script'i gerçek model yerine kullanıp başarı iddia etmeyin. |
| İnternet/Render uyku sorunu | Canlı başarı iddia etmeyin. Yerel kod ve fake test kanıtını ayrı isimle gösterin. |

Gerçek demo yapılınca: tarih, başlangıç SHA + uncommitted diff bilgisi, model ID, tool adları/HTTP kodları, doğrulanan belge durumu, yalnız gerçek response usage ve sağlayıcı usage/billing maliyeti kaydedilir. Kayıt/video henüz yoktur; bu dosya kanıt değildir. Fake fixture token sayıları gerçeğe eklenmez. Başarısız denemeler ve kayıp timeout tüketimi de ayrıca belirtilir.
