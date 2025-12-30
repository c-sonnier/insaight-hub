# frozen_string_literal: true

class DeleteInsightTool < MCP::Tool
  description "Delete an insight and all its files"

  input_schema(
    properties: {
      slug: { type: "string", description: "The insight slug to delete" }
    },
    required: ["slug"]
  )

  class << self
    def call(slug:, server_context:)
      user = server_context[:user]
      insight = InsightItem.find_by(slug: slug)

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
