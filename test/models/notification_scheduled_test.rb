require 'test_helper'
require 'timecop'

class NotificatioScheduledTest < ActiveSupport::TestCase

  test 'send report on the following dates' do
    5.times { create_user!() }

    notification = build_scheduled_report_notification()
    notification.save!

    assert notification.scheduled_dates.all? { |date| date.kind_of?(String) }
    dates = notification.scheduled_dates.map { |date| Time.zone.parse(date) }

    assert_equal 3, dates.length
    assert_equal 5, notification.rows_count

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
