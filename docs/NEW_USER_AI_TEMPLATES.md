# Yeni kullanıcı AI başlangıç şablonları

**Gönderim hazırlığı:** Kullanıcının yeni talebiyle tüm yerel kontroller tekrar çalıştırıldı; Rails 197/2111, ayrı PostgreSQL 86/1226, RuboCop 126 dosyada temiz, Zeitwerk ve Tailwind başarılı. Güncel `main / Auto-Deploy Off` kullanıcı teyidi alındı. Commit/push yetkisi yalnız bu gönderim aşamasına aittir; aşağıdaki geliştirme oturumunun “yapılmadı” ifadeleri tarihsel kayıttır. Yeni commit SHA ve Actions sonucu gerçek işlem sonrasında son yanıtta bildirilir; production deploy yetkilendirilmedi.

25.10.2026. Yerel başlangıç SHA: `cd8919f3e1273629b46a1ba711ee2e7ecf794948`. Production'a bağlanılmadı; API anahtarı/.env okunmadı, gerçek Gemini çağrısı, mevcut kayıtları silme, commit/push/deploy yapılmadı.

## Yeniden üretilen neden ve kanıt sınırı

Eski `RegistrationsController#create` yalnız `User.save` çağırıyordu. `Templates::DemoSeeder` kayıt sırasında çalışmıyordu. Bu yüzden temiz bir kayıtla yeni kullanıcı **0 şablonla** oluşuyordu. AI `new` sayfası `Templates::Manage.all` ile yalnız current_user'ın kullanılabilir sürümü olan şablonlarını listeliyor; boşsa seçim/konuşma formu oluşturmuyordu. Dolayısıyla bu yol Gemini'ye hiç ulaşmıyordu.

Authentication/current_user cookie+session üzerinden çalışıyor; AI'nin global feature flag'i var, kullanıcı başına ayrı Gemini credential gerekmiyor. Şablon sahibi ve sabit sürüm mevcut Conversations/Manage servislerinde kontrol ediliyor. Başka kullanıcının şablonlarını göstermek çözüm olarak kullanılmadı; bu izolasyon doğru ve korundu.

Bu neden yeni kayıt integration testinde, eski kodla `Template.count` için beklenen +3 yerine **0** olarak yeniden üretildi. **Canlı ikinci hesabın şablon sayısı/hata kodu incelenmedi**; production'da aynı nedenin tek hata olduğunu iddia etmiyoruz. Kullanılabilir kendi şablonu olduğu halde devam edemeyen hesapta feature flag, güvenli hata kodu, kota, provider/model erişimi veya süreç belleği gibi ayrı nedenler hâlâ değerlendirilmeli. Bu görev bunları gevşetmez veya otomatik model çağrısı yapmaz.

## Uygulanan çözüm

