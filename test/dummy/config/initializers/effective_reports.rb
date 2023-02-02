EffectiveReports.setup do |config|
  config.reports_table_name = :reports
  config.report_columns_table_name = :report_columns
  config.report_scopes_table_name = :report_scopes

  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }

  # Reports Settings
  # Configure the class responsible for the reports.
  # This should extend from Effective::Reports
  # config.reports_class_name = 'Effective::Reports'

  # Reportable Class Names
  # The following classes will be available to build reports from
  # They must define acts_as_reportable to be included
  config.reportable_class_names = ['User']

  # Mailer Settings
  # Please see config/initializers/effective_reports.rb for default effective_* gem mailer settings
  #
  # Configure the class responsible to send e-mails.
  # config.mailer = 'Effective::ReportsMailer'
  #
  # Override effective_resource mailer defaults
  #
  # config.parent_mailer = nil      # The parent class responsible for sending emails
  # config.deliver_method = nil     # The deliver method, deliver_later or deliver_now
  # config.mailer_layout = nil      # Default mailer layout
  # config.mailer_sender = nil      # Default From value
  # config.mailer_admin = nil       # Default To value for Admin correspondence
  # config.mailer_subject = nil     # Proc.new method used to customize Subject

  # Will work with effective_email_templates gem
  config.use_effective_email_templates = true
end
