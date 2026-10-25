# Gemini 404 — çağrısız yerel tanılama

**Sonraki kullanıcı bildirimi (25.10.2026):** Model yapılandırması değiştirilince gerçek yerel web akışı taslak/gönderim/imza/signed ile tamamlandı. Yeni model ID'si belirtilmedi. Bu beyan aşağıdaki önceki çağrısız tanılamanın tarihsel kapsamını değiştirmez; hesap erişimi/production Codex tarafından doğrulanmış sayılmaz. [Final kayıt](AI_FINAL_RELEASE_REPORT.md).

25.10.2026. Gerçek Gemini API çağrısı yapılmadı. Anahtar gösterilmedi, ham hata yanıtı/log/ENV dump alınmadı. Provider/model, ücretli izinler, CSRF ve mevcut belge akışları değiştirilmedi. Commit/push/deploy veya veritabanı işlemi yok.

## Endpoint incelemesi

| İşlem | Uygulamanın oluşturduğu istek |
| --- | --- |
| Model erişimi/metadata | `GET https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash` — gövde yok. |
| Üretim/function calling | `POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent` — JSON gövde. |

Model `ProviderConfig` tarafından `SIGNFLOW_LLM_MODEL` değişkeninden okunur ve GeminiProvider'a aynen aktarılır. Yapılandırma çıplak ID ister; `models/` öneki veya tam URL kabul edilmez. Yol birleştirmesinde çift `models/`, yanlış API sürümü veya yanlış metot bulunmadı. Host sabit Google host'u, port 443, TLS açık, proxy devralma/redirect yok. Anahtar yalnız `x-goog-api-key` header'ında; URL veya JSON gövdesinde değil.

