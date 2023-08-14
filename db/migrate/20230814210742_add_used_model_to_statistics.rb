class AddUsedModelToStatistics < ActiveRecord::Migration[7.0]
  def change
    add_column :discourse_chatbot_usage_histories, :used_ai_model, :string
  end
end
