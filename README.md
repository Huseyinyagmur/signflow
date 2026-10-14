# SignFlow

Ruby 3.4.11 / Rails 8.1.4, SQLite, ERB, Hotwire ve Tailwind CSS ile geliştirilmiş üniversite projesi. Kullanıcı kayıt olur, giriş yapar, sözleşme taslağı oluşturur, imzalama bağlantısını paylaşır ve alıcının demo imzasını takip eder. Hukuken nitelikli elektronik imza veya doğrulanmış kimlik iddiasında bulunmaz.

## Yerel çalıştırma (Windows PowerShell)

```powershell
Set-Location C:\signflow
bundle install
bundle exec rails db:migrate
bundle exec rails tailwindcss:build
bundle exec rails server -b 127.0.0.1 -p 3000
```

http://localhost:3000 adresini açın. Sunucu zaten çalışıyorsa ikinci bir sunucu başlatmayın. Gemfile değişikliklerinden sonra sunucuyu durdurup yeniden başlatın. Windows'ta Puma'nın restart işlemi sunucuyu kapatıp yeniden başlatamayabilir; bu durumda yukarıdaki server komutunu yeniden çalıştırın.

Tek bir ana adres kullanın: localhost ve 127.0.0.1 farklı origin ve cookie kapsamlarıdır. Oturum açtıktan sonra ikisi arasında geçiş yapmayın. Güvenlik başlıklarını etkileyen config değişikliklerinden sonra sunucuyu yeniden başlatıp açık form sayfalarını yenileyin. Referrer-Policy same-origin kullanılır; no-referrer normal form POST'larında Origin: null üretebilir ve Rails CSRF doğrulamasında reddedilir. CSRF/origin denetimini kapatmayın.

CSS kaynaklarını değiştirirken ayrı PowerShell penceresinde `bundle exec rails tailwindcss:watch` kullanabilirsiniz. Yeni CSS değişikliğinden sonra gerekirse tarayıcıyı yenileyin.

## Elle uçtan uca deneme

1. Ana sayfadan hesap oluşturun (en az 12 karakter parola), ardından giriş yapın.
2. Yeni sözleşme ekranında başlık ve metin girip taslak kaydedin.
3. Taslağı düzenleyerek alıcı adı, e-postası ve gelecekte bir son imza tarihi ekleyin. Tarih Türkiye saatidir.
4. Detay ekranından **İmzaya gönder** düğmesine basın.
5. Gösterilen bağlantıyı o anda kopyalayın. Ham token saklanmadığından sayfadan ayrılınca link tekrar görüntülenemez.
6. Bağlantıyı başka tarayıcıda veya gizli pencerede açın. JavaScript gereklidir; URL fragment'i CSRF korumalı POST gövdesine aktarılır.
7. Sözleşmeyi okuyun, adınızı yazın, kabul kutusunu işaretleyip demo imzayı tamamlayın.
8. Sahibin çalışma alanında dashboard veya belge detayını yenileyin. Durum **İmzalandı**, girilen ad ve imza zamanı görünür.
9. Aynı bağlantıyı yeniden açmak reddedilir. Son tarihi geçmiş pending belgeler de imzalanamaz.

## Kontroller

```powershell
bundle exec rails db:prepare RAILS_ENV=test
bundle exec rails test
bundle exec rails zeitwerk:check
bundle exec rubocop
bundle exec rails tailwindcss:build
bundle exec rails documents:expire
```

`rails zeitwerk` ve `rails tailwindcss` tek başına görev değildir; yukarıdaki tam görev adlarını kullanın.

## Süre sonu

Dashboard, belge listesi/detayı ve token erişimi ilgili belgeleri Documents::Expiration üzerinden kalıcı olarak expired yapar. İstek almayan tüm belgeleri işlemek için `bundle exec rails documents:expire` çalıştırın. Otomatik zamanlayıcı kurulmamıştır; komut Windows Görev Zamanlayıcı'ya ileride açıkça bağlanabilir. İmza kontrolü zamanlayıcıdan bağımsızdır ve son tarihe eşit anda reddeder.

## Sınırlar

Temel değişkenli şablonlar ve sürüm geçmişi vardır. PDF, gerçek e-posta servisi, gelişmiş şablon iş akışları, yapay zekâ ve deploy yoktur. Link yenileme/yeniden gösterme, parola sıfırlama ve e-posta doğrulaması yoktur. Cookie oturumları 12 saatliktir, giriş denemesi sınırı süreç başına bellektedir. Linke sahip kişi demo imza atabilir; gerçek alıcı kimliği doğrulanmaz.

Mimari ve ajan kuralları: [AGENT.md](AGENT.md). İkinci aşama dosya listesi, gerçek test sonuçları, rotalar ve doğrulama sınırları: [rapor](docs/PHASE2_REPORT.md).

## Gerçek Kullanıcı Problemi ve Çözümümüz

