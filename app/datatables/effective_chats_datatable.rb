# Dashboard Chats
class EffectiveChatsDatatable < Effective::Datatable
  datatable do
    order :updated_at

    col :token, visible: false
    col :created_at, visible: false
    col :updated_at, label: 'Last active'

    col :title
    col :chat_users
    col :chat_messages_count, label: ets(Effective::ChatMessage)

    actions_col
  end

  collection do
    chats = Effective::Chat.deep.where(id: current_user.chats)

    if attributes[:year].present?
      chats = chats.where(created_at: Time.zone.local(attributes[:year]).all_year)
    end

    chats
  end

end
