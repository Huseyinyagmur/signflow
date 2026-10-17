# SignFlow — Son Kanıt Denetimi

**Araştırma ve erişim tarihi: 17 Ekim 2026 (Europe/Istanbul).** Kapsam: **2026 ABD Fortune 500** ve mevcut SignFlow tesliminin araştırma kanıtları. Global 500, Europe 500 ve Fortune 1000 bu evrenin yerine kullanılmadı. README, AGENT.md ve [önceki doğrulama notu](RESEARCH_VERIFICATION.md) okundu; eski erişim iddiaları yeni kontrol yerine kabul edilmedi.

Bu çalışma uygulama geliştirmesi değildir. Uygulama/test/güvenlik dosyaları, AGENT.md ve veritabanları değiştirilmedi; Rails/DB komutu, migration, deploy, commit veya push çalıştırılmadı. Gizli dosyalar okunmadı. Harici açık kaynak kodu yalnızca sayım için bellekte okundu; çalıştırılmadı. Yeni araştırma ölçümleri mevcut SignFlow LOC ölçümünün yerine geçirilmedi.

## 1. Sonuç ve kanıt ölçeği

| Soru | Sonuç |
| --- | --- |
| Bütün Fortune 500 için aynı tarihli değerleme minimum–maksimumu bulundu mu? | **Liste uçları artık hesaplandı:** 500 üyenin 472 dolu piyasa değerinde QVC Group 18,9 milyon $ – Nvidia 4,23792 trilyon $. Uçların 31 Mart referansı destekli; bütün 472 satırın aynı gününü bağımsız kurma tamamlanmadı. Bölüm 13 yeni sonucu ve kapsamı verir. |
| Kesin en az/en çok çalışanlı üyeler bulundu mu? | **Evet, Fortune'un yayımladığı ölçüde:** 500/500 kayıtta BitGo 603 – Walmart 2.100.000. Bu standartlaştırılmış aynı gün FTE sayımı değildir. |
| En az bir Fortune şirketinin DocuSign'a ödeme yaptığı doğrudan kanıtlandı mı? | **Hayır.** Comcast ve bazı alternatifler için güçlü ticari müşteri kanıtı var; isimli satın alma bedeli/sözleşmesi/faturası bulunamadı. |
| Gerçek yorum doğrudan okundu mu? | **Evet: TrustRadius / Liz Duffié, 25.05.2021.** Capterra'nın istenen yorumu indeks düzeyinde kaldı. |
| Bütün 85 şartları tamam mı? | **Hayır.** Tam liste taraması yapıldı, ancak doğrudan Fortune ödeme belgesi ve bütün piyasa satırlarının ortak tarih denetimi açık. |
| 100 kapsamındaki çözüm savunulabilir mi? | **Sınırlı metin şablonu problemi için evet.** Kod ve kullanıcı test beyanıyla desteklenir; PDF koordinatları ve ölçülmüş kullanıcı kazanımı kapsam dışı. 100 puan garantisi yok. |

Genel kanıt notları: **A: Doğrudan doğrulandı; B: Güçlü ama dolaylı kanıt; C: Zayıf/ikincil kaynak; D: Doğrulanamadı.** Not, belirtilen iddiaya verilir; kaynağın tüm içeriğine verilmez. Örneğin resmî vaka dosyası doğrudan okunmuştur, fakat **ödeme için B** düzeyindedir. Bir kaynağın erişilebilirliği, doğruluğu ve iddiaya yeterliliği ayrı değerlendirilir. Arama sonucu görülen fakat gövdesi açılamayan bilgi A sayılmaz.

Ödeme araştırmasında ayrıca kullanıcının istediği ayrım korunur: **ödeme-A** isimli satın alma/ödeme belgesi; **ödeme-B** güçlü ticari müşteri; **ödeme-C** logo/ortaklık/ikincil liste; **ödeme-D** ilişki veya ödeme doğrulanamadı. Bu denetimde uygun Fortune müşterisi için ödeme-A bulunmadı.

## 2. Değerleme: tanım, evren ve hesap

2026 Fortune sıralaması şirketlerin **yıllık gelirine** dayanır; en değerli şirketler sıralaması değildir. Liste duyurusu 2025 mali yıl gelirlerini esas aldığını açıklar. Bir şirketin 2026 profili daha sonra güncellenebilir; profil güncelleme tarihi ile listede kullanılan hesap dönemi ve piyasa fiyat tarihi aynı değildir.

