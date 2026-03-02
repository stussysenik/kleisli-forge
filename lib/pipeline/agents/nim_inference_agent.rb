module Pipeline
  module Agents
    # Agent 6: Calls NVIDIA NIM API for AI inference
    # Category Theory Role: External functor (NIM API)
    # Supports both streaming and non-streaming modes
    class NimInferenceAgent < BaseAgent
      agent_name "nim_inference"
      agent_position 6

      attr_reader :on_token

      # Pass a block for streaming: agent.on_stream { |delta, full| ... }
      def on_stream(&block)
        @on_token = block
        self
      end

      protected

      def process(input)
        messages = input[:messages]
        prefs = input[:model_preferences] || {}

        if @on_token
          result = nim_client.stream(
            messages: messages,
            temperature: prefs[:temperature] || 0.2,
            max_tokens: prefs[:max_tokens] || 4096
          ) do |delta, full|
            @on_token.call(delta, full)
          end
        else
          result = nim_client.chat_with_fallback(
            messages: messages,
            temperature: prefs[:temperature] || 0.2,
            max_tokens: prefs[:max_tokens] || 4096
          )
        end

        Success({
          raw_response: result[:content],
          model_used: result[:model],
          usage: result[:usage],
          spec_context: input[:spec_context]
        })
      rescue Nim::Client::Error => e
        Failure(error: "NIM inference failed: #{e.message}", stage: name)
      end

      def validate_input(input)
        if input[:messages].blank?
          Failure(error: "No messages provided for NIM inference", stage: name)
        else
          Success(input)
        end
      end
    end
  end
end
