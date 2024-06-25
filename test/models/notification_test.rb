require 'test_helper'
require 'timecop'

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

    with_time_travel(notification.scheduled_dates.first) do
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

  test 'scheduled email with attached report' do
    notification = build_scheduled_emails_notification()
    notification.assign_attributes(attach_report: true)
    notification.save!

    assert notification.scheduled_email?

    users = 5.times.map { create_user!() }
    assert_equal 5, notification.rows_count

    with_time_travel(notification.scheduled_dates.first) do
      assert_email(count: 1) { notification.notify! }

      mail = ActionMailer::Base.deliveries.last
      assert mail.attachments.present?

      attachment = mail.attachments.first
      assert_equal "#{Time.zone.now.strftime('%F')}-test-report.csv", attachment.filename
      assert attachment.content_type.include?('csv')

      body = attachment.body.to_s
      assert body.include?('Id,Email,First name,Last name')

      users.each do |user|
        assert body.include?(user.id.to_s)
        assert body.include?(user.email.to_s)
        assert body.include?(user.first_name.to_s)
        assert body.include?(user.last_name.to_s)
      end

      assert_equal 1, notification.notification_logs.count
      assert_equal 1, notification.last_notified_count
      assert_equal Time.zone.now.beginning_of_day, notification.last_notified_at.beginning_of_day
    end
  end

  test 'notification previews email' do
    notification = build_immediate_report_notification()
    user = create_user!()

    assert_equal 1, notification.rows_count

    message = notification.preview()

    assert_equal user.email, message.to.first

    assert message.subject.to_s.include?(user.first_name)
    assert message.subject.to_s.include?(user.last_name)

    assert message.body.to_s.include?(user.first_name)
    assert message.body.to_s.include?(user.last_name)
  end

  test 'report notification with html email' do
    template = Effective::EmailTemplate.where(template_name: :notification).first!
    template.save_as_html!

    notification = build_immediate_report_notification()

    notification.update!(
      body: '<p>Hello {{ first_name }} {{ last_name }}</p>',
      content_type: 'text/html'
    )

    users = 5.times.map { create_user!() }

    assert_equal 0, notification.notification_logs.count
    assert_equal 5, notification.rows_count

    assert_email(count: 5, html_layout: true) { notification.notify! }

    assert_equal 5, notification.notification_logs.count
    assert_equal 5, notification.last_notified_count
    assert_equal Time.zone.now.beginning_of_day, notification.last_notified_at.beginning_of_day

    mails = ActionMailer::Base.deliveries.last(5)
    assert_equal 5, mails.length

    mails.each do |message|
      html_body = message.parts.find { |part| part.content_type.start_with?('text/html') }
      assert html_body.present?
    end

    users.each do |user|
      assert notification.notification_logs.find { |log| log.email == user.email }.present?
      assert mails.find { |mail| mail.to.join(',') == user.email }.present?
    end
  end

end
