module Effective
  class MessagingMailer < EffectiveMessaging.parent_mailer_class

    include EffectiveMailer
    include EffectiveEmailTemplatesMailer if EffectiveMessaging.use_effective_email_templates

    # def messaging_submitted(resource, opts = {})
    #   @assigns = assigns_for(resource)
    #   @applicant = resource

    #   subject = subject_for(__method__, "Messaging Submitted - #{resource}", resource, opts)
    #   headers = headers_for(resource, opts)

    #   mail(to: resource.user.email, subject: subject, **headers)
    # end

    protected

    def assigns_for(resource)
      if resource.kind_of?(Effective::Messaging)
        return messaging_assigns(resource)
      end

      raise('unexpected resource')
    end

    def messaging_assigns(resource)
      raise('expected an messaging') unless resource.class.respond_to?(:effective_messaging_resource?)

      values = {
        date: messaging.created_at.strftime('%F')
      }.compact

      { messaging: values }
    end

  end
end
