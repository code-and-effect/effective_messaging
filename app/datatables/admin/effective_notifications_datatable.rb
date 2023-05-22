module Admin
  class EffectiveNotificationsDatatable < Effective::Datatable
    filters do
      scope :all
    end

    datatable do
      order :updated_at

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :audience
      col :audience_emails, visible: false

      col :schedule
      col :schedule_type, visible: false
      col :immediate_days, visible: false
      col :immediate_times, visible: false

      col :report, search: Effective::Report.emails.sorted

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
