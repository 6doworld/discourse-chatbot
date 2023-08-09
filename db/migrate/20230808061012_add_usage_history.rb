# frozen_string_literal: true

class AddUsageHistory < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_chatbot_usage_histories do |t|
      t.integer :user_id, null: false, index: true
      t.integer :status, null: false, default: 0
      t.integer :prompt_tokens_consumed
      t.integer :completion_tokens_consumed
      t.integer :total_tokens_consumed
      t.timestamps
    end
  end
end
