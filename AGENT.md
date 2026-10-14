# SignFlow

SignFlow, sözleşme oluşturma ve demo elektronik imzalama akışını öğreten bir üniversite projesidir. Hukuken nitelikli elektronik imza, kimlik doğrulaması veya mevzuata uygunluk iddiasında bulunulmaz.

## Ortam ve kapsam

Windows 11, Ruby 3.4.11, Rails 8.1.4, SQLite ve Tailwind CSS kullanılır. PowerShell'de Rails komutları `bundle exec rails` ile çalıştırılır. İkinci aşama ERB, Turbo ve Stimulus ile kayıt, giriş, belge yönetimi ve alıcı demo imza akışını kapsar.

## Mimari kararlar

- MVC korunur. Controller yalnızca HTTP, kimlik doğrulama ve parametrelerle ilgilenir; belge iş kuralları Document modelindedir.
- User, bcrypt / has_secure_password ile parola hash'i saklar. E-posta normalize edilir ve benzersizdir. Asgari parola uzunluğu 12 karakterdir.
- Documents::Manage, her sorguyu oturum kullanıcısının documents ilişkisi üzerinden yapar. Controller'dan Document.find çağırmayın; kullanıcı kimliğini istek parametresinden almayın.
- Durum grafiği: draft -> pending -> signed veya expired. Geçişler send_for_signature!, sign!, expire! metotlarıyla, veritabanı kilidi ve transaction içinde yapılır. update_columns, update_all ve doğrudan SQL model korumalarını atlar; iş akışında kullanmayın.
- Gönderimden sonra metin, alıcı ve süre değiştirilemez; belge sahibi hiçbir zaman değiştirilemez. Düzeltmeler için yeni bir taslak oluşturulur.
- 32 rastgele bayt içeren URL güvenli token yalnızca gönderim metodundan bir kez döner. Veritabanına SHA-256 hash'i yazılır. Token bir bearer yetkisidir; linki bilen kişi o belgeye erişebilir. Gerçek alıcı kimliği bu aşamada doğrulanmaz.
- Alıcı işlemlerinde Documents::Signing kullanılır; belge ID'si kabul edilmez. İmzalanmış, süresi dolmuş veya bilinmeyen token aynı RecordNotFound sonucunu verir. Token, signed / expired geçişinde silinir.
- Time.current kullanılır; son tarihe eşit anda imza kabul edilmez. Documents::Expiration, liste/detay ve alıcı erişiminde ilgili kapsamı kalıcı olarak günceller. Tüm belgeler için `bundle exec rails documents:expire` çalıştırılabilir. Güvenilir otomatik zamanlayıcı kurulmuş değildir; istek gelmeyen belgeler komut çalışana kadar veritabanında pending kalabilir, ancak imzalanamaz.
- Paylaşım linki `/sign#token=...` biçimindedir. Fragment HTTP isteğine girmez; Stimulus fragment'i geçmişten temizleyip token'ı CSRF korumalı POST gövdesiyle aktarır. Token şifreli oturum cookie'sinde tutulur. Path veya query token kullanmayın. Link gönderim yanıtında yalnızca bir kez gösterilir; DB hash'inden ham token geri üretilemez. Link sayfası no-store, Turbo snapshot'ları no-cache kullanır. Alıcı sayfaları noindex kullanır.
- Referrer-Policy uygulama genelinde config/application.rb üzerinden same-origin olarak tanımlanır. Layout meta etiketi veya controller ile no-referrer eklemeyin: normal HTML POST'larında Origin: null üreterek Rails origin doğrulamasını bozar. CSRF ve origin denetimi açık kalmalıdır. Regression testlerinde gerçek form token'ı ve Origin başlığı birlikte kullanılmalıdır; yalnızca tokensız POST testi yeterli değildir.
- SignatureAcceptance açık kabul ve en çok 120 karakterlik boş olmayan ad ister. Documents::Signing imzalamadan önce bu form nesnesini doğrular. signer_name ve signed_at aynı kilitli geçişte kaydedilir; bu ad bir doğrulanmış kimlik değildir. Eski iç model çağrıları için sign! varsayılan olarak recipient_name kullanabilir; herkese açık HTTP akışı her zaman girilen adı ve açık kabulü gerektirir.
- İmza formu kendi token'ını POST gövdesinde taşır; yalnızca oturumdaki son token'a güvenmeyin. Böylece aynı tarayıcıda farklı sözleşmelerin açık sekmeleri birbirinin belgesini imzalamaz.
- Oturum Rails şifreli cookie'sinde tutulur; giriş/çıkışta reset_session yapılır. HttpOnly, SameSite=Lax, 12 saatlik süre ve production'da Secure kullanılır. Rails CSRF koruması korunur. Giriş limiti süreç başına bellek deposundadır; çok süreçli dağıtımda ortak depoya taşınmalıdır. Cookie oturumlarında çalınmış cookie'nin sunucudan tek tek iptali bulunmaz; sonraki üretim aşamasında sunucu taraflı Session modeli değerlendirilmeli.
- İleride Template ve değişmez TemplateVersion modelleri eklenebilir. Kullanıcıya ait şablon sürümünden üretilen belgeye title/content anlık kopyası yazılır; şablon değişikliği gönderilmiş belgeyi değiştirmez. Şablon modellerini bu aşamada oluşturmayın.

## Kodlama ve test

- Rails adlandırmalarına uyun; servisler app/services altında olmalı. Hassas alanları JSON'a otomatik dökmeyin.
- Ham token ve parolayı loglamayın, kaynak koduna veya seed'e yazmayın. Token parametreleri mevcut filter_parameters tarafından filtrelenir. Alıcıya sözleşme kimliği üzerinden erişim vermeyin. ERB otomatik escaping korunmalı; sözleşme içeriğine veya imzalayan adına raw / html_safe uygulamayın.
- Zaman testlerinde travel_to / travel bloklarını kullanın; sleep veya sabit bugünün tarihini kullanmayın. Mikrosaniyeli son tarih sınırlarında `travel_to deadline, with_usec: true` kullanın; varsayılan travel_to mikrosaniyeleri sıfırlar.
- Yeni belge uçları için sahiplik ve yetkisiz erişim testleri ekleyin. Model, servis ve oturum testlerini gerçekten çalıştırın; çalışmayan kontrolleri başarılı göstermeyin.
- SQLite yazmaları ve zaman testleri Windows'ta tek worker ile çalışır.

PowerShell komutları:

```powershell
bundle install
bundle exec rails db:migrate
bundle exec rails db:prepare RAILS_ENV=test
bundle exec rails test
bundle exec rails zeitwerk:check
bundle exec rails tailwindcss:build
bundle exec rails documents:expire
bundle exec rubocop
```

## Yapılmaması gerekenler

- Mevcut Rails projesini silmeyin, yeniden üretmeyin veya kullanıcı dosyalarının üzerine topluca yazmayın.
- Kullanıcı talebi olmadan db:drop / db:reset, force push, deploy veya GitHub'a push yapmayın.
- Bu aşamada PDF, gerçek e-posta servisi, gelişmiş şablonlar, yapay zekâ entegrasyonu veya deploy eklemeyin. Dashboard ve temel responsive arayüz ikinci aşamanın kapsamındadır.
- Yetkilendirmeyi istemciye bırakmayın; sahibin belge sorgularını global kapsamdan yapmayın.
- Demo onayını hukuken nitelikli elektronik imza olarak sunmayın.
