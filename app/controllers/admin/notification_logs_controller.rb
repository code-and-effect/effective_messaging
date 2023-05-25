module Admin
  class NotificationLogsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_messaging) }

    include Effective::CrudController

    private

    def permitted_params
      params.require(:effective_notification_log).permit!
    end

  end
end