[Google Models.get referansı](https://ai.google.dev/api/models#method:-models.get) ve [generateContent referansı](https://ai.google.dev/api/generate-content) bu GET/POST yollarını doğruluyor. Yanlış URL/metot varsayımıyla endpoint değiştirilmedi.

## Güvenli yerel yapılandırma kontrolü

Çalıştırılan komut:

```powershell
$env:RAILS_ENV='development'
bundle exec rails runner script/check_gemini_configuration.rb
```

Yeni development runner sürecinde gerçek sonuç:

- Dotenv etkin; yükleme sırasındaki mevcut yerel dosya `.env`.
- Provider `gemini`; etkin model **`gemini-2.5-flash`**, bildirilen ID ile aynı.
- Gemini key tanımlı: **true**. Değer, uzunluk, özet veya fingerprint gösterilmedi.
- Web flag, sentetik veri, free-mode ve free-tier teyidi **true**; paid izni **false**.
- Provider kurulumu/preflight/üretim çalıştırılmadı; Gemini isteği **0**.

Bu komut **yeni runner sürecini** doğrular; mevcut web sürecinin belleğini/ENV'sini okumaz. 3000 portundaki Ruby süreci PID 7704, 25.10.2026 11:05:21 başlangıçlıydı; `.env` son değişikliği 10:59:21, Gemfile.lock değişikliği 11:01:34. Dolayısıyla gözlenen web süreci bu dosya değişikliklerinden sonra başlamıştı. Bu zaman bilgisi mevcut web ENV değerinin doğrudan ölçümü değildir. Web'de o isteğin hangi modelle yapıldığı veya dosya/process ENV önceliği ayrıca kanıtlanmadı; process ENV dosyayı geçersiz kılabilir.

Dosyayı değiştirdiğinizde kendi web sunucunuzu tamamen durdurup aynı güvenilir terminalden `bundle exec rails server` ile yeniden başlatın. Yeni runner çıktısını eski web süreci için kesin kanıt saymayın. Tanılama script'i model erişim testi değildir. Web'e config/secret gösteren yeni endpoint eklenmedi.

## 404 neyi kanıtlar?

Mevcut güvenli `gemini_http_404` kategorisi hem metadata GET hem generateContent POST için aynıdır. Ham yanıt veya çağrının hangi aşamada kaldığı olmadan tek başına modelin yanlış olduğunu, hesabın erişmediğini ya da modelin kaldırıldığını kesin kanıtlamaz.

[Google'ın güncel 2.5 Flash sayfası](https://ai.google.dev/gemini-api/docs/models/gemini-2.5-flash) erişimin bu modelleri geçmişte aktif kullanmış kullanıcılarla sınırlandırıldığını; modellerin henüz deprecated olmadığını belirtiyor. Bu yüzden **hesap/proje erişimi olası neden**. Kullanıcının hesabının/modelinin erişimi gerçek çağrı yapılmadan doğrulanmadı. Kamuya açık belge bu hesaba erişim veya ücretsiz kota kanıtı değildir. Model otomatik değiştirilmedi, ücretli fallback veya sessiz başarı eklenmedi.

Metadata GET 404 dönerse mevcut web akışı üretime ilerlemez. Metadata başarılı olup POST 404 dönerse o modelin bu sürüm/metotla kullanılabilirliği ayrıca kontrol edilmelidir. URL ve metot için aşağıdaki deterministik testler doğru inşayı doğruluyor; gerçek servis yanıtının nedeni açık kalıyor.

## Eklenenler ve testler

- `script/check_gemini_configuration.rb`: yerel development/test için salt okunur runner tanılaması; sadece allowlist model, güvenli bayraklar, key-var/yok ve statik endpoint'ler. Gerçek değerler veya model yanıtı yok.
- `test/lib/gemini_endpoint_test.rb`: yapılandırılmış modelin aynen aktarılması, exact GET/POST yolları, gövde/header güvenliği; soket açmayan Net::HTTP nesnesiyle gerçek HTTP builder'ın host/443/TLS/metot kontrolü; metadata ve üretim 404'ünde retry/fallback/başarı olmaması.

İlk hedefli paket (son HTTP-builder testi eklenmeden): **14 test / 127 assertion, 0 failure/error/skip**. Tam test ve lint sonuçları son doğrulama sonrasında aşağıda kaydedilir. Mevcut dotenv testleri development otomatik yükleme, process ENV önceliği ve test/production izolasyonunu sentetik dosyalarla sınar. Testler gerçek Google hesabı veya çalışan web süreci değildir.

İlk tam pakette **186 test / 1892 assertion, 0 failure / 1 error** görüldü: sahte HTTP nesnesinde Ruby Net::HTTP'nin `HAVE_ZLIB` sabiti eksikti. Bu test düzeneğine gerçek sabit eklendi; uygulama veya güvenlik kuralı değiştirilmedi. Düzeltilmiş endpoint paketi **4 test / 38 assertion, 0 failure/error/skip** ile geçti.

| Son kontrol | Gerçek sonuç |
| --- | --- |
| `RAILS_ENV=test` ile `bundle exec rails test` | **186 test / 1904 assertion, 0 failure/error/skip**, exit 0. |
| `bundle exec rubocop` | **123 dosya, ihlal yok**, exit 0. |
| `RAILS_ENV=test` ile `bundle exec rails zeitwerk:check` | **All is good!**, exit 0. |
| Development runner tanılaması | Başarılı; yapılandırılmış model doğru, key-var/yok true, gerçek Gemini çağrısı yok. |
| `git diff --check`, `.env` ignore/izleme kontrolü | Whitespace hatası yok; `.env` ignored, Git tarafından izlenmiyor. |

Windows'taki opsiyonel libvips DLL/Rack uyarıları devam ediyor; başarısız test olarak gizlenmedi veya başarıyla karıştırılmadı. PostgreSQL için opt-in concurrency bu görevde ayrıca çalıştırılmadı; veritabanı/model/iş akışı kodu değiştirilmedi. Yeni HTTP testleri gerçek soket açmaz. Provider endpoint kodunda hata bulunmadığından düzeltme yapılmadı; gerçek 404'ün hesap/servis tarafındaki kesin nedeni açık kaldı.
