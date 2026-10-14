# SignFlow — Üçüncü aşama raporu

14 Ekim 2026. Mevcut manuel sözleşme ve demo imza akışı korunarak kullanıcıya ait değişkenli şablonlar, sürüm geçmişi ve sunucu önizlemesi eklendi.

## Dosyalar

Başlangıçtaki kaynak dosyaları Git'te untracked durumundaydı; liste bu aşamadaki düzenleme kaydına dayanır. Repo yeniden oluşturulmadı, commit/push/deploy yapılmadı.

### Oluşturulan (22)

| Dosya | İşlev |
| --- | --- |
| [db/migrate/20261014000400_create_templates.rb](../db/migrate/20261014000400_create_templates.rb) | Şablon/sürüm tabloları, foreign key ve benzersizlik kısıtları; belge kaynak sürümü. |
| [app/models/template.rb](../app/models/template.rb) | Kullanıcı sahipliği ve güncel sürüm bağlantısı. |
| [app/models/template_version.rb](../app/models/template_version.rb) | Değiştirilemeyen başlık/açıklama/metin sürümü ve değişken listesi. |
| [app/models/template_revision.rb](../app/models/template_revision.rb) | Şablon düzenleme formu. |
| [app/models/concerns/template_text.rb](../app/models/concerns/template_text.rb) | Ortak metin/sözdizimi doğrulamaları. |
| [app/services/templates/renderer.rb](../app/services/templates/renderer.rb) | İzinli alan algılama, sıkı değer doğrulaması ve tek geçişli düz metin değiştirme. |
| [app/services/templates/manage.rb](../app/services/templates/manage.rb) | Kullanıcı kapsamlı liste/arama ve transaction içinde sürüm oluşturma. |
| [app/services/templates/demo_seeder.rb](../app/services/templates/demo_seeder.rb) | Kullanıcı başına üç idempotent ders örneği. |
| [app/controllers/templates_controller.rb](../app/controllers/templates_controller.rb) | Şablon sayfaları, geçmiş ve örnek ekleme HTTP işlemleri. |
| [app/controllers/template_documents_controller.rb](../app/controllers/template_documents_controller.rb) | Seçili sürümden önizleme ve taslak oluşturma. |
| [app/views/templates/index.html.erb](../app/views/templates/index.html.erb) | Liste, arama ve demo ekleme. |
| [app/views/templates/new.html.erb](../app/views/templates/new.html.erb) | Yeni şablon ekranı. |
| [app/views/templates/edit.html.erb](../app/views/templates/edit.html.erb) | Şablon düzenleme ekranı. |
| [app/views/templates/_form.html.erb](../app/views/templates/_form.html.erb) | Başlık, açıklama, metin ve izinli alan rehberi. |
| [app/views/templates/show.html.erb](../app/views/templates/show.html.erb) | Güncel/geçmiş sürüm detayı ve oluşturma bağlantısı. |
| [app/views/templates/history.html.erb](../app/views/templates/history.html.erb) | Sürüm geçmişi. |
| [app/views/template_documents/new.html.erb](../app/views/template_documents/new.html.erb) | Dinamik alanlar, sunucu önizlemesi ve taslak kaydı. |
| [test/models/template_test.rb](../test/models/template_test.rb) | Model, sürüm değişmezliği ve belge kaynak sahipliği testleri. |
| [test/services/template_renderer_test.rb](../test/services/template_renderer_test.rb) | Alan algılama, bozuk/eksik/fazla değer ve injection testleri. |
| [test/services/templates_manage_test.rb](../test/services/templates_manage_test.rb) | Sürüm, sahiplik, arama, snapshot ve seed testleri. |
| [test/integration/template_workflow_test.rb](../test/integration/template_workflow_test.rb) | Sayfalar, güvenlik, önizleme ve şablondan signed akışı. |
| [docs/PHASE3_REPORT.md](../docs/PHASE3_REPORT.md) | Bu rapor. |

