module Effective
  class NotificationJob < ApplicationJob

    def perform(id, force:)
      Notification.find(id).notify!(force: force)
    end

  end
end
