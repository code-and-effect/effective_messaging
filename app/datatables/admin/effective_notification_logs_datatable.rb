module Admin
  class EffectiveNotificationLogsDatatable < Effective::Datatable
    datatable do
      order :created_at

      col :id, visible: false
      col :created_at, as: :date, label: 'Date'

      col :notification
      col :report, visible: !attributes[:inline]
      col :resource, search: :string
      col :user, search: :string
      col :email
      col :skipped

      actions_col
    end

    collection do
      Effective::NotificationLog.deep.all
    end
  end
end
