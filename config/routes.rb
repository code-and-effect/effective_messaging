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
    resources :chat_messages, except: [:new, :create]

    resources :notifications do
      post :enable, on: :member
      post :disable, on: :member

      post :send_now, on: :member
      post :skip_once, on: :member
    end

    resources :notification_logs, only: [:index, :destroy]
  end

end