- `Users::Register`: yalnız yeni User alır. User kaydı ve mevcut `Templates::DemoSeeder` aynı User.transaction içinde çalışır; seeder → `Templates::Manage` → immutable TemplateVersion zinciri kullanılır. Şablon validasyonu başarısız olursa kullanıcı/şablon/sürümler birlikte rollback edilir. Başarı bildirimi ancak transaction tamamlanınca gelir. User callback'i eklenmedi; eski kullanıcılar veya ayrı model/operatör oluşturma yolları otomatik değiştirilmez.
- Üç başlangıç başlığı mevcut kataloğun aynısıdır: **Yazılım Geliştirme Hizmet Sözleşmesi**, **Gizlilik Sözleşmesi**, **Danışmanlık Hizmet Sözleşmesi**. Her kullanıcı kendi Template ve v1 TemplateVersion kayıtlarını alır; ortak tenant kaydı paylaşılmaz.
- Eski şablonsuz hesaplar: AI GET sayfası açık boş durum açıklaması, **Üç başlangıç şablonunu ekle** POST formu ve kendi şablonunu oluşturma bağlantısı sunar. GET veya giriş, otomatik backfill yapmaz. POST `/ai_contracts/prepare_templates`, current_user'a bağlıdır; CSRF/origin ve AI feature flag korunur; istekten user_id alınmaz. Redirect tekrar AI seçim ekranına döner. Ekleme Gemini çağrısı yapmaz.
- DemoSeeder'ın mevcut kullanıcı satır kilidi/transaction'ı ve `(user_id, seed_key)` unique DB index'i tekrar/eşzamanlı işlemlerde tek set sağlar. Şablonlar başlığa göre değil sabit seed_key'e göre tanınır. Kullanıcı düzenlemesi/sürüm geçmişi değiştirilmez; özel şablon aynı başlığı taşısa da üzerine yazılmaz.
- Mevcut seed kaydı current_version taşımıyorsa veya kaynak sürümü kendisine ait değilse IncompleteTemplate ile işlem durur. Başka kayıt/sürüm kopyalanarak veya eski kayıt üzerine yazılarak hata gizlenmez. AI recovery güvenli 422 gösterir; normal şablon ekranındaki demo ekleme de açık hata mesajı verir. Böyle bir eski kayıt için kendi yeni şablonunu oluşturma yolu kullanılabilir; bozuk kaydı otomatik onarma bu değişikliğin kapsamında değildir.
- Geçersiz registration hâlâ model hatalarını gösterir. Şablon kurulumu hatasında hesap oluşturulmuş gibi mesaj/oturum verilmez; kayıt formu güvenli hata verir. Beklenmeyen altyapı/DB istisnaları da transaction'ı geri alır; bunların her birini kullanıcı validasyonu gibi yutan genel rescue eklenmedi.

## Gerçek testler

İlk test-first paket: **6 test / 21 assertion, 4 failure / 2 error**. Yeni kullanıcıda +0 şablon, şablon hatasını simüle ederken kullanıcının yine kaydolması, eksik recovery rotası/boş durum yeniden üretildi. İlk uygulama sonrası **6 / 119**, hata yok. Sonradan eklenen eksik sürüm testi eski seeder ile +2 yeni kayıt ve yanlış başarı yolunu yakaladı: **7 / 127, 1 failure**. IncompleteTemplate kontrolü eklenerek düzeltildi. Güvenlik kontrolleri kapatılmadı.

| Kontrol | Gerçek sonuç |
| --- | --- |
| `RAILS_ENV=test` / `bundle exec rails test` | **197 test / 2111 assertion; 0 failure/error/skip**, exit 0. |
| İzole PostgreSQL 18 genişletilmiş paket | **86 test / 1226 assertion; 0 failure/error/skip**, exit 0. |
| `bundle exec rubocop` | **126 dosya; ihlal yok**, exit 0. |
| `bundle exec rails zeitwerk:check` — test ortamı | **All is good!**, exit 0. |
| `bundle exec rails tailwindcss:build` — test ortamı | Başarılı, exit 0. |

Yeni testler: kayıtla üç şablon/sürüm, login ve normal listeleme, LLM'siz conversation başlangıcı, iki kullanıcı izolasyonu/yabancı sürüm reddi, seed hatasında tüm kaydın rollback'i ve yeniden deneme, eski hesap GET'inde yazma olmaması, recovery tekrarında no-op, özel şablonların korunması, hatada kısmi set olmaması, geçersiz/sahipsiz sürüm için yanlış başarı olmaması, auth/CSRF/origin/user_id sahteciliği ve flag kapalı erişim. Mevcut normal sözleşme/imza/API/CLI regresyonları tam pakette korundu.

PG komutu CI'nin mevcut hedeflerine yeni integration ve starter concurrency dosyalarını, ayrıca eski template manage/workflow regresyonlarını ekleyerek çalıştırıldı. Yalnız `127.0.0.1:55443/signflow_agent_test` kullanıldı; dump `tmp/new-user-templates/postgresql-schema.rb` altında. İzole test DB'de `db:migrate` başarıyla çalıştı; bekleyen yeni migration yoktu. Yeni PostgreSQL yarışında iki bağlantı `3` ve `0` döndürdü; bir kullanıcıda yalnız üç template ve üç version kaldı. Windows opsiyonel libvips DLL ve Rack uyarıları vardı; başarısız kontrol gibi gizlenmedi. Gerçek tarayıcı/production/yeni model çağrısı doğrulanmadı.

