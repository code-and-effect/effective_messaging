module Admin
  class ChatMessagesController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_messaging) }

    include Effective::CrudController

    def permitted_params
      params.require(:effective_chat_message).permit!
    end

  end
end
