# SignFlow — İkinci aşama raporu

Tarih: 14 Ekim 2026. Mevcut Rails altyapısı ve merkezi durum geçişleri korunarak kayıt → giriş → taslak → paylaşım bağlantısı → alıcı demo imzası → signed akışı eklendi.

## Dosyalar

Başlangıçta projenin kaynak dosyaları Git'te untracked durumundaydı. Bu liste ikinci aşamada oluşturulan veya düzenlenen dosyaların çalışma kaydıdır; ilk aşama dosyalarının tamamı yeniden oluşturulmadı.

### Oluşturulan (31)

- [app/controllers/pages_controller.rb](../app/controllers/pages_controller.rb)
- [app/controllers/registrations_controller.rb](../app/controllers/registrations_controller.rb)
- [app/controllers/dashboard_controller.rb](../app/controllers/dashboard_controller.rb)
- [app/controllers/documents_controller.rb](../app/controllers/documents_controller.rb)
- [app/controllers/signing_controller.rb](../app/controllers/signing_controller.rb)
- [app/models/signature_acceptance.rb](../app/models/signature_acceptance.rb)
- [app/services/documents/expiration.rb](../app/services/documents/expiration.rb)
- [db/migrate/20261014000300_add_signer_name_to_documents.rb](../db/migrate/20261014000300_add_signer_name_to_documents.rb)
- [lib/tasks/documents.rake](../lib/tasks/documents.rake)
- [test/integration/signflow_workflow_test.rb](../test/integration/signflow_workflow_test.rb)
- [test/models/signature_acceptance_test.rb](../test/models/signature_acceptance_test.rb)
- [test/services/expiration_test.rb](../test/services/expiration_test.rb)
- [public/signflow.svg](../public/signflow.svg)
- [app/views/shared/_errors.html.erb](../app/views/shared/_errors.html.erb)
- [app/views/pages/home.html.erb](../app/views/pages/home.html.erb)
- [app/views/sessions/new.html.erb](../app/views/sessions/new.html.erb)
- [app/views/registrations/new.html.erb](../app/views/registrations/new.html.erb)
- [app/views/dashboard/show.html.erb](../app/views/dashboard/show.html.erb)
- [app/views/documents/_table.html.erb](../app/views/documents/_table.html.erb)
- [app/views/documents/index.html.erb](../app/views/documents/index.html.erb)
- [app/views/documents/new.html.erb](../app/views/documents/new.html.erb)
- [app/views/documents/edit.html.erb](../app/views/documents/edit.html.erb)
- [app/views/documents/_form.html.erb](../app/views/documents/_form.html.erb)
- [app/views/documents/show.html.erb](../app/views/documents/show.html.erb)
- [app/views/signing/_access.html.erb](../app/views/signing/_access.html.erb)
- [app/views/signing/show.html.erb](../app/views/signing/show.html.erb)
- [app/views/signing/unavailable.html.erb](../app/views/signing/unavailable.html.erb)
- [app/views/signing/complete.html.erb](../app/views/signing/complete.html.erb)
- [app/javascript/controllers/clipboard_controller.js](../app/javascript/controllers/clipboard_controller.js)
- [app/javascript/controllers/signing_link_controller.js](../app/javascript/controllers/signing_link_controller.js)
- [docs/PHASE2_REPORT.md](../docs/PHASE2_REPORT.md)

### Düzenlenen (15)

- [AGENT.md](../AGENT.md)
- [README.md](../README.md)
- [app/models/document.rb](../app/models/document.rb)
- [app/services/documents/manage.rb](../app/services/documents/manage.rb)
- [app/services/documents/signing.rb](../app/services/documents/signing.rb)
- [app/controllers/concerns/authentication.rb](../app/controllers/concerns/authentication.rb)
- [app/controllers/sessions_controller.rb](../app/controllers/sessions_controller.rb)
- [config/routes.rb](../config/routes.rb)
- [db/schema.rb](../db/schema.rb)
- [test/test_helper.rb](../test/test_helper.rb)
- [test/controllers/sessions_controller_test.rb](../test/controllers/sessions_controller_test.rb)
- [test/services/documents_test.rb](../test/services/documents_test.rb)
- [app/views/layouts/application.html.erb](../app/views/layouts/application.html.erb)
- [app/helpers/application_helper.rb](../app/helpers/application_helper.rb)
- [app/assets/tailwind/application.css](../app/assets/tailwind/application.css)

Yerel geliştirme ve test veritabanları migrate edildi. Git dışında tutulan app/assets/builds/tailwind.css yeniden derlendi; yerel çalışma logları üretildi. Gemfile, User modeli ve ilk iki migration değiştirilmedi.

