# rake effective_messaging:notify
namespace :effective_messaging do
  desc 'Sends scheduled notifications for effective messaging'
  task notify: :environment do
    puts 'Sending notifications'

    notifications = Effective::Notification.all.deep.notifiable

    notifications.find_each do |notification|
      begin
        notified = notification.notify!
        Rails.logger.info "Sent notifications for #{notification.report}" if notified
      rescue => e
        if defined?(ExceptionNotifier)
          data = { notification_id: notification.id, report_id: notification.report_id, resource_id: notification.current_resource&.id }
          ExceptionNotifier.notify_exception(e, data: data)
        end

        puts "Error with effective_messaging #{notification.id} resource #{notification.current_resource&.id}: #{e.errors.inspect}"
      end
    end

    puts 'All done'
  end
end
