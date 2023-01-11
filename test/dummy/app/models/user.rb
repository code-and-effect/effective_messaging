class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  acts_as_addressable :billing

  effective_messaging_user

  def effective_messaging_anonymous_name
    'Anonymous' + Base64::encode64("#{id}-#{created_at.strftime('%F')}").chomp.first(8)
  end

end