## Uygulama

- ERB/Tailwind: SignFlow markalı ana sayfa, kayıt, giriş, dashboard, sözleşme listesi/durum filtreleri, taslak formu, belge detayı, alıcı imza formu, sonuç ve kullanılamayan bağlantı ekranı.
- Hotwire: normal kayıt/giriş/taslak işlemlerinde Turbo; bağlantı kopyalama ve fragment aktarımında Stimulus.
- Gönderim yanıtı linki bir kez gösterir. Ham token veritabanına, flash'a veya URL query/path'ine yazılmaz. URL fragment'i tarayıcı tarafından CSRF korumalı POST'a aktarılır ve geçmişten temizlenir.
- Alıcı görünümü için token şifreli cookie oturumunda tutulur. İmza formu ayrıca kendi token'ını gönderir; farklı sekmelerdeki belgeler karışmaz.
- Documents::Manage sahipliği sınırlar. Documents::Signing, SignatureAcceptance ile açık kabulü ve girilen adı doğrular. Document.sign! adı ve imza zamanını aynı kilitli işlemde saklar.
- Son tarih denetimi ve signed_at aynı Time.current örneğini kullanır. Gönderilmiş belge içeriği ve imza metaverisi normal model güncellemeleriyle değiştirilemez.
- Son tarih sınırında erişim reddedilir. Documents::Expiration erişilen kapsamı kalıcı günceller; documents:expire tüm belgeler için ayrıca çalışır. Otomatik zamanlayıcı kurulmamıştır.
- CSRF, otomatik ERB escaping, token log filtreleme ve no-store korunur. Referrer-Policy, aşağıda açıklanan sonraki düzeltmeyle same-origin yapılmıştır. Gerçek elektronik imza ve doğrulanmış kimlik iddiası yoktur.

### Sonraki CSRF düzeltmesi

Manuel testte normal HTML gönderiminde Origin: null hatası görüldü. İlk uygulamadaki global no-referrer meta etiketi ve alıcı controller'ındaki no-referrer başlığı buna neden olabiliyordu. İkisi kaldırıldı; config/application.rb üzerinden tek bir same-origin başlığı tanımlandı. CSRF ve origin kontrolü açık bırakıldı. Aşağıdaki 49 test sonucu ikinci aşamanın tarihsel sonucudur; yeni regresyonlar test/integration/csrf_origin_test.rb dosyasındadır.

Düzeltme sonrası `bundle exec rails test`: 57 test, 479 doğrulama, 0 başarısızlık, 0 hata, 0 atlanan. `bundle exec rubocop`: 50 dosya, ihlal yok. Yeni testler gerçek form token'ları ve Origin başlıklarıyla iki yerel host üzerinde tam akışı; null/farklı origin, eksik token, Turbo tarzı CSRF header ve cookie host ayrımını kapsar. Gerçek tarayıcı bağlantısı yine bulunamadı; integration testleri tarayıcının Referrer-Policy'yi uygulama davranışını çalıştırmış sayılmaz.

## Rotalar

| Yöntem | Yol | Ekran/işlem |
| --- | --- | --- |
| GET | / | Ana sayfa |
| GET | /registration/new | Kayıt |
| POST | /registration | Hesap oluşturma |
| GET | /session/new | Giriş |
| POST | /session | Oturum açma |
| GET | /session | Mevcut oturumun sınırlı JSON bilgisi |
| DELETE | /session | Çıkış |
| GET | /dashboard | Durum sayaçları ve son belgeler |
| GET | /documents | Sözleşmeler ve durum filtresi |
| GET | /documents/new | Yeni taslak |
| POST | /documents | Taslak kaydetme |
| GET | /documents/:id | Belge detayı |
| GET | /documents/:id/edit | Taslak düzenleme |
| PATCH/PUT | /documents/:id | Taslak güncelleme |
| POST | /documents/:id/send_for_signature | Pending geçişi ve tek seferlik link |
| GET | /sign | Link aktarımı veya alıcı sözleşmesi |
| POST | /sign/access | Token'ı doğrulama ve alıcı oturumuna aktarma |
| POST | /sign | Açık kabul ve demo imza |
| GET | /sign/complete | Onay ekranı |
| GET | /up | Mevcut sağlık kontrolü |

## Gerçek doğrulama sonuçları

