module Effective
  class NotificationsMailer < EffectiveMessaging.parent_mailer_class
    include EffectiveMailer

    # def notify(notification, opts = {})
    #   raise('expected an Effective::Notification') unless notification.kind_of?(Effective::Notification)

    #   # Returns a Hash of params to pass to mail()
    #   # Includes a :to, :from, etc
    #   rendered = notification.render_email()

    #   # Attach report
    #   attach_report!(notification)

    #   # Works with effective_logging to associate this email with the notification
    #   headers = headers_for(notification, opts)

    #   # Use postmark broadcast-stream
    #   headers.merge!(message_stream: 'broadcast-stream') if defined?(Postmark)

    #   # Calls effective_resources subject proc, so we can prepend [LETTERS]
    #   subject = subject_for(__method__, rendered.fetch(:subject), notification, opts)

    #   # Pass everything to mail
    #   mail(rendered.merge(headers).merge(subject: subject))
    # end

    # Does not use effective_email_templates mailer
    def notify_resource(notification, resource, opts = {})
      raise('expected an Effective::Notification') unless notification.kind_of?(Effective::Notification)
      raise('expected an acts_as_reportable resource') unless resource.class.try(:acts_as_reportable?)

      # Returns a Hash of params to pass to mail()
      # Includes a :to, :from, etc
      rendered = notification.render_email(resource)

      # Attach report
      attach_report!(notification)

      # Works with effective_logging to associate this email with the notification
      headers = headers_for(notification, opts)

      # Use postmark broadcast-stream
      headers.merge!(message_stream: 'broadcast-stream') if defined?(Postmark)

      # Calls effective_resources subject proc, so we can prepend [LETTERS]
      subject = subject_for(__method__, rendered.fetch(:subject), resource, opts)

      # Pass everything to mail
      mail(rendered.merge(headers).merge(subject: subject))
    end

    private

    def attach_report!(notification)
      return unless notification.attach_report?

      report = notification.report
      raise("expected a report for notification id=#{notification.id}") unless report.present?

      # Attach Report CSV built from datatables
      datatable = EffectiveReportDatatable.new(view_context, report: report)

      attachments["#{Time.zone.now.strftime('%F')}-#{report.to_s.parameterize}.csv"] = {
        mime_type: datatable.csv_content_type,
        content: datatable.csv_file
      }
    end

    def mailer_settings
      EffectiveMessaging
    end

    # Authorization for the Datatables.
    def authorize!(action, resource)
      true
    end

  end
end