[Capterra'daki DocuSign yorumlarında](https://www.capterra.com/p/121506/Docusign/reviews/) yer alan 17 Ağustos 2026 tarihli **“Signing takes a minute, template upkeep takes an afternoon”** değerlendirmesi bu aşamanın çıkış noktasıdır. Yorumda, belge düzeni veya alanların dayandığı metin değişince şablon alanlarını tekrar yerleştirmenin bakım yükü oluşturduğu; arama ve bazı yönetim işlemlerinin gereğinden fazla adım istediği anlatılıyor.

SignFlow, ders demosunda bu problemi ortak metni tek yerde düzenleyerek, değişken alanları otomatik algılayarak, başlık/açıklama araması ve değiştirilemeyen sürüm geçmişi sunarak ele alır. Şablondan oluşturulan sözleşme bağımsız bir metin kopyası taşır. Şablon güncellemesi eski taslakları veya imzalı belgeleri etkilemez. Şablonların özgün üründe hiç bulunmadığı iddia edilmez; farkımız, tekrar eden sözleşmeler için daha sade ve merkezi bir oluşturma/güncelleme deneyimi sunmaktır. PDF alan yerleşimi bu projenin kapsamında değildir.

### Şablon sistemini deneme

**Migration sonrası sunucuyu yeniden başlatın.** Açık Rails süreci eski Document sütun bilgisini bellekte tutabilir. db/schema.rb ve diskteki SQLite tablosunda template_version_id bulunsa bile eski süreç `MissingAttributeError` verebilir. Windows'ta sunucuyu Ctrl+C ile tamamen durdurup `bundle exec rails server -b 127.0.0.1 -p 3000` ile yeniden açın; ardından form sayfasını yenileyin. Veritabanını sıfırlamayın ve gereksiz ikinci bir sütun migration'ı oluşturmayın.

Veri değiştirmeyen tanılama:

```powershell
bundle exec rails db:migrate:status
bundle exec rails runner script/check_template_schema.rb
```

Tanılama gerçek sütun, nullable/index/foreign key, model ilişkisi ve kaydedilmemiş belge atamasını kontrol eder. Ayrı ve temiz bir Rails sürecinde çalışır; çalışan web sunucusunun önbelleğini temizlemez. Gerçek şema regresyonu ve uçtan uca akış `test/integration/template_schema_regression_test.rb` içinde test edilir.

```powershell
bundle exec rails db:migrate
bundle exec rails db:seed
bundle exec rails tailwindcss:build
```

Seed mevcut kullanıcıların her birine üç ders örneği ekler. Hesap yoksa hesap oluşturduktan sonra **Şablonlarım → Demo şablonları ekle** düğmesini kullanın. Seed/düğme tekrar çalıştırıldığında kullanıcı verileri veya düzenlenmiş örnekler değiştirilmez; demo hesap/parola oluşturulmaz.

1. Dashboard'dan **Şablondan oluştur** veya sol menüden **Şablonlarım** ekranına gidin.
2. Örneklerden birini seçin veya **Yeni şablon** ile başlık, açıklama ve metin girin.
3. Metinde `{{alici_adi}}`, `{{hizmet}}`, `{{ucret}}`, `{{baslangic_tarihi}}`, `{{bitis_tarihi}}` alanlarından gerekenleri kullanın. Aynı alanı tekrar yazabilirsiniz; yalnızca bir kez doldurulur. Bilinmeyen/bozuk alanlar reddedilir.
4. **Sözleşme oluştur** düğmesine basın, algılanan değişkenleri doldurun; alıcı e-postası ve gelecekte bir son imza tarihi ekleyin. Alıcı adı boş bırakılırsa `alici_adi` değerinden doldurulur.
5. **Önizle** ile hazırlanmış metni kontrol edin; **Sözleşme taslağını oluştur** ile kaydedin. Kaydetme metni sunucuda yeniden üretir; gönderilen content alanına güvenmez.
6. Mevcut detay sayfasından **İmzaya gönder**, bağlantıyı kopyala ve başka tarayıcı/gizli pencerede demo imzala akışını tamamlayın.
7. Şablonu düzenleyin; **Sürüm geçmişi** ekranında v1/v2 metinlerini görün. Eski sürümden de sözleşme oluşturabilirsiniz. Önceden üretilen sözleşme ve imzalı metin değişmez.

Değişkenler düz metindir; HTML, ERB veya Ruby olarak çalıştırılmaz. Önizleme ve sözleşme ekranları otomatik HTML escaping kullanır. Eksik, boş, fazla veya string olmayan alanlar sunucuda reddedilir. Önizleme isteğe bağlıdır; kaydetme aynı doğrulamaları her zaman uygular. Önizleme/kaydetme formu iki işlem adresinde de geçerli oturuma bağlı CSRF token taşır. same-origin politikası korunur.

Model, servis, HTTP, XSS, CSRF, sahiplik ve imzalama testleri için `bundle exec rails test` çalıştırın. Üçüncü aşama dosya listesi ve gerçek sonuçlar: [Üçüncü aşama raporu](docs/PHASE3_REPORT.md).

Şema/önbellek hatası için tanı ve gerçek sonuçlar: [Şema düzeltme raporu](docs/SCHEMA_FIX_REPORT.md).