| Komut/kontrol | Sonuç |
| --- | --- |
| bundle exec rails db:migrate | Başarılı; signer_name migration uygulandı. |
| bundle exec rails db:prepare RAILS_ENV=test | Başarılı; test migration uygulandı. |
| bundle exec rails test | Son başarılı çalışma: 49 test, 303 doğrulama, 0 başarısızlık, 0 hata, 0 atlanan. |
| bundle exec rails zeitwerk | Çıkış 1: tanımsız komut. |
| bundle exec rails zeitwerk:check | Çıkış 0: All is good! |
| bundle exec rubocop | Çıkış 0: 49 dosya, ihlal yok. |
| bundle exec rails tailwindcss | Çıkış 1: tanımsız komut. |
| bundle exec rails tailwindcss:build | Çıkış 0: Tailwind 4.3.3 derlemesi tamamlandı. Test komutu da CSS'yi yeniden derledi. |
| bundle exec rails documents:expire | Çıkış 0: Expired document sweep completed. |
| bundle exec brakeman --no-pager | Çıkış 0; raporda 0 hata, 0 güvenlik uyarısı. Windows/Ruby iç istisna mesajları ayrıca görüldü. |
| node --check (iki yeni Stimulus dosyası) | Çıkış 0; sözdizimi kontrolleri geçti. Bu kontrol tarayıcı çalıştırma testi değildir. |
| Canlı HTTP: /, /session/new, /registration/new, /sign | Yeniden başlatılan localhost:3000 sunucusunda dördü de 200 ve SignFlow içeriği döndürdü. |
| Görsel/gerçek tarayıcı kontrolü | Yapılamadı. Browser bağlantısı kullanılabilir tarayıcı bulamadı; tarayıcı listesi boş döndü. |

İlk test girişimi bekleyen test migration nedeniyle durdu; test DB hazırlandı. Sonraki çalışmada iki zaman testi, belge deadline'ından önce 12 saatlik cookie oturumu sona erdiği için başarısız oldu. Test deadline'ları bir saat ileriye alınarak oturum süresi ile belge süre kuralı ayrı doğrulandı. Başarılı sonuçlar bu düzeltmelerden sonraki çalışmalara aittir.

Test kapsamı: kayıt/giriş, taslak oluşturma/düzenleme, gönderim ve hash saklama, ayrı alıcı oturumu, açık kabul ve ad, signed doğrulaması, token tekrar kullanımı, son tarih, kalıcı expiration, geçersiz geçişler, sahiplik, yanlış belge ID'si, XSS escaping, açık CSRF korumasıyla akış ve eksik CSRF reddi, token log filtreleme, iki linkin aynı tarayıcıda açılması.

## Windows ve kalan sınırlar

- Eski sunucu bcrypt eklenmeden önce açıldığı için ilk canlı kayıt isteği LoadError verdi. rails restart sonrasında Windows/Puma otomatik yeniden açılmadı; sunucu bundle exec rails server -b 127.0.0.1 -p 3000 ile gizli arka plan PowerShell sürecinde yeniden başlatıldı ve canlı istekler başarılı oldu.
- Ruby/VIPS isteğe bağlı HEIF, JXL, Magick, OpenSlide ve Poppler DLL uyarıları devam ediyor; model/HTTP testleri ve CSS derlemesini engellemedi.
- Brakeman Ractor/fork/forwardable kaynaklı Windows/Ruby mesajları yazdı, ancak raporu 0 hata ve 0 uyarıyla tamamladı. Bu statik rapor üretim güvenliği garantisi değildir.
- JavaScript bağlantı aktarımı ve clipboard davranışı gerçek tarayıcıda doğrulanamadı; HTTP akışı ve JS sözdizimi doğrulandı. Responsive tasarımın ekran görüntüsüyle görsel QA'sı yapılmadı.
- Otomatik süre sonu zamanlayıcısı yoktur. İstek almayan belgeler manuel sweep'e kadar pending kalabilir; süre kontrolü yine imzayı engeller.
- Link kaybedilirse yeniden gösterilmez/yenilenmez; yeni taslak gerekir. JavaScript gereklidir.
- PDF, gerçek e-posta, gelişmiş şablon, AI, deploy, parola sıfırlama, e-posta doğrulama ve gerçek kimlik doğrulama yoktur. Giriş limiti süreç başına bellektedir; cookie oturumlarının tek tek sunucu iptali yoktur.

## Yerel deneme

PowerShell çalıştırma komutları ve adım adım elle deneme [README.md](../README.md) içinde bulunur. http://localhost:3000 adresinden kayıt olun, giriş yapın, belgeyi oluşturup gönderin, linki başka tarayıcıda açıp demo imzayı tamamlayın ve sahibin ekranını yenileyin. Başka bilgisayarda açmak için localhost adresi yeterli değildir; bu aşama yerel kullanımı hedefler.
