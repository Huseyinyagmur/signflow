module Templates
  class DemoSeeder
    EXAMPLES = [
      { key: "software", title: "Yazılım Geliştirme Hizmet Sözleşmesi",
        description: "Yazılım projeleri için beş değişkenli ders demosu.",
        content: "DERS DEMOSU — Gerçek hukuki kullanım için hazırlanmış değildir.\n\nAlıcı: {{alici_adi}}\nHizmet: {{hizmet}}\nToplam ücret: {{ucret}}\nBaşlangıç: {{baslangic_tarihi}}\nBitiş: {{bitis_tarihi}}\n\nHizmet sağlayıcı, belirtilen dönemde yazılım geliştirme çalışmasını yürütür. Alıcı kapsamı değerlendirir ve örnek teslimatları inceler. Kapsam değişiklikleri taraflarca ayrıca görüşülür." },
      { key: "confidentiality", title: "Gizlilik Sözleşmesi",
        description: "Alıcı ve hizmet alanlarıyla hızlı bir gizlilik sözleşmesi örneği.",
        content: "DERS DEMOSU — Gerçek hukuki kullanım için hazırlanmış değildir.\n\n{{alici_adi}}, {{hizmet}} kapsamında paylaşılan örnek bilgileri yalnızca çalışma amacıyla kullanmayı kabul eder. Bilgiler izinsiz üçüncü kişilere aktarılmaz.\n\nBu örnek düzenleme {{baslangic_tarihi}} ile {{bitis_tarihi}} arasındaki demo çalışmasını kapsar." },
      { key: "consulting", title: "Danışmanlık Hizmet Sözleşmesi",
        description: "Danışmanlık kapsamı, ücret ve çalışma dönemini doldurun.",
        content: "DERS DEMOSU — Gerçek hukuki kullanım için hazırlanmış değildir.\n\nAlıcı: {{alici_adi}}\nDanışmanlık konusu: {{hizmet}}\nÜcret: {{ucret}}\nDönem: {{baslangic_tarihi}} – {{bitis_tarihi}}\n\nDanışman, belirtilen konuda örnek analiz ve öneriler sunar. Görüşme takvimi ve teslimatlar tarafların ortak değerlendirmesiyle belirlenir. Bu metin herhangi bir sonuç garantisi içermez." }
    ].freeze

    def self.call(user:)
      user.with_lock do
        manager = Manage.new(user: user)
        created_count = 0
        EXAMPLES.each do |example|
          next if user.templates.exists?(seed_key: example.fetch(:key))

          manager.create!(example.except(:key), seed_key: example.fetch(:key))
          created_count += 1
        end
        created_count
      end
    end
  end
end
