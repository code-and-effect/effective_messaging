# frozen_string_literal: true

Rails.application.routes.draw do
  mount EffectiveMessaging::Engine => '/', as: 'effective_messaging'

  namespace :admin do
    resources :chats
  end
end

EffectiveMessaging::Engine.routes.draw do
  # Public routes
  scope module: 'effective' do
    resources :chats, only: [:show, :update]
  end

  namespace :admin do
  end

end
