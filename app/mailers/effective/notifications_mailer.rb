module Effective
  class NotificationsMailer < EffectiveMessaging.parent_mailer_class
    include EffectiveMailer

    # This is not an EffectiveEmailTemplatesMailer

    def notify(notification, opts = {})
      raise('expected an Effective::Notification') unless notification.kind_of?(Effective::Notification)

      # Returns a Hash of params to pass to mail()
      # Includes a :to, :from, :subject and :body, etc
      rendered = notification.assign_renderer(view_context).render_email

      # Attach report
      attach_report!(notification)
      rendered.delete(:content_type) if notification.attach_report?

      # Works with effective_logging to associate this email with the notification
      headers = headers_for(notification, opts)

      # Use postmark broadcast-stream
      if defined?(Postmark)
        headers.merge!(message_stream: 'broadcast-stream') 
        attach_unsubscribe_link!(rendered)
      end

      # Calls effective_resources subject proc, so we can prepend [LETTERS]
      subject = subject_for(__method__, rendered.fetch(:subject), notification, opts)

      # Pass everything to mail
      mail(rendered.merge(headers).merge(subject: subject))
    end

    # Does not use effective_email_templates mailer
    def notify_resource(notification, resource, opts = {})
      raise('expected an Effective::Notification') unless notification.kind_of?(Effective::Notification)
      raise('expected an acts_as_reportable resource') unless resource.class.try(:acts_as_reportable?)

      # Returns a Hash of params to pass to mail()
      # Includes a :to, :from, :subject and :body
      rendered = notification.assign_renderer(view_context).render_email(resource)

      # Works with effective_logging to associate this email with the notification
      headers = headers_for(notification, opts)

      # Use postmark broadcast-stream
      if defined?(Postmark)
        headers.merge!(message_stream: 'broadcast-stream') 
        attach_unsubscribe_link!(rendered)
      end

      # Calls effective_resources subject proc, so we can prepend [LETTERS]
      subject = subject_for(__method__, rendered.fetch(:subject), resource, opts)

      # Pass everything to mail
      mail(rendered.merge(headers).merge(subject: subject))
    end

    private

    def attach_report!(notification)
      return unless notification.attach_report?
      raise("expected a scheduled email notification") unless notification.scheduled_email?

      report = notification.report
      raise("expected a report for notification id=#{notification.id}") unless report.present?

      # Attach Report CSV built from datatables
      datatable = EffectiveReportDatatable.new(view_context, report: report)

      attachments["#{Time.zone.now.strftime('%F')}-#{report.to_s.parameterize}.csv"] = {
        mime_type: datatable.csv_content_type,
        content: datatable.csv_file
      }
    end

    def attach_unsubscribe_link!(rendered)
      raise('expected a Hash') unless rendered.kind_of?(Hash)
      raise('expected a Hash with a :body') unless rendered.key?(:body)

      name = EffectiveResources.et('acronym')
      url = view_context.root_url

      unsubscribe = [
        "You received this message because of your affiliation with the #{name} at #{url}",
        "If you do not want to receive this messages any more, you may unsubscribe from this list.",
        "Please understand that unsubscribing means you will no longer receive mandatory messages and announcements."
      ].join(" ")

      # Attach unsubscribe link
      rendered[:body] = "#{rendered[:body]}\r\n\r\n#{unsubscribe}"

      rendered
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
