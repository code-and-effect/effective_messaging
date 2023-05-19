module Effective
  class NotificationsMailer < EffectiveMessaging.parent_mailer_class
    include EffectiveMailer

    # Does not use effective_email_templates mailer

    def notification(notification, resource, opts = {})
      raise('expected an Effective::Notification') unless notification.kind_of?(Effective::Notification)
      raise('expected an acts_as_reportable resource') unless resource.class.try(:acts_as_reportable?)

      # Returns a Hash of params to pass to mail()
      # Includes a :to, :from, etc
      rendered = notification.render_email(resource)

      # Works with effective_logging to associate this email with the notification
      headers = headers_for(notification, opts)

      # Use postmark broadcast-stream
      if defined?(Postmark)
        headers.merge!(message_stream: 'broadcast-stream')
      end

      # Calls effective_resources subject proc, so we can prepend [LETTERS]
      subject = subject_for(__method__, rendered.fetch(:subject), resource, opts)

      # Pass everything to mail
      mail(rendered.merge(headers).merge(subject: subject))
    end

    private

    def mailer_settings
      EffectiveMessaging
    end

  end
end
