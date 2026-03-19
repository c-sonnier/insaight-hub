# frozen_string_literal: true

class PublishInsightTool < MCP::Tool
  extend OrganizationResolvable

  description "Publish a draft insight to make it visible to all users"

  input_schema(
    properties: {
      organization: { type: "string", description: "Organization name or ID (use list_organizations to find)" },
      slug: { type: "string", description: "The insight slug to publish" }
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
          text: { error: "You can only publish your own insights" }.to_json
        }])
      end

      if insight.published?
        return MCP::Tool::Response.new([{
          type: "text",
          text: { message: "Insight is already published", slug: slug }.to_json
        }])
      end

      insight.publish!

      result = {
        success: true,
        organization: account.name,
        insight: {
          id: insight.id,
          title: insight.title,
          slug: insight.slug,
          status: insight.status,
          published_at: insight.published_at&.iso8601
        }
      }
      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end
  end
end
