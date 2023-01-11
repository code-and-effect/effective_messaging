module Admin
  class EffectiveChatMessagesDatatable < Effective::Datatable

    datatable do
      col :id, visible: false
      col :token, visible: false

      col :created_at, label: 'Date'
      col :chat, search: :string

      col :name
      col :body, label: 'Message'

      actions_col
    end

    collection do
      scope = Effective::ChatMessage.deep.all

      if attributes[:user_id].present? && attributes[:user_type].present?
        user = attributes[:user_type].constantize.find(attributes[:user_id])
        scope = Effective::ChatMessage.for_user(user)
      end

      scope

    end

  end
end
