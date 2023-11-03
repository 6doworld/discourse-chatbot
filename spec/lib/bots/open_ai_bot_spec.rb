# frozen_string_literal: true

require_relative '../../plugin_helper'

describe ::DiscourseChatbot::OpenAIBot do
  shared_examples "saves tokens usage" do
    let(:user) { Fabricate(:user) }
    let(:statistics_tracker) do
      ::DiscourseChatbot::UsageHistory.new(user: user, status: :initialized)
    end

    it "saves tokens usage" do
      subject
      statistics_tracker.reload

      expect(statistics_tracker.prompt_tokens_consumed).to eq(17)
      expect(statistics_tracker.completion_tokens_consumed).to eq(17)
      expect(statistics_tracker.total_tokens_consumed).to eq(34)
    end
  end

  shared_examples "does not save tokens usage" do
    it "does not save tokens usage" do
      subject
      expect(::DiscourseChatbot::UsageHistory.count).to eq(0)
    end
  end

  shared_examples "when request was successful" do
    let(:bot_response) do
      OpenStruct.new(
        parsed_response: {},
        choices: choices,
        usage: {
          "prompt_tokens" => "17", # dummy value
          "completion_tokens" => "17", # dummy value
          "total_tokens" => "34", # dummy value
        }
      )
    end

    it { is_expected.to eq 'Foo' }

    # workaround while using mocha gem
    it 'uses proper model name' do
      subject
      expect(openai_bot.send(:model_name)).to eq model_name
    end

    it_behaves_like "saves tokens usage"
  end

  shared_examples "when request ended up with error" do
    let(:bot_response) { OpenStruct.new(parsed_response: { "error" => "Error" }) }
    let(:error_message) do
      "Sorry, I'm not well right now. Lets talk some other time. " \
        "Meanwhile, please ask the admin to check the logs, thank you!"
    end

    before do
      Rails.logger.expects(:error).with("OpenAIBot: There was a problem: StandardError")
    end

    it { is_expected.to eq error_message }

    # workaround while using mocha gem
    it 'uses proper model name' do
      subject
      expect(openai_bot.send(:model_name)).to eq model_name
    end

    it_behaves_like "does not save tokens usage"
  end

  let(:openai_bot) { ::DiscourseChatbot::OpenAIBot.new }

  describe "#get_response" do
    subject { openai_bot.get_response("User prompt", user, statistics_tracker) }

    let(:user) { nil }
    let(:statistics_tracker) { nil }
    let(:choices) do
      [
        {
          "message" => {
            "content" => "Foo"
          }
        }
      ]
    end

    context "when request type is chat" do
      before do
        ::OpenAI::Client.any_instance.stubs(:chat).returns(bot_response)
      end

      context "when using default model" do
        %w[gpt-3.5-turbo gpt-3.5-turbo-16k gpt-4 gpt-4-32k].each do |model|
          let(:model_name) { model }

          before do
            SiteSetting.set("chatbot_open_ai_model", model_name)
            SiteSetting.set("chatbot_open_ai_model_custom", false)
            SiteSetting.set("chatbot_open_ai_model_custom_type", "completions")
            SiteSetting.set("chatbot_open_ai_model_custom_name", "my_awesome_custom_model")
          end

          it_behaves_like "when request was successful"
          it_behaves_like "when request ended up with error"
        end
      end

      context "when using custom model" do
        let(:model_name) { "my_awesome_custom_model" }

        before do
          SiteSetting.set("chatbot_open_ai_model_custom", true)
          SiteSetting.set("chatbot_open_ai_model", "gpt-3.5-turbo")
          SiteSetting.set("chatbot_open_ai_model_custom_name", model_name)
          SiteSetting.set("chatbot_open_ai_model_custom_type", "chat")
        end

        it_behaves_like "when request was successful"
        it_behaves_like "when request ended up with error"
      end
    end

    context "when request type is completions" do
      let(:choices) { [{ "text" => "Foo" }] }

      before do
        ::OpenAI::Client.any_instance.stubs(:completions).returns(bot_response)
      end

      context "when using default model" do
        %w[text-davinci-003 text-davinci-002].each do |model|
          let(:model_name) { model }

          before do
            SiteSetting.set("chatbot_open_ai_model", model_name)
            SiteSetting.set("chatbot_open_ai_model_custom", false)
            SiteSetting.set("chatbot_open_ai_model_custom_type", "chat")
            SiteSetting.set("chatbot_open_ai_model_custom_name", "my_awesome_custom_model")
          end

          it_behaves_like "when request was successful"
          it_behaves_like "when request ended up with error"
        end
      end

      context "when using custom model" do
        let(:model_name) { "my_awesome_custom_model" }

        before do
          SiteSetting.set("chatbot_open_ai_model_custom", true)
          SiteSetting.set("chatbot_open_ai_model", "text-davinci-003")
          SiteSetting.set("chatbot_open_ai_model_custom_name", model_name)
          SiteSetting.set("chatbot_open_ai_model_custom_type", "completions")
        end

        it_behaves_like "when request was successful"
        it_behaves_like "when request ended up with error"
      end
    end

    context "when user is in diamond access group" do
      let(:model_name) { "gpt-4" }
      let!(:user) { Fabricate(:admin) }

      before do
        ::OpenAI::Client.any_instance.stubs(:chat).returns(bot_response)

        SiteSetting.set("chatbot_brilliant_access_groups", "1") # 1 is admins group id
        SiteSetting.set("chatbot_brilliant_access_ai_model", model_name)
      end

      it_behaves_like "when request was successful"
      it_behaves_like "when request ended up with error"
    end

    context "when user is not in diamond access group" do
      let(:model_name) { "gpt-3.5-turbo" }
      let!(:user) { Fabricate(:user) }

      before do
        ::OpenAI::Client.any_instance.stubs(:chat).returns(bot_response)

        SiteSetting.set("chatbot_brilliant_access_groups", "1") # 1 is admins group id
        SiteSetting.set("chatbot_brilliant_access_ai_model", "gpt-4")
      end

      it_behaves_like "when request was successful"
      it_behaves_like "when request ended up with error"
    end
  end
end
