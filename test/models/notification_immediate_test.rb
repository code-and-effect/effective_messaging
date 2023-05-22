require 'test_helper'
require 'timecop'

class NotificatioImmediateTest < ActiveSupport::TestCase

  test 'send report immediately then every 7 days for 3 times total' do
    5.times { create_user!() }

    notification = build_immediate_report_notification()
    notification.save!

    assert_equal 7, notification.immediate_days
    assert_equal 3, notification.immediate_times
    assert_equal 5, notification.rows_count

    now = Time.zone.now.beginning_of_day

    # Send the first time
    with_time_travel(now) { assert_email(count: 5) { notification.notify! } }

    # Nothing to do
    with_time_travel(now + 1.days) { assert_email(count: 0) { notification.notify! } }
    with_time_travel(now + 6.days) { assert_email(count: 0) { notification.notify! } }

    # Send the second time
    with_time_travel(now + 7.days) { assert_email(count: 5) { notification.notify! } }

    # Nothing to do
    with_time_travel(now + 13.days) { assert_email(count: 0) { notification.notify! } }

    # Send the third time
    with_time_travel(now + 14.days) { assert_email(count: 5) { notification.notify! } }

    # Nothing to do
    with_time_travel(now + 20.days) { assert_email(count: 0) { notification.notify! } }

    # Nothing to do. We already sent 3 times
    with_time_travel(now + 21.days) { assert_email(count: 0) { notification.notify! } }
    with_time_travel(now + 28.days) { assert_email(count: 0) { notification.notify! } }
  end

  test 'send emails immediately then every 7 days for 3 times total' do
    5.times { create_user!() }

    notification = build_immedate_emails_notification()
    notification.save!

    assert_equal 7, notification.immediate_days
    assert_equal 3, notification.immediate_times
    assert_equal 5, notification.rows_count

    now = Time.zone.now.beginning_of_day

    # Send the first time
    with_time_travel(now) { assert_email(count: 5) { notification.notify! } }

    # Nothing to do
    with_time_travel(now + 1.days) { assert_email(count: 0) { notification.notify! } }
    with_time_travel(now + 6.days) { assert_email(count: 0) { notification.notify! } }

    # Send the second time
    with_time_travel(now + 7.days) { assert_email(count: 5) { notification.notify! } }

    # Nothing to do
    with_time_travel(now + 13.days) { assert_email(count: 0) { notification.notify! } }

    # Send the third time
    with_time_travel(now + 14.days) { assert_email(count: 5) { notification.notify! } }

    # Nothing to do
    with_time_travel(now + 20.days) { assert_email(count: 0) { notification.notify! } }

    # Nothing to do. We already sent 3 times
    with_time_travel(now + 21.days) { assert_email(count: 0) { notification.notify! } }
    with_time_travel(now + 28.days) { assert_email(count: 0) { notification.notify! } }
  end

  test 'send immediately for 1 time total' do
    5.times { create_user!() }

    notification = build_immediate_report_notification()
    notification.update!(immediate_days: 0, immediate_times: 1)

    now = Time.zone.now.beginning_of_day

    # Send the first time
    with_time_travel(now) { assert_email(count: 5) { notification.notify! } }

    # Nothing to do
    with_time_travel(now + 1.days) { assert_email(count: 0) { notification.notify! } }
    with_time_travel(now + 2.days) { assert_email(count: 0) { notification.notify! } }
  end

  # TODO LATER THIS WILL BE FOR SCHEDULED IMMEDIATE EMAILS WITH AUDIENCE EMAILS
  # test 'send immediately for 1 time total' do
  #   5.times { create_user!() }

  #   notification = build_immediate_report_notification()
  #   notification.update!(immediate_days: 0, immediate_times: 1)

  #   now = Time.zone.now.beginning_of_day

  #   # Send the first time
  #   with_time_travel(now) { assert_email(count: 5) { notification.notify! } }

  #   # Nothing to do
  #   with_time_travel(now + 1.days) { assert_email(count: 0) { notification.notify! } }
  #   with_time_travel(now + 2.days) { assert_email(count: 0) { notification.notify! } }
  # end

end
