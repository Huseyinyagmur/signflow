# SignFlow AI — güvenli yerel web demosu

**25.10.2026 kullanıcı beyanı:** Model değişikliği sonrası bu yerel akış gerçek Gemini ile signed'a kadar tamamlandı. Başarılı model ID'si bildirilmedi. Bu belgeyi kullanırken kendi doğrulanmış ID'nizi seçin; eski örnekteki 2.5 değerini zorunlu ayar sanmayın. Bağımsız Codex/production kabulü yapılmadı. [Final kanıt kaydı](AI_FINAL_RELEASE_REPORT.md).

Bu komutlar kullanıcı içindir; geliştirme sırasında gerçek Gemini çağrısı yapılmadı. Anahtarı sohbete, kaynak dosyaya, terminal komutuna veya ekran kaydına yazmayın. Yalnız sentetik veri kullanın. Render ortamına henüz uygulamayın. [Teknik rapor ve sınırlar](AI_CONTRACT_WEB_REPORT.md).

## Hazırlık

**Yerel `.env` seçeneği:** Rails development artık `dotenv-rails` ile proje kökündeki `.env` dosyasını otomatik yükler. Dosya yoksa `.env.example` dosyasını özel olarak `.env` adıyla kopyalayın; mevcut dosyanın üzerine yazmayın. Gerekli provider/model/feature flag/sentetik veri ve free-tier teyit ayarlarını yukarıdaki güvenlik koşullarına göre kendiniz düzenleyin. Anahtarı yalnız özel yerel dosyaya girin; dosya Git tarafından yok sayılır, paylaşmayın. Dosya değişince sunucuyu tamamen yeniden başlatın. Mevcut process ENV dosyadan önceliklidir (boş tanımlı değişken de önceliklidir); farklı sonuçta yalnız gerekli değişkenin tanımını özel olarak kontrol edin, tüm environment'ı yazdırmayın. `.env.example` kendisi yüklenmez. Test/production `.env` yüklemez; Render'da aynı isimli Environment Variables kullanılır. Aşağıdaki maskeli terminal yöntemi alternatif olarak korunur.

Mevcut Rails sunucusunu kendiniz durdurun; yeni migration nedeniyle tamamen yeniden başlatılmalı. Windows PowerShell, `C:\signflow`:

```powershell
bundle exec rails db:migrate
bundle exec rails tailwindcss:build
$env:AI_CONTRACTS_ENABLED='true'
$env:SIGNFLOW_LLM_PROVIDER='gemini'
$env:SIGNFLOW_LLM_MODEL=Read-Host 'Hesabınızda başarıyla kullandığınız Gemini model ID'
$env:SIGNFLOW_GEMINI_TIER='free'
$env:SIGNFLOW_ALLOW_PAID_LLM='false'
$env:SIGNFLOW_SYNTHETIC_DATA='true'
```

Model ID örnektir; daha önce **kendi hesabınızda** erişimini kontrol ettiğiniz, mevcut sağlayıcının desteklediği ID'yi seçin. Model bulunamazsa erişim hatası gösterilir; fallback yoktur. Burada 2.5 erişimi veya ücretsiz kota garantisi verilmez. Yeni model/allowlist gerekiyorsa önce resmî belge ve hesabınız kontrol edilmelidir.

Google AI Studio'da doğru projenin ücretsiz/billing-off durumunu ve kullanım koşullarını bizzat kontrol edin. Free katmanda girdiler geliştirme/insan incelemesine konu olabilir; kişisel/gizli veri göndermeyin. `FREE_TIER_CONFIRMED` bir kullanıcı beyanıdır, uygulama faturayı okuyamaz/free-only garantisi vermez. **Kontrolden sonra** aynı PowerShell'de:

```powershell
$env:SIGNFLOW_GEMINI_FREE_TIER_CONFIRMED='true'
$geminiSecret = Read-Host 'GEMINI_API_KEY (gizli)' -AsSecureString
try {
  $env:GEMINI_API_KEY = [System.Net.NetworkCredential]::new('', $geminiSecret).Password
  bundle exec rails server
} finally {
  Remove-Item Env:GEMINI_API_KEY -ErrorAction SilentlyContinue
  $geminiSecret.Dispose()
}
```

Anahtar process environment'ındadır; terminale basılmaz veya dosyaya kaydedilmez. Aynı hesap/OS erişimi olan süreçler environment okuyabilir; özel makine/terminal kullanın. `Get-ChildItem Env:`, transcript, env dump veya debug HTTP logging açmayın. `.env.example` otomatik yüklenmez. Web için `AGENT_API_ENABLED`, bearer token veya API credential gerekmez.