| Kavram | Kullanılan anlam | Kaynak / konum |
| --- | --- | --- |
| Annual revenue | Bir dönemin satış/gelir akışı; şirketin piyasa fiyatı değil | [Fortune Analytics](https://fortune.com/analytics/fortune-500), liste tanımı ve veri alanları; sayfada yayın günü yok, 2026 ürünü. |
| Market capitalization | Halka açık hisse fiyatı × dolaşımdaki hisse sayısı; özkaynağın piyasa değeri | [Investor.gov](https://www.investor.gov/introduction-investing/investing-basics/glossary/market-capitalization), tanım; yayın/veri günü belirtilmiyor. |
| Enterprise value | Basitleştirilmiş biçimde market cap + borç − nakit; bazı hesaplar başka finansman kalemleri ekler | [Fidelity araştırma sözlüğü](https://www.fidelity.com/webcontent/ap010098-etf-content/18.05.0/help/research/learn_er_glossary_1.shtml), Enterprise Value; yöntem bilgisi, belirli şirket verisi değil, yayın günü yok. |
| Company valuation | Kullanılan yönteme göre özkaynak veya işletme değerini ifade edebilen genel terim | Bu raporda ölçüm türü açık yazılır; özel şirket işlem/finansman değerlemesi borsa market cap'i yerine konmaz. |

Özel şirketler için sürekli gözlenen hisse fiyatı yoktur. Eski bir finansman turu veya işlem bedeli, aynı günün halka açık şirket market cap'iyle tek dağılımda karşılaştırılmaz. Negatif/eksik veya farklı tarihli alanları sessizce elemek de evreni değiştirir.

### 2.1 Gerçekten kontrol edilen yedi şirket

**Tarihsel örnek kontrolü:** Bu alt bölüm ilk dar taramayı korur. Güncel kapsam/sonuç artık **bölüm 13'teki 500 şirketlik liste kontrolüdür**; aşağıdaki farklı tarihli profiller tam listenin yerine geçmez.

Her bağlantı halka açık Fortune şirket profilidir. Kaynak konumu: **Company Information / Key Financials / Fortune 500 liste bilgisi** ve sayfanın kamuya açık `__NEXT_DATA__` yıl-sıra alanları. Piyasa değeri sütununun birimi profillerde milyon ABD dolarıdır. Aşağıdaki milyon değerleri raporun hesap girdileridir; README'de milyar/trilyon dönüşümü yapıldı.

| Üye / 2026 ABD sırası | Market cap (milyon $) | Piyasa verisi tarihi | Profil güncellemesi | Kaynak |
| --- | ---: | --- | --- | --- |
| BitGo / 278 | 950 | 31.03.2026 | 03.06.2026 | [BitGo](https://fortune.com/company/bitgo-holdings/) |
| Gold.com / 398 | 1.128 | 31.03.2026 | 03.06.2026 | [Gold.com, eski A-Mark URL'si](https://fortune.com/company/a-mark-precious-metals/) |
| Global Partners / 234 | 1.431 | 31.03.2026 | 03.06.2026 | [Global Partners](https://fortune.com/company/global-partners/) |
| World Kinect / 128 | 1.846 | 13.07.2026 | 28.07.2026 | [World Kinect, eski şirket URL'si](https://fortune.com/company/world-fuel-services/) |
| Galaxy Digital / 76 | 9.104 | 13.07.2026 | 28.07.2026 | [Galaxy Digital](https://fortune.com/company/galaxy-digital/) |
| Walmart / 2 | 916.771 | 18.08.2026 | 29.09.2026 | [Walmart](https://fortune.com/company/walmart/) |
| Nvidia / 16 | 5.445.390 | 24.09.2026 | 08.10.2026 | [Nvidia](https://fortune.com/company/nvidia/) |

**İlk örnek hesabı:** Yedi gözlemin `min(market_cap)` = 950 milyon $, `max` = 5.445.390 milyon $ = 5,44539 trilyon $. Bu **karışık tarihli, amaçlı seçilmiş örneklerin zarfıdır**. Aynı tarihli 31.03.2026 alt kümesinde n=3, min=950 ve max=1.431 milyon $ olur. Üç şirketin maksimumu Nvidia hakkında bir sonuç değildir. İlk nicel karşılaştırmada diğer **493** üye dışarıdaydı; yeni tarama bütün üyeleri içerir. Eski örnek minimumu yeni liste minimumu değildir.

**Üyelik yöntemindeki önemli tuzak:** Kamuya açık HTML içindeki liste kayıtları `slug=fortune500`, `year=2026`, `rank` birlikte kontrol edildi. Tek başına “Fortune 500” kategori başlığı yeterli değildir: [NGL Energy Partners](https://fortune.com/company/ngl-energy-partners/) için 2026 sıra **614** görüldü; profilin 569 çalışan bilgisi onu en küçük Fortune 500 üyesi yapmaz. Bu şirket dışlandı. Sayfa erişiminde ücretli listeye giriş veya erişim engeli aşma yapılmadı.

**En yüksek için destek:** [Fortune'un 03.06.2026 yayımlama duyurusu](https://fortunemedia.mediaroom.com/2026-06-03-Amazon-Claims-No-1-Spot-on-the-Fortune-500), değer lideri olarak Nvidia'yı belirtir. Ayrı yayıncı [CompaniesMarketCap, 14.08.2026 dünya sıralaması](https://companiesmarketcap.com/time-machine/2026-08-14/), o gün Nvidia'yı ilk sırada 5,453 trilyon $ gösterir. Bu iki kaynak **lider şirketi farklı tarihlerde destekler**; yukarıdaki 24 Eylül değerinin bağımsız fiyat doğrulaması değildir. CMC 31 Mart tarihli uç noktasından kullanılabilir tam seri alınamadı. Yeni liste hesabı bu ikincil seriden değil, bölüm 13'teki resmî tablodan yapıldı.

[Fortune Analytics](https://fortune.com/analytics/fortune-500), 2026 ürününde market value ve employees alanlarını açıkça listeler. **Ücretli veri satın alınmadı**; ancak sonraki araştırmada kamuya açık liste HTML'sinin tablosu edinildi. Ücretli ürün ile açık sayfa ayrı kaynak yollarıdır. Yeni hesap, boş değerler ve sürüm kaydı bölüm 13'tedir; hisse sınıfları/fiyat serileriyle bağımsız yeniden değerleme değildir.

## 3. İstihdam: dönem ve tanım denetimi

| Şirket / üyelik | Doğrulanan çalışan bilgisi | Veri dönemi | Birincil pasaj / tarih |
| --- | --- | --- | --- |
| BitGo / 278 | **603 full-time çalışan**; Fortune da 603 | 31.12.2025 | [SEC 10-K](https://www.sec.gov/Archives/edgar/data/1740604/000174060426000020/btgo-form10xk.htm), Human Capital; dosyalama 27.03.2026. |
| Gold.com / 398 | Fortune **975**; şirket raporu **993**, bunların 37'si hariç tamamı full-time | 30.06.2025 | [SEC yıllık rapor PDF'si](https://www.sec.gov/Archives/edgar/data/1591588/000119312525227653/amrk_ars_fy_25.pdf#page=15), PDF s.15 / basılı s.12, Human Capital; belge üzerindeki 11.09.2025 tarih bilgisi. |
| Galaxy Digital / 76 | **700** | Profilde çalışan ölçüm günü açık değil | [Fortune](https://fortune.com/company/galaxy-digital/), çalışan alanı; güncelleme 28.07.2026. |
| Global Partners / 234 | **3.982** | Profilde çalışan ölçüm günü açık değil | [Fortune](https://fortune.com/company/global-partners/), çalışan alanı; güncelleme 03.06.2026. |
| World Kinect / 128 | **4.003** | Profilde çalışan ölçüm günü açık değil | [Fortune](https://fortune.com/company/world-fuel-services/), çalışan alanı; güncelleme 28.07.2026. |
| Nvidia / 16 | **42.000** | 31.01.2026 mali yıl | [Fortune](https://fortune.com/company/nvidia/), çalışan ve mali yıl alanları; güncelleme 08.10.2026. |
| Walmart / 2 | **Yaklaşık 2,1 milyon dünya çapında çalışan** | FY2026 | [Walmart yıllık rapor duyurusu](https://corporate.walmart.com/news/2026/04/23/walmart-releases-2026-annual-report-and-proxy-statement), 23.04.2026; [şirketin konum bilgileri](https://corporate.walmart.com/about/location-facts) de FY2026 toplamını verir. |

**Gold.com ölçü ayrımı:** İlk kontrolde açıklanamayan 975/993 farkı, yeni bulunan Fortune metodolojisiyle aritmetik olarak uyuşur: (993−37)+37×0,5=974,5, yuvarlanmış 975. Bu şirket için Fortune'un açık gerekçe açıklaması bulunmadı; **yöntemle uyumlu çıkarım** düzeyindedir. Ham toplam ile ağırlıklandırılmış alan birbirinin yerine geçirilmedi; bölüm 13 ayrıntıyı verir.

**Headcount ≠ FTE.** Full-time çalışanların kişi sayısı tam-zaman eşdeğeri bir saat toplamı değildir. Walmart'ın genel toplamını yalnızca full-time veya FTE diye yeniden adlandırmıyoruz. Proxy raporlarındaki ücret karşılaştırmasına alınan alt popülasyon da dünya toplamıyla birleştirilmez. Ölçüm günü bulunmayan profile aynı gün varsayımı eklenmedi.

**İlk gözlem ve yeni sonuç:** Yedi örnekteki 603–yaklaşık 2.100.000 uçları bölüm 13'te artık **500/500 Fortune çalışan alanı üzerinden** doğrulandı. Sonuç Fortune metodolojisi kapsamındadır; bütün şirketlerin ham kişi sayısı/saat bazlı FTE serisini yeniden oluşturmaz. NGL'nin üyelik dışı olduğu kontrolü geçerlidir.

**Toplam istihdam:** [Fortune 03.06.2026 duyurusu](https://fortunemedia.mediaroom.com/2026-06-03-Amazon-Claims-No-1-Spot-on-the-Fortune-500) liste üyelerinin dünya çapında **30,5 milyon** kişi çalıştırdığını bildirir. Bu toplam ABD'de çalışan sayısı veya aynı günün FTE toplamı değildir; yayımlayıcının 2026 liste toplamıdır.

## 4. En yüksek öncelik: DocuSign'a ödeme kanıtı

### 4.1 Adayların ayrı üyelik ve müşteri denetimi

Müşteri olma bilgisi tarihsel kaynağın tarihiyle sınırlıdır; 2018'de müşteri olmak 2026'da aynı sözleşmenin sürmesini veya bedelini kanıtlamaz. Tabloda doğrulanmış 2026 sıra, müşterilik tarihini değiştirmez.

| Kanıt önceliği / aday | 2026 ABD Fortune üyeliği | Gerçekte bulunan ilişki | Ödeme düzeyi / eksik |
| --- | --- | --- | --- |
| 1 — Comcast Business | Ana şirket [Comcast 37](https://fortune.com/company/comcast/) | Ayrıntılı resmî vaka + SEC S-1 müşteri anlatımı | **B**; fatura/satın alma lisans sözleşmesi yok. Birincil örnek korundu. |
| 2 — Microsoft | [11](https://fortune.com/company/microsoft/) | 07.06.2022 açıklaması açıkça müşteri ve ortak diyor | **B**; ortaklık tek başına yeterli olmazdı, müşteri ifadesi de ödeme bedeli değil. |
| 3 — Salesforce | [114](https://fortune.com/company/salesforce-com/) | 2018 S-1'de temsilî müşteri ve vaka | **B**; isimli yazılım alım tutarı yok. |
| 4 — Bank of America | [20](https://fortune.com/company/bank-of-america-corp/) | 2018 S-1 temsilî müşteri listesi | **B**; lisans ödeme kaydı yok. |
| 4 — Verizon | [28](https://fortune.com/company/verizon/) | 2018 S-1 temsilî müşteri listesi | **B**; lisans ödeme kaydı yok. |
| 4 — Walmart | [2](https://fortune.com/company/walmart/) | 2018 S-1 temsilî müşteri listesi | **B**; lisans ödeme kaydı yok. |
| T-Mobile | [2026 tam listede](https://fortune.com/ranking/fortune500/) yok; profil yıl-sırası da bulunamadı | Resmî e-kitap ve S-1'de tarihsel kullanım | Kullanım **B**; güncel Fortune şartı sağlanmadı, ödeme **D**. |
| Accenture | [Profil](https://fortune.com/company/accenture/) ülke Ireland; bu denetimde ABD 2026 üyeliği yok | 12.03.2015 açıklamasında **partner** | Müşterilik/ödeme **D**; ortaklık müşteriliğe çevrilmedi, US evrenine katılmadı. |
| AT&T | [35](https://fortune.com/company/att/) | Araştırılan sonuçlarda yeterli isimli satın alma kanıtı yok | **D**; entegrasyon veya imzalı dosya müşteri ödemesi değildir. |
| Amazon | [1](https://fortune.com/company/amazon-com/) | Araştırılan sonuçlarda yeterli müşteri satın alma kanıtı yok | **D**; Amazon/AWS teknik ilişkileri ödeme diye yorumlanmadı. |
| JPMorgan Chase | [12](https://fortune.com/company/jpmorgan-chase/) | Bankacılık/lockbox ve imzalı belge sonuçları müşteri alımı göstermiyor | **D**. |

**Ticari ilişki kaynakları ve pasajlar:**

- [Comcast resmî vaka PDF'si](https://www.docusign.com/sites/default/files/resource_event_files/docusign_case_study-comcast__2.pdf): **PDF s.1** araçların değerlendirilip seçilmesi ve satış/tablet entegrasyonu; **s.2** Terry Connell'in kullanım anlatımı. Yayın tarihi basılı değil; erişim tarihi uygulamanın başlangıcı sayılmaz. Comcast Business ayrı Fortune üyesi değil, ana şirketin iş birimidir.
- [DocuSign SEC S-1](https://www.sec.gov/Archives/edgar/data/1261333/000119312518099555/d506878ds1.htm), dosyalama **28.03.2018**: **Our Customers / Representative Customers / Customer Case Studies**, basılı **s.88–91**. Listede Bank of America, Salesforce, Comcast, T-Mobile, Verizon, Walmart; Salesforce vakası s.89, T-Mobile s.90, Comcast s.91 civarı. Toplam ücretli müşteri sayısının bulunması, adı geçen her kuruma tek tek fatura veya ücret atamaz.
- [Microsoft–DocuSign açıklaması](https://www.docusign.com/company/news-center/docusign-and-microsoft-deepen-relationship-to-accelerate-anywhere-work), **07.06.2022**: Microsoft'un hem müşteri hem ortak olduğu paragraf. Doğrudan sözleşme/bedel açıklaması değil.
- [DocuSign ödül açıklaması](https://investor.docusign.com/news-and-events/press-releases/news-details/2015/Digital-Transformation-Heroes-Receive-DocuSign-DTM-Awards-in-San-Francisco/default.aspx), **12.03.2015**: müşteri ödülleri ile partner ödülleri farklı gruplarda; Accenture partner grubunda. Bu ayrım müşterilik varsayımını engeller.
- [Sales Agreements e-kitabı](https://www.docusign.com/sites/default/files/resource_event_files/personalized_sales_agreements_for_more_efficient_sales_cycles.pdf): **PDF s.4 T-Mobile, s.6 Comcast**, s.7 tarih kodu **2020.08.10**. README'deki tarihsel kaynak korundu; bu denetimdeki yeni SEC okumaları tarihsel müşteri kullanımını destekler. Belge sürüm kodu ödeme günü değildir.

### 4.2 Satın alma kayıtları ve reddedilen sonuçlar

SEC EDGAR, şirket IR siteleri, resmî vaka sayfaları, SAM.gov ve USAspending alanlarında aday adlarıyla `paid subscription agreement`, `license contract`, `purchase order`, `enterprise subscription`, `software maintenance` ifadeleri arandı. Ayrıca 10-K müşteri/abonelik açıklamaları kontrol edildi. Arama, dünyanın tüm özel sözleşmelerini kapsamaz; **bulunamadı** ile **hiç ödeme yapılmadı** aynı iddia değildir.

| Bulgu / araştırma izi | Neden ödeme-A sayılmadı? |
| --- | --- |
| SEC dosyalarının üzerinde DocuSign Envelope ID bulunması | Başka bir alım/finansman sözleşmesinin imzalama aracını gösterebilir; yazılımı kimin satın aldığı ve ne ödediği çıkmaz. |
| [Comcast EIS sözleşme değişikliği](https://business.comcast.com/~/media/business_comcast_com/PDFs/Defined-Technologies-EIS-Contract/Modifications2/GS00Q17NSD3008%20%20P00426.pdf) | Arama sonucu telekom erişim hizmeti alımını gösteriyor; alıcı devlet, satıcı Comcast. DocuSign yazılımına Comcast ödemesi değil. Gövde bu denetimde okunmadı; arama izi olarak C. |
| [T-Mobile 2026 yatırımcı aylık raporu](https://s29.q4cdn.com/310188824/files/doc_downloads/2026/02/20260228-TMUST-2024-2-Investor-Report_FINAL.pdf) | Arama sonucundaki ödeme ifadeleri finansal menkul kıymet akışına ait; DocuSign lisansı değil. PDF gövdesi bu denetimde açılmadı. |
| [SAM 140D0425Q0760 ilanı](https://sam.gov/opp/6ed447a58c1f40258026d1d598e82073/view) | İndeks 26.11.2025 tarihli DOI/AVSO marka gerekçesi gösterdi; doğrudan açmada yalnızca sayfa kabuğu geldi. Devlet alıcısı Fortune şirketi değil; ilan da ödeme dekontu değildir. |
| [SAM DHA bilgi toplama ilanı](https://sam.gov/opp/ad87f8a0a3af46afabac5d9c12aa296b/view) | İndekste 23.06.2026 kaynak araştırması; ödeme veya sonuçlanmış satın alma diye sunulmadı. |
| [USAspending 75N97023P00098](https://www.usaspending.gov/award/CONT_AWD_75N97023P00098_7529_-NONE-_-NONE-) | İndekste HHS–FEDTRIBE yazılım bakım alımı çıktı; doğrudan açmada okunabilir işlem gövdesi yok. Miktarlar doğrulanmış gibi aktarılmadı. Alıcı Fortune şirketi değil. |
| JPMorgan bankacılık/lockbox veya alacaklı kayıtları | Bankanın rolü, DocuSign aboneliği satın alan müşteri olduğunu göstermez. |

**Son hüküm:** Comcast'ın kullanım/entegrasyon kanıtı güçlüdür; doğrudan ödeme şartı **D** kalır. Microsoft veya Salesforce'u birincil seçmek bu eksiği kapatmaz. Gelecekte isimli bir satın alma sözleşmesi bulunursa taraflar, ürün, bedel/taahhüt, tarih, belge sayfası ve ilgili Fortune üyelik yılı birlikte doğrulanmalı. Yalnızca pazarlama %95 beyanıyla ödeme ispatı tamamlanamaz.

## 5. SaaS portföyü ve harcama

| Kaynak | Doğrudan kontrol edilen yer | Değer / kapsam / tarih |
| --- | --- | --- |
| [Zylo 2026 SaaS Management Index](https://zylo.com/2026-saas-management-index) | Portföy büyüklüğü ve harcama istatistik kartları, About the Report | **305 ortalama / 240 medyan uygulama; 55,7 milyon $ ortalama / 20,6 milyon $ medyan yıllık SaaS harcaması.** Rapor yılı 2026; sayfada kesin yayın günü ve dört ölçünün tekil şirket dönemleri yok. |
| [Zylo tamamlayıcı yazı](https://zylo.com/blog/saas-statistics) | Aynı rapora atıflar | İkinci bağımsız örneklem değil; değişen yazıdan eski şirket büyüklüğü rakamları taşınmadı. |
| [BetterCloud State of SaaS 2025 PDF](https://pages.bettercloud.com/rs/719-KZY-706/images/BetterCloud-State-of-SaaS-2025.pdf#page=4) | **PDF s.4**, uygulama ortalaması | **106 uygulama**; rapor yılı 2025. Kesin yayın günü belirtilmiyor. [Açıklayıcı yazı](https://www.bettercloud.com/monitor/2025-state-of-saas-trends/) da kontrol edildi. |

Zylo'nun lisans ve yönetilen harcama büyüklükleri tek başına bu dört kartın şirket sayısını veya Fortune alt örneklemini açıklamaz. Kümülatif yönetilen veri ile mevcut rapor kohortu eşit sayılmadı. Ortalamalar büyük kurumlara duyarlıdır; medyanlar farklı özetlerdir. Hiçbiri tüm IT bütçesini ölçmez.

BetterCloud ayrı sağlayıcı/ayrı araştırmadır, fakat iki yayıncı da SaaS yönetimi satıcısıdır; tarafsız tam Fortune sayımı değildir. Farklı yıl, kurum büyüklüğü ve uygulama tanımları nedeniyle 106 ile 305'in ortalaması alınmaz. Fortune'a özel sayı/harcama serisi ve aynı tanımlı boyut kırılımları doğrulanamadı; tam raporun şirket bazlı verisi edinilmedi. README yalnızca kaynaklı örneklem ölçülerini verir.

## 6. LOC, ürün kapsamı, süre ve maliyet

### 6.1 Sayısal LOC ile özellik kanıtının ayrılması

[DocuSign FY2026 10-K](https://www.sec.gov/Archives/edgar/data/1261333/000126133326000021/docu-20260131.htm), **Item 1 Business**, IAM/eSignature/CLM ve kurumsal anlaşma yönetimini açıklar. Mali yıl **31.01.2026**, [SEC dosyalama kaydına](https://www.sec.gov/Archives/edgar/data/1261333/000126133326000021/0001261333-26-000021-index.html) göre dosyalama **18.03.2026**. [Identify](https://www.docusign.com/products/identify) kimlik ürününü, [Trust Center](https://www.docusign.com/trust) güvenlik/uyumluluk alanlarını destekler; bu iki sayfada kesin yayın günü yok. [eSignature API adresi](https://developers.docusign.com/docs/esign-rest-api/) açıldı ancak araçta ayrıntılı gövde çıkarılamadı; API kapsamının ayrıntıları yalnız bu sayfadan doğrulanmış sayılmadı.

Bu kaynaklar README'nin modül seçimini gerekçelendirir; hiçbirinde 300.000 LOC ölçümü bulunmadı. Bu sayı **kapsamdan modüllere tahsis edilen mühendislik varsayımıdır**. Modül payları toplanarak 300.000 elde edilir; geçmiş DocuSign kaynak kodu veya ekibin üretkenliği hakkında ölçüm değildir.

### 6.2 Ayrı açık kaynak ölçümü: DocuSeal

Kaynak: [DocuSeal sabit commit](https://github.com/docusealco/docuseal/tree/3c65b0e4ba872fe71d5566c0d09c3ace59a7fb8a). SHA: `3c65b0e4ba872fe71d5566c0d09c3ace59a7fb8a`; commit zamanı **12.10.2026 12:29:17 UTC**. 17 Ekim sonunu aşmayan public GitHub commit sorgusuyla seçildi; ZIP bellekte okundu, hiçbir dosya çalıştırılmadı. Karşılaştırma **n=1 açık kaynak proje**dir.

| Kategori | Dosya | Fiziksel satır | Boş olmayan satır |
| --- | ---: | ---: | ---: |
| app/ | 693 | 35.343 | 31.261 |
| test/ ve spec/ | 63 | 6.249 | 5.008 |
| Altyapı: config/, migration, lib/, bin/ ve kök build girdileri | 239 | 28.301 | 23.716 |
| **Toplam** | **995** | **69.893** | **59.985** |

Yöntem: UTF-8 metinde Python `splitlines()` ile fiziksel, `line.strip()` ile boş olmayan satır. Seçilen kaynak uzantıları `.rb`, `.erb`, `.js`, `.ts`, `.css`, `.scss`, `.yml`, `.yaml`, `.rake`, `.ru`, `.html`; ayrıca Gemfile/Rakefile/Dockerfile ve metin bin dosyaları. Vendor, public, node_modules, build/derlenmiş çıktılar, lock dosyaları, belgeler, DB şemaları ve binary dosyalar hariç. Boş olmayan satırlar yorumları içerir; parser tabanlı SLOC değildir. Altyapıdaki lib/ kodu da sayıldığı için sadece framework ayarı sayısı gibi okunmamalı.

Karşılaştırmanın amacı büyüklüğü görünür kılmaktır. DocuSeal'ın kapsamı, bağımlılıkları ve enterprise özellik sınırları DocuSign'la aynı değildir. **69.893 → 300.000 dönüşümü, katsayısı veya istatistiksel güven aralığı kurulmadı.** 300.000'in gerçekçi kesin değer olduğu bu tek gözlemden ispatlanamaz.

[Mevcut SignFlow ölçümü](RESEARCH_MEASUREMENTS.json) korundu: **131 dosya / 4.071 fiziksel / 3.570 boş olmayan satır**; uygulama/test/altyapı ayrımı README'de sürüyor. Bu tarihli yerel ölçüm, dış proje sayımından ve varsayımsal kurumsal üründen ayrıdır.

### 6.3 API hesabının yeniden doğrulanması

[Resmî OpenAI fiyat sayfası](https://developers.openai.com/api/docs/pricing) ve [GPT-5.4 model sayfası, Pricing](https://developers.openai.com/api/docs/models/gpt-5.4) açıldı. Standart kısa bağlam için **input 2,50 $/1M, output 15 $/1M** doğrulandı; cached input kullanılmadı. Yayın günü belirtilmiyor; fiyatın erişim tarihi 17.10.2026. Bu, gerçek SignFlow çağrılarında aynı modelin kullanıldığı anlamına gelmez.

Varsayımlar: L=300.000 satır; q=20 output token/satır; r=5 input/output; k tekrar/review katsayısı. O=L×q=6M; I=r×O=30M; C=k×(I/1M×2,50 + O/1M×15).

| Senaryo | Input | Output | Input bedeli | Output bedeli | Toplam |
| --- | ---: | ---: | ---: | ---: | ---: |
| k=1 | 30M | 6M | 75 $ | 90 $ | **165 $** |
| k=3 | 90M | 18M | 225 $ | 270 $ | **495 $** |
| k=5 | 150M | 30M | 375 $ | 450 $ | **825 $** |

Her isteğin kısa bağlam sınırında kaldığı varsayılır; toplam tokenı tek istekte göndermek anlamına gelmez. Uzun bağlam, cache, ücretli araç, ek reasoning, farklı model/fiyat veya tekrar deseni sonucu değiştirir. Bu model **toplam ürün geliştirme maliyeti değildir**.

Gerçek durum kullanıcının **17.10.2026 beyanı**: Codex / ChatGPT aboneliğine dahil kullanım; yaklaşık **1–2 saat** aktif süre; ayrı API faturası **0 $**; token sayısı ölçülmedi; abonelik payı bilinmiyor. Bu süre veya gerçek maliyet modelden geriye hesaplanmadı. Render Free seçimi de kullanıcı beyanıdır. [Render Free belgelerindeki](https://render.com/docs/free) **15 dakika uyku / 30 gün PostgreSQL erişim süresi / 14 gün yükseltme ek süresi** doğrudan kontrol edildi; abonelik bedeli sıfırmış veya veri süresiz kalıcıymış gibi sunulmadı.

README'deki iş kırılımı korundu: 6 odaklı saat/gün ile 44–72 saat → **8–12 iş günü**; şablonlarla 60–96 saat → **10–16 gün**. Kurumsal baz 460–720 mühendis-gün ×1,25 = **575–900**; beş mühendisle 115–180 gün ×1,20 = **138–216 iş günü**. Bunlar bu dokümantasyonun tahminleridir, sektör ölçümü veya kullanıcının gerçekleşmiş 1–2 saatinin yerine geçen süre değildir.

## 7. Gerçek yorum: doğrudan kaynak ile indeksin ayrılması

### 7.1 Capterra — açık kalan doğrulama

[Capterra yorumları](https://www.capterra.com/p/121506/Docusign/reviews/) üzerindeki istenen **17.08.2026** tarihli değerlendirme arama indeksinde başlık/tarih ve bağlamıyla bulundu. Doğrudan web açma içerik türü/erişim hatası verdi; normal HTTP GET **403** döndürdü. Kullanılabilir bağlı Browser oturumu bulunmadı. Bu nedenle yorumun tam sayfası, kalıcı bireysel bağlantısı ve PDF bakım şikâyetinin özgün gövdesi **doğrudan doğrulanmış değildir**. README'de eski çıkış noktası korunur fakat birincil doğrudan yorum kanıtı olarak kullanılmaz.

### 7.2 Doğrudan okunan alternatif: Liz Duffié

Kaynak: [TrustRadius bireysel değerlendirme](https://www.trustradius.com/reviews/docusign-2021-05-20-15-48-31?utm_campaign=product_guide&utm_medium=direct&utm_source=blog&utm_term=p). Sayfada görülen yayın tarihi **25.05.2021**, kullanıcı **Liz Duffié**, kurum **Parachute Home**, görev People & Culture yöneticisi, ürün **DocuSign for Enterprise**. **Pros and Cons** bölümünde şablonların daha esnek düzenlenmesi isteniyor. Yorum genel olarak olumlu; bütünüyle memnuniyetsizlik veya bütün kullanıcılar için şikâyet diye sunulmadı. URL'deki 20 Mayıs tarihi yayın tarihi yerine alınmadı.

Keşif kaynağı [TrustRadius ürün rehberi](https://solutions.trustradius.com/buyer-blog/docusign-product-guide/), **02.07.2024**, Template Creation and Management bölümündeki bağlantıdır. Özgün yorumun gövdesi bağlantı üzerinden gerçekten açılıp okundu. Sonraki bir web aracı tekrarında hata alındı; ardından normal HTTP GET yeniden **200** verdi ve aynı sayfada tarih, yazar, kurum ve düzenleme ihtiyacı bulundu. Böylece rehber özetine dayanmakla yetinilmedi. Erişimin her zaman sorunsuz olduğu iddia edilmez.

Aynı rehberin atıf verdiği [11.01.2023 Emily Wallace yorumu](https://www.trustradius.com/reviews/docusign-2023-01-09-14-52-06?utm_campaign=product_guide&utm_medium=direct&utm_source=blog&utm_term=p) da açıldı; görülen Cons bölümü hesap/envelope aktarımı hakkındaydı. Rehberin alan hizalama anlatımı bu özgün yoruma kontrolsüzce atfedilmedi. G2 ve Software Advice denemeleri okunabilir gövde vermedi; GetApp sonuçları bu konuda tarihli bireysel alternatif kanıt yerine konmadı.

**İhtiyaç–çözüm eşlemesi:** [Renderer](../app/services/templates/renderer.rb) yalnız desteklenen beş adın metindeki alt kümesini algılar, değerleri kullanıcı girer. [Önizleme](../app/controllers/template_documents_controller.rb) sunucu tarafında kayıt oluşturmadan üretir. [Şablon servisi](../app/services/templates/manage.rb) her düzenlemeyi yeni sürüme yazar, [TemplateVersion](../app/models/template_version.rb) kayıt sonrası değişmezdir. [Belge üretim servisi](../app/services/documents/manage.rb) metnin bağımsız kopyasını oluşturur; [Document](../app/models/document.rb) gönderilen metni korur. Bunlar metin düzenleme ve güvenli güncelleme ihtiyacına somut karşılıktır.

**Sınır:** PDF koordinatlama/alan hizalama editörü, gerçek kimlik doğrulaması veya bildirim otomasyonu yok. Beş alan için veri otomatik bulunmaz; kullanıcı girişinden metin üretilir. Liz ile kullanıcı deneyi yapılmadı, zaman tasarrufu ölçülmedi. 100 çözümü **metin şablonu düzenleme** kapsamında savunulur; Capterra'daki tüm PDF sorununu çözdüğü ileri sürülmez.

Sunum cümlesi README'de doğrudan doğrulanan bu kullanıcı, tarih ve sınırlı çözüm üzerinden güncellendi.

## 8. Kaynak güvenilirlik ve çapraz doğrulama tablosu

Tüm satırların **erişim tarihi 17.10.2026**. Yayın tarihi bulunmayan kaynaklara tahmini gün eklenmedi. “İki kaynak” sayısı, bağımsız ölçüm sayısı değildir.

| İddia / kaynak | Yayın / veri tarihi | Kontrol yeri ve erişim | Not |
| --- | --- | --- | --- |
| [Fortune liste duyurusu](https://fortunemedia.mediaroom.com/2026-06-03-Amazon-Claims-No-1-Spot-on-the-Fortune-500) | 03.06.2026 / 2026 liste, FY2025 gelirleri | Liste tanımı, toplam çalışan ve değer lideri; gövde okundu | **A**, yayımlayıcının kendi listesi. |
| [Fortune Analytics](https://fortune.com/analytics/fortune-500) | Gün yok / 2026 veri ürünü | Alanlar okundu; tam veri edinilmedi | Alan tanımı **A**, tam uçlar **D**. |
| İlk yedi [Fortune profilinin tablosu](#21-gerçekten-kontrol-edilen-yedi-şirket) | Güncellemeler ve fiyat günleri tablo 2.1'de | Finansal/çalışan alanları + açık HTML yıl-sıra kaydı | Profil verileri **A**; yeni tam liste sonucu bölüm 13'te. |
| [CMC tarihli sıralama](https://companiesmarketcap.com/time-machine/2026-08-14/) | 14.08.2026 veri anı | Dünya sıralaması; tablo okundu | **C**, ikincil veri derleyicisi; farklı tarih. |
| [BitGo SEC](https://www.sec.gov/Archives/edgar/data/1740604/000174060426000020/btgo-form10xk.htm) | 27.03.2026 / 31.12.2025 | Human Capital; gövde okundu | **A**, 603 full-time. |
| [Gold SEC PDF](https://www.sec.gov/Archives/edgar/data/1591588/000119312525227653/amrk_ars_fy_25.pdf#page=15) | 10-K 11.09.2025; yıllık paket mektubu Ekim 2025 / veri 30.06.2025 | PDF s.15 / basılı s.12; doğrudan metin okundu | **A**, 993; Fortune 975 için yöntemle uyumlu çıkarım bölüm 13.2'de. |
| [Walmart duyuru](https://corporate.walmart.com/news/2026/04/23/walmart-releases-2026-annual-report-and-proxy-statement) | 23.04.2026 / FY2026 | Dünya toplamı; gövde okundu | **A**, yaklaşık toplam, FTE değil. |
| [Comcast vaka](https://www.docusign.com/sites/default/files/resource_event_files/docusign_case_study-comcast__2.pdf) | Belirtilmiyor / tarihsel uygulama | PDF s.1–2 okundu | Kullanım **A**, ödeme **B**. |
| [DocuSign S-1](https://www.sec.gov/Archives/edgar/data/1261333/000119312518099555/d506878ds1.htm) | 28.03.2018 / tarihsel müşteriler | Customers, basılı s.88–91 okundu | İsimli müşteri **A**, doğrudan ödeme **D**. |
| [Microsoft açıklaması](https://www.docusign.com/company/news-center/docusign-and-microsoft-deepen-relationship-to-accelerate-anywhere-work) | 07.06.2022 / o tarihteki ilişki | Müşteri ve ortak paragrafı okundu | Kullanım **A**, ödeme **B**. |
| [2015 ödüller](https://investor.docusign.com/news-and-events/press-releases/news-details/2015/Digital-Transformation-Heroes-Receive-DocuSign-DTM-Awards-in-San-Francisco/default.aspx) | 12.03.2015 / aynı dönem | Müşteri/partner ayrımı okundu | Rol bilgisi **A**; Accenture müşteri varsayımı **D**. |
| [Why Docusign](https://www.docusign.com/why-docusign) | Yayın günü yok / güncel pazarlama sayfası | Fortune kullanım yüzdesi gövdede görüldü | Beyanın varlığı **A**, bağımsız doğruluğu **B**, isimli ödeme **D**. |
| [SAM ilanı](https://sam.gov/opp/6ed447a58c1f40258026d1d598e82073/view) | İndeks 26.11.2025 | Gövde değil indeks/kabuk | **C**; Fortune ödeme şartı **D**. |
| [USAspending kaydı](https://www.usaspending.gov/award/CONT_AWD_75N97023P00098_7529_-NONE-_-NONE-) | İndeks 2023–2026 alım dönemi | İşlem gövdesi açılamadı | **C** araştırma izi; miktar doğrulanmadı. |
| [Zylo](https://zylo.com/2026-saas-management-index) | Gün yok / 2026 rapor | Dört kart ve örneklem açıklaması okundu | Örneklem ölçüleri **A**, Fortune genellemesi **D**. |
| [BetterCloud PDF](https://pages.bettercloud.com/rs/719-KZY-706/images/BetterCloud-State-of-SaaS-2025.pdf#page=4) | Gün yok / 2025 | PDF s.4 okundu | Kendi örneklemi için **A**. |
| [DocuSign FY2026 10-K](https://www.sec.gov/Archives/edgar/data/1261333/000126133326000021/docu-20260131.htm) | 18.03.2026 / 31.01.2026 | Item 1 Business okundu | Ürün kapsamı **A**, gerçek LOC **D**. |
| [DocuSeal commit](https://github.com/docusealco/docuseal/tree/3c65b0e4ba872fe71d5566c0d09c3ace59a7fb8a) | 12.10.2026 / o SHA | ZIP kaynaklarında ayrı sayım | Kapsamlı yerel ölçüm **A**, DocuSign LOC çıkarımı **D**. |
| [GPT-5.4 resmî fiyat](https://developers.openai.com/api/docs/models/gpt-5.4) | Gün yok / erişilen tarife | Pricing bölümü okundu | Tarife **A**, gerçek SignFlow token/maliyet hesabı **D**. |
| [TrustRadius Liz](https://www.trustradius.com/reviews/docusign-2021-05-20-15-48-31?utm_campaign=product_guide&utm_medium=direct&utm_source=blog&utm_term=p) | 25.05.2021 / kişisel deneyim | Özgün sayfa, tarih, yazar ve Cons; GET 200 | Gerçek yorumun içeriği **A**, bütün kullanıcılar için sonuç değil. |
| [Capterra](https://www.capterra.com/p/121506/Docusign/reviews/) | İndeks 17.08.2026 | Doğrudan GET 403; gövde okunamadı | İndeks **C**, doğrudan doğrulama **D**. |
| [Render Free](https://render.com/docs/free) | Gün yok / erişilen politika | Free web ve Free Postgres bölümleri okundu | Politika **A**, kullanıcının hesabı/başlangıç günü **D**. |
| [Gerçek uzak CI](https://github.com/Huseyinyagmur/signflow/actions/runs/39058528378) | 17.10.2026 / belirtilen commit | Actions runs/jobs API yanıtları okundu | Dört iş sonucu **A**; canlı tarayıcı akışı değil. |

**Birden fazla kaynakla desteklenen iddialar:** BitGo 603, SEC + Fortune; Walmart toplamı, şirket + Fortune; Nvidia lider şirketi, Fortune + CMC (farklı tarihler); Comcast kullanımı, vaka + SEC S-1. İlk iki çiftte Fortune şirket raporundan türemiş olabilir; ayrı yayıncı her zaman bağımsız gözlem değildir. Comcast'ın iki belgesi de DocuSign beyanıdır, iki bağımsız müşteri denetimi değildir. Zylo ölçülerini BetterCloud doğrulamıyor; iki ayrı örneklem veriyor. Liz yorumu ve aynı platformun rehberi de iki bağımsız kullanıcı kanıtı sayılmaz.

## 9. Uygulama, CI ve test kanıtlarının sınırı

**Bu araştırmada gerçek okuma kontrolleri:** Canlı [ana sayfa](https://signflow-k2tg.onrender.com/) ilk GET denemesinde zaman aşımına uğradı; sonraki GET **200**, SignFlow metni mevcut, DocuSign metni yok. Bu kayıt/imza testi değildir; uyku veya geçici ağ gecikmesi için tek başına tanı da koymaz. Yerel `rg -n -i docusign app` eşleşme vermedi; bu görsellerdeki tüm marka unsurlarının veya her canlı ekranın denetimi değildir.

**Uzak CI gerçekten kontrol edildi:** [39058528378](https://github.com/Huseyinyagmur/signflow/actions/runs/39058528378), `main` push, SHA `d8dbf7994afccc3162662a3d4a4e9978bca9f11c`; scan_ruby, scan_js, lint, test işleri **success**. Son güncelleme **17.10.2026 18:33:09 UTC / 21:33:09 Türkiye**. Kaynak: [workflow runs API](https://api.github.com/repos/Huseyinyagmur/signflow/actions/workflows/ci.yml/runs?branch=main&per_page=1) ve [run jobs API](https://api.github.com/repos/Huseyinyagmur/signflow/actions/runs/39058528378/jobs). Yeni iş tetiklenmedi; bu SHA son yerel doküman değişikliklerini kapsamaz.

**Kod incelemesi:** [Document](../app/models/document.rb), [Signing](../app/services/documents/signing.rb), [Expiration](../app/services/documents/expiration.rb) merkezî geçişleri ve Time.current kontrolünü korur. [Model testleri](../test/models/document_test.rb), [workflow testi](../test/integration/signflow_workflow_test.rb) içinde travel_to ve mikrosaniyeli sınırlar görüldü; [şablon regresyonu](../test/integration/template_schema_regression_test.rb) kayıt oluşturmayan önizleme ve devam akışına kanıt sağlar. Bu turn'de testler çalıştırılmadı.

**Tarihsel yerel otomatik sonuç:** [Önceki kontrol kaydı](RESEARCH_VERIFICATION.md), 17.10.2026: **92 test, 900 assertion, 0 failure/error/skip**. Bu sonuç yeni tarayıcı testi veya yeni test koşusu değildir. **Kullanıcı beyanı**, aynı tarih canlı Render: oturum **5/5**, normal belge **6/6**, şablon **8/8**, restart sonrası kalıcılık **başarılı**. Adım logları bağımsız görülmedi; bu oranlar Codex otomasyonu diye sunulmadı.

## 10. README değişiklikleri ve kalan riskler

README tümden yeniden yazılmadı. Üst özet, canlı URL/rozet, yerel kullanım, Render rehberi, zaman kuralları, gerçek ölçümler, manuel test beyanı, AGENT bağlantısı ve Yapamadıklarım korundu. Değişen araştırma alanları:

1. Değerleme tanımları; yedi örnek, üç şirketlik aynı gün alt kümesi, sıra doğrulama yöntemi ve dışlanan NGL.
2. Çalışan tanımları, üç ilave aday ve Gold.com SEC/Fortune çelişkisi.
3. Comcast SEC desteği, alternatif adaylar ve açık ödeme eksikliği.
4. Zylo yeniden doğrulaması ve ayrı BetterCloud örneklemi.
5. Resmî ürün kapsamı, sabit SHA'lı DocuSeal ölçümü, fiyat ve tekrar hesabı.
6. Doğrudan Liz yorumu, beş özellik için somut eşleştirme ve yeni sunum cümlesi; eski Capterra bağlamı silinmedi.
7. Doğrulanmış uzak CI run/commit bilgisi ve madde madde teslim durumu.

**Güncellenen riskler:** 500 şirketlik açık liste artık incelendi; 472 piyasa alanının her birinin ortak günü bağımsız doğrulanmadı. Çalışan uçları Fortune ölçüsünde bulundu, ancak bu alanlar standart FTE değildir. Gold farkı yöntemle uyuşur; şirket bazlı açıklama yok. Doğrudan Fortune müşterisi ödeme belgesi hâlâ yok; T-Mobile alınan güncel ABD listesinde bulunmuyor. Capterra gövdesi, gerçek token/abonelik payı, kullanıcı etki deneyi ve bağımsız canlı tarayıcı testi eksikleri; Free PostgreSQL süre sınırı korunur. Araştırma eksikliği uygulama güvenliğini gevşeterek kapatılmadı.

## 11. Nihai 0/85/100 denetimi

| Gereksinim | Durum | Gerekçe |
| --- | --- | --- |
| 0 riski — canlı URL | Tamamlandı | Ana sayfa GET 200; uçtan uca davranış iddiası yok. |
| 0 riski — çalışan aort dilimi | Kısmi | Kod/test kanıtı ve kullanıcı beyanı; bu çalışmada bağımsız canlı uçtan uca deney yok. |
| 0 riski — özgün marka | Kısmi | app/ metin taraması temiz; bütün canlı ekranlar görsel incelenmedi. |
| 0 riski — uydurma test olmaması | Tamamlandı | Beyan/önceki test/uzak CI ayrıldı. |
| 85 — Fortune ticari müşterisi | Tamamlandı | Comcast üyeliği ve kullanım vakası. |
| 85 — Fortune şirketinin para ödemesi | Doğrulanamadı | Ödeme-A yok; ödeme-B ile karıştırılmadı. |
| 85 — Faz 1 | Kısmi | 500 çalışan / 472 piyasa değeri üzerinden liste uçları var; tüm piyasa satırlarının ortak tarih kontrolü açık. |
| 85 — Faz 2 | Tamamlandı | Kapsam/LOC/API/süre modeli; varsayım etiketli. |
| 85 — yeşil CI | Tamamlandı | Bağlantılı belirli run/commit başarılı. |
| 85 — travel_to durum/zaman testleri | Tamamlandı | Kod var; önceki koşu ayrı kayıtlı, yeniden koşulmadı. |
| 85 — AGENT.md | Tamamlandı | Okundu, bağlantısı ve içeriği korundu. |
| 85 — Yapamadıklarım | Tamamlandı | Eksikler açık ve korunmuş. |
| 100 — 85'in tamamı | Kısmi | Doğrudan ödeme ve ortak piyasa tarihi eksikleri kapanmadı. |
| 100 — gerçek kullanıcı yorumu | Tamamlandı | Doğrudan erişilen tarihli TrustRadius alternatifi. |
| 100 — çalışan hedef çözüm | Kısmi | Mevcut metin şablonu kodu ve kullanıcı testi; PDF/etki ölçümü yok. |

Bu tablo not ilanı değildir. Kanıtsız “85/100'ün tümü tamamlandı” iddiası yerine eksik veri/belge gereksinimini görünür kılar.

## 12. Son dosya ve bağlantı kontrolleri

**Aşağıdaki sayılar önceki denetimin tarihsel kontrol kaydıdır.** Bölüm 13 güncellemesinden sonraki kontroller ayrıca bölüm 13.4'te kaydedilir; eski test/link sayıları yeni koşu gibi sunulmaz.

17.10.2026 tarihinde README ve bu raporda yapılan gerçek kontroller:

- **25 Markdown tablosu:** satır sütun sayıları tutarlı; UTF-8 replacement character bulunmadı. Yerel Markdown başlık bağlantıları hedefleriyle eşleşti.
- **38 benzersiz yerel dosya hedefi:** hepsi mevcut. Bu kontrol dosyaların içindeki her komutun çalıştırıldığı anlamına gelmez.
- **63 benzersiz dış HTTP hedefi** (PDF fragment'leri aynı HTTP hedefinde birleştirildi): **52 HTTP 200, 10 HTTP 403, 1 zaman aşımı**. HTTP 200 yalnızca erişim kontrolüdür; ilgili pasajların okunması ayrıca yukarıda belirtilmiştir.
- Normal HTTP kontrolünde SEC belgeleri, Fidelity, DocuSign'ın 2015 IR açıklaması, TrustRadius rehberi, BetterCloud yazısı ve Capterra erişim engeli verdi. Bazılarının gövdeleri araştırma web aracında okunabildi; bu erişim farkı gizlenmedi. Comcast kamu sözleşmesi zaman aşımına uğradı ve zaten yalnız araştırma izi olarak kullanıldı. Capterra bu iki yolda da özgün gövde kanıtı sağlamadı.
- DocuSeal sayım toplamları ve API/iş günü aritmetiği tekrar hesaplandı; tutarlı. Sayım fiziksel satır ölçümüdür; kaynak kodu çalıştırılmadı.
- Başlangıç SHA-256 kaydıyla karşılaştırılan **87 dosyada** (uygulama/test kapsamı ve AGENT.md) değişiklik yok. Git çalışma ağacındaki teslim değişiklikleri yalnız **README.md** ve yeni **docs/FINAL_EVIDENCE_AUDIT.md**. Geçmiş araştırma belgeleri korunuyor.
- `git diff --check`: **başarılı**, whitespace hatası yok. Rails/Minitest/RuboCop/Zeitwerk bu araştırmada çalıştırılmadı; yeni test başarısı iddia edilmedi. Veritabanına dokunulmadı, deploy/commit/push yapılmadı.

Erişim engeli bir bağlantının yanlış olduğunu veya belgenin içeriğinin hiçbir istemcide görülemediğini tek başına göstermez. Buna karşılık arama indeksinin varlığı da okunmayan özgün belgeyi doğrudan doğrulanmış yapmaz.

## 13. Son iki kanıt için genişletilmiş araştırma

**İkinci araştırmanın erişim tarihi yine 17.10.2026.** Yalnız README ve bu rapor güncellendi. Bu bölüm, önceki dar veri kapsamını genişletir; aşağıdaki sonuçlar bölüm 2.1'deki yedi profil örneğinin yerine geçen **liste düzeyi** hesaptır. Ödeme sonucu ise olumsuz kalmıştır. Yeni uygulama testi, ödeme, abonelik veya veri satın alma işlemi yapılmadı.

### 13.1 Kaynak ve tam liste kapsamı

Kaynak: [Fortune 500 — 2026 resmî sıralaması](https://fortune.com/ranking/fortune500/). Normal, kimlik doğrulamasız HTTP GET **200** yanıtının HTML'sindeki `script#__NEXT_DATA__` JSON'u okundu. Yol: `props.pageProps.franchiseSearch.items`; metodoloji: `props.pageProps.franchise.methodology`. Bu kamuya açık sayfanın verisidir; ücretli API veya satın alınmış Analytics dosyası değildir. Web metin çıkarıcısı yalnız ilk on şirketi gösterirken HTML cevabı daha geniş tabloyu taşıyordu; önceki dar sonuç bu veri yolunu kullanmamıştı.

**Yıl/sürüm:** `franchiseSearch.year = "2026"`; yayın `dateGmt` zaman damgası **03.06.2026 09:10:22 UTC**, kaynak `modifiedGmt` alanı **05.10.2026 19:37:51**. Bu yayın/güncelleme zamanları fiyatın ölçüm tarihi değildir. Girdi 1.000 kayıt içeriyordu; yalnız sıra **1–500** seçildi. Global/Europe/2025 verisi eklenmedi.

| Kontrol | Gerçek sonuç | Kanıt düzeyi / sınır |
| --- | ---: | --- |
| 2026 ABD üyelik kaydı | 500 benzersiz şirket / %100 | **A**; ad ve slug tekilliği kontrol edildi. |
| Benzersiz sıra numarası | 498 | **A**; 160 ve 350'de eşit sıralar var. Şirketleri sıra alanına göre tekilleştirmek yanlışlıkla iki üyeyi silerdi. |
| Dolu piyasa değeri | 472 / %94,4 | **A**; bütün 500 üyeye oran. Halka açık şirketler için ayrıca bağımsız eksiksiz evren kurulmadı. |
| Boş piyasa değeri | 28 / %5,6 | **A**; sıfır veya tahmini değer atanmadı. |
| Dolu çalışan alanı | 500 / %100 | **A**; yayımlayıcının ölçüsü, 500 bağımsız rapor denetimi değil. |
| Ek açılan üye profili | 59 / %11,8 | **A**; 28 boş piyasa alanı + küçük/büyük uç adayları + müşteri adayları; çakışmalar tek sayıldı. |
| Ticker metni bulunan profil | 32 | **A** alan okuması; 31 dolu market-cap satırı + boş değerli Continental Resources. Tüm 472 şirket için ticker eşleşmesi tamamlanmadı. |

**Boş piyasa değeri olan 28 üye:** State Farm Insurance (32), New York Life Insurance (62), Nationwide (69), Publix Super Markets (72), United Services Automobile Assn. (93), TIAA (94), Liberty Mutual Insurance Group (95), Massachusetts Mutual Life Insurance (100), Northwestern Mutual (109), CHS (130), GuideWell Mutual Holding (140), American Family Insurance Group (226), Guardian Life Ins. Co. of America (232), Pacific Life (240), Auto-Owners Insurance (241), Peter Kiewit Sons' (242), Jones Financial (Edward Jones) (249), Farmers Insurance Exchange (271), Land O'Lakes (273), Mutual of Omaha (288), Erie Insurance Group (308), Western & Southern Financial Group (321), Graybar Electric (342), Thrivent Financial (387), FM (392), Ace Hardware (419), Securian Financial Group (457), Continental Resources (493). Kaynak: yukarıdaki resmî tablo; 17.10.2026. Bunlar çalışan karşılaştırmasından çıkarılmadı.

**Ticker tuzağı:** İlk 27 boş piyasa değerli profil `Ticker=None`, Continental Resources profilinde `CLR` metni verdi. Bu eski bir simge olabilir; alanın dolu olması güncel halka açıklık kanıtı sayılmadı. Continental için yapay piyasa değeri hesaplanmadı. Yedi önceki örnekten farklı olarak bütün üyelerin **liste satırı** okundu, fakat bütün üyelerin 10-K/fiyat serisi okunmuş gibi gösterilmez.

**Tekrar üretme yöntemi:** Aşağıdaki araştırma kodu Rails'i başlatmaz veya veritabanına bağlanmaz. Python ortamında BeautifulSoup (`beautifulsoup4`) bulunmalıdır; bu bir uygulama bağımlılığı önerisi değildir. Buradaki çalışmada paket zaten mevcuttu. Dinamik kaynak sonradan değişirse yeni sonuç/sürüm açıkça kaydedilmelidir.

```python
import hashlib
import json
import urllib.request
from bs4 import BeautifulSoup

url = "https://fortune.com/ranking/fortune500/"
with urllib.request.urlopen(url, timeout=30) as response:
    html = response.read().decode("utf-8")
page = json.loads(BeautifulSoup(html, "html.parser")
                  .find("script", id="__NEXT_DATA__").string)
source = page["props"]["pageProps"]["franchiseSearch"]
assert str(source["year"]) == "2026"
rows = [r for r in source["items"] if 1 <= int(r["rank"]) <= 500]
assert len(rows) == len({r["slug"] for r in rows}) == 500

def number(value):
    if value is None or not str(value).strip():
        return None
    return float(str(value).replace("$", "").replace(",", ""))

for field in ("Market Value ($M)", "Employees"):
    observed = [(number(r["data"].get(field)), r["name"], r["rank"])
                for r in rows if number(r["data"].get(field)) is not None]
    print(field, len(observed), min(observed), max(observed))

canonical = [{"rank": r["rank"], "name": r["name"], "slug": r["slug"],
              "market_value_millions": r["data"].get("Market Value ($M)"),
              "employees": r["data"].get("Employees")} for r in rows]
payload = json.dumps(canonical, ensure_ascii=False, sort_keys=True,
                     separators=(",", ":")).encode("utf-8")
print("SHA-256", hashlib.sha256(payload).hexdigest())
```

UTF-8 açıkça çözümlenmiş kanonik 500 kaydın SHA-256'sı: `824de666dd5201b31349f153d7283991c4332d7be358b7295663018e45c58349`. İlk ayrıştırmada otomatik karakter kodlaması iki şirket adını bozdu; UTF-8 açık çözümleme ile düzeltildi. Sayısal alanlar ve uçlar değişmedi. Hash, gerçeğin bağımsız ispatı değildir; kullanılan açık verinin sürümünü karşılaştırmayı sağlar. Tam ticari veri seti veya uzun yayın metni repoya kopyalanmadı; yalnız yöntem, kapsam ve türetilen sonuçlar raporlandı.

### 13.2 Uçlar, tarihler ve ölçü tanımları

| Ölçü / uç | Şirket / 2026 sırası | Değer | Ölçüm dönemi / kontrol edilen konum | Düzey |
| --- | --- | ---: | --- | --- |
| Liste piyasa değeri minimumu | QVC Group / 433; QVCGA | **18,9 milyon $** | Liste `Market Value ($M)` alanı 18.9; [QVC profili](https://fortune.com/company/qurate-retail/), Company Information dipnotu **31.03.2026**. | **A**, 472 dolu satırın minimumu. |
| Liste piyasa değeri maksimumu | Nvidia / 16; NVDA | **4.237.920 milyon $ = 4,23792 trilyon $** | Liste alanı; [Bridgeway Aggressive Investors 1 bilgi formu](https://bridgewayfunds.com/wp-content/uploads/sites/2/2026/04/MF-Aggressive-Investors-BRAGX-1-1.pdf#page=1), **PDF s.1**, Top Ten Issuers / Market Cap ($mil); Portfolio Date **31.03.2026**. Yayın günü belirtilmiyor, URL Nisan 2026 klasöründe. | Fortune tablosu **A**, ayrı fon yayınındaki tutar/tarih desteği **B**; fon fiyat verisini derler. |
| Çalışan minimumu | BitGo Holdings / 278; BTGO | **603** | 500 liste satırı; [10-K Human Capital](https://www.sec.gov/Archives/edgar/data/1740604/000174060426000020/btgo-form10xk.htm), **31.12.2025**, 603 full-time; dosyalama **27.03.2026**. | **A**, Fortune ölçüsünde tüm liste karşılaştırması + uç için şirket raporu. |
| Çalışan maksimumu | Walmart / 2; WMT | **2.100.000** | 500 liste satırı; [23.04.2026 şirket duyurusu](https://corporate.walmart.com/news/2026/04/23/walmart-releases-2026-annual-report-and-proxy-statement), Annual Report Highlights ve About Walmart, **FY2026 dünya toplamı yaklaşık 2,1 milyon**. | **A**, Fortune ölçüsünde tüm liste karşılaştırması + şirket açıklaması. |

**Yakın uç adayları da sıralandı:** Piyasa değerinde QVC'den sonra Accendra Health (407) **174,3 milyon $**, Community Health Systems (350, eşit sıra) **407,6 milyon $**; Nvidia'dan sonra Apple (4) **3.725.926,5 milyon $**. Çalışanda BitGo'dan sonra Galaxy Digital (76) **700**, Welltower (401) **712**, Gold.com (398) **975**; Walmart'tan sonra Amazon (1) **1.576.000**. Bütün bu değerler aynı resmî **2026 liste tablosunun alanlarıdır**, bağımsız şirket değerlemesi değil. Erişim: 17.10.2026. Böylece BitGo ve QVC yalnız önceden seçilmiş örnekler oldukları için uç ilan edilmedi.

**Ortak tarih sınırı:** Liste satırlarında ayrı fiyat tarihi bulunmuyor. QVC'nin dipnotu ve Nvidia'yla aynı rakamı taşıyan Bridgeway formu uçların **31 Mart** referansını destekler. Bununla birlikte **472 satırın her birinin** 31 Mart fiyatı/hisse adedi yeniden toplanmadı; bu yüzden bağımsız ve tamamen aynı tarihli yeniden değerleme olarak A verilmedi. Güncel Nvidia profili **24 Eylül / 5,44539 trilyon $** taşır; bu rakam dondurulmuş liste alanına yazılmadı. Benzer şekilde güncel Walmart/Comcast profillerinin Ağustos değerleri eski liste tablosuyla birleştirilmedi.

**Çalışan metodolojisi artık doğrudan okundu:** Resmî liste JSON'undaki `methodology`, **Employees** başlığı mali yıl sonu çalışanını ve ayrım mevcutsa part-time kişilerin **yarım** sayılmasını açıklar. **Revenues** başlığı mali yılların **31.01.2026 veya öncesinde** bittiğini, aksi belirtilmedikçe dönemin **31.12.2025** olduğunu söyler. Bu karma uygulama herkes için aynı saat bazlı FTE hesabı değildir. Kaynak: resmî sıralama sayfası, yayın/güncelleme tarihleri bölüm 13.1; erişim 17.10.2026. Yayımlayıcı ölçüsünde çalışan uçları A, tüm şirketlerin standart ham headcount/FTE uçları D'dir.

**Gold.com hesabı:** [2025 yıllık rapor PDF s.15 / basılı s.12, Human Capital](https://www.sec.gov/Archives/edgar/data/1591588/000119312525227653/amrk_ars_fy_25.pdf#page=15) yeniden açılıp okundu: **30.06.2025'te 993 toplam**, bunların **37'si hariç tamamı full-time**. Fortune'un kuralını uygularsak 956+18,5=974,5; yarımı yukarı yuvarlama varsayımıyla **975** olur. Bu, iki kaynağın yöntemleriyle **uyumlu açıklama (B)**; doğrudan şirket/Fortune teyitli neden değildir. PDF'deki hissedarlara mektup **Ekim 2025** tarihli; içerdiği 10-K'nin 11 Eylül tarihi tüm yıllık rapor paketinin yayın günüyle karıştırılmamalı.

**BitGo sıra çelişkisi:** [Şirketin 10.06.2026 duyurusu](https://investors.bitgo.com/news/news-details/2026/BitGo-Holdings-Named-to-2026-Fortune-500-in-First-Year-as-a-Public-Company/default.aspx) **273** der; erişilen Fortune tablosu/profili **278** der. Bu raporda **alınan Fortune sürümünün 278 sırası** kullanıldı. Çelişkinin nedenine ilişkin düzeltme duyurusu bulunmadı; sessizce birleştirilmedi. İki kaynak üyeliği destekler, aynı sırayı desteklemez. Çalışan minimumunu bu sıra farkı değiştirmez.

**T-Mobile kapsam kararı:** Tam 500 kayıtta ad/slug yok; profilin eksik satırından hareketle belirsizlikte bırakmak yerine **bu veri sürümünde güncel üyelik örneği olarak dışlandı**. Accenture ve Neiman Marcus da bu 500 şirket içinde yok. Dışlanmanın her şirket için hukuki/kurumsal nedeni bu denetimde araştırılmış sayılmaz.

### 13.3 Genişletilmiş ödeme araması ve reddedilen kanıtlar

Comcast ve T-Mobile önce yeniden araştırıldı. Comcast'ın resmî PDF'si tekrar açıldı; ücret/fatura bulunmadı. Ardından Microsoft, Salesforce, Verizon, Walmart, FedEx, Fannie Mae, QVC, Hertz, PG&E, Duke Energy, HP, Costco, Cisco, UnitedHealth ve dağıtıcı kanalı adaylarına geçildi. SEC'in S-1/10-K/proxy bölümleri, şirket portalları, resmî satın alma ve mahkeme kayıtları araştırıldı. `paid`, `subscription fees`, `annual contract value`, `purchase order`, `license agreement`, `invoice`, `disbursements`, `related person transactions` terimleri şirket adlarıyla birleştirildi. Hiç sonuç vermeyen sorgular da sonuç yok olarak değerlendirildi; şirketler müşteri varsayılmadı.

Yeni şirketlerin üyeliği de aynı tam listeden kontrol edildi: **QVC 433, Hertz 465, PG&E 185, Duke Energy 145, FedEx 50, Fannie Mae 26, HP 84, Costco 13, Cisco 83, UnitedHealth 3, Ingram Micro 90, CDW 205**. Bunların sıralarının bilinmesi DocuSign müşteriliğini/ödemesini kanıtlamaz. World Wide Technology/SHI aramaları da yapıldı; adları ilgisiz alt dizgelerle eşleştirilip Fortune üyesi sayılmadı.

| Yeni birincil belge / URL | Yayın/veri tarihi ve gerçekten okunan yer | Ne kanıtlar / ne kanıtlamaz? | Düzey |
| --- | --- | --- | --- |
| [DocuSign Eylül 2018 S-1](https://www.sec.gov/Archives/edgar/data/1261333/000119312518270936/d614105ds1.htm) | 2018 dosyalaması; Customer Case Studies, basılı **s.96** ve devamı, FY2018 ACV giriş paragrafı; Customers ve Related Party bölümleri okundu | İsimli vaka grubunun yıllık sözleşme değerinin artışı ticari niteliği destekler; aralıktaki katsayı şirket bazında ayrılmıyor. İmzalı müşteri ücret sözleşmesi/ödeme kaydı değil. | **B**, A'ya yükseltilmedi. |
| [DocuSign 2021 proxy](https://www.sec.gov/Archives/edgar/data/1261333/000126133321000071/def14a2021.htm) | 2021; **Transactions With Related Persons, basılı s.58–59** | Politika ve tazmin düzenlemeleri incelendi; isimli Fortune müşterisinin yazılım bedeli bulunmadı. 120.000 $ açıklama eşiği müşteri faturası değildir. | Ödeme iddiası **D**. |
| [Detroit Purchase Order 3083653](https://detroitmi.gov/sites/detroitmi.localhost/files/contracts/3083/PO_3083653.pdf#page=2) | **01.05.2025**, PDF **s.1** bağlayıcı taahhüt; **s.2** 16.478 $ tutar ve DoIT'in DocuSign fatura ödemesi talebi | Gerçek satın alma kaydı; iki DocuSign faturasına atıf var. **Alıcı City of Detroit**, Fortune şirketi değil. Ayrıca emir kaydı nakdin kesin çıkışını tek başına göstermez. | Bağlayıcı kamu alımı için **A**, istenen Fortune şartı için **D**. |
| [Neiman Marcus Schedule G](https://cases.stretto.com/public/X064/10251/PLEADINGS/1025106202080000000073.pdf#page=131) | **19.06.2020**, mahkeme Case 20-32519, Doc 926; **PDF s.131**, Schedule G ekinin basılı s.13, kayıtlar **2.282–2.286** | DocuSign Master Software Agreement, lisans ve pricing anlaşmaları gerçekten listeleniyor; tutar **Unknown**. Belgenin ilk sayfası borçlunun Neiman Marcus olduğunu gösterdi: Hertz değildir ve alınan 2026 listesinde yok. | Belirtilen sözleşmelerin kayıtlı varlığı **A**, ücret/ödeme ve 2026 Fortune şartı **D**. |
| [Fannie Mae SEC Exhibit 10.24](https://www.sec.gov/Archives/edgar/data/310522/000031052226000015/exhibit1024confidentialagr.htm) | 2026 yıllık dosyalama eki; işten ayrılma anlaşması, kabul/Execution bölümü | DocuSign'ın kurumun belirlediği imzalama aracı olması; maaş/ayrılma bedelleri DocuSign lisans ücreti değil. | Kullanım için destek **B**, doğrudan ödeme **D**. |
| [PG&E Contractor Resources](https://www.pge.com/en/about/doing-business-with-pge/interconnections/contractor-resources.html) | Yayın günü yok; interconnection imza seçenekleri | Kurumsal e-imza kullanımı; DocuSign satın alma bedeli açıklanmıyor. | Kullanım **B**, doğrudan ödeme **D**. |
| [Ingram Micro DocuSign şartları](https://latams.ingrammicro.com/es-mx/general/docusign-terms-and-conditions) | Sürüm/yayın günü açık değil; reseller/End Customer tanımları | Dağıtıcı–bayi koşulları; isimli Fortune alıcısının tamamlanmış ödeme veya imzalı siparişi değil. | İstenen ödeme **D**. |

Neiman PDF'si web aracında hata verdi; normal HTTP ile **3.791.461 bayt / 175 sayfa** alınıp pypdf ile ilk sayfa ve ilgili sayfa gerçekten okundu. Bu kontrol, arama sonucunu yanlış şirkete atfetme riskini ortaya çıkardı. Belgenin tam metni repoya eklenmedi.

**Diğer erişim sınırları:** Watsonville DocuSign sipariş formu arama sonucunda bulundu, doğrudan açma **403** verdi; gövdesi okunmuş sayılmadı. Belediye/üniversite siparişleri, tedarikçilerin genel şartları ve Comcast/T-Mobile'ın kendi müşterilerine sattığı hizmet sözleşmeleri Fortune alıcısının DocuSign ödemesine çevrilmedi. SAM/USAspending'deki kamu alıcısı ayrımı önceki bölüm 4.2'de geçerliliğini korur.

**Kesin ödeme cevabı: Hayır.** Bu genişletilmiş aramada da **2026 ABD Fortune üyeliği + DocuSign'a bağlayıcı ücretli alım/ödeme belgesi** şartları birlikte doğrudan doğrulanamadı. Comcast güçlü dolaylı kanıt olarak korunur. Detroit alımı gerçek olsa da şartı karşılamaz; sınıf A belge bulunması uygun sınıf A Fortune belgesi bulunması demek değildir. Bedel uydurulmadı, müşteri vakası faturaya dönüştürülmedi.

### 13.4 Kapanan eksikler ve teslim sınırı

**Gerçekten kapanan eksikler:** Yalnız yedi örnekle sınırlı sayısal kapsam; çalışan ölçüsünde tam liste minimum–maksimumu; 472 dolu piyasa alanında liste minimum–maksimumu; boş kayıt sayısı/oranı; resmî part-time yöntemi; Gold.com farkının yöntemle uyumlu hesabı; T-Mobile'ın erişilen güncel listeye aday olarak alınmaması. Güncel profil fiyatı ile liste sürümü ayrımı ve BitGo sıra çelişkisi görünür kılındı.

**Açık kalanlar:** Fortune müşterisinin doğrudan ücretli sözleşme/ödeme kaydı; her piyasa satırının ortak gününün bağımsız doğrulanması; bütün üyeler için güncel ticker/halka açıklık ve standart FTE serisinin ayrı ayrı kurulması. Bu nedenle özellikle ödeme koşulu bakımından **85 puan riski sürüyor**. Kullanıcının 92 test/900 assertion kaydı, canlı test beyanları, CI rozeti, TrustRadius kanıtı ve aort dilimi değiştirilmedi; yeni test koşusu iddiası yok.

**Bu güncellemenin gerçek kontrolleri:** README ve rapordaki **28 Markdown tablosunun** sütunları tutarlı; başlık bağlantıları geçerli ve **38 yerel dosya hedefi** mevcut. Toplam **74 dış HTTP hedefinden yeni eklenen 11'i** ayrıca GET ile denendi: **6 HTTP 200, 5 HTTP 403**. Önceki 63 hedefin tarihsel sonuçları bölüm 12'de korunur; bu turn'de hepsi yeniden açılmış gibi sunulmaz. SEC, BitGo IR ve PG&E'nin bu HTTP 403 yanıtlarına rağmen gövdeleri araştırma web aracında okunabildi; yöntem farkı kaydedildi.

Rapora eklenen Python kodu internetten yeniden veri alarak **gerçekten çalıştırıldı**: market cap için **472 / QVC 18.9 / Nvidia 4237920.0 (milyon $)**; çalışan için **500 / BitGo 603 / Walmart 2100000**. Açık UTF-8 çözümlemeden sonraki SHA-256 yukarıdaki değerle eşleşti. Bu araştırma kontrolüdür, Rails testi değildir.

`git diff --check` başarılı. Korunan **87 uygulama/test dosyası ve AGENT kapsamının** başlangıç hash'leri değişmedi; teslim değişiklikleri yalnız README.md ve bu rapordur. Veritabanına dokunulmadı; migration, test, deploy, commit veya push çalıştırılmadı. Eski başarılı test kaydı aynen korunuyor.
