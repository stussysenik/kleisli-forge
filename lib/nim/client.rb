require "faraday"
require "faraday/retry"
require "json"

module Nim
  class Client
    BASE_URL = "https://integrate.api.nvidia.com/v1"
    DEFAULT_MODEL = "qwen/qwen3-coder-480b-a35b-instruct"
    FALLBACK_MODEL = "nvidia/llama-3.1-nemotron-ultra-253b-v1"

    class Error < StandardError; end
    class AuthenticationError < Error; end
    class RateLimitError < Error; end
    class ModelError < Error; end

    attr_reader :model

    def initialize(api_key: nil, model: nil, timeout: 120)
      @api_key = api_key || Rails.application.credentials.dig(:nvidia_nim, :api_key)
      @model = model || DEFAULT_MODEL
      @timeout = timeout

      raise AuthenticationError, "NVIDIA NIM API key not configured" if @api_key.blank?
    end

    # Standard (non-streaming) chat completion
    def chat(messages:, temperature: 0.2, max_tokens: 4096, **options)
      payload = {
        model: @model,
        messages: messages,
        temperature: temperature,
        max_tokens: max_tokens,
        **options
      }

      response = connection.post("/v1/chat/completions") do |req|
        req.body = payload.to_json
      end

      parse_response(response)
    rescue Faraday::Error => e
      handle_faraday_error(e)
    end

    # Streaming chat completion - yields chunks as they arrive
    def stream(messages:, temperature: 0.2, max_tokens: 4096, &block)
      payload = {
        model: @model,
        messages: messages,
        temperature: temperature,
        max_tokens: max_tokens,
        stream: true
      }

      full_content = ""
      buffer = ""

      streaming_connection.post("/v1/chat/completions") do |req|
        req.body = payload.to_json
        req.options.on_data = proc do |chunk, _size, _env|
          buffer += chunk
          while (line_end = buffer.index("\n"))
            line = buffer.slice!(0..line_end).strip
            next if line.empty?
            next unless line.start_with?("data: ")

            data = line.sub("data: ", "")
            next if data == "[DONE]"

            parsed = JSON.parse(data)
            delta = parsed.dig("choices", 0, "delta", "content")
            if delta
              full_content += delta
              block&.call(delta, full_content)
            end
          end
        end
      end

      { content: full_content, model: @model, streaming: true }
    rescue Faraday::Error => e
      handle_faraday_error(e)
    end

    # Try primary model, fall back to secondary
    def chat_with_fallback(messages:, **options)
      chat(messages: messages, **options)
    rescue ModelError
      @model = FALLBACK_MODEL
      chat(messages: messages, **options)
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.request :json
        f.request :retry, {
          max: 3,
          interval: 1,
          interval_randomness: 0.5,
          backoff_factor: 2,
          retry_statuses: [429, 500, 502, 503, 504]
        }
        f.response :raise_error
        f.adapter Faraday.default_adapter
        f.headers["Authorization"] = "Bearer #{@api_key}"
        f.headers["Content-Type"] = "application/json"
        f.options.timeout = @timeout
        f.options.open_timeout = 10
      end
    end

    def streaming_connection
      @streaming_connection ||= Faraday.new(url: BASE_URL) do |f|
        f.headers["Authorization"] = "Bearer #{@api_key}"
        f.headers["Content-Type"] = "application/json"
        f.headers["Accept"] = "text/event-stream"
        f.options.timeout = @timeout
        f.options.open_timeout = 10
        f.adapter Faraday.default_adapter
      end
    end

    def parse_response(response)
      data = JSON.parse(response.body)
      content = data.dig("choices", 0, "message", "content")

      {
        content: content,
        model: data["model"],
        usage: data["usage"],
        finish_reason: data.dig("choices", 0, "finish_reason")
      }
    end

    def handle_faraday_error(error)
      case error
      when Faraday::UnauthorizedError
        raise AuthenticationError, "Invalid NIM API key"
      when Faraday::TooManyRequestsError
        raise RateLimitError, "NIM API rate limit exceeded"
      when Faraday::ClientError
        raise ModelError, "NIM API client error: #{error.message}"
      else
        raise Error, "NIM API error: #{error.message}"
      end
    end
  end
end