## Dosyalar

| Dosya | İşlev |
| --- | --- |
| `app/services/users/register.rb` | Atomik yeni kullanıcı + başlangıç şablonu kurulumu. |
| `app/controllers/registrations_controller.rb` | Servis çağrısı ve güvenli kayıt/şablon hatası. |
| `app/services/templates/demo_seeder.rb` | Mevcut idempotent eklemeyi korur; sürümsüz eski seed kaydında yanlış başarıyı engeller. |
| `app/controllers/ai_contracts_controller.rb`, `config/routes.rb` | Oturum/CSRF korumalı ve owner kapsamlı recovery POST'u. |
| `app/views/ai_contracts/new.html.erb` | Açık boş durum, başlangıç seti ekleme ve kendi şablonunu oluşturma seçenekleri. |
| `app/controllers/templates_controller.rb` | Eski şablon ekranında eksik sürüm hatasını anlaşılır gösterir. |
| `test/integration/new_user_templates_test.rb` | Yeni kayıt, owner izolasyonu, rollback/retry, recovery, conversation ve eski hesap regresyonları. |
| `test/postgresql/starter_templates_concurrency_test.rb` | İki bağımsız bağlantı ile setin tekilleştirilmesi. |
| `.github/workflows/ci.yml` | Mevcut PG job'ına yeni integration/concurrency hedefleri; uzakta çalıştırılmadı. |
| `AGENT.md`, bu rapor | Güncel kayıt/seed kuralları, kanıt ve deployment sınırları. |

## Güvenli dağıtım adımları — bu görevde uygulanmadı

1. Yerel diff ve test sonuçlarını inceleyin. Yeni migration/gem/environment gereksinimi yok. Commit/push/deploy bu görevde yapılmadı; ayrıca yetkilendirin.
2. Render Auto-Deploy Off ve doğru branch/SHA'yı yeniden kontrol edin; production yedeği ve ayrı restore testi hazırlığını koruyun. Yeni deploy ilk kullanıcı kayıtlarını etkileyeceği için düşük trafikli bir zaman seçin.
3. İncelenmiş kodu yetkili süreçle yayınlayıp yeni SHA'nın CI sonuçlarını doğrulayın; ardından ayrıca onaylı manuel deploy uygulayın. Mevcut build/start komutları değişmez. **db:seed, reset/drop/schema:load veya toplu backfill çalıştırmayın.**
4. Eski kullanıcılar ve şablonlar kendiliğinden değişmez. Önceden kayıt olup boş kalan kullanıcı, AI sayfasındaki açık recovery düğmesini kullanır. Eksik sürüm hatası alırsa kayıtları silmek yerine kendi yeni şablonunu oluşturabilir; veri onarımı ayrıca değerlendirilir.
5. Yerel/ayrı izinli sentetik ortamda yeni kayıt → giriş → üç kendi şablonu → conversation başlangıcını tekrar kontrol edin. Production'da kayıt/AI/imza denemesi ayrıca izinliyse yalnız sentetik verilerle yapın; model çağrısı için ayrı free/billing koşulları geçerlidir.
6. Sorunda önce AI flag'ini kapatıp incelenmiş önceki koda dönebilirsiniz. Veri/migration rollback'i yapmayın: yeni kullanıcının oluşmuş başlangıç şablonları kendi kayıtları olarak korunur. Eski koda dönüş yeni kayıtlara otomatik set eklemeyi durdurur; mevcut setleri silmez.

Mevcut oturum/CSRF, bearer API yetkileri, Gemini anahtar yönetimi, kota, sabit sürüm, idempotent draft ve insan gönderim/imza sınırı değiştirilmedi.
