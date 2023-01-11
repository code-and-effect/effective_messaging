module Effective
  class ChatsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    include Effective::CrudController

    resource_scope -> { Effective::Chat.all.deep }

    private

    def permitted_params
      params.require(:effective_chat).permit(:user_type, chat_messages_attributes: [:body])
    end

  end
end
