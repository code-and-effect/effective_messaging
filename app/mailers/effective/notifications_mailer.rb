module Effective
  class NotificationsMailer < EffectiveMessaging.parent_mailer_class
    include EffectiveMailer
    include EffectiveEmailTemplatesMailer

    def notification(notification, resource = nil, opts = {})
      raise('expected an Effective::Notification') unless notification.kind_of?(Effective::Notification)

      @assigns = assigns_for(notification, resource)

      # Find the TO email address for this resource
      to = notification.to_email(resource)
      raise('expected a to email address') unless to.present?

      # Attach report
      attach_report!(notification)
      opts.delete(:content_type) if notification.attach_report?

      # Use postmark broadcast-stream
      if defined?(Postmark)
        opts.merge!(message_stream: 'broadcast-stream') 
        append_unsubscribe_link!(notification, opts)
      end

      mail(to: to, **headers_for(resource, opts))
    end

    private

    def assigns_for(notification, resource)
      notification.assign_renderer(view_context).assigns_for(resource)
    end

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

    def append_unsubscribe_link!(notification, opts)
      raise('expected a Hash') unless opts.kind_of?(Hash)
      raise('expected a Hash with a :body') unless opts.key?(:body)

      name = EffectiveResources.et('acronym')
      url = view_context.root_url

      unsubscribe = [
        "You received this message because of your affiliation with the #{name} at #{url}",
        "If you do not want to receive this messages any more, you may unsubscribe from this list.",
        "Please understand that unsubscribing means you will no longer receive mandatory messages and announcements."
      ].join(" ")

      if notification.email_notification_html?
        opts.merge!(body: "#{opts[:body]}\r\n<br/><p>#{unsubscribe}</p>")
      else
        opts.merge!(body: "#{opts[:body]}\r\n\r\n#{unsubscribe}")
      end

      true
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
