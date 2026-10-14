module Templates
  class Renderer
    class InvalidInput < StandardError; end

    FIELDS = {
      "alici_adi" => "Alıcı adı", "hizmet" => "Hizmet", "ucret" => "Ücret",
      "baslangic_tarihi" => "Başlangıç tarihi", "bitis_tarihi" => "Bitiş tarihi"
    }.freeze
    PLACEHOLDER = /(?<!\{)\{\{\s*([a-z_][a-z0-9_]*)\s*\}\}(?!\})/

    def self.fields(content)
      names = content.scan(PLACEHOLDER).flatten.uniq
      unknown = names - FIELDS.keys
      raise InvalidInput, "Bilinmeyen değişken: #{unknown.join(', ')}" if unknown.any?
      raise InvalidInput, "Değişken biçimi {{alan_adi}} olmalıdır." if content.gsub(PLACEHOLDER, "").match?(/\{\{|\}\}/)

      names
    end

    def self.render(content, values:)
      fields = fields(content)
      raise InvalidInput, "Değişkenler bir alan-değer listesi olmalıdır." unless values.is_a?(Hash)

      normalized = values.stringify_keys
      extra = normalized.keys - fields
      raise InvalidInput, "Bu sürümde bulunmayan alan: #{extra.join(', ')}" if extra.any?

      fields.each do |field|
        value = normalized[field]
        unless value.is_a?(String) && value.strip.present? && value.length <= 5000
          raise InvalidInput, "#{FIELDS.fetch(field)} boş bırakılamaz ve en fazla 5000 karakter olabilir."
        end
      end
      # Single-pass literal substitution: inserted values are never parsed or evaluated.
      content.gsub(PLACEHOLDER) { normalized.fetch(Regexp.last_match(1)) }
    end
  end
end