### Düzenlenen (12)

| Dosya | Değişiklik |
| --- | --- |
| [app/models/user.rb](../app/models/user.rb) | Kullanıcıya ait şablon ilişkisi. |
| [app/models/document.rb](../app/models/document.rb) | İsteğe bağlı kaynak sürümü ve sahiplik/değişmezlik koruması. |
| [app/services/documents/manage.rb](../app/services/documents/manage.rb) | Güvenli sürümden bağımsız belge kopyası hazırlama. |
| [config/routes.rb](../config/routes.rb) | Şablon, geçmiş, demo, önizleme ve üretme rotaları. |
| [app/views/layouts/application.html.erb](../app/views/layouts/application.html.erb) | Şablon menüsü ve çalışma alanı başlığı. |
| [app/views/dashboard/show.html.erb](../app/views/dashboard/show.html.erb) | Şablondan oluştur düğmesi. |
| [app/views/documents/show.html.erb](../app/views/documents/show.html.erb) | Kaynak sürümü bağlantısı. |
| [db/seeds.rb](../db/seeds.rb) | Mevcut kullanıcılar için idempotent şablon seed çağrısı. |
| [db/schema.rb](../db/schema.rb) | Migration ile üretilen güncel şema. |
| [test/test_helper.rb](../test/test_helper.rb) | Şablon test yardımcısı. |
| [AGENT.md](../AGENT.md) | Üçüncü aşama mimarisi, güvenlik, seed ve CSRF kuralları. |
| [README.md](../README.md) | Kaynaklı kullanıcı problemi, çözüm ve şablon deneme adımları. |

Yerel geliştirme/test veritabanları migrate edildi; Git dışında tutulan Tailwind derleme çıktısı ve loglar güncellendi. Gemfile, oturum controller'ı, imzalama servisi, CSRF config'i ve mevcut test dosyaları değiştirilmedi; test_helper'a yalnızca yeni yardımcı eklendi.

## Mimari

- **Template:** kullanıcıya ait kimlik ve isteğe bağlı sabit demo seed anahtarı; güncel sürümü gösteren current_version_id.
- **TemplateVersion:** başlık, açıklama, metin ve v1/v2/v3 numarası. Kayıt sonrası readonly; sürüm update/destroy işlemi yoktur.
- **Templates::Manage:** bütün okumalar kullanıcının templates ilişkisiyle sınırlı. Güncelleme satır kilidi altında yeni sürüm ekler ve güncel pointer'ı aynı transaction içinde değiştirir. İlk oluşturma da tek transaction'dır.
- **TemplateRevision:** başlık/metin gerekliliği, uzunluklar ve şablon sözdiziminin form doğrulaması.
- **Templates::Renderer:** beş izinli değişkeni algılar; tekrar edenleri tek alan olarak sunar. Bozuk veya bilinmeyen yer tutucular ve eksik/boş/fazla/string olmayan değerler reddedilir. {{alan_adi}} ve çevresinde boşluk bulunan biçim desteklenir.
- **Documents::Manage#build_from_template:** seçilen sürümün kullanıcısını kontrol eder, doldurulmuş metni ve başlığı bağımsız belgeye kopyalar. Belge optional template_version_id ile kaynak sürümünü korur. Bu ilişki sonradan değiştirilemez.
- **Sürüm sabitleme:** form version_id taşır. Form açıkken şablon güncellense bile gönderilen bilgiler ilk seçilmiş sürüme uygulanır; eski sürüm de seçilebilir.
- **Önizleme:** sunucu renderer'ı kullanır, belge oluşturmaz. Kaydetme metni yeniden üretir; istemciden content kabul edilmez. Önizleme zorunlu değildir; kaydetme bütün doğrulamaları uygular.
- **Seed:** mevcut kullanıcılar için üç ders örneği. Kullanıcı başına seed_key benzersizdir. Tekrar çalıştırma mevcut/özelleştirilmiş örneği değiştirmez. Yeni hesapta örnekler Şablonlarım → Demo şablonları ekle ile alınabilir. Yeni kullanıcı/şifre yaratılmaz.

