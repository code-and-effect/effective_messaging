# rake effective_messaging:send_notifications
namespace :effective_messaging do
  desc 'Sends scheduled notifications for effective messaging'
  task send_notifications: :environment do
    puts 'Sending notifications'

    table = ActiveRecord::Base.connection.table_exists?(:notifications)
    blank_tenant = defined?(Tenant) && Tenant.current.blank?

    if table && !blank_tenant
      notifications = Effective::Notification.all.deep.enabled

      notifications.find_each do |notification|
        begin
          notification.notify!
          Rails.logger.info "Sent notifications for #{notification} and #{notification.report}"
        rescue => e
          data = { notification_id: notification.id, report_id: notification.report_id, resource_id: notification.current_resource&.id }
          ExceptionNotifier.notify_exception(e, data: data) if defined?(ExceptionNotifier)
          puts "Error with effective_messaging #{notification.id} resource #{notification.current_resource&.id}: #{e.errors.inspect}"
        end
      end
    end

    puts 'All done'
  end
end
