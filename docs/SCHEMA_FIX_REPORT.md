# template_version_id şema/önbellek düzeltmesi

14 Ekim 2026. Hata: şablon önizlemesinde `ActiveModel::MissingAttributeError: can't write unknown attribute template_version_id`.

## Neden ve kanıtlar

- Gerçek bağlantı: `C:/signflow/storage/development.sqlite3`.
- SQLite `PRAGMA table_info(documents)` içinde `template_version_id INTEGER` var; NOT NULL değil.
- `index_documents_on_template_version_id` mevcut. Foreign key `documents.template_version_id -> template_versions.id` mevcut.
- `20261014000400 CreateTemplates` dahil dört migration `up` durumda. db/schema.rb ve model ilişkisi aynı şemayla uyumlu.
- Document ilişkisi `belongs_to :template_version, optional: true`; TemplateVersion karşılığı has_many :documents. İlişki tanımını değiştirmek gerekmiyordu.
- Hata veren web sunucusu PID 17936, 18:48:29'da başladı. Şablon migration'ı bu süreç açıldıktan sonra uygulandı. 19:18:24'te aynı eski süreçte önizleme hatası loglandı.
- Temiz Rails runner aynı geliştirme DB'sinde fiziksel sütunu ve model sütununu gördü; aynı Documents::Manage#build_from_template çağrısıyla kaydedilmemiş belgeye kaynak sürümü başarıyla atadı.

Sorun eksik migration veya eksik fiziksel sütun değildi: migration öncesinde açılmış web sürecinde eski Document sütun metaverisi kalmıştı. Ayrı terminalde db:migrate veya test çalıştırmak bu süreci yenilememişti. Önceki aşamada migration sonrası çalışan sunucunun yeniden başlatılması eksik bırakılmıştı.

## Düzeltme

Eski sunucu durdurulup aynı proje/port ile temiz süreçte başlatıldı. Yeni migration eklenmedi; mevcut ilişki ve servis davranışı korundu. Her istekte sütun önbelleğini sıfırlayan veya kaynak ilişkisini atlayan bir geçici çözüm eklenmedi. Güvenlik ayarları, CSRF/origin doğrulaması ve same-origin politikası değiştirilmedi.

Veri silen veya şema yeniden yükleyen işlem kullanılmadı. Önce/sonra tüm satırların SHA-256 özeti karşılaştırıldı: users 1, documents 1, templates 3, template_versions 3; dört tablonun tüm satır içerikleri aynı kaldı.

## Dosyalar

| Dosya | İşlem |
| --- | --- |
| [script/check_template_schema.rb](../script/check_template_schema.rb) | Yeni: veri değiştirmeyen gerçek şema/model/ilişki tanılaması; kayıtsız nesne atamasını kontrol eder. Ayrı süreçte çalışır, web sürecini yenilemez. |
| [test/integration/template_schema_regression_test.rb](../test/integration/template_schema_regression_test.rb) | Yeni: SQLite kataloğu, nullable/index/FK, önizlemede kayıt oluşmaması, kaynak sürümünün SQL'den okunması, açık CSRF/Origin ile signed akışı ve şablonsuz belge uyumluluğu. |
| [README.md](../README.md) | Migration sonrası tam sunucu restart'ı, veri silmeden tanılama komutları ve test açıklaması. |
| [AGENT.md](../AGENT.md) | Migration/çalışan süreç uyumu ve geçici cache hack'lerini kullanmama kuralı. |
| [docs/SCHEMA_FIX_REPORT.md](SCHEMA_FIX_REPORT.md) | Bu rapor. |

## Gerçek komut sonuçları

| Komut | Sonuç |
| --- | --- |
| bundle exec rails db | Çıkış 0. Konsola yalnızca PRAGMA table_info / foreign_key_list sorguları ve .quit verildi. Sütun ve foreign key doğrulandı. |
| bundle exec rails db:migrate:status | Çıkış 0. Dört migration up. Uygulanmamış migration yok. |
| bundle exec rails runner script/check_template_schema.rb | Çıkış 0. Gerçek sütun, nullable/index/FK, model optional ilişkisi ve kayıtsız atama başarılı. |
| bundle exec rails test | Çıkış 0. **87 test, 819 doğrulama; 0 başarısızlık, 0 hata, 0 atlanan.** Önceki 84 test korundu; 3 regresyon eklendi. |
| bundle exec rails zeitwerk | Çıkış 1. Tanımsız komut; başarılı olarak değerlendirilmedi. |
| bundle exec rails zeitwerk:check | Çıkış 0. All is good! |
| bundle exec rubocop | Çıkış 0. 66 dosya, ihlal yok. |
| Canlı localhost:3000 ana sayfa | Yeniden başlatma sonrası HTTP 200; Referrer-Policy same-origin. |

Önizleme, taslak kaydı, imzaya gönderim, ayrı alıcı HTTP oturumu ve signed geçişi integration testinde tamamlandı. Önizleme boyunca dört tablo için kayıt sayısı değişmedi. Oluşturulan belgenin template_version_id değeri yeni SQL sorgusuyla doğrulandı. Şablonsuz belgenin null kaynakla görüntülenmesi ve imzalanması ayrıca geçti.

## Doğrulama sınırı ve yeniden deneme

Bu görevde gerçek tarayıcı üzerinden kullanıcı oturumuyla önizleme tekrar edilmedi. Testler gerçek SQLite test şeması üzerinde HTTP/integration testleridir; tanılama ayrıca gerçek geliştirme veritabanını salt okunur şekilde kontrol etti. Yeni test, yanlış gerçek şemayı ve servis ilişki atamasındaki hatayı yakalar; uzun süredir açık bir web sürecinin migration sonrası eski önbelleğini tek başına otomatik yenilemez. Bunun için migration sonrası sunucu yeniden başlatma adımı zorunludur.

Sunucu şu anda yeniden başlatılmış durumda. Açık şablon oluşturma sayfasını yenileyip Önizle → Taslak oluştur → İmzaya gönder → alıcı demo imzası adımlarını tekrar deneyin. Bundan sonraki şema değişikliklerinde sunucuyu Ctrl+C ile durdurun; db:migrate ardından bundle exec rails server -b 127.0.0.1 -p 3000 ile yeniden açın. Veritabanını sıfırlamayın.

Windows ortamındaki isteğe bağlı VIPS DLL uyarıları sürdü; kontrolleri engellemedi.
