# frozen_string_literal: true

require "openai"

module ::DiscourseChatbot
  # TODO: refactor ugly if-else blocks & instance variables amount
  class OpenAIBot < Bot
    CHAT_MODEL_NAMES = %w[gpt-3.5-turbo gpt-3.5-turbo-16k gpt-4 gpt-4-32k].freeze
    COMPLETIONS_MODEL_NAMES = %w[text-davinci-003 text-davinci-002].freeze

    def initialize
      @client = ::OpenAI::Client.new(access_token: SiteSetting.chatbot_open_ai_token)
    end

    def get_response(prompt, user = nil, statistics_tracker = nil)
      @user = user
      @statistics_tracker = statistics_tracker

      response = begin
                   if request_type_chat?
                     make_chat_request(prompt)
                   elsif request_type_completions?
                     make_completions_request(prompt)
                   end
                 end

      # TODO: remove this after testing
      ::Rails.logger.debug("Model name used for generating response: #{model_name}")

      error = response.parsed_response["error"]
      return handle_error_response(error["message"]) if error.present?

      record_tokens_usage(response)
      if request_type_chat?
        response.dig("choices", 0, "message", "content")
      elsif request_type_completions?
        response["choices"][0]["text"]
      end
    end

    def ask(opts)
      super(opts)
    end

    private

    attr_reader :client, :user, :statistics_tracker

    def record_tokens_usage(response)
      return unless response["choices"].present? || statistics_tracker.present?

      usage = response.dig("usage")
      statistics_tracker.update(
        prompt_tokens_consumed: usage.dig("prompt_tokens").to_i,
        completion_tokens_consumed: usage.dig("completion_tokens").to_i,
        total_tokens_consumed: usage.dig("total_tokens").to_i
      )
    end

    def request_type_chat?
      @_request_type_chat ||= begin
                                if use_brilliant_access_model?
                                  CHAT_MODEL_NAMES.include?(brilliant_access_model_name)
                                elsif use_custom_model?
                                  custom_model_type == "chat"
                                else
                                  CHAT_MODEL_NAMES.include?(default_model_name)
                                end
                              end
    end

    def request_type_completions?
      @_request_type_completions ||= begin
                                       if use_brilliant_access_model?
                                         COMPLETIONS_MODEL_NAMES.include?(brilliant_access_model_name)
                                       elsif use_custom_model?
                                         custom_model_type == "completions"
                                       else
                                         COMPLETIONS_MODEL_NAMES.include?(default_model_name)
                                       end
                                     end
    end

    def make_chat_request(prompt)
      client.chat(
        parameters: {
          model: model_name,
          messages: prompt,
          max_tokens: SiteSetting.chatbot_max_response_tokens,
          temperature: SiteSetting.chatbot_request_temperature / 100.0,
          top_p: SiteSetting.chatbot_request_top_p / 100.0,
          frequency_penalty: SiteSetting.chatbot_request_frequency_penalty / 100.0,
          presence_penalty: SiteSetting.chatbot_request_presence_penalty / 100.0
        })
    end

    def make_completions_request(prompt)
      client.completions(
        parameters: {
          model: SiteSetting.chatbot_open_ai_model,
          prompt: prompt,
          max_tokens: SiteSetting.chatbot_max_response_tokens,
          temperature: SiteSetting.chatbot_request_temperature / 100.0,
          top_p: SiteSetting.chatbot_request_top_p / 100.0,
          frequency_penalty: SiteSetting.chatbot_request_frequency_penalty / 100.0,
          presence_penalty: SiteSetting.chatbot_request_presence_penalty / 100.0
        })
    end

    def handle_error_response(error_message)
      raise StandardError, error_message
    rescue => e
      statistics_tracker&.failed!
      Rails.logger.error ("OpenAIBot: There was a problem: #{e}")
      I18n.t('chatbot.errors.general')
    end

    def model_name
      @_model_name ||= begin
                         return brilliant_access_model_name if use_brilliant_access_model?

                         use_custom_model? ? custom_model_name : default_model_name
                       end
    end

    def use_custom_model?
      @_use_custom_model ||= (SiteSetting.chatbot_open_ai_model_custom == true)
    end

    def use_brilliant_access_model?
      @_brilliant_access_groups ||= (brilliant_access_group_ids & user_group_ids).any?
    end

    def default_model_name
      @_default_model_name ||= SiteSetting.chatbot_open_ai_model
    end

    def custom_model_name
      @_custom_model_name ||= SiteSetting.chatbot_open_ai_model_custom_name
    end

    def brilliant_access_model_name
      @_brilliant_users_model_name ||= SiteSetting.chatbot_brilliant_access_ai_model
    end

    def user_group_ids
      @_user_group_ids ||= GroupUser.where(user: user).pluck(:group_id)
    end

    def brilliant_access_group_ids
      @_brilliant_access_group_ids ||= SiteSetting.chatbot_brilliant_access_groups.split('|').map(&:to_i)
    end

    def custom_model_type
      @_custom_model_type ||= SiteSetting.chatbot_open_ai_model_custom_type
    end
  end
end
