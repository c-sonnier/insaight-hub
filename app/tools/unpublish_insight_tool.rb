# frozen_string_literal: true

class UnpublishInsightTool < MCP::Tool
  description "Revert a published insight back to draft status"

  input_schema(
    properties: {
      slug: { type: "string", description: "The insight slug to unpublish" }
    },
    required: ["slug"]
  )

  class << self
    def call(slug:, server_context:)
      user = server_context[:user]
      account = server_context[:account]
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
          text: { error: "You can only unpublish your own insights" }.to_json
        }])
      end

      if insight.draft?
        return MCP::Tool::Response.new([{
          type: "text",
          text: { message: "Insight is already a draft", slug: slug }.to_json
        }])
      end

      insight.unpublish!

      result = {
        success: true,
        insight: {
          id: insight.id,
          title: insight.title,
          slug: insight.slug,
          status: insight.status
        }
      }
      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end
  end
end
