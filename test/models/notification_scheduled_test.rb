require 'test_helper'
require 'timecop'

class NotificatioScheduledTest < ActiveSupport::TestCase

  test 'send report on the following dates' do
    5.times { create_user!() }

    notification = build_scheduled_report_notification()
    notification.save!

    refute notification.scheduled_email?

    assert notification.scheduled_dates.all? { |date| date.kind_of?(String) }
    dates = notification.scheduled_dates.map { |date| Time.zone.parse(date).beginning_of_day }

    assert_equal 3, dates.length
    assert_equal 5, notification.rows_count

    # Nothing to do
    with_time_travel(dates.first - 1.day) { assert_email(count: 0) { notification.notify! } }

    # Send the first time
    with_time_travel(dates.first) { assert_email(count: 5) { notification.notify! } }

    # Nothing to do
    with_time_travel(dates.first + 1.days) { assert_email(count: 0) { notification.notify! } }
    with_time_travel(dates.second - 6.days) { assert_email(count: 0) { notification.notify! } }

    # Send the second time
    with_time_travel(dates.second) { assert_email(count: 5) { notification.notify! } }

    # Third time
    with_time_travel(dates.third) { assert_email(count: 5) { notification.notify! } }

    # Nothing to do
    with_time_travel(dates.third + 2.days) { assert_email(count: 0) { notification.notify! } }
  end

  test 'scheduled email on the following dates' do
    5.times { create_user!() }

    notification = build_scheduled_emails_notification()
    notification.save!

    assert notification.scheduled_email?

    assert notification.scheduled_dates.all? { |date| date.kind_of?(String) }
    dates = notification.scheduled_dates.map { |date| Time.zone.parse(date).beginning_of_day }

    assert_equal 3, dates.length
    assert_equal 5, notification.rows_count

    # Nothing to do
    with_time_travel(dates.first - 1.day) { assert_email(count: 0) { notification.notify! } }

    # Send the first time
    with_time_travel(dates.first) { assert_email(count: 1) { notification.notify! } }

    # Nothing to do
    with_time_travel(dates.first + 1.days) { assert_email(count: 0) { notification.notify! } }
    with_time_travel(dates.second - 6.days) { assert_email(count: 0) { notification.notify! } }

    # Send the second time
    with_time_travel(dates.second) { assert_email(count: 1) { notification.notify! } }

    # Third time
    with_time_travel(dates.third) { assert_email(count: 1) { notification.notify! } }

    # Nothing to do
    with_time_travel(dates.third + 2.days) { assert_email(count: 0) { notification.notify! } }
  end

end
