module Admin
  class EffectiveChatsDatatable < Effective::Datatable

    datatable do
      col :id, visible: false
      col :token, visible: false

      col :created_at, visible: false
      col :updated_at

      col :parent, visible: false

      col :chat_users
      col :chat_messages
      col :chat_messages_count

      col :title
      col :anonymous

      actions_col
    end

    collection do
      Effective::Chat.deep.all
    end

  end
end
