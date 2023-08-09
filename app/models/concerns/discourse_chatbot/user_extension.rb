# frozen_string_literal: true

module DiscourseChatbot
  module UserExtension
    extend ActiveSupport::Concern

    prepended do
      has_many :chatbot_usages,
               class_name: "DiscourseChatbot::UsageHistory",
               dependent: :destroy
    end
  end
end
