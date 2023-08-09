# frozen_string_literal: true

::DiscourseChatbot::Engine.routes.draw do
  namespace :admin, constraints: AdminConstraint.new do
    get "statistics" => "statistics#show"
  end
end