## Tarayıcı adımları

1. **http://localhost:3000/ai_contracts/new** adresini açın. Bütün akışta aynı host'u kullanın; localhost/127.0.0.1 arasında geçiş yapmayın.
2. Sentetik hesabınızla giriş yapın. `AI ile Sözleşme Oluştur` menüsünde kendinize ait şablonu seçin. `hizmet` ve `ucret` değişkenlerini kullanan bir demo şablon uygundur. Sentetik veri kutusunu onaylayıp konuşmayı başlatın.
3. Örnek talep: `Ahmet için 25 bin TL tutarında Web demo sözleşmesi hazırla.` Şablonunuzun diğer zorunlu alanları varsa onlar da sorulur.
4. Sorulan e-posta ve gelecekteki son tarihi açıkça girin: `Alıcı Ahmet, e-posta ahmet@example.com, son imza 2030-01-01T18:00:00+03:00.` Bu tarih demo gününüzde gelecekte olmalı. Hizmet tarihleri istenirse `YYYY-MM-DD` biçiminde açıkça yazın. E-posta/tutar/tarih uydurulmaz; model yanlış biçim veya değeri önerirse güvenli hata alırsınız.
5. Sağ panelde sabit şablon sürümünü, alanları ve güvenilir renderer önizlemesini inceleyin. Bu noktada Document kaydı yoktur. Serbest Gemini metni hukuki sözleşme olarak kullanılmaz.
6. **Taslağı Oluştur** düğmesine basın. Normal belge detayına yönlendirilir; durum draft olmalı. Aynı onayı tekrar göndermek ikinci belge oluşturmaz.
7. Sözleşmelerim listesinde belgeyi bulun. İnceleyin/düzenleyin, ardından kendiniz **İmzaya gönder** deyin. Alıcı bağlantısıyla mevcut demo imzayı tamamlayın; durum signed olmalı. Kullanıcı 25.10.2026 yerel denemesinde bunu tamamladığını bildirdi; yeni ortam/production için ayrı izinli doğrulama gerekir.
8. Kod/anahtar göstermeden yalnız alanları, önizlemeyi ve draft/signed durumlarını sunumda gösterin. İmza linki ve private secret ekranını paylaşmayın.

## Hata ve tekrar davranışı

- Yenileme aynı durumu gösterir; aynı mesaj/step tekrarında model çağrısı yinelenmez. Farklı mesajı eski formdan göndermek 409 verir; sayfayı yenileyin.
- Önceki model isteği başarısız olduysa otomatik tekrar/ücretli replay yoktur. Yeni konuşma başlatmadan önce servis/kota durumunu kontrol edin.
- 429 ve `web_quota_exceeded`: kullanıcı kotası fixed 10 dakika penceresinde yenilenir; Retry-After muhafazakâr 600 saniyedir. Provider 429'u ise Google kotasıdır; web kotasını sıfırlamak çözüm değildir.
- `gemini_http_401/403/404`, `gemini_model_unavailable`: kendi model/proje/key erişiminizi özel olarak kontrol edin; anahtarı paylaşmayın. `invalid_model_question_json`: bir biçim onarımı da başarısız; sahte başarı yok. Ham response loglamayın.
- `conversation_lost_start_new`/`conversation_expired`: konuşma en fazla bir saat erişilebilirdir, restart/reload'da durum kaybolabilir. Henüz taslak yoksa yeni konuşma gerekir. Önce normal belge listesini kontrol edin; oluşturulmuş belge kalıcıdır.
- Bir saat dolmadan gönderilmiş ama yanıtı kaybolmuş draft onayı, aynı konuşma üzerinden güvenle tekrar denenebilir. Daha sonra da tamamlanmış receipt mevcut belgeyi bulur. Yeni konuşma yeni bir iş olduğundan ayrı taslak oluşturabilir.
- UI yükleniyor göstergesi ve responsive görünüm integration testlerinin yerine gerçek tarayıcıda kontrol edilmelidir. Gerçek LLM çıkarım kalitesi ve maliyeti henüz ölçülmedi.

## Yerel kontroller

```powershell
bundle exec rails test
bundle exec rubocop
bundle exec rails zeitwerk:check
bundle exec rails tailwindcss:build
```

Testler fake model kullanır; gerçek anahtar gerektirmez. Ayrı PostgreSQL concurrency yalnız loopback `*_agent_test` DB ve mevcut opt-in değişkeniyle çalıştırılır; production DATABASE_URL kullanmayın. CI ek testleri içerir ama uzak Actions sonucu bu çalışmada doğrulanmadı. Bu rehber commit/push/deploy izni değildir.
