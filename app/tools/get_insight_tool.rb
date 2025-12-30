# frozen_string_literal: true

class GetInsightTool < MCP::Tool
  description "Get a single insight by slug, including all its files"

  input_schema(
    properties: {
      slug: { type: "string", description: "The insight slug" }
    },
    required: ["slug"]
  )

  class << self
    def call(slug:, server_context:)
      insight = InsightItem.includes(:user, :insight_item_files).find_by(slug: slug)

      unless insight
        return MCP::Tool::Response.new([{
          type: "text",
          text: { error: "Insight not found", slug: slug }.to_json
        }])
      end

      result = {
        insight: {
          id: insight.id,
          title: insight.title,
          slug: insight.slug,
          description: insight.description,
          audience: insight.audience,
          status: insight.status,
          tags: insight.tags,
          entry_file: insight.entry_file,
          author: {
            id: insight.user.id,
            name: insight.user.name
          },
          files: insight.insight_item_files.map do |file|
            {
              id: file.id,
              filename: file.filename,
              content_type: file.content_type,
              content: file.content
            }
          end,
          published_at: insight.published_at&.iso8601,
          created_at: insight.created_at.iso8601,
          updated_at: insight.updated_at.iso8601
        }
      }

      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end
  end
end
