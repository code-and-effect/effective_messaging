require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  test 'report notification sends many emails to users' do
    notification = build_immediate_report_notification()
    notification.save!

    users = 5.times.map { create_user!() }

    assert_equal 0, notification.notification_logs.count
    assert_equal 5, notification.rows_count

    assert_email(count: 5) { notification.notify! }

    assert_equal 5, notification.notification_logs.count
    assert_equal 5, notification.last_notified_count
    assert_equal Time.zone.now.beginning_of_day, notification.last_notified_at.beginning_of_day

    mails = ActionMailer::Base.deliveries.last(5)
    assert_equal 5, mails.length

    users.each do |user|
      assert notification.notification_logs.find { |log| log.email == user.email }.present?
      assert mails.find { |mail| mail.to.join(',') == user.email }.present?
    end
  end

  test 'emails notification sends many emails to audience_emails' do
    notification = build_immedate_emails_notification()
    notification.save!

    users = 5.times.map { create_user!() }

    assert_equal 0, notification.notification_logs.count
    assert_equal 5, notification.rows_count

    assert_email(count: 5) { notification.notify! }

    mails = ActionMailer::Base.deliveries.last(5)
    assert_equal 5, mails.length

    mails.each do |mail|
      assert_equal mail.to.join(','), notification.audience_emails.join(',')
    end

    assert_equal 5, notification.notification_logs.count
    assert_equal 5, notification.last_notified_count
    assert_equal Time.zone.now.beginning_of_day, notification.last_notified_at.beginning_of_day

    users.each do |user|
      assert notification.notification_logs.find { |log| log.email == user.email }.present?
    end
  end

  test 'scheduled emails notification sends many emails to users' do
    notification = build_scheduled_report_notification()
    notification.save!

    refute notification.scheduled_email?

    users = 5.times.map { create_user!() }

    assert_equal 0, notification.notification_logs.count
    assert_equal 5, notification.rows_count

    assert_email(count: 5) { notification.notify! }

    assert_equal 5, notification.notification_logs.count
    assert_equal 5, notification.last_notified_count
    assert_equal Time.zone.now.beginning_of_day, notification.last_notified_at.beginning_of_day

    mails = ActionMailer::Base.deliveries.last(5)
    assert_equal 5, mails.length

    users.each do |user|
      assert notification.notification_logs.find { |log| log.email == user.email }.present?
      assert mails.find { |mail| mail.to.join(',') == user.email }.present?
    end
  end

  # This case is unique. This is scheduled_email?
  test 'scheduled emails notification sends one email to audience_emails' do
    notification = build_scheduled_emails_notification()
    notification.save!

    assert notification.scheduled_email?

    users = 5.times.map { create_user!() }

    assert_equal 0, notification.notification_logs.count
    assert_equal 5, notification.rows_count

    with_time_travel(notification.scheduled_dates.first) do
      assert_email(count: 1) { notification.notify! }

      mails = ActionMailer::Base.deliveries.last(1)

      mails.each do |mail|
        assert_equal mail.to.join(','), notification.audience_emails.join(',')
      end

      assert_equal 1, notification.notification_logs.count
      assert_equal 1, notification.last_notified_count
      assert_equal Time.zone.now.beginning_of_day, notification.last_notified_at.beginning_of_day
    end
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
