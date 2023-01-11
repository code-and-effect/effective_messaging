module Admin
  class EffectiveChatsDatatable < Effective::Datatable

    datatable do
      col :id, visible: false
      col :token, visible: false

      col :created_at, visible: false
      col :updated_at

      col :parent, visible: false
      col :title
      col :anonymous

      col :chat_users

      col(:chat_users, search: :string) do |chat|
        if chat.anonymous?
          chat.chat_users.map do |chat_user|
            content_tag(:div, chat_user.name, class_name: 'col-resource_item')
          end
        else
          chat.chat_users.map do |chat_user|
            link = link_to(chat_user.name, "/admin/users/#{chat_user.user_id}/edit")
            content_tag(:div, link, class_name: 'col-resource_item')
          end
        end.join
      end.search do |collection, term|
        Effective::Chat.search_by_chat_user_name(term)
      end

      col :chat_messages_count, label: 'Num Messages'

      col :last_notified_at, visible: false

      actions_col(new: false)
    end

    collection do
      scope = Effective::Chat.deep.all

      if attributes[:user_id].present? && attributes[:user_type].present?
        user = attributes[:user_type].constantize.find(attributes[:user_id])
        scope = Effective::Chat.for_user(user)
      end

      scope
    end

  end
end
