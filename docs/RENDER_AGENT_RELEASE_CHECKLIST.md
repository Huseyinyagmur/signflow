# SignFlow Agent — kontrollü Render yayını kontrol listesi

**Güncel AI web yayını:** Aşağıdaki metin önceki Aşama 3 hazırlığının tarihsel listesidir. Yeni additive conversation migration'ı, Gemini backend env, tek süreç kısıtı ve kullanıcı onay kapıları için [final yayın raporunu](AI_FINAL_RELEASE_REPORT.md) kullanın. Yeni görev yerel commit'i yetkilendirir; Auto-Deploy doğrulanmadan push, ayrıca son kullanıcı onayı olmadan deploy yapılmaz.

**25.10.2026: hazırlık belgesi. Dashboard'a erişilmedi; hiçbir hesap ayarı, canlı SHA, plan, Auto-Deploy veya backup doğrulanmadı. Deploy/push yapılmadı.** Kutular kullanıcı/operatör tarafından gerçek kontrolden sonra işaretlenir. [Temel Render rehberi](RENDER_DEPLOYMENT.md).

## Yetki ve canlı durum — henüz doğrulanmadı

- [ ] Yayın yetkisi ve kontrollü zaman aralığı belirlendi; bu geliştirme görevi commit/push/deploy izni değildir.
- [ ] Dashboard'da doğru servis/repo/bağlı branch ve canlı commit SHA kaydedildi; yerel Git SHA'nın canlı olduğu varsayılmadı.
- [ ] Settings → Auto-Deploy değeri gerçekten görüldü. On Commit / After CI Checks Pass / Off seçeneklerinden mevcut olan kaydedildi. Kontrol edilmeden main'e push/merge yok.
- [ ] Kontrollü yayın için Off veya gerçekten gerekli CI kontrollerini bekleyen ayar kullanıcı tarafından seçildi. After CI Checks Pass'in skipped/neutral sonuçları da kabul edebildiği bilinerek her kritik job'ın **success** olduğu ayrıca görüldü. [Resmî deploy belgesi](https://render.com/docs/deploys).
- [ ] Hedef SHA için scan_ruby, scan_js, lint, test ve agent_postgresql sonuçları başarıyla tamamlandı. Yerel test sonucu uzak CI yerine yazılmadı.

## PostgreSQL ve migration — canlıya dokunmadan önce

- [ ] Mevcut DATABASE_URL aynı kalıcı PostgreSQL'e bağlı; yeni/boş DB, SQLite veya geçici diskle değiştirilmedi. URL'nin kendisi kanıt dosyasına yazılmadı.
- [ ] Veritabanı planı, süre sonu, disk alanı, backup/retention ve uygulanabilir restore adımları Dashboard'da kontrol edildi. Süreli Free PostgreSQL kalıcı ücretsiz DB sanılmadı.
- [ ] Migration öncesi kurtarılabilir backup ve kullanıcı/belge/şablon/sürüm/idempotency verileri için kontrol ölçüleri hazır. Kişisel veri veya secret çıktıya dökülmedi.
- [ ] Hedef sürümün migration listesi incelendi. **Bu Aşama 3 yeni migration eklemedi**, ancak canlı Aşama 1'i içermiyorsa `20261025000100_create_agent_access` bekliyor olabilir; canlı migration durumu bilinmiyor.
- [ ] Build `bash bin/render-build.sh`; start `bash bin/render-start.sh`; health `/up` Dashboard ile karşılaştırıldı. Yerel script start'ta db:migrate sonrası Puma çalıştırıyor; migration hatası start'ı durdurur. Ücretsiz serviste pre-deploy desteği varsayılmadı.
- [ ] Eski/yeni kod ve DB'nin birlikte uyumu kontrol edildi; eşzamanlı deploy/uzun migration planlanmadı. db:reset/drop/schema:load/seed/veri dönüşümü yapılmıyor.

## Feature flag ve güvenlik

- [ ] İlk kontrollü dağıtımda `AGENT_API_ENABLED` kapalı. API 404 dönmeli; web kayıt/giriş/sözleşme/şablon/imza önce smoke ile doğrulanmalı.
- [ ] Oturum sahibi `/agent_credentials` listesini görebiliyor ve API kapalıyken de mevcut credential'ı iptal edebiliyor. Yeni credential üretimi flag kapalıyken engelli.
- [ ] Kontrol sonrası flag kullanıcı kararıyla açıldı ve servis yenilendi. Token yalnız özel oluşturma yanıtında gösteriliyor; prodüksiyon loglarına/ekran kaydına alınmıyor.
- [ ] Secure/HttpOnly/SameSite cookie, HTTPS, izinli host, same-origin ve CSRF/origin koruması korunuyor; localhost/127.0.0.1/onrender host'ları karıştırılmıyor.
- [ ] **Tek web instance ve tek Puma süreci** ayarı doğrulandı (`WEB_CONCURRENCY=0` mevcut öneri). 60 okuma/10 POST, credential başına 60 saniyelik process-memory kotasıdır. Restart/eviction sıfırlar; birden fazla process/instance ortak bütçe sağlamaz. Ölçeklemeden önce ortak store/edge sınırı tasarlanmalı.
- [ ] Yetkisiz bearer denemeleri için bu değişiklik IP bazlı anti-abuse koruması eklemiyor; internete genel açılımın sınırları ayrıca değerlendirildi.
- [ ] Anthropic key'i Render'a konmadı: LLM istemcisi yerelde çalışır. DATABASE_URL/RAILS_MASTER_KEY dışarı verilmedi; mevcut değerler bu çalışmada okunmadı/değiştirilmedi.

## Kullanıcı onaylı yayından sonra kabul

- [ ] Sentetik hesapla credential oluştur/listele/iptal, yanlış kullanıcı erişimi, API draft/replay/conflict, 429/Retry-After ve iptal sonrası 401 doğrulandı.
- [ ] Taslak web'de insan tarafından incelenip gönderildi; alıcı demo imzaladı; signed durumu görüldü. Agent'ın send/sign yetkisi yok.
- [ ] Restart sonrası eski kayıtlar, credential iptalleri ve idempotency duruyor. Kota belleği reset olabilir; DB idempotency reset olamaz.
- [ ] /up başarısı tek başına DB/TLS/JS/iş akışı kanıtı sayılmadı. Canlı browser ve proxy log kontrolü ayrıca yapıldı; secret içeren kayıt paylaşılmadı.
- [ ] Gerçek LLM denemesi ancak kullanıcının ayrı anahtar/bütçe kararıyla ve sentetik veriyle yapıldı; kod deploy'u LLM faturası izni sayılmadı.

## Sorunda geri dönüş

- [ ] Önce `AGENT_API_ENABLED` kapatılır; gerekirse kullanıcı arayüzünden ilgili credential'lar iptal edilir. Flag kapatmak credential'ı kalıcı iptal etmez.
- [ ] Bilinen başarılı build/SHA ve geri dönüş prosedürü hazır; [Render rollback belgesi](https://render.com/docs/rollbacks) kontrol edildi.
- [ ] Kod rollback'i DB rollback'i değildir. Yeni agent tabloları/idempotency kayıtları düşürülmez, mevcut PostgreSQL geri alınmaz veya sıfırlanmaz.
- [ ] Rollback sırasında eski environment/start ayarları yeniden kullanılabilir; **sonrasında flag, build/start ve Auto-Deploy tekrar kontrol edilir**. Dashboard/API rollback davranışının Auto-Deploy için aynı olduğu varsayılmaz.
- [ ] Normal kullanıcı akışı tekrar test edilir; eksik UI/eski sürüm yüzünden iptal yolu yoksa güvenli operatör yolu önceden planlanır. Restore gerekiyorsa ayrıca onaylı kurtarma prosedürü uygulanır.

Bu liste doğrulanmış canlı ayar raporu değildir; bu çalışmada herhangi bir kutu tamamlanmış olarak işaretlenmedi.
