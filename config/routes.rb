# frozen_string_literal: true

Rails.application.routes.draw do
  mount EffectiveMessaging::Engine => '/', as: 'effective_messaging'
end

EffectiveMessaging::Engine.routes.draw do
  # Public routes
  scope module: 'effective' do
    resources :chats, only: [:show, :update]
  end

  namespace :admin do
    resources :chats
    resources :chat_messages, only: [:index, :show, :destroy]
  end

end
