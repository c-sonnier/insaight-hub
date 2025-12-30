# frozen_string_literal: true

class GetTagsTool < MCP::Tool
  description "Get all unique tags used across insights"

  input_schema(
    properties: {},
    required: []
  )

  class << self
    def call(server_context:)
      # Extract all unique tags from insights
      tags = InsightItem
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
