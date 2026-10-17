# SignFlow

[![CI](https://github.com/Huseyinyagmur/signflow/actions/workflows/ci.yml/badge.svg?branch=main&event=push)](https://github.com/Huseyinyagmur/signflow/actions/workflows/ci.yml)

**Canlı uygulama:** [signflow-k2tg.onrender.com](https://signflow-k2tg.onrender.com/) · **GitHub:** [Huseyinyagmur/signflow](https://github.com/Huseyinyagmur/signflow)

Ruby 3.4.11 / Rails 8.1.4, ERB, Hotwire (Turbo/Stimulus), Tailwind CSS ve Minitest ile geliştirilmiş üniversite projesi. Development/test SQLite, production PostgreSQL kullanır ([Gemfile](Gemfile), [veritabanı ayarı](config/database.yml); inceleme: 17.10.2026). Kullanıcı sözleşme oluşturur, güvenli bağlantıyı paylaşır ve alıcının demo imzasını takip eder. Nitelikli elektronik imza veya doğrulanmış kimlik iddiası yoktur. İlham kaynağı DocuSign yalnızca bu README'nin araştırma bağlamında anılır; uygulama markası SignFlow'dur.

**Teslim durumu (17.10.2026):** Yukarıdaki canlı ana sayfa HTTP GET ile 200 döndürdü ve SignFlow metni içerdi. Bu kontrol kayıt/imza akışının tarayıcı testi değildir. Free web ve Free PostgreSQL seçimi kullanıcı beyanıdır; Render hesabı veya faturası incelenmedi. Önceki production hazırlığı raporundaki “deploy yapılmadı” ifadesi o çalışmanın tarihsel sonucudur; bu README aşamasında da deploy veya push yapılmadı.

## Ödev Özeti

| Başlık | Hızlı erişim / sonuç |
| --- | --- |
| Canlı uygulama / kaynak / CI | [Canlı SignFlow](https://signflow-k2tg.onrender.com/) · [GitHub](https://github.com/Huseyinyagmur/signflow) · [Actions ve üstteki CI rozeti](https://github.com/Huseyinyagmur/signflow/actions/workflows/ci.yml) |
| Fortune 500 müşteri kanıtı | Birincil örnek **Comcast Business**: [resmî müşteri vaka çalışması](https://www.docusign.com/sites/default/files/resource_event_files/docusign_case_study-comcast__2.pdf) + [Comcast Fortune profili](https://fortune.com/company/comcast/). Ticari kullanım güçlü; doğrudan ödeme/fatura kanıtı yok. |
| Aort dilimi | [Kayıt → giriş → taslak → gönder → güvenli link → demo imza → signed](#aort-dilimi--çalışan-ana-iş-akışı); durum ve zaman kuralları gerçek dosyalarla bağlantılı. |
| Canlı manuel doğrulama | [Kullanıcı beyanı, 17.10.2026](#canlı-render-manuel-kabul-testleri--kullanıcı-beyanı): oturum 5/5, normal sözleşme 6/6, şablon 8/8; restart sonrası kalıcılık başarılı. Codex otomasyonu değil. |
| Süre / maliyet | [Bildirilen süre ve maliyet](#gerçek-geliştirme-ve-barındırma-maliyeti): yaklaşık 1–2 saat, ayrı API faturası 0 $; abonelik payı bilinmiyor. [İş günü tahmini](#gün-bazlı-geliştirme-süresi--mühendislik-tahmini) ve [varsayımsal API hesabı](#coding-agent-için-varsayımsal-api-maliyeti) ayrı modellerdir. |
| Kullanıcı acısı / çözüm | [17.08.2026 tarihli Capterra yorumu ve çözüm](#gerçek-kullanıcı-problemi-ve-çözümümüz): tekrar eden metin şablonları, önizleme ve sürüm geçmişi; PDF koordinatlama çözümü değildir. Doğrudan kaynak erişim sınırı aşağıda belirtilir. |
| Eksikler / puan kriterleri | [Yapamadıklarım](#yapamadıklarım) · [0/85/100 teslim eşlemesi](#085100-kısa-teslim-eşlemesi) · [AGENT.md](AGENT.md). Bunlar kesin not iddiası değildir. |

## Render production kurulumu

Development/test SQLite, production PostgreSQL kullanır. Native Ruby build komutu
`bash bin/render-build.sh`, start komutu `bash bin/render-start.sh`, health yolu `/up`.
Build asset/Tailwind derler; start migration sonrası Puma başlatır. Gerekli gizli değişkenler:
`DATABASE_URL`, `RAILS_MASTER_KEY`. Plan seçimi, environment, manuel deploy, migration ve
sorun giderme adımları: [Render rehberi](docs/RENDER_DEPLOYMENT.md).
Otomatik kaynak oluşturan render.yaml yoktur. Rehberde kalıcılık için önerilen ücretli PostgreSQL ile kullanıcının ödev demosunda seçtiğini bildirdiği süreli Free PostgreSQL birbirinden farklıdır; ücretsiz veritabanı süresiz saklama garantisi değildir.

## Araştırma yöntemi ve kanıt sınırı

Araştırma/erişim tarihi **17.10.2026**; kapsam **2026 ABD Fortune 500**. Global 500 ve Europe 500 verileri bu listeye karıştırılmaz. Dış veriler kaynaklarıyla, yerel sayımlar ölçüm etiketiyle, kullanıcı bilgileri beyan etiketiyle, varsayımlar tahmin etiketiyle gösterilir. Erişim tarihi, finansal verinin ölçüm tarihi değildir. Dinamik şirket profilleri sonradan değişebilir. Doğrudan erişilemeyen veya tüm listeyi kapsamayan kanıttan kesin minimum çıkarılmaz; eksikler [teslim kontrol tablosunda](#ödev-teslim-kontrol-tablosu) açık kalır.

## Faz 1 — Fortune 500 genel araştırması

### A. Şirket değeri ile yıllık gelir

Fortune 500, şirketleri **yıllık gelire göre** sıralar. Piyasa değeri ise halka açık şirketin hisse fiyatı × dolaşımdaki hisse sayısıdır; yıllık satış tutarı veya enterprise value ile aynı ölçü değildir. ABD listesi ve dönem tanımı için [Fortune sıralaması](https://fortune.com/ranking/fortune500/) (2026; erişim: 17.10.2026).

Fortune'un yayımlayıcı duyurusunda listeye giriş gelir eşiği **7,5 milyar $**, gelir lideri Amazon'un geliri **700 milyar $ üzeri** olarak verilir; bunlar değerleme aralığı değildir ([Fortune, 03.06.2026 duyurusu](https://fortunemedia.mediaroom.com/2026-06-03-Amazon-Claims-No-1-Spot-on-the-Fortune-500); 2026 listesi, ilgili mali yıllar; erişim: 17.10.2026).

**Tüm liste için kesin minimum–maksimum piyasa değeri hesaplanamadı.** Özel şirketlerin borsa piyasa değeri yoktur; kamuya açıklanmayan özel değerlemeler hisse senedi market cap'i yerine kullanılamaz. Aynı gün için bütün halka açık üyelerin verileri de bu çalışmada elde edilmedi. Aşağıdaki seçilmiş örnekler aynı tarihli bir tam-listeden türetilmiş aralık değildir:

| Halka açık örnek | Piyasa değeri | Değer tarihi / kaynak / erişim |
| --- | ---: | --- |
| BitGo Holdings | 950 milyon $ | 31.03.2026; [Fortune profili](https://fortune.com/company/bitgo-holdings/); 17.10.2026 |
| Gold.com | 1,128 milyar $ | 31.03.2026; [Fortune profili](https://fortune.com/company/a-mark-precious-metals/); 17.10.2026 |
| Nvidia | 5,44539 trilyon $ | 24.09.2026; [Fortune profili](https://fortune.com/company/nvidia/); 17.10.2026 |

Fortune'un liste yayımlama duyurusu Nvidia'yı o dönemin en değerli üyesi olarak tanımlar ([03.06.2026 duyurusu](https://fortunemedia.mediaroom.com/2026-06-03-Amazon-Claims-No-1-Spot-on-the-Fortune-500); erişim: 17.10.2026). Yukarıdaki daha sonraki Nvidia gözlemi liste yayımlanma gününün maksimumu olarak sunulmaz. Tablodaki küçük örnek de listenin minimumu değildir.

**Açık kapsamlı örnek aralığı:** Tablodaki üç gözlemin sayısal alt/üst ucu **950 milyon–5,44539 trilyon $**'dır; farklı tarihlerden seçilmiş gözlemlerin zarfıdır, aynı günün Fortune 500 piyasa değeri aralığı değildir. Aynı gün karşılaştırılabilen **31.03.2026 tarihli BitGo–Gold.com alt kümesi** yalnızca **950 milyon–1,128 milyar $** aralığını verir (kapsam: bu iki şirket; kaynaklar yukarıdaki profil satırları, erişim: 17.10.2026). Özel şirketler bu hesaba katılmaz.

**Daha kapsamlı veri kaynağı:** [Fortune Analytics 2026 veri ürünü](https://fortune.com/analytics/fortune-500), piyasa değeri ve çalışan alanlarını içeren resmî tam listeyi sunar (erişim: 17.10.2026). Ücretli veri edinilmedi. Bu nedenle bütün üyeler üzerinden istatistik hesaplanmadı; satın alınmayan veri incelenmiş gibi gösterilmez. İleride erişilirse boş/özel şirket alanları, değer tarihleri ve çalışan tanımları denetlenerek gözlem sayısı ile birlikte yeniden hesaplanmalı.

### B. Çalışan sayısı

ABD Fortune 500 üyelerinin dünya çapındaki toplam istihdamı **30,5 milyon kişi** olarak bildirilmiştir; yalnızca ABD'deki çalışanlar değildir ([Fortune, 03.06.2026 duyurusu](https://fortunemedia.mediaroom.com/2026-06-03-Amazon-Claims-No-1-Spot-on-the-Fortune-500); 2026 listesi, şirketlerin rapor dönemleri; erişim: 17.10.2026).

| Şirket bazında doğrulanan örnek | Çalışan | Dönem / kaynak / erişim |
| --- | ---: | --- |
| BitGo Holdings | 603 | 2026 liste profili, güncelleme 03.06.2026; [Fortune](https://fortune.com/company/bitgo-holdings/); 17.10.2026 |
| Gold.com | 975 | 30.06.2025'te biten mali yıl; [Fortune](https://fortune.com/company/a-mark-precious-metals/); 17.10.2026 |
| Walmart | Yaklaşık 2.100.000 | FY2026 sonu; [şirketin 23.04.2026 yıllık rapor duyurusu](https://corporate.walmart.com/news/2026/04/23/walmart-releases-2026-annual-report-and-proxy-statement); 17.10.2026 |

Bu gözlemlerde alt uç BitGo, üst uç Walmart'tır; **bütün Fortune 500 için kesin çalışan minimumu veya maksimumu hesaplanmadı**. Şirketlerin rapor tarihleri ve part-time/FTE tanımları farklı olabilir. Küçük örnekten genel minimum iddiası çıkarılmaz. Kesin sonuç için bütün üyelerin aynı kapsamlı çalışan alanları gerekir; erişilebilir resmî sıralama ve seçilmiş profiller bu veri setini sağlamadı.

Bu bölümün **üç şirketlik örnek aralığı 603–yaklaşık 2.100.000 çalışan**dır (kapsam ve dönem: yukarıdaki üç satır; erişim: 17.10.2026). Bu aralık liste toplamı değildir; toplam istihdam ayrı paragrafta verilmiştir. Resmî tam veri için yukarıdaki Fortune Analytics kaynağı bulunmuştur, fakat veri erişimi olmadığı için genel minimum/maksimum açık kalır.

### C–D. SaaS uygulama sayısı ve yıllık SaaS harcaması

| Metrik | Ortalama | Medyan | Dönem / kaynak / erişim |
| --- | ---: | ---: | --- |
| SaaS portföyü | 305 uygulama | 240 uygulama | [Zylo 2026 SaaS Management Index](https://zylo.com/2026-saas-management-index); 17.10.2026 |
| Yıllık SaaS harcaması | 55,7 milyon $ | 20,6 milyon $ | [Zylo 2026 SaaS Management Index](https://zylo.com/2026-saas-management-index); 17.10.2026 |

**Bunlar Zylo örnekleminin ölçüleridir; Fortune 500 kesin ortalaması/medyanı değildir.** SaaS yönetimi sağlayıcısının gözlemlediği kurumlar tüm işletmeleri temsil eden rastgele örneklem kabul edilemez; Fortune 500'e ait ayrı kırılım doğrulanmadı. Ortalama büyük gözlemlerden etkilenir, medyan ortadaki gözlemi temsil eder; birbirinin yerine kullanılmaz. Kurum ölçeği, lisans sayısı, ürün karması ve tüketim ücretleri gideri değiştirir. Bu ölçüler bütün IT bütçesi, donanım veya toplam personel gideri değildir. [Zylo'nun tamamlayıcı istatistik yazısı](https://zylo.com/blog/saas-statistics) da aynı rapora atıf yapar; bağımsız ikinci örneklem değildir (erişim: 17.10.2026).

## Seçilen SaaS — DocuSign ve kurumsal kullanım kanıtı

Ürün sağlayıcısı Fortune 500 üyelerinin yaklaşık **%95'inin** DocuSign kullandığını belirtir ([Why Docusign](https://www.docusign.com/why-docusign); sayfanın erişilen sürümü: 17.10.2026). Bu, sağlayıcının pazarlama beyanıdır; bağımsız müşteri denetimi, tüm üyeler için ödeme makbuzu veya özellikle bu yılın üyelerinin tek tek doğrulanması değildir.

### Birincil örnek — Comcast Business

**Comcast'ın 2026 ABD Fortune 500 üyeliği** [Fortune profilinin ilgili liste bölümünde](https://fortune.com/company/comcast/) görülür (erişim: 17.10.2026). Comcast Business bu şirketin iş birimidir; ayrı bir Fortune şirketi olarak sayılmaz.

[DocuSign'ın resmî Comcast müşteri vaka çalışması](https://www.docusign.com/sites/default/files/resource_event_files/docusign_case_study-comcast__2.pdf#page=1), alternatifler değerlendirildikten sonra Agreement Cloud platformunun seçildiğini, satış araçlarıyla entegre edildiğini ve saha temsilcilerinin tablet üzerinde sözleşme hazırlayıp imzalattığını açıklar. Devam sayfasında müşteri yöneticisi Terry Connell'in kullanım anlatımı bulunur (s. 1–2; erişim: 17.10.2026; PDF'de açık yayın tarihi tespit edilmedi). Bu, yalnızca bir logo değil, sağlayıcının yayımladığı somut kurumsal kullanım vakasıdır. PDF'nin erişildiği yıl, ilk uygulama veya müşteri sözleşmesi tarihi sayılmaz.

**Ücretli kullanım kriterinin kanıt sınırı:** Resmî müşteri vakası, ticari bir ürünün gerçek iş sürecinde kullanıldığına güçlü kanıttır; kamuya açık lisans sözleşmesi, fiyat, fatura veya ödeme kaydı değildir. Ücretli aboneliğin doğrudan belgesi bulunmadığından “ödeme kesin kanıtlandı” denmez. Ödev doğrudan ödeme belgesi arıyorsa bu alt kriter açık kalır; ticari kullanım kanıtı ile ödeme kanıtı ayrı değerlendirilmelidir.

### Korunan ek örnek — T-Mobile

**T-Mobile vaka kanıtı:** [Personalized Sales Agreements for More Efficient Sales Cycles](https://www.docusign.com/sites/default/files/resource_event_files/personalized_sales_agreements_for_more_efficient_sales_cycles.pdf#page=4) e-kitabının T-Mobile sayfası, mağazalarda kredi/kiralama belgelerinin cihaz üzerinde hazırlanıp imzalandığı dijital süreci anlatır (s. 4; belge tarih kodu 10.08.2020, erişim: 17.10.2026). Bu, yalnızca logo kullanımından daha güçlü bir gerçek iş süreci/müşteri ilişkisi kanıtıdır; güncel ücretli abonelik tutarını veya sözleşme bedelini kanıtlamaz. T-Mobile'a ait açıklanmamış lisans ücreti yazılmamıştır.

**Fortune üyeliği kanıtındaki eksik:** Erişilen [T-Mobile Fortune profili](https://fortune.com/company/t-mobile/) bu araştırmada güncel ABD liste satırını göstermedi. [2026 ABD listesi](https://fortune.com/ranking/fortune500/) üyelik kontrolünün asıl kaynağıdır; T-Mobile'ın o yılki resmî satırı ve sırası doğrulanamadı (erişim: 17.10.2026). İnternetteki üçüncü taraf yeniden listeler resmî yıl kanıtı sayılmadı. Dolayısıyla “T-Mobile'ın 2026 üyeliği doğrulandı” denmiyor; teslim öncesi resmî satır/sayfa kanıtı eklenmesi gerekir.

Önceki kaynak da korunur: [DocuSign e-kitabının Comcast Business vakası](https://www.docusign.com/sites/default/files/resource_event_files/personalized_sales_agreements_for_more_efficient_sales_cycles.pdf#page=6) aynı saha satış sürecini anlatır (s. 6; 2020 belge sürümü, erişim: 17.10.2026). Birincil Fortune müşteri örneği artık yukarıdaki Comcast vaka çalışmasıdır. Bu seçim T-Mobile'ın eksik yıl kanıtını doğrulamaz. Her iki müşteri için de kamuya açık ödeme tutarı doğrulanmadı.

## Faz 2 — Kod büyüklüğü ve maliyet tahmini

### Kurumsal ürün için modül bazlı varsayım

DocuSign'ın üretim kaynak koduna veya doğrulanmış LOC envanterine erişilmedi. **300.000 satır**, kullanıcı tarafından aktarılan ödev ölçeğine oturtulmuş planlama varsayımıdır; doğrulanmış DocuSign satır sayısı değildir. Aşağıdaki dağılım dış ölçüm değil, bu ödev için hazırlanmış mühendislik tahminidir (tahmin tarihi: 17.10.2026):

| Modül | Tahmini satır |
| --- | ---: |
| Kimlik ve yetkilendirme | 20.000 |
| Belge yönetimi | 30.000 |
| İmzalama motoru | 40.000 |
| İş akışları | 30.000 |
| Şablon yönetimi | 20.000 |
| API ve entegrasyonlar | 35.000 |
| Audit logging | 20.000 |
| Güvenlik ve uyumluluk | 35.000 |
| Yönetim ve raporlama | 20.000 |
| Test ve altyapı | 50.000 |
| **Toplam — tahmin** | **300.000** |

Kaynak/etiket: ödev için varsayımsal modül modeli, 17.10.2026; satırlar tedarikçi verisi değildir. Dil/framework, tekrar kullanım ve üretilen kod sonucu değiştirir; LOC kalite, güvenlik veya iş değeri ölçüsü değildir.

### SignFlow gerçek satır ölçümü

**Ölçüm: 17.10.2026**, mevcut çalışma ağacı; temel commit ve dosya SHA-256 değerleri [ölçüm dökümünde](docs/RESEARCH_MEASUREMENTS.json) kayıtlıdır. `git ls-files` ile izlenen UTF-8 kaynaklar Python `splitlines()` ile sayıldı. Fiziksel satır boş satırları/yorumları içerir; boş olmayan satır yorumları içerir, parser tabanlı SLOC değildir. Uzun tek satır ERB/CSS ifadeleri tek satır sayılır. Rails iskeletinden kalan proje dosyaları da sayılır; bu bir özgün yazarlık hesabı değildir.

| Kapsam | Dosya | Fiziksel satır | Boş olmayan satır |
| --- | ---: | ---: | ---: |
| Uygulama: app/, derlenmiş assets hariç | 62 | 1.177 | 1.045 |
| Testler: test/ | 15 | 1.463 | 1.337 |
| Altyapı: config/db migration/lib/bin/script/CI ve kök build dosyaları | 54 | 1.431 | 1.188 |
| **Kaynak toplamı; üretilen şemalar hariç** | **131** | **4.071** | **3.570** |
| Üretilen DB şemaları; ayrı kategori | 4 | 255 | 237 |

Tablonun tüm sayıları [yerel ölçüm dökümünden](docs/RESEARCH_MEASUREMENTS.json) gelir (17.10.2026). Uzantı ve dosya bazlı kapsam/hash/sayılar aynı dosyadadır. README, AGENT, docs, lock dosyaları, vendor/public, derlenmiş assets, binaries, .git, tmp/log/storage ve kurulu gem kaynakları kaynak toplamına dahil değildir. Bağımlılık kaynak kodu ölçülmedi; **Gemfile.lock'un 400 fiziksel satırı** bağımlılık kodu değil kilit metadatasıdır ([ölçüm](docs/RESEARCH_MEASUREMENTS.json), 17.10.2026). Uygulama ile testler ayrıdır; bu küçük prototip varsayımsal kurumsal ürünle eşdeğer değildir.

### Coding agent için varsayımsal API maliyeti

Bu hesap gerçekleşmiş Codex kullanımı veya kullanılan modelin tespiti değildir. Örnek model **GPT-5.4** için standart kısa bağlam fiyatı **1 milyon input token başına 2,50 $**, **1 milyon output token başına 15,00 $** alınmıştır ([resmî OpenAI model/fiyat sayfası](https://developers.openai.com/api/docs/models/gpt-5.4); erişim: 17.10.2026). Cache indirimi, Batch indirimi veya uzun bağlam fiyatı varsayılmadı; her isteğin standart kısa bağlam eşiğinde kaldığı varsayılır.

Ödev ölçeği için tahmin varsayımları (bu README'nin modeli, 17.10.2026):

- L = 300.000 satır; output yoğunluğu q = 20 token/satır; output = L × q = 6 milyon token.
- Bağlam/yeniden okuma için input/output oranı r = 5; input = 30 milyon token.
- Tek üretim turu: C = (30 × 2,50) + (6 × 15,00) = **165 $**.
- Yeniden üretim/review turu katsayısı k = 1–5 kabul edilirse **165–825 $**; örnek k = 3 için **495 $**.

Bu rakamlar yalnızca yukarıdaki [resmî fiyat](https://developers.openai.com/api/docs/models/gpt-5.4) ve açık varsayımların aritmetiğidir (hesap tarihi: 17.10.2026); token sayıları ölçülmemiştir. Token/satır oranı sabit bir fizik kuralı değildir. Araç çağrıları, ek reasoning/output, uzun bağlam, test tekrarları, insan emeği, hukuk/güvenlik denetimi, destek, altyapı ve bakım ayrıca maliyet yaratır. Bu tutar **kurumsal ürünün toplam geliştirme teklifi veya profesyonel tamamlanma süresi değildir**. Gerçek faturalandırmada billable input/output kullanım dökümü gerekir.

### Gün bazlı geliştirme süresi — mühendislik tahmini

**Varsayımsal plan, 17.10.2026:** Kodlama ajanı kullanan deneyimli bir Rails geliştiricisi; hazır temel proje; net kabul kriterleri; bir iş gününde 8 saat mesai içinde 6 saat odaklı mühendislik işi. Süre bir teslim taahhüdü veya ölçülmüş hız değildir. Analiz, test, düzeltme ve dokümantasyon iş kalemlerine dahildir; token maliyetinden gün hesabı yapılmaz.

| Aort dilimi iş kalemi | Tahmini odaklı saat |
| --- | ---: |
| Kapsam, veri modeli ve güvenlik tasarımı | 6–10 |
| Kayıt, giriş, oturum ve temel navigasyon | 6–10 |
| Taslak, düzenleme, alıcı ve gönderim bağlantısı | 8–12 |
| Güvenli imzalama, durum/zaman ve tekrar kullanım kuralları | 10–16 |
| Model/servis/HTTP testleri, regresyon ve düzeltme | 10–16 |
| Demo deploy hazırlığı ve teslim dokümantasyonu | 4–8 |
| **Toplam — varsayım** | **44–72** |

**Hesap:** Tek geliştirici için iş günü = yukarı yuvarla(toplam odaklı saat / 6): **8–12 iş günü**. Kapsam, manuel sözleşme aort dilimidir; mevcut Rails altyapısı kullanılır. Metin şablonları/sürüm/önizleme eklenirse **16–24 saat** ek varsayımıyla toplam **60–96 saat → 10–16 iş günü** olur. Tüm sayılar bu README'nin iş kırılımı tahminidir (17.10.2026); dış sektör ortalaması veya gerçekleşmiş süre değildir.

Tam kurumsal ürün için farklı bir kapsam ve takım gerekir; aşağıdaki plan gerçek DocuSign organizasyonu/süresi hakkında iddia içermez. Bir mühendis-gün aynı 6 saat odaklı iş kabulüdür:

| Kurumsal iş paketi | Tahmini mühendis-gün |
| --- | ---: |
| Çok kiracılı mimari, platform ve veri yönetimi | 60–90 |
| Kurumsal kimlik, SSO ve yetkilendirme | 40–60 |
| Belge/PDF işleme ve gelişmiş şablonlar | 60–90 |
| İmzalama, kimlik ve hukuki gereksinimlere yönelik teknik çalışma | 60–100 |
| Workflow, API ve entegrasyonlar | 100–160 |
| Audit, güvenlik ve uyumluluk mühendisliği | 60–100 |
| Ölçek/dayanıklılık testleri, operasyon ve sürümleme | 80–120 |
| **Baz iş yükü — varsayım** | **460–720** |

**Hesap:** %25 belirsizlik payıyla **575–900 mühendis-gün**. Beş tam zamanlı mühendisle ideal bölüşüm **115–180 iş günü**; bağımlılık/koordinasyon için ayrıca %20 süre payıyla **138–216 iş günü** takvim süresi tahmin edilir. Bu iş kırılımı modeli (17.10.2026), yaklaşık kurumsal LOC varsayımıyla aynı geniş kapsamı ele alır; LOC/gün verimlilik iddiası değildir. Tasarım/ürün desteği ve hukuk/denetim hizmetlerinin hazır olduğu varsayılır; dış onay beklemeleri, sertifikasyon takvimi ve canlı bakım ayrıca süre gerektirebilir. Böyle bir plan nitelikli elektronik imza veya mevzuat uygunluğu garantisi vermez.

**Gerçek süre korunur:** Kullanıcının aşağıda bildirdiği **yaklaşık 1–2 saat**, kendi proje çalışmasına ilişkin beyandır. Bu planlama tahminiyle değiştirilmez veya bütün profesyonel ürünün tamamlanma süresi olarak genellenmez.

### Gerçek geliştirme ve barındırma maliyeti

Aşağıdakiler kullanıcının **17.10.2026 tarihli görev beyanıdır**; fatura veya kullanım dashboard'u denetlenmedi. Beyan, API tahmininden ayrıdır:

| Kalem | Bildirilen durum | Muhasebe sınırı |
| --- | --- | --- |
| Araç | OpenAI Codex; ChatGPT aboneliğine dahil kullanım | Abonelik ile API token tarifesi aynı ödeme modeli değildir. |
| Aktif geliştirme süresi | Yaklaşık 1–2 saat | Kullanıcı beyanı; profesyonel ürünün bütün geliştirme/bakım süresi değildir. |
| Ayrı API/token faturası | 0 $ | Ek API faturası olmadığı beyanı; toplam proje maliyeti sıfır değildir. |
| Token adedi | Ölçülmedi | API fiyatından geriye doğru gerçek token hesabı yapılmaz. |
| ChatGPT abonelik bedeli | Tutar bildirilmedi | Abonelik maliyeti vardır; sıfır kabul edilmedi. Projeye ayrılacak payı hesaplanmadı. |
| Render Web Service | Free; temel plan bedeli 0 $ | Kullanıcı beyanı; kullanım aşımı/gelecek plan değişimi hariç. |
| Render PostgreSQL | Free; temel plan bedeli 0 $ | Kullanıcı beyanı; süreli demo kaynağı, kalıcı ücretsiz DB değil. |

Free PostgreSQL oluşturulduktan **30 gün** sonra erişilemez olur; ücretli plana geçiş için **14 günlük** ek süre sonunda silinir. Free web **15 dakika** hareketsizlikte uyur ([Render resmî Free belgeleri](https://render.com/docs/free); erişim: 17.10.2026). Hesaptaki oluşturma tarihi görülmediği için kesin DB bitiş günü yazılmadı. Toplam gerçekleşmiş maliyet, bilinmeyen abonelik payı nedeniyle hesaplanamadı; ek API bedelinin sıfır oluşu bu belirsizliği kaldırmaz.

## Aort dilimi — çalışan ana iş akışı

**Kayıt → Giriş → Sözleşme oluşturma → İmzaya gönderme → Güvenli bağlantı → Demo imzalama → signed.** Şablondan üretim, aynı taslak ve imzalama yoluna bağlanır; ayrı bir imzalama motoru değildir.

```mermaid
stateDiagram-v2
    draft --> pending: İmzaya gönder
    pending --> signed: Açık kabul ve ad; son tarihten önce
    pending --> expired: Son tarihe ulaşılmış
```

| Adım / kural | Gerçek kod kanıtı |
| --- | --- |
| Kayıt / parola hash'i / giriş / oturum | [RegistrationsController](app/controllers/registrations_controller.rb), [User](app/models/user.rb), [SessionsController](app/controllers/sessions_controller.rb), [Authentication](app/controllers/concerns/authentication.rb) |
| Sahibe ait taslak oluşturma, düzenleme ve gönderme | [DocumentsController](app/controllers/documents_controller.rb), [Documents::Manage](app/services/documents/manage.rb) |
| Durum geçişleri, kilitli imzalama, hash ve gönderilmiş metnin korunması | [Document](app/models/document.rb): send_for_signature!, sign!, expire!, protect_sent_document |
| Fragment → CSRF korumalı POST; token ile erişim | [Stimulus signing_link](app/javascript/controllers/signing_link_controller.js), [SigningController](app/controllers/signing_controller.rb), [Documents::Signing](app/services/documents/signing.rb) |
| Girilen ad, açık kabul, kayıt ve onay | [SignatureAcceptance](app/models/signature_acceptance.rb), [SigningController](app/controllers/signing_controller.rb), [onay ekranı](app/views/signing/complete.html.erb) |
| Kalıcı süre sonu; isteğe bağlı toplu komut | [Documents::Expiration](app/services/documents/expiration.rb), [documents:expire](lib/tasks/documents.rake) |
| Şablon sürümü / metin üretimi / kayıtsız önizleme | [Templates::Manage](app/services/templates/manage.rb), [TemplateVersion](app/models/template_version.rb), [Templates::Renderer](app/services/templates/renderer.rb), [TemplateDocumentsController](app/controllers/template_documents_controller.rb) |

**Son tarihe eşit anda ve sonrasında imza reddedilir.** Time.current kontrolü hem token erişiminde hem kilitli sign! geçişinde vardır; token ikinci kez kullanılamaz. `travel_to` / `with_usec: true` sınır testleri [Document testlerinde](test/models/document_test.rb), [belge servis testlerinde](test/services/documents_test.rb), [expiration testinde](test/services/expiration_test.rb) ve [HTTP workflow testlerinde](test/integration/signflow_workflow_test.rb) gerçekten bulunur (kod inceleme: 17.10.2026). Şablon → signed ve CSRF akışı [template_workflow_test](test/integration/template_workflow_test.rb) ve [gerçek şema regresyonunda](test/integration/template_schema_regression_test.rb) yer alır. Otomatik zamanlayıcı kurulmuş değildir; son tarih güvenliği scheduler'a bağlı değildir.

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

### Canlı Render manuel kabul testleri — kullanıcı beyanı

**Uygulama ve tarih:** [Canlı SignFlow](https://signflow-k2tg.onrender.com/), **17 Ekim 2026**. Aşağıdaki sonuçlar kullanıcının canlı uygulamada yaptığı manuel doğrulamalar olarak bildirilmiştir; Codex tarafından otomatik gerçekleştirilmiş testler değildir.

| Manuel kontrol grubu | Kullanıcının bildirdiği sonuç |
| --- | --- |
| Kayıt, giriş ve oturum | 5/5 |
| Normal sözleşme oluşturma ve imzalama | 6/6 |
| Şablon oluşturma ve imzalama | 8/8 |
| Yeniden başlatma sonrasında veri kalıcılığı | Başarılı |

Kaynak: bu README güncellemesi için kullanıcının 17.10.2026 tarihli beyanı. Tekil adım listesi, test kayıtları ve Render dashboard'u bu çalışmada bağımsız denetlenmedi; oranlar aynen aktarıldı. Restart sonrası kalıcılık, ücretsiz PostgreSQL'in süre sınırını ortadan kaldırmaz. Aşağıdaki Minitest sonucu ayrı bir yerel otomatik kontroldür.

### Yerel otomatik test kaydı

**Önceki dokümantasyon çalışmasının yerel doğrulaması (17.10.2026):** `bundle exec rails test` gerçekten çalıştırıldı; **92 test, 900 assertion, 0 failure, 0 error, 0 skip** ([kontrol kaydı](docs/RESEARCH_VERIFICATION.md)). Bu sonuç uzaktaki Actions veya canlı tarayıcı akışının sonucu değildir. Bu son README düzenlemesinde Rails testleri yeniden çalıştırılmadı; uygulama/test/güvenlik dosyaları ve veritabanları değiştirilmedi.

GitHub Actions CI, main dalına push ve main hedefli pull request olaylarında çalışır. Ubuntu 24.04 üzerinde Ruby 3.4.11, Gemfile.lock'taki Bundler sürümü ve ruby/setup-ruby Bundler cache kullanılır. SQLite test veritabanı hazırlanır; Minitest, Zeitwerk, RuboCop ve mevcut güvenlik taramaları çalıştırılır. Başarısız komutun hatası gizlenmez; ilgili CI işi başarısız olur. Testler izole test ortamında çalışır; geliştirme veritabanı kullanılmaz.

[Actions → CI](https://github.com/Huseyinyagmur/signflow/actions/workflows/ci.yml) sayfasından ilgili commit/PR çalışmasını açıp scan_ruby, scan_js, lint ve test işlerinin loglarını kontrol edin. Rozet main üzerindeki push çalışmasının durumunu gösterir. Yerel kontrollerin başarılı olması uzaktaki Actions çalışmasının başarılı olduğu anlamına gelmez. Workflow ancak siz değişiklikleri GitHub'a gönderdiğinizde çalışır; bu kurulum otomatik commit/push yapmaz. Projede test/system bulunmadığı için tarayıcı sistem testi işi yoktur.

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

## Yapamadıklarım

Kod incelemesi: 17.10.2026. Bu bölüm önceki “Sınırlar” içeriğini birleştirir; eksik özellikler tamamlanmış gibi sunulmaz.

- **Nitelikli elektronik imza ve gerçek alıcı kimlik doğrulaması yok.** [SignatureAcceptance](app/models/signature_acceptance.rb) yalnızca ad/açık kabul alır; [Documents::Signing](app/services/documents/signing.rb) bearer token denetler. Linke sahip kişi demo imza atabilir; sertifika veya doğrulanmış kimlik kullanılmaz.
- **Gerçek e-posta gönderimi yok.** [DocumentsController](app/controllers/documents_controller.rb) bağlantıyı sahibine gösterir; paylaşım kullanıcıya aittir. Mailer iskeleti bulunması çalışan gönderim servisi anlamına gelmez.
- **PDF oluşturma, PDF üzerine alan yerleştirme/imzalama ve imzalı PDF indirme yok.** [Belge rotaları](config/routes.rb) ve [belge görünümü](app/views/documents/show.html.erb) metin tabanlıdır.
- **Otomatik expiration zamanlayıcısı yok.** [Toplu görev](lib/tasks/documents.rake) vardır; [recurring.yml](config/recurring.yml) belge expiration işini planlamaz ve production async job kullanır. Erişimde süre kontrolü yine aktiftir.
- **Tam DocuSign ölçeği yok.** Çoklu imzacı sıralaması, kapsamlı API/CRM entegrasyonları, değiştirilemez audit deposu, kurumsal uyumluluk denetimi, gelişmiş PDF editörü, yapay zekâ ve ödeme yoktur. Mevcut düz metin şablon/sürüm özelliği bunların eşdeğeri değildir.
- **Link yeniden üretme/yeniden gösterme, parola sıfırlama ve e-posta doğrulaması yok.** [Routes](config/routes.rb) bu uçları sunmaz. Cookie süresi **12 saat** ([session_store](config/initializers/session_store.rb); inceleme: 17.10.2026); rate limit süreç belleğindedir. Çalınmış cookie'yi sunucuda tek tek iptal eden Session modeli yoktur.
- **Süresiz ücretsiz hosting/veritabanı garantisi yok.** Kullanıcının bildirdiği Free Render planlarında uyku ve PostgreSQL süre sınırı vardır; kesin sınırlar [resmî Render kaynağında](https://render.com/docs/free) açıklanır (erişim: 17.10.2026). Canlı URL bulunması üretim SLA'sı, backup veya kalıcı ücretsiz DB kanıtı değildir.
- **Araştırma kanıtları eksik kalan yerler:** Tüm Fortune üyelerinin aynı tarihli değerleme/çalışan minimum–maksimumu, T-Mobile'ın resmî güncel liste satırı, müşteri ödeme bedelleri, gerçek token adedi ve aboneliğin projeye düşen maliyeti doğrulanamadı. Bu eksikler için sayı uydurulmadı.

Mimari ve ajan kuralları: [AGENT.md](AGENT.md). İkinci aşama dosya listesi, gerçek test sonuçları, rotalar ve doğrulama sınırları: [rapor](docs/PHASE2_REPORT.md).

## Gerçek Kullanıcı Problemi ve Çözümümüz

[Capterra'daki DocuSign yorumlarında](https://www.capterra.com/p/121506/Docusign/reviews/) **17.08.2026** tarihli **“Signing takes a minute, template upkeep takes an afternoon”** değerlendirmesi bu aşamanın çıkış noktasıdır (kaynak erişim kontrolü: 17.10.2026). Başlık, tarih ve yorum metni arama motorunun indekslenmiş Capterra içeriğinde görüldü; doğrudan sayfa erişimi HTTP 403 ile engellendi. Bu nedenle doğrulama düzeyi indeks metnidir; doğrudan sayfa görüntüsü veya kalıcı yorum bağlantısı arşivlenmedi. Kaynak yorumu teşvikli değerlendirme olarak işaretler; bu tek kişinin deneyimidir, bütün kullanıcıları temsil eden istatistik değildir.

**Doğrudan kaynakla kontrol yolu:** [Capterra yorum sayfasını](https://www.capterra.com/p/121506/Docusign/reviews/) tarayıcıda açıp yukarıdaki başlığı ve tarihi birlikte arayın; Cons bölümündeki elle PDF alan yerleşimi ve şablon bakım yükü anlatımını karşılaştırın. Bu son incelemede de doğrudan web açma başarısız oldu; kullanılabilir Browser bağlantısı bulunmadı. Bu nedenle “Codex doğrudan sayfada doğruladı” ifadesi eklenmedi. Kaynağın doğrudan görüntüsü görülmeden bu alt kriter tamamlanmış sayılmaz; indeks teyidi ile doğrudan teyit ayrıdır.

Yorumdaki sorun: belge düzeni veya dayanak metin değişince PDF alanlarını elle yeniden yerleştirmenin tekrar eden bakım yükü oluşturması ve zaman kaybettirmesi. Arama/işlem adımlarına ilişkin şikâyetler de vardır. Yorum uzun alıntı yerine burada özetlenmiştir.

SignFlow, ders demosunda bu problemi ortak metni tek yerde düzenleyerek, değişken alanları otomatik algılayarak, başlık/açıklama araması ve değiştirilemeyen sürüm geçmişi sunarak ele alır. Şablondan oluşturulan sözleşme bağımsız bir metin kopyası taşır. Şablon güncellemesi eski taslakları veya imzalı belgeleri etkilemez. Şablonların özgün üründe hiç bulunmadığı iddia edilmez; farkımız, tekrar eden sözleşmeler için daha sade ve merkezi bir oluşturma/güncelleme deneyimi sunmaktır. PDF alan yerleşimi bu projenin kapsamında değildir.

### 100 puanlık çözüm gerekçesi ve sınırı

Bu başlık ödev kriterini ifade eder; verilmiş bir not veya ölçülmüş kullanıcı kazanımı değildir. Çözüm özellikle **metin tabanlı tekrar eden şablonları** basitleştirir. [Renderer](app/services/templates/renderer.rb) değişkenleri algılar, [önizleme controller'ı](app/controllers/template_documents_controller.rb) kayıtsız metin üretir, [şablon servisi](app/services/templates/manage.rb) yeniden kullanılabilir sürümleri oluşturur, [TemplateVersion](app/models/template_version.rb) eski sürümü korur. [Document](app/models/document.rb) ve [belge üretim servisi](app/services/documents/manage.rb) önceki sözleşmelerin bağımsız metin kopyasını korur. Bunlar PDF koordinatı yerleştiren bir editörün eşdeğeri değildir; önizleme kullanıcı tarafından tetiklenir, metni sunucu otomatik üretir. Zaman tasarrufu için kullanıcı deneyi yapılmadığından yüzde/saat kazanımı iddia edilmez.

**Sunum cümlesi:** “Sık şablon güncelleyen sözleşme yöneticisinin Capterra'daki 17.08.2026 tarihli bakım yükü şikâyetini, SignFlow'da yeniden kullanılabilir metin şablonları, değişkenlerden üretilen önizleme ve eski imzalı metni koruyan sürüm geçmişiyle ele alıyoruz.” ([yorum kaynağı](https://www.capterra.com/p/121506/Docusign/reviews/); indeks kontrolü: 17.10.2026.)

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

## Ödev teslim kontrol tablosu

Kontrol tarihi: **17.10.2026**. “Kısmi” satırları tamamlanmış kanıt değildir; değerlendirmede bu ayrım korunmalı.

| Ödev maddesi | Durum | README'deki kanıt / kalan ihtiyaç |
| --- | --- | --- |
| Teslim bağlantıları, CI rozeti, teknolojiler | Tamamlandı | Ödev Özeti ve görünür üst bölüm; kullanıcı manuel testi ile Codex GET kontrolü ayrıldı. |
| Faz 1: gelir / piyasa değeri ayrımı | Tamamlandı | Gelir sıralaması; tarihli halka açık şirket örnekleri. |
| Bütün şirketler için kesin değerleme alt/üst sınırı | Kısmi / veri eksik | Özel değerlemeler kamuya açık değil; aynı tarihli tam alt küme yok. Örnekler genel minimum değildir. |
| Çalışan toplamı | Tamamlandı | Fortune yayımlayıcı duyurusu. |
| Çalışan kesin minimum / maksimum | Kısmi / veri eksik | Seçili şirketler doğrulandı; tüm üyelerin karşılaştırılabilir alanları gerekiyor. |
| SaaS sayısı: ortalama / medyan | Tamamlandı | Zylo; Fortune'a özgü olmayan örneklem açıklandı. |
| SaaS gideri: ortalama / medyan | Tamamlandı | Zylo; tüm IT giderinden ayrıldı. |
| DocuSign Fortune kullanım beyanı | Tamamlandı | Sağlayıcı kaynağı; bağımsız ödeme denetimi olmadığı açık. |
| Birincil Fortune müşteri vakası: Comcast Business | Ticari kullanım doğrulandı | Resmî Comcast müşteri PDF'si + Fortune üyeliği; doğrudan ödeme belgesi değil. |
| T-Mobile dijital sözleşme vaka kanıtı | Tamamlandı | Sağlayıcı PDF'si; tarihsel müşteri kullanımı. |
| T-Mobile resmî 2026 Fortune satırı | Kısmi / doğrulanamadı | Resmî yıl satırı eksik; birincil kanıt Comcast, T-Mobile ek tarihsel vaka olarak korundu. |
| Ticari kullanım / ücretli abonelik ayrımı | Tamamlandı, tutar bilinmiyor | Kullanım vakası mevcut; kamuya açık ödeme kanıtı/bedel doğrulanmadı. |
| Faz 2: modüller ve kurumsal satır varsayımı | Tamamlandı — tahmin | Tedarikçi LOC sayısı olarak sunulmadı. |
| SignFlow gerçek LOC | Tamamlandı — ölçüm | Dosya bazlı hash/sayı içeren ölçüm dökümü. |
| Agent/API maliyet modeli | Tamamlandı — tahmin | Resmî model tarifesi, input/output ve tekrar varsayımları. |
| İş günü tahmini: aort / tam kurumsal ürün | Tamamlandı — tahmin | Saat bazlı iş kırılımı, odaklı gün, mühendis-gün, ekip ve belirsizlik hesabı ayrı. |
| Gerçek süre / maliyet | Beyan kaydedildi | Token ölçülmedi; abonelik payı ve toplam maliyet hesaplanamadı. |
| Aort dilimi ve zaman testleri | Tamamlandı — kod incelemesi | Gerçek dosyalar, geçişler ve travel_to kullanımı bağlantılı. |
| Canlı Render manuel kabul / restart kalıcılığı | Kullanıcı beyanı kaydedildi | 17.10.2026 canlı kontrolleri; Codex tarafından otomatik yapıldığı iddia edilmedi. |
| Kullanıcı acısı ve çözüm | İndeks üzerinden doğrulandı | Capterra doğrudan erişim engelli; not veya tasarruf yüzdesi iddiası yok. |
| Yapamadıklarım | Tamamlandı | Kod ve platform sınırları açık. |
| Mevcut yerel kullanım / CI / şablon belgeleri | Korundu | Tekrar eden sınırlar birleştirildi; geçmiş raporlar bağlı. |
| AGENT / uygulama / güvenlik | Korundu | Bu son düzenleme yalnızca README'yi değiştirir; mevcut araştırma dokümanları korundu, push/deploy yok. |

Kaynak erişim kayıtları ve yerel kontroller: [araştırma doğrulama notu](docs/RESEARCH_VERIFICATION.md). Geçmiş aşama raporlarının sonuçları kendi tarihlerine aittir; güncel uzak CI veya canlı tarayıcı başarısı olarak aktarılmaz.

## 0/85/100 kısa teslim eşlemesi

Bu eşleme görevde aktarılan gereksinimleri özetler; hocanın tam rubrik metni burada bulunmadığından kesin not veya otomatik puan kararı değildir. Özellikle doğrudan ödeme ve yorum erişimi eksikleri kapatılmış sayılmaz.

| Puan kriteri / kontrol | Teslimde karşılığı | Kanıt durumu |
| --- | --- | --- |
| 0 puan riskini denetleme: yalnızca ürün adı/logo yerine incelenebilir çalışan teslim | Canlı URL, kaynak repo, CI bağlantısı, kullanıcı manuel test beyanı ve kod bağlantıları | Mevcut; canlı akış sonuçları kullanıcı beyanı, önceki yerel test kaydı ayrı. |
| 85 kapsamı: Fortune 500 şirketinin seçilen SaaS'ı kullanması | Birincil Comcast Business resmî vaka çalışması + Comcast Fortune profili; T-Mobile ek örnek | Ticari kullanım güçlü; doğrudan ücretli sözleşme/fatura kriteri varsa **ödeme kanıtı eksik**. |
| 85 kapsamı: Faz 1 sayısal araştırma | Açık kapsamlı değer/çalışan aralıkları, toplam istihdam, Zylo ortalama/medyanları | Örnekler kaynaklı; bütün liste kesin alt/üst sınırları **kısmi**. |
| 85 kapsamı: Faz 2 ölçek, maliyet ve gün hesabı | Modül LOC tahmini, gerçek ölçüm, API varsayımı, aort ve kurumsal iş günü hesabı | Ölçüm / tahmin / kullanıcı beyanı ayrıldı; gerçek token ve toplam abonelik payı bilinmiyor. |
| 85 kapsamı: aort dilimi, zaman kuralları ve teslim dürüstlüğü | Kayıt → signed; gerçek dosyalar, travel_to, test kaydı, kullanıcı manuel testleri, Yapamadıklarım | Belgelenmiş; nitelikli imza veya sınırsız ücretsiz kalıcılık iddiası yok. |
| 100 kapsamı: belirli gerçek kullanıcı acısı | Tarihli Capterra değerlendirmesi ve doğrudan kaynak bağlantısı | İndeks teyidi var; **doğrudan sayfa doğrulaması yapılamadı**. |
| 100 kapsamı: acıya yönelik çalışan çözüm ve sınırı | Metin şablonları, değişken önizleme, sürüm geçmişi ve eski imzalı metnin korunması | Kod ve kullanıcı şablon testi beyanı var; **PDF alan koordinatlama sorunu tamamen çözülmedi**. |
