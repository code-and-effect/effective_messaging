EffectiveEmailTemplates.setup do |config|
  # Configure Database Tables
  config.email_templates_table_name = :email_templates

  # config.layout = 'application'   # All EffectiveEmailTemplates controllers will use this layout
  # Not allowed to select text/html by default
  config.select_content_type = false
end
