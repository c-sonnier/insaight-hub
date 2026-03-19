# frozen_string_literal: true

class MoveInsightTool < MCP::Tool
  extend OrganizationResolvable

  description "Move an insight from one organization to another. You must be a member of both organizations."

  input_schema(
    properties: {
      slug: { type: "string", description: "The insight slug to move" },
      from_organization: { type: "string", description: "Source organization name or ID" },
      to_organization: { type: "string", description: "Target organization name or ID" }
    },
    required: ["slug", "from_organization", "to_organization"]
  )

  class << self
    def call(slug:, from_organization:, to_organization:, server_context:)
      identity = server_context[:identity]

      # Resolve source org
      source_account, source_user, error = resolve_organization(organization: from_organization, server_context: server_context)
      return error if error

      # Resolve target org
      target_account, target_user, error = resolve_organization(organization: to_organization, server_context: server_context)
      return error if error

      # Find the insight in source org
      insight = source_account.insight_items.find_by(slug: slug)

      unless insight
        return MCP::Tool::Response.new([{
          type: "text",
          text: { error: "Insight not found in '#{source_account.name}'", slug: slug }.to_json
        }])
      end

      # Check ownership
      unless insight.user_id == source_user.id
        return MCP::Tool::Response.new([{
          type: "text",
          text: { error: "You can only move your own insights" }.to_json
        }])
      end

      insight.update!(account: target_account, user: target_user)

      result = {
        success: true,
        message: "Moved '#{insight.title}' from '#{source_account.name}' to '#{target_account.name}'",
        insight: {
          slug: insight.slug,
          organization: target_account.name
        }
      }
      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end
  end
end
