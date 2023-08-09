# frozen_string_literal: true

module DiscourseChatbot
  module Admin
    class StatisticsController < ::Admin::AdminController
      requires_plugin ::DiscourseChatbot::PLUGIN_NAME

      def show
        render_json_dump({
          total_tokens_consumed: total_tokens_consumed,
          total_chat_interactions: total_chat_interactions,
          total_users_interacted: total_users_interacted
        })
      end

      private

      def total_tokens_consumed
        @_total_tokens_consumed ||= ::DiscourseChatbot::UsageHistory.
          sum(:total_tokens_consumed)
      end

      def total_chat_interactions
        @_total_chat_interactions ||= ::DiscourseChatbot::UsageHistory.count
      end

      def total_users_interacted
        @_total_users_interacted ||= ::DiscourseChatbot::UsageHistory.
          select(:user_id).
          distinct.count
      end
    end
  end
end
