require "test_helper"

class TemplateRendererTest < ActiveSupport::TestCase
  test "detects unique fields in first appearance order and tolerates whitespace" do
    assert_equal %w[alici_adi hizmet ucret], Templates::Renderer.fields("{{alici_adi}} {{ hizmet }} {{alici_adi}} {{ucret}}")
    assert_empty Templates::Renderer.fields("Sabit metin.")
  end

  test "rejects unknown malformed empty nested and unmatched placeholders" do
    [ "{{foo}}", "{{}}", "{{alici_adi", "alici_adi}}", "{{ALICI}}", "{{a.b}}", "{{{alici_adi}}}", "{{ {{ucret}} }}" ].each do |text|
      assert_raises(Templates::Renderer::InvalidInput) { Templates::Renderer.fields(text) }
    end
  end

  test "replaces repeated placeholders literally in one pass" do
    result = Templates::Renderer.render("{{hizmet}} / {{hizmet}} / {{ucret}}",
      values: { "hizmet" => '{{ucret}} \\1 <%= 7 * 7 %>', "ucret" => "100 TRY" })
    assert_equal '{{ucret}} \\1 <%= 7 * 7 %> / {{ucret}} \\1 <%= 7 * 7 %> / 100 TRY', result
  end

  test "rejects missing blank extra non-string and excessive values" do
    [ {}, { "hizmet" => " " }, { "hizmet" => nil }, { "hizmet" => [ "value" ] },
      { "hizmet" => { "nested" => "value" } }, { "hizmet" => "a" * 5001 },
      { "hizmet" => "Valid", "ucret" => "unexpected" } ].each do |values|
      assert_raises(Templates::Renderer::InvalidInput) { Templates::Renderer.render("{{hizmet}}", values: values) }
    end
    assert_raises(Templates::Renderer::InvalidInput) { Templates::Renderer.render("{{hizmet}}", values: "value") }
  end

  test "HTML and ERB are inert text rather than executed instructions" do
    result = Templates::Renderer.render('<%= raise "executed" %> {{hizmet}}', values: { "hizmet" => '<script id="attack">alert(1)</script>' })
    assert_includes result, '<%= raise "executed" %>'
    assert_includes result, '<script id="attack">'
  end
end
