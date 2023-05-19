require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  test 'report notification sends many emails' do
    notification = build_immediate_report_notification()
    notification.save!

    users = 5.times.map { create_user!() }

    assert_equal 0, notification.notification_logs.count
    assert_equal 5, notification.rows_count

    assert_email(count: 5) { notification.notify! }

    assert_equal 5, notification.notification_logs.count
    assert_equal 5, notification.last_notified_count
    assert_equal Time.zone.now.beginning_of_day, notification.last_notified_at.beginning_of_day

    users.each do |user|
      assert notification.notification_logs.find { |log| log.email == user.email }.present?
    end
  end

  test 'emails notification sends one email' do
    notification = build_immedate_emails_notification()
    notification.save!

    5.times { create_user!() }

    assert_equal 0, notification.notification_logs.count
    assert_equal 5, notification.rows_count

    assert_email(count: 1) { notification.notify! }

    assert_equal 1, notification.notification_logs.count
    assert_equal 1, notification.last_notified_count
    assert_equal Time.zone.now.beginning_of_day, notification.last_notified_at.beginning_of_day

    assert_equal notification.audience_emails.join(','), notification.notification_logs.first.email
  end

  test 'notification renders email' do
    notification = build_immediate_report_notification()
    user = build_user()

    rendered = notification.render_email(user)

    assert_equal user.email, rendered[:to]

    assert rendered[:subject].to_s.include?(user.first_name)
    assert rendered[:subject].to_s.include?(user.last_name)

    assert rendered[:body].to_s.include?(user.first_name)
    assert rendered[:body].to_s.include?(user.last_name)
  end

end
