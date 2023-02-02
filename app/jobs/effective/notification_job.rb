module Effective
  class NotificationJob < ApplicationJob

    def perform(id, force)
      notification = Notification.find(id)
      notification.notify!(force: force)
    end

  end
end
