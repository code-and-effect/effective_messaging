module Admin
  class NotificationsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_messaging) }

    include Effective::CrudController

    private

    def permitted_params
      params.require(:effective_notification).permit!
    end

  end
end
