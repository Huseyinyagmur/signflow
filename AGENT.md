# SignFlow

SignFlow, sözleşme oluşturma ve demo elektronik imzalama akışını öğreten bir üniversite projesidir. Hukuken nitelikli elektronik imza, kimlik doğrulaması veya mevzuata uygunluk iddiasında bulunulmaz.

## Ortam ve kapsam

Windows 11, Ruby 3.4.11, Rails 8.1.4, SQLite ve Tailwind CSS kullanılır. PowerShell'de Rails komutları `bundle exec rails` ile çalıştırılır. Üçüncü aşama mevcut kayıt/giriş ve demo imza akışına kullanıcıya ait değişkenli şablonlar, sürüm geçmişi ve sunucu önizlemesi ekler.

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
- Template kullanıcıya aittir; current_version_id güncel TemplateVersion'a işaret eder. Başlık, açıklama ve metin sürümde saklanır. Templates::Manage oluşturma/güncellemeyi transaction ve şablon satırı kilidiyle yapar. İlk oluşturma sırasında geçici boş current_version_id yalnızca transaction içinde bulunur. Versiyon numarası şablon içinde benzersiz ve pozitiftir.
- TemplateVersion kayıt sonrası readonly'dir; eski sürümler düzenlenmez veya silinmez. Her kaydetme yeni bir tam sürüm oluşturur. current_version yalnızca aynı şablona ait olabilir. Kullanıcı ve seed_key yeniden atanamaz; şablon silme uçları bu kapsamda yoktur.
- Templates::Manage tüm liste, arama, şablon ve sürüm sorgularını kullanıcının templates ilişkisi üzerinden sınırlar. Arama yalnızca güncel sürümün başlık/açıklamasında parametreli LIKE ile yapılır; wildcard karakterleri escape edilir.
- Templates::Renderer yalnızca alici_adi, hizmet, ucret, baslangic_tarihi, bitis_tarihi adlarını kabul eder. {{alan_adi}} veya {{ alan_adi }} biçimi kullanılır. Bozuk/bilinmeyen yer tutucular, eksik/boş/fazla veya string olmayan değerler reddedilir. Değiştirme tek geçişli düz metin işlemidir; Ruby/ERB çalıştırma, eval veya recursive interpolation kullanılmaz. Sonuç HTML olarak yorumlanmaz; ERB escaping korunur.
- TemplateRevision, şablon editörünün doğrulanan form nesnesidir. Şablon metni en fazla 50000, alan değeri en fazla 5000 karakterdir. Tekrarlanan alan yalnızca bir kez sorulur. Önizleme ve kaydetme aynı sunucu renderer'ını kullanır; istemciden content kabul edilmez.
- Documents::Manage#build_from_template, sürümün sahibiyle belge sahibini doğrular ve başlık/metnin bağımsız kopyasını oluşturur. Document.template_version_id kaynak sürüme işaret eder ve belge oluşturulduktan sonra değiştirilemez. Manuel belge oluşturma geçerlidir; bu belgelerin kaynak sürümü boş olabilir. Taslak metni sonradan elle düzenlenebilir, şablon düzenlemesi mevcut belgeleri güncellemez.
- Oluşturma formu version_id ile açıldığı sürüme sabitlenir; kullanıcı formu doldururken güncel şablon değişse bile aynı sürüm kullanılır. Farklı şablon veya başka kullanıcıya ait version_id reddedilir. Birden fazla POST action'ı kullanan önizleme/kaydetme formu Rails'in oturuma bağlı global form_authenticity_token değerini taşır; CSRF ve origin kontrolü kapatılmaz.
- Templates::DemoSeeder üç ders örneğini kullanıcı başına sabit seed_key ile ekler. db:seed mevcut kullanıcıları işler; yeni kullanıcı arayüzde Demo şablonları ekle düğmesine basabilir. Seed tekrarı mevcut veriyi veya kullanıcının düzenlediği örneği değiştirmez. Demo hesap/parola oluşturmayın.

## Kodlama ve test

- Rails adlandırmalarına uyun; servisler app/services altında olmalı. Hassas alanları JSON'a otomatik dökmeyin.
- Ham token ve parolayı loglamayın, kaynak koduna veya seed'e yazmayın. Token parametreleri mevcut filter_parameters tarafından filtrelenir. Alıcıya sözleşme kimliği üzerinden erişim vermeyin. ERB otomatik escaping korunmalı; sözleşme içeriğine veya imzalayan adına raw / html_safe uygulamayın.
- Zaman testlerinde travel_to / travel bloklarını kullanın; sleep veya sabit bugünün tarihini kullanmayın. Mikrosaniyeli son tarih sınırlarında `travel_to deadline, with_usec: true` kullanın; varsayılan travel_to mikrosaniyeleri sıfırlar.
- Yeni belge uçları için sahiplik ve yetkisiz erişim testleri ekleyin. Model, servis ve oturum testlerini gerçekten çalıştırın; çalışmayan kontrolleri başarılı göstermeyin.
- SQLite yazmaları ve zaman testleri Windows'ta tek worker ile çalışır.
- Şema değiştiren migration sonrasında çalışan Rails sunucusunu tamamen yeniden başlatın. Ayrı db:migrate/runner süreci web sunucusunun Document sütun önbelleğini yenilemez. Sütun yok hatasında önce gerçek SQLite PRAGMA bilgisi, migration durumu ve temiz runner sürecini karşılaştırın. Her istekte reset_column_information çağırmayın, alanı atlayarak hatayı gizlemeyin ve mevcut sütun için tekrar migration eklemeyin. Veri değiştirmeyen tanılama: bundle exec rails runner script/check_template_schema.rb. Regresyonlar SQLite kataloğunu ve kayıtsız önizleme → kayıt → signed akışını doğrular.

PowerShell komutları:

```powershell
bundle install
bundle exec rails db:migrate
bundle exec rails db:prepare RAILS_ENV=test
bundle exec rails db:seed
bundle exec rails test
bundle exec rails zeitwerk:check
bundle exec rails tailwindcss:build
bundle exec rails documents:expire
bundle exec rubocop
```

## Yapılmaması gerekenler

- Mevcut Rails projesini silmeyin, yeniden üretmeyin veya kullanıcı dosyalarının üzerine topluca yazmayın.
- Kullanıcı talebi olmadan db:drop / db:reset, force push, deploy veya GitHub'a push yapmayın.
- Bu aşamada PDF, gerçek e-posta servisi, gelişmiş şablon iş akışları, yapay zekâ entegrasyonu, ödeme veya deploy eklemeyin. Temel değişkenli şablonlar ve sürüm geçmişi üçüncü aşamanın kapsamındadır.
- Yetkilendirmeyi istemciye bırakmayın; sahibin belge sorgularını global kapsamdan yapmayın.
- Demo onayını hukuken nitelikli elektronik imza olarak sunmayın.
