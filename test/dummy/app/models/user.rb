class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  acts_as_addressable :billing

  effective_messaging_user
end
