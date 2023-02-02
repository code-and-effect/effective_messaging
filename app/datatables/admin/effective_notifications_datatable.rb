module Admin
  class EffectiveNotificationsDatatable < Effective::Datatable
    filters do
      scope :all
      scope :notifiable, label: 'Upcoming'
      scope :completed
    end

    datatable do
      order :updated_at

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :send_at
      col :report, search: Effective::Report.emails.sorted

      col :subject
      col :body, visible: false

      col :from, visible: false
      col :cc, visible: false
      col :bcc, visible: false

      col :started_at, visible: false
      col :completed_at
      col :notifications_sent, visible: false

      actions_col
    end

    collection do
      Effective::Notification.deep.all
    end
  end
end
