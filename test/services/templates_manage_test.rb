require "test_helper"

class TemplatesManageTest < ActiveSupport::TestCase
  setup do
    @template = create_template
    @manager = Templates::Manage.new(user: @template.user)
  end

  test "creation and each update add an immutable full snapshot" do
    first = @template.current_version
    assert_equal 1, first.number
    assert_difference "TemplateVersion.count", 2 do
      @manager.update!(@template.id, title: "Second", description: "New description", content: "{{hizmet}} v2")
      @manager.update!(@template.id, title: "Third", description: "Third description", content: "{{hizmet}} v3")
    end
    assert_equal [ 1, 2, 3 ], @template.versions.order(:number).pluck(:number)
    assert_equal "Third", @template.reload.title
    assert_equal 3, @template.current_version.number
    assert_equal "Hizmet şablonu", first.reload.title
    assert_equal "{{alici_adi}} için {{hizmet}}. Ücret: {{ucret}}.", first.content
  end

  test "invalid creation and update are atomic" do
    assert_no_difference [ "Template.count", "TemplateVersion.count" ] do
      assert_raises(ActiveModel::ValidationError) { @manager.create!({ title: "", content: "{{unknown}}" }) }
      assert_raises(ActiveModel::ValidationError) { @manager.update!(@template.id, title: "Invalid", content: "{{unknown}}") }
    end
    assert_equal 1, @template.reload.current_version.number
  end

  test "search is scoped current version only and escapes LIKE wildcards" do
    other = create_template(user: create_user(email: "other@example.com"))
    assert_equal [ @template.id ], @manager.all(query: "Hizmet").pluck(:id)
    assert_empty @manager.all(query: "%")
    assert_empty @manager.all(query: "' OR 1=1 --")
    @manager.update!(@template.id, title: "Updated", description: "new", content: "Fixed")
    assert_empty @manager.all(query: "Hizmet")
    assert_equal [ @template.id ], @manager.all(query: "new").pluck(:id)
    assert_not_includes @manager.all.pluck(:id), other.id
  end

  test "other users cannot read edit or select a template version" do
    other = Templates::Manage.new(user: create_user(email: "other@example.com"))
    assert_raises(ActiveRecord::RecordNotFound) { other.find(@template.id) }
    assert_raises(ActiveRecord::RecordNotFound) { other.update!(@template.id, title: "Changed", content: "Text") }
    assert_raises(ActiveRecord::RecordNotFound) { other.version(@template.id, @template.current_version_id) }
    another = create_template(user: @template.user)
    assert_raises(ActiveRecord::RecordNotFound) { @manager.version(@template.id, another.current_version_id) }
  end

  test "generated documents copy text and keep the selected version after template changes" do
    version = @template.current_version
    document = Documents::Manage.new(user: @template.user).build_from_template(version: version,
      attributes: { recipient_email: "recipient@example.com", expires_at: 1.hour.from_now },
      values: { "alici_adi" => "Deniz", "hizmet" => "Development", "ucret" => "100 TRY" })
    document.save!
    assert_equal "Deniz", document.recipient_name
    assert_equal "Deniz için Development. Ücret: 100 TRY.", document.content
    assert_equal version, document.template_version
    document.send_for_signature!
    document.sign!(signer_name: "Deniz")
    @manager.update!(@template.id, title: "Updated", content: "Different {{hizmet}}")
    assert_equal "Deniz için Development. Ücret: 100 TRY.", document.reload.content
    assert_equal version.id, document.template_version_id
    assert document.signed?
    assert_not document.update(template_version: @template.reload.current_version)
  end

  test "generation rejects another owners version" do
    manager = Documents::Manage.new(user: create_user(email: "other@example.com"))
    assert_raises(ActiveRecord::RecordNotFound) do
      manager.build_from_template(version: @template.current_version, attributes: {}, values: {})
    end
  end

  test "demo seeds are idempotent preserve edits and do not overwrite unrelated templates" do
    owner = @template.user
    assert_difference [ "Template.count", "TemplateVersion.count" ], 3 do
      assert_equal 3, Templates::DemoSeeder.call(user: owner)
    end
    seeded = owner.templates.find_by!(seed_key: "software")
    @manager.update!(seeded.id, title: "My edited sample", content: "My custom text")
    assert_no_difference [ "Template.count", "TemplateVersion.count" ] do
      assert_equal 0, Templates::DemoSeeder.call(user: owner)
    end
    assert_equal "My edited sample", seeded.reload.title
    assert_equal "My custom text", seeded.content
    assert_equal "Hizmet şablonu", @template.reload.title
    other = create_user(email: "other@example.com")
    Templates::DemoSeeder.call(user: other)
    assert_equal 3, other.templates.count
    assert_equal 4, owner.templates.count
  end
end
