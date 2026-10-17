# README araştırma ve doğrulama notu

Tarih: **17.10.2026** (Europe/Istanbul). Bu çalışma üniversite ödevi araştırması ve dokümantasyondur; uygulama, test veya güvenlik kodu değiştirilmedi. Render hesabında işlem, deploy, commit veya push yapılmadı. AGENT.md korunur. Temel Git commit'i ve kaynak dosyalarının hash'leri [ölçüm dökümündedir](RESEARCH_MEASUREMENTS.json).

## Kanıt sınıfları

- **Dış kaynak:** Sayı, kapsam ve ölçüm/rapor tarihi kaynakta aranır; erişim tarihi bunlardan ayrıdır.
- **Yerel ölçüm:** Fiziksel satır ve boş olmayan satır sayımı; gerçek API token ölçümü değildir.
- **Kullanıcı beyanı:** Codex/abonelik kullanımı, aktif süre, API faturası ve Render plan seçimi. Fatura veya Render dashboard'u incelenmedi.
- **Tahmin:** Kurumsal LOC dağılımı, token yoğunluğu, input oranı ve tekrar katsayısı. DocuSign iç verisi değildir.

## Kaynak kontrolü

Aşağıdaki tüm kontrollerin erişim tarihi 17.10.2026'dır. Tam URL bazlı son GET sonuçları [link kontrol dökümünde](RESEARCH_LINK_CHECK.json) bulunur. HTTP durum kodu içerik iddiasını tek başına doğrulamaz; aşağıdaki içerik incelemesi ayrıca yapılmıştır.

