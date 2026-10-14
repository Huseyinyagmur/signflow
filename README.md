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

PDF, gerçek e-posta servisi, gelişmiş şablonlar, yapay zekâ ve deploy yoktur. Link yenileme/yeniden gösterme, parola sıfırlama ve e-posta doğrulaması yoktur. Cookie oturumları 12 saatliktir, giriş denemesi sınırı süreç başına bellektedir. Linke sahip kişi demo imza atabilir; gerçek alıcı kimliği doğrulanmaz.

Mimari ve ajan kuralları: [AGENT.md](AGENT.md). İkinci aşama dosya listesi, gerçek test sonuçları, rotalar ve doğrulama sınırları: [rapor](docs/PHASE2_REPORT.md).