Manuel taslak oluşturma çalışır; kaynak sürümü boş olabilir. Oluşturulmuş taslak kullanıcı tarafından elle düzenlenebilir. Şablon düzenlemeleri mevcut taslak/pending/signed sözleşme metnini değiştirmez.

## Güvenlik

- Şablon ve sürüm ID'leri owner scope içinde çözülür; nested sürüm başka şablona aitse de reddedilir.
- Arama parametreli SQL kullanır, LIKE wildcard'ları escape edilir. Yalnızca güncel başlık/açıklama aranır.
- Ruby/ERB eval kullanılmaz. Yerine koyulan değerler tekrar parse edilmez. HTML ve ERB işaretleri düz metin olarak kalır; gösterimde otomatik ERB escaping uygulanır.
- İki farklı POST hedefi olan önizleme/kaydetme formu, Rails'in oturuma bağlı global authenticity token'ını taşır. Bu bir CSRF istisnası değildir; token ve origin doğrulaması açıktır.
- Önceki same-origin düzeltmesi, token fragment/POST aktarımı, hash saklama, tekrar kullanım reddi, deadline ve durum geçişleri korunur.
- Demo sözleşme metinleri gerçek hukuki kullanım için değildir; doğrulanmış kimlik veya nitelikli elektronik imza iddiası yoktur.

## Gerçek komut sonuçları

| Komut | Sonuç |
| --- | --- |
| bundle exec rails db:migrate | Çıkış 0; CreateTemplates migration uygulandı. |
| bundle exec rails db:prepare RAILS_ENV=test | Çıkış 0; test şeması hazırlandı. |
| bundle exec rails test | Çıkış 0; **84 test, 766 doğrulama, 0 başarısızlık, 0 hata, 0 atlanan**. |
| bundle exec rails zeitwerk:check | Çıkış 0; All is good! |
| bundle exec rubocop | Çıkış 0; 64 dosya, ihlal yok. |
| bundle exec rails tailwindcss:build | Çıkış 0; Tailwind 4.3.3 derlendi. |
| bundle exec rails db:seed | Çıkış 0; mevcut kullanıcılar için seed çalıştı. |
| Gerçek tarayıcı/görsel QA | Yapılamadı; Browser bağlantısı kullanılabilir tarayıcı bulamadı, tarayıcı listesi boş döndü. |

İlk test çalışmaları, test yardımcısındaki Ruby keyword/hash çağrısı ve bozuk üçlü parantez algılaması nedeniyle başarısız oldu; düzeltildi. Yeni HTTP testi ayrıca forma özel token'ın farklı preview action'ında geçerli olmadığını yakaladı; çok action'lı form için geçerli oturum token'ıyla düzeltildi. Yukarıdaki sonuçlar bu düzeltmelerden sonraki çalışmaya aittir.

Yeni testler: oluşturma/düzenleme, pozitif/benzersiz sürüm, eski sürümün update/destroy koruması, geçmişi görüntüleme, güncel sürümde arama, wildcard/injection girdileri, owner/version yetkilendirmesi, eksik/bozuk/fazla/nested değerler, XSS/ERB'nin çalışmaması, önizlemede kayıt oluşmaması, istemci content alanının dikkate alınmaması, sabit sürüm, seed idempotency ve özelleştirmeyi koruma. Açık CSRF ve Origin başlığıyla şablon → önizleme → belge → gönderim → ayrı alıcı oturumu → signed ve template güncellemesinin imzalı metni değiştirmemesi test edildi. Mevcut 57 test de aynı suite içinde geçti.

## Çalışan yeni rotalar

