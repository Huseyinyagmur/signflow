# Gerçek LLM denemesi — kullanıcı için kısa ve güvenli rehber

**25.10.2026. Henüz gerçek LLM çağrısı yapılmadı.** Bu adımları kendi hesabınızda, yalnız sentetik veriyle ve maliyeti kendiniz onayladıktan sonra uygulayın. Anahtarınızı sohbete, terminal komutuna, GitHub'a veya rapora yazmayın.

1. Yerelde API'yi açıp sunucuyu başlatın/yeniden başlatın:

   ```powershell
   $env:AGENT_API_ENABLED='true'
   bundle exec rails server
   ```

2. SignFlow web hesabınıza girin → **Agent erişimi** (`/agent_credentials`). Erişim adı ve 1/7/30 gün seçip oluşturun. Bu adımı projeksiyon kapalı yapın. Token yalnız ilk POST yanıtında görünür; listeye, flash/session'a veya tekrar GET'e kaydedilmez. Kaybederseniz erişimi iptal edip yenisini oluşturun. Varsayılan 7 gün, demo için 1 gün yeterlidir.
3. Anthropic hesabınızda workspace'e bağlı API key ve kredi/harcama sınırını özel olarak hazırlayın. Bu çalışma anahtar istemedi veya kaydetmedi. İstemci başlarken env boşsa SignFlow token'ını ve Anthropic key'ini ayrı **maskeli console girişleriyle** alır; gerçek değerleri komutlara yazmayın. Etkileşimli terminal kullanın; ekran kaydını bu sırada kapatın. `.env.example` isim örneğidir, otomatik yüklenmez.
4. Ayrı bir PowerShell'de yalnız gizli olmayan ayarları yapın. 12/28 örnektir; kendi şablon/sürüm ID'lerinizi girin:

   ```powershell
   $env:SIGNFLOW_BASE_URL='http://127.0.0.1:3000'
   $env:SIGNFLOW_ALLOW_LOOPBACK_HTTP='true'
   $env:SIGNFLOW_TEMPLATE_ID='12'
   $env:SIGNFLOW_TEMPLATE_VERSION_ID='28'
   $env:SIGNFLOW_LLM_MODEL='claude-haiku-4-5-20251001'
   $env:SIGNFLOW_SYNTHETIC_DATA='true'
   ```

5. **Ücretli kullanım kararını yalnız siz verdikten sonra** aşağıdakini uygulayın. Bu bayrak maliyet hard cap'i değildir; sağlayıcı bütçenizi ayrıca kontrol edin:

   ```powershell
   $env:SIGNFLOW_ALLOW_PAID_LLM='true'
   ruby script/signflow_agent.rb --job benim-sentetik-denemem-001
   ```

6. Maskeli girişleri tamamlayın; ardından istemci model erişimini kontrol eder. Başarısızsa gerçek LLM çalışmış gibi sunmayın. Başarıdan sonra “Ahmet için 25 bin TL'lik yazılım sözleşmesi hazırla” talebini girin; eksik e-posta ve gelecekteki açık offsetli imza tarihini tamamlayın. Sürümün zorunlu değişkenlerini de verin. Çıkarılan alanlar doğruysa EVET ile **yalnız taslak oluşturmayı** onaylayın.
7. Araç adları, HTTP kodları, draft ID/status ve login gerektiren inceleme yolu görünür. Aynı işlemin tekrarında yeni job açmayın:

   ```powershell
   ruby script/signflow_agent.rb --job benim-sentetik-denemem-001 --resume
   ```

   Resume model çağırmaz; aynı kayıtlı payload/key ile replay ve GET yapar. Kota 429 verirse Retry-After süresi/60 saniyelik pencereyi bekleyip aynı job ile tekrar deneyin. İstemcinin 0,5 sn backoff'u tüm kota penceresini beklemez; iki deneme sonrası durabilir. 401'de süre/iptali kontrol edin; 409'da payload'ı/key'i kör değiştirerek devam etmeyin.
8. Web'de taslağı inceleyip **İmzaya gönder** düğmesini kendiniz kullanın. Alıcı ayrı pencerede mevcut demo imzayı tamamlasın. Agent'a cookie/CSRF/parola/imza linki vermeyin. Tam akış: [demo rehberi](AGENT_LLM_DEMO.md).
9. İş bitince web'de **Erişimi iptal et**; terminali kapatın veya varsa secret env değişkenlerini kaldırın. `tmp/llm-jobs` secret içermez ama sentetik payload içerir; Git'e/ekran kaydına koymayın. Windows'ta özel dosya/clipboard/NTFS erişimini kontrol edin.

**Model kontrolü:** 25.10.2026 [resmî sayfa](https://platform.claude.com/docs/en/models/haiku-4-5/overview), `claude-haiku-4-5-20251001` için Active (legacy), input $1/1M ve output $5/1M gösterdi. Hesap erişimi bilinmiyor; gerçek denemede preflight zorunlu, sessiz fallback yok. 8.000 input + 2.000 output varsayımı yaklaşık $0,018'dir; gerçek kullanım/fatura ölçümü değildir. Model/fiyatı deneme gününde yeniden kontrol edin.

Gerçek deneme sonrası yalnız model ID, araç/HTTP kodları, belge durumu ve gerçek response usage/billing bilgilerini kanıt olarak kaydedin. API key/token, ham prompt veya gerçek müşteri bilgisi eklemeyin. Fake test token sayılarını gerçek usage'a katmayın.
