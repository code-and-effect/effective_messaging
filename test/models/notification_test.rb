require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  test 'notification sends emails' do
    notification = build_notification()
    notification.save!

    5.times { create_user!() }
    assert_equal 5, notification.rows_count

    assert_email(count: 5) { notification.notify! }

    assert_equal 5, notification.notifications_sent
  end

  test 'notification renders email' do
    notification = build_notification()
    user = build_user()

    rendered = notification.render_email(user)

    assert_equal user.email, rendered[:to]

    assert rendered[:subject].to_s.include?(user.first_name)
    assert rendered[:subject].to_s.include?(user.last_name)

    assert rendered[:body].to_s.include?(user.first_name)
    assert rendered[:body].to_s.include?(user.last_name)
  end

  test 'notifiable?' do
    notification = build_notification()
    assert notification.notifiable?
    assert notification.notify_now?

    notification.send_at = Time.zone.now + 1.minute
    assert notification.notifiable?
    refute notification.notify_now?

    notification.send_at = Time.zone.now - 1.minute
    assert notification.notifiable?
    assert notification.notify_now?

    notification.started_at = Time.zone.now
    refute notification.notifiable?

    notification.started_at = nil
    notification.completed_at = Time.zone.now
    refute notification.notifiable?
  end

end
