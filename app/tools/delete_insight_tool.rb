# frozen_string_literal: true

class DeleteInsightTool < MCP::Tool
  extend OrganizationResolvable

  description "Delete an insight and all its files"

  input_schema(
    properties: {
      organization: { type: "string", description: "Organization name or ID (use list_organizations to find)" },
      slug: { type: "string", description: "The insight slug to delete" }
    },
    required: ["slug"]
  )

  class << self
    def call(slug:, organization: nil, server_context:)
      account, user, error = resolve_organization(organization: organization, server_context: server_context)
      return error if error

      insight = account.insight_items.find_by(slug: slug)

      unless insight
        return MCP::Tool::Response.new([{
          type: "text",
          text: { error: "Insight not found", slug: slug }.to_json
        }])
      end

      # Check ownership
      unless insight.user_id == user.id
        return MCP::Tool::Response.new([{
          type: "text",
          text: { error: "You can only delete your own insights" }.to_json
        }])
      end

      title = insight.title
      insight.destroy!

      result = {
        success: true,
        message: "Insight '#{title}' has been deleted"
      }
      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end
  end
end