| Yöntem | Yol | İşlem |
| --- | --- | --- |
| GET | /templates | Şablonlarım, q ile başlık/açıklama araması |
| GET | /templates/new | Yeni şablon |
| POST | /templates | v1 oluşturma |
| GET | /templates/:id | Güncel sürüm; version_id ile geçmiş sürüm detayı |
| GET | /templates/:id/edit | Şablon düzenleme |
| PATCH/PUT | /templates/:id | Yeni sürüm oluşturma |
| GET | /templates/:id/history | Sürüm geçmişi |
| POST | /templates/add_examples | Eksik demo örneklerini kullanıcıya ekleme |
| GET | /templates/:template_id/documents/new | Seçili sürümün değişkenlerini doldurma |
| POST | /templates/:template_id/documents/preview | Kaydetmeden sunucu önizlemesi |
| POST | /templates/:template_id/documents | Bağımsız taslak oluşturma |

Mevcut /dashboard, /documents ve /sign rotaları çalışmaya devam eder.

## Tarayıcıdan elle deneme

1. Tek bir host seçerek http://localhost:3000 adresinden kayıt/giriş yapın. localhost ve 127.0.0.1 arasında oturum içinde geçiş yapmayın.
2. Şablonlarım ekranını açın. Üç demo yoksa Demo şablonları ekle düğmesine basın.
3. Yazılım Geliştirme Hizmet Sözleşmesi → Sözleşme oluştur yolunu izleyin.
4. Alıcı adı, hizmet, ücret, başlangıç ve bitiş tarihlerini doldurun. Alıcı e-postası ve gelecekte bir son imza tarihi ekleyin.
5. Önizle'ye basın; metni kontrol edip Sözleşme taslağını oluştur düğmesiyle kaydedin.
6. Detay ekranında kaynak sürümünü görün; İmzaya gönder ile linki kopyalayın.
7. Başka tarayıcı/gizli pencerede linki açın, metni kabul edip girilen adla demo imzayı tamamlayın. Sahibin sayfasını yenileyin; signed görünür.
8. Şablonu düzenleyip kaydedin; v2 oluşur. Sürüm geçmişinden v1'i açın; hem eski sürüm hem imzalı sözleşmenin eski metni korunur.
9. Şablon aramasını ve örnek eklemeyi tekrar deneyin; örnekler çoğalmaz, düzenlenmiş örneğin üzerine yazılmaz.
10. Yeni şablonda bilinmeyen {{bilinmeyen}} alanı veya üretimde boş alan deneyin; hata görünür, eksik belge kaydedilmez.

Bu adımlar kullanıcı içindir; gerçek tarayıcıda tarafımdan uygulanmış değildir. HTTP/integration testleri render edilen ekranları ve tüm iş akışını doğruladı.

## Kaynak ve sınırlar

Çıkış noktası olan Capterra değerlendirmesi, tarihi, bağlantısı ve çözüm karşılaştırması [README'nin ilgili bölümündedir](../README.md#gerçek-kullanıcı-problemi-ve-çözümümüz). Kaynakta şablonların ve arama akışının bakım maliyeti anlatılır. SignFlow, şablonu özgün üründe olmayan bir özellik olarak sunmaz; metin tabanlı ders demosunda daha sade ve merkezi akış hedefler.

PDF, gerçek e-posta, AI, ödeme ve deploy eklenmedi. İzinli beş alan dışında kullanıcı tanımlı alan tipleri, şablon silme, paylaşma, klasörleme, sürüm karşılaştırma veya PDF alan yerleşimi yoktur. Arama SQLite LIKE ile güncel başlık/açıklamada çalışır; gelişmiş tam metin araması yoktur. Gerçek tarayıcı/görsel kontrol yapılmadı. Önceki süre sonu zamanlayıcısı, link yenileme, oturum iptali ve kimlik doğrulama sınırları README'de geçerlidir.

Windows/Ruby ortamındaki isteğe bağlı VIPS DLL uyarıları devam etti; migration, test, seed ve derlemeyi engellemedi.
