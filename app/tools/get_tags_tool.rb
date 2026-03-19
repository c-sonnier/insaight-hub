# frozen_string_literal: true

class GetTagsTool < MCP::Tool
  extend OrganizationResolvable

  description "Get all unique tags used across insights"

  input_schema(
    properties: {
      organization: { type: "string", description: "Organization name or ID (use list_organizations to find)" }
    },
    required: []
  )

  class << self
    def call(organization: nil, server_context:)
      account, _user, error = resolve_organization(organization: organization, server_context: server_context)
      return error if error

      # Extract all unique tags from account's insights
      tags = account.insight_items
        .where.not(metadata: nil)
        .pluck(:metadata)
        .map { |m| m&.dig("tags") }
        .compact
        .flatten
        .uniq
        .sort

      result = { organization: account.name, tags: tags }
      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end
  end
end