| Kaynak | İncelenen içerik | Sınır |
| --- | --- | --- |
| [ABD Fortune 500](https://fortune.com/ranking/fortune500/) | Güncel liste yılı ve gelir sıralaması | Erişilebilir görünüm bütün şirketlerin ölçülebilir alanlarını sağlamadı; tam veri edinilmedi. |
| [Fortune yayımlayıcı duyurusu](https://fortunemedia.mediaroom.com/2026-06-03-Amazon-Claims-No-1-Spot-on-the-Fortune-500) | Toplam istihdam, gelir eşiği, gelir lideri ve değer lideri açıklaması | Araştırma web aracı metni açtı; yerel Python doğrudan GET kontrolü 403 verdi. Bu fark gizlenmedi. |
| [BitGo](https://fortune.com/company/bitgo-holdings/), [Gold.com](https://fortune.com/company/a-mark-precious-metals/), [Nvidia](https://fortune.com/company/nvidia/) | README'deki tarihli örnek değerler ve ilgili çalışan alanları | Seçilmiş gözlemler; aynı tarihli tüm şirket minimum–maksimumu değil. Dinamik profiller güncellenebilir. |
| [Walmart yıllık rapor duyurusu](https://corporate.walmart.com/news/2026/04/23/walmart-releases-2026-annual-report-and-proxy-statement) | FY2026 küresel çalışan büyüklüğü | Örnek üst uç; bütün Fortune üyelerinin aynı kapsamlı veri denetimi yapılmadı. |
| [Zylo Index](https://zylo.com/2026-saas-management-index), [istatistik yazısı](https://zylo.com/blog/saas-statistics) | Ortalama/medyan portföy ve yıllık SaaS gideri ayrı ayrı karşılaştırıldı | Fortune 500 örneklemi değil; ikinci sayfa bağımsız ikinci araştırma değil. Form doldurulmadı, gizli/kapalı rapor edinilmedi. |
| [Why Docusign](https://www.docusign.com/why-docusign) | Fortune kullanım oranı beyanı | Sağlayıcının beyanı; bağımsız müşteri/ödeme denetimi değil. |
| [DocuSign vaka e-kitabı](https://www.docusign.com/sites/default/files/resource_event_files/personalized_sales_agreements_for_more_efficient_sales_cycles.pdf) | T-Mobile s. 4, Comcast s. 6, belge tarih kodu s. 7; PDF metni yerelde çıkarılarak okundu | Tarihsel süreç kullanımı; güncel ücretli abonelik tutarı veya 2026 müşteri devamlılığı çıkarılamaz. |
| [T-Mobile Fortune profili](https://fortune.com/company/t-mobile/) | Profil erişilebilir, güncel ABD satırı bulunamadı | Resmî 2026 üyelik/sıra kanıtı eksik. Üçüncü taraf yeniden sıralamalar kanıt diye geçirilmedi. |
| [Comcast Fortune profili](https://fortune.com/company/comcast/) | 2026 Fortune 500 kategorisi | Tamamlayıcı müşteri örneği; T-Mobile satırını doğrulamaz. |
| [Capterra](https://www.capterra.com/p/121506/Docusign/reviews/) | Talepteki yorumun başlığı, tarihi, Pros/Cons ve incentivized review etiketi arama indeksindeki Capterra metninde bulundu | Doğrudan GET 403; web açma aracı da erişemedi. Yorum ekran görüntüsü/permalink arşivlenmedi. README indeks doğrulamasını açıkça söyler. |
| [OpenAI GPT-5.4](https://developers.openai.com/api/docs/models/gpt-5.4) | Resmî model sayfası açıldı; input/output tarife ve uzun bağlam koşulu incelendi | Model yalnızca örnek API hesabıdır; gerçek Codex model/token kullanımı ölçülmedi. |
| [Render Free](https://render.com/docs/free) | Web uyku ve PostgreSQL sona erme/silinme politikası | Kullanıcının gerçek planı/DB başlangıç tarihi hesapta doğrulanmadı. |

## Yerel sayımın yeniden doğrulanması

[RESEARCH_MEASUREMENTS.json](RESEARCH_MEASUREMENTS.json), sayılan her dosyanın kategorisini, SHA-256 değerini, fiziksel/boş olmayan satırlarını ve toplamları içerir. Kaynak kapsamı git ls-files listesindeki çalışma ağacı dosyalarıdır; yalnızca commit'teki içerik okunmadı. docs/ ve README sayılmaz; bu araştırma dokümanlarının eklenmesi kaynak sayısını büyütmez.

Sayım mantığı:

```python
lines = path.read_text(encoding="utf-8").splitlines()
physical_lines = len(lines)
nonblank_lines = sum(bool(line.strip()) for line in lines)
```

Uzantılar ve özel dosya adları dökümde açıklanmıştır. app/assets/builds, vendor/public, binaries ve kurulu gem kodu hariçtir. db/schema.rb, db/cache_schema.rb, db/queue_schema.rb ve db/cable_schema.rb ayrı generated_schema kategorisidir. Diğer Rails iskelet dosyaları proje kaynağı kapsamında kalır; “hepsini öğrenci yazdı” sonucu çıkarılamaz. Sayım, parser tabanlı yorumdan arındırılmış SLOC değildir. JSON toplamları dosya kayıtları üzerinden ayrıca yeniden toplandı.

## Aritmetik kontrolü

README'deki modül tahminlerinin toplamı belirtilen ödev ölçeğini verir. API senaryosunda output = L × q, input = r × output, maliyet = input/1e6 × input_tarifesi + output/1e6 × output_tarifesi formülü kullanıldı; tekrar katsayısı bundan sonra uygulanır. Kaynak ölçümü ile token tahmini birbirine dönüştürülmüş gerçek kullanım diye sunulmaz. ChatGPT aboneliği API tarifesine göre faturalandırılmış kabul edilmez. Abonelik payı bilinmediği için gerçekleşmiş toplam maliyet çıkarılmadı.

## Doğrulanamayanlar ve teslim sınırı

- Tam kapsamlı Fortune çalışan/değerleme minimum–maksimumu; halka açık üyeler için ortak tarihli tam veri seti.
- T-Mobile'ın resmî 2026 ABD Fortune liste satırı ve sırası.
- T-Mobile/Comcast için ödeme makbuzu, lisans bedeli ve güncel sözleşme devamlılığı.
- DocuSign gerçek üretim LOC sayısı; API token kullanım dökümü; projeye düşen abonelik tutarı.
- Capterra yorumunun doğrudan sayfa görüntüsü/kalıcı tekil URL'si.
- Canlı uygulamada bu aşamada kayıt, JavaScript, imza veya TLS/browser kabul testi. Ana sayfaya salt okunur GET yapıldı; canlı veri eklenmedi.

README kontrol tablosunda bu noktalar tam kanıt olarak işaretlenmedi. “100 puanlık” ifade ödev kriteridir; verilmiş not değildir.

## Gerçek yerel kontrol sonuçları

Kontrol tarihi: 17.10.2026.

| İşlem | Sonuç |
| --- | --- |
| bundle exec rails test | Çıkış kodu 0; 92 test, 900 assertion, 0 failure, 0 error, 0 skip. Minitest çalışma süresi 29,538438 saniye; Ruby/asset başlangıç süresi bu rakama dahil değildir. |
| README yerel linkleri | 37 benzersiz hedef mevcut; doğrulama notundaki destek doküman linkleri de mevcut. |
| README dış linkleri | 19 benzersiz URL; 17 HTTP 200, 2 HTTP 403 (Capterra ve Fortune yayımlayıcı duyurusu). Fragment içeren PDF sayfa linkleri için HTTP hedefi fragment olmadan denetlendi. |
| Sayısal kontrol | Ölçüm JSON toplamları dosyalardan yeniden toplandı; LOC modül toplamı ve API maliyet aritmetiği doğrulandı. |
| Kaynak koruması | Ölçülen bütün kaynak dosyalarının SHA-256 değerleri değişmedi; AGENT.md başlangıç hash'i ile aynı. |
| git diff --check | Başarılı; whitespace hatası yok. |

Test sırasında Windows libvips opsiyonel DLL uyarıları görüldü; test komutu başarılı tamamlandı. Bu aşamada RuboCop, Zeitwerk, production migration, tarayıcı sistem testi veya uzaktaki Actions yeniden çalıştırılmadı; bunlar için başarı iddiası yoktur. Test ortamı SQLite kullanır; development veritabanını değiştiren migration/seed/reset komutu çalıştırılmadı.

Değişen dosyalar: README.md; yeni destek dosyaları docs/RESEARCH_MEASUREMENTS.json, docs/RESEARCH_LINK_CHECK.json ve bu doğrulama notudur. PDF araştırma kopyası yalnızca gitignored tmp altındadır; kaynak belgenin tam metni repoya eklenmedi. Araştırma notları kısa özetlerdir; uzun yorum veya makale kopyası içermez.
