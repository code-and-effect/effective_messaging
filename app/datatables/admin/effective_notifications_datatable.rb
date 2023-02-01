module Admin
  class EffectiveNotificationsDatatable < Effective::Datatable
    filters do
      scope :all
      scope :upcoming
      scope :notified
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

      col :last_notified_at

      actions_col
    end

    collection do
      Effective::Notification.deep.all
    end
  end
end
