# Dashboard Chats
class EffectiveChatsDatatable < Effective::Datatable
  datatable do
    order :updated_at

    col :token, visible: false
    col :created_at, visible: false
    col :updated_at

    col :title

    col :chat_users, label: 'Participants'
    col :chat_messages_count, label: 'Messages'

    col :anonymous, visible: false
    col :parent, visible: false

    actions_col
  end

  collection do
    Effective::Chat.deep.where(id: current_user.chats)
  end

end
