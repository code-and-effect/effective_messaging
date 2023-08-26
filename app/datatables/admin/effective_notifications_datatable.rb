module Admin
  class EffectiveNotificationsDatatable < Effective::Datatable
    filters do
      scope :all
      scope :enabled
      scope :disabled
    end

    datatable do
      order :updated_at

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :audience, visible: false

      col :audience_emails, label: 'Send to' do |notification|
        if notification.audience == 'emails'
          notification.audience_emails.join(', ')
        else
          'report user'
        end
      end

      col :enabled

      col :schedule
      col :schedule_type, visible: false
      col :immediate_days, visible: false
      col :immediate_times, visible: false
      col :scheduled_method, visible: false
      col :scheduled_dates, visible: false

      col :report, search: Effective::Report.notifiable.sorted, action: :show

      col(:rows_count) do |notification|
        notification.report.collection().count
      end

      col :subject
      col :body, visible: false

      col :from, visible: false, search: Array(EffectiveMessaging.froms).presence
      col :cc, visible: false
      col :bcc, visible: false

      col :last_notified_at
      col :last_notified_count

      actions_col
    end

    collection do
      Effective::Notification.deep.all
    end
  end
end
