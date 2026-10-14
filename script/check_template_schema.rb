# Read-only diagnostic. Run in a fresh Rails process; this does not refresh a running server.
# bundle exec rails runner script/check_template_schema.rb
connection = ActiveRecord::Base.connection
column = connection.columns(:documents).find { |entry| entry.name == "template_version_id" }
index_exists = connection.indexes(:documents).any? { |entry| entry.columns == [ "template_version_id" ] }
foreign_key_exists = connection.foreign_keys(:documents).any? do |entry|
  entry.to_table == "template_versions" && entry.column == "template_version_id"
end
association = Document.reflect_on_association(:template_version)

puts "Environment: #{Rails.env}"
puts "Database: #{ActiveRecord::Base.connection_db_config.database}"
puts "Physical column: #{column.present?}; nullable: #{column&.null}"
puts "Index: #{index_exists}; foreign key: #{foreign_key_exists}"
puts "Model column: #{Document.column_names.include?('template_version_id')}; optional: #{association.options[:optional]}"

unless column&.null && index_exists && foreign_key_exists && Document.column_names.include?("template_version_id") && association.options[:optional]
  abort "Template schema mismatch. Check db:migrate:status and apply pending migrations without resetting data."
end

if (version = TemplateVersion.first)
  values = version.variables.index_with { "Demo" }
  document = Documents::Manage.new(user: version.template.user).build_from_template(
    version: version, attributes: {}, values: values)
  raise "Unsaved document source mismatch" unless document.new_record? && document.template_version_id == version.id

  puts "Template association assignment: OK (unsaved document; no records written)."
end
puts "Schema check: OK. Restart the web server after migrations; this check runs in a separate process."
