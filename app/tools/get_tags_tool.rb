# frozen_string_literal: true

class GetTagsTool < MCP::Tool
  description "Get all unique tags used across insights"

  input_schema(
    properties: {},
    required: []
  )

  class << self
    def call(server_context:)
      account = server_context[:account]

      # Extract all unique tags from account's insights
      tags = account.insight_items
        .where.not(metadata: nil)
        .pluck(:metadata)
        .map { |m| m&.dig("tags") }
        .compact
        .flatten
        .uniq
        .sort

      result = { tags: tags }
      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end
  end
end
