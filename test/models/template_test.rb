require "test_helper"

class TemplateTest < ActiveSupport::TestCase
  test "requires an owner and cannot point to another templates version" do
    assert_not Template.new.valid?
    first = create_template
    other = create_template(user: first.user)
    assert_not first.update(current_version: other.current_version)
    assert_equal first.id, first.reload.current_version.template_id
  end

  test "versions validate title content syntax and positive unique numbers" do
    template = create_template
    version = template.versions.build(title: "", content: "{{unknown}}", number: 0)
    assert_not version.valid?
    %i[title content number].each { |field| assert version.errors[field].any? }
    version.assign_attributes(title: "Title", content: "Fixed", number: 1)
    assert_not version.valid?
    assert version.errors[:number].any?
    version.assign_attributes(number: 2, content: "")
    assert_not version.valid?
    assert version.errors[:content].any?
  end

  test "saved versions cannot be updated or destroyed" do
    version = create_template.current_version
    assert_raises(ActiveRecord::ReadOnlyRecord) { version.update!(content: "Changed") }
    assert_raises(ActiveRecord::ReadOnlyRecord) { version.destroy! }
    assert_equal "{{alici_adi}} için {{hizmet}}. Ücret: {{ucret}}.", version.reload.content
  end

  test "owner and demo identity cannot be reassigned" do
    template = create_template
    other = create_user(email: "other@example.com")
    assert_raises(ActiveRecord::ReadonlyAttributeError) { template.update!(user: other) }
    assert_raises(ActiveRecord::ReadonlyAttributeError) { template.update!(seed_key: "new") }
  end

  test "document template provenance belongs to its owner and is immutable" do
    template = create_template
    other = create_user(email: "other@example.com")
    document = other.documents.build(title: "Title", content: "Text", template_version: template.current_version)
    assert_not document.valid?
    own_document = create_document(user: template.user)
    assert_not own_document.update(template_version: template.current_version)
  end
end
