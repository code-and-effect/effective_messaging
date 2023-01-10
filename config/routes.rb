# frozen_string_literal: true

Rails.application.routes.draw do
  mount EffectiveMessaging::Engine => '/', as: 'effective_messaging'
end

EffectiveMessaging::Engine.routes.draw do
  # Public routes
  scope module: 'effective' do
  end

  namespace :admin do
  end

end
