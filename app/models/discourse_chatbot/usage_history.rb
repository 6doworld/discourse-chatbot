# frozen_string_literal: true

module DiscourseChatbot
  class UsageHistory < ActiveRecord::Base
    # RELATIONS
    belongs_to :user

    # VALIDATIONS
    validates :status, presence: true

    # ENUMS
    enum :status, [:initialized, :launched, :failed, :sent]
  end
end
