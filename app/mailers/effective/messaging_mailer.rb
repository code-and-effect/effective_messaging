module Effective
  class MessagingMailer < EffectiveMessaging.parent_mailer_class
    include EffectiveMailer
    include EffectiveEmailTemplatesMailer

    def chat_new_message(chat, chat_user, opts = {})
      raise('expected a chat') unless chat.kind_of?(Chat)
      raise('expected a chat user') unless chat_user.kind_of?(ChatUser)

      user = chat_user.user
      raise('expected user to have an email') unless user.try(:email).present?

      @assigns = chat_assigns(chat, user: user).merge(assigns_for(chat_user))

      subject = subject_for(__method__, "New Message - #{chat}", chat, opts)
      headers = headers_for(chat, opts)

      mail(to: user.email, subject: subject, **headers)
    end

    protected

    def assigns_for(resource)
      if resource.kind_of?(Effective::Chat)
        return chat_assigns(resource)
      end

      if resource.kind_of?(Effective::ChatUser)
        return chat_user_assigns(resource)
      end

      raise('unexpected resource')
    end

    def chat_assigns(chat, user:)
      raise('expected a chat') unless chat.kind_of?(Chat)
      raise('expected a user') unless user.present?

      url = chat.parent&.chat_url(chat: chat, user: user, root_url: root_url)
      url ||= effective_messaging.chat_url(chat)

      values = {
        date: chat.created_at.strftime('%F'),
        title: chat.title,
        url: url
      }.compact

      { chat: values }
    end

    def chat_user_assigns(chat_user)
      raise('expected a chat_user') unless chat_user.kind_of?(ChatUser)

      values = {
        name: chat_user.name
      }.compact

      { user: values }
    end

  end
end
