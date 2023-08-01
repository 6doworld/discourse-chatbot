# frozen_string_literal: true
require "openai"

module ::DiscourseChatbot
  class Bot

    def initialize
      raise "Overwrite me!"
    end

    def get_response(prompt, user = nil)
      raise "Overwrite me!"
    end

    def ask(opts)
      content = opts[:type] == POST ? PostPromptUtils.create_prompt(opts) : MessagePromptUtils.create_prompt(opts)

      get_response(content, asking_user(opts[:user_id]))
    end

    private

    def asking_user(user_id)
      @_asking_user ||= ::User.find_by(id: user_id)
    end
  end
end
