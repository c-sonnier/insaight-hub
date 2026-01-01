# frozen_string_literal: true

class AddCommentTool < MCP::Tool
  description "Add a comment to an insight"

  input_schema(
    properties: {
      slug: { type: "string", description: "The insight slug" },
      body: { type: "string", description: "The comment body text" },
      parent_id: { type: "integer", description: "Parent comment ID for replies (optional)" }
    },
    required: ["slug", "body"]
  )

  class << self
    def call(slug:, body:, parent_id: nil, server_context:)
      user = server_context[:user]

      # Find the insight
      insight_item = InsightItem.find_by(slug: slug)
      unless insight_item
        return MCP::Tool::Response.new([{
          type: "text",
          text: { error: "Insight not found with slug: #{slug}" }.to_json
        }])
      end

      # Validate parent comment if provided
      if parent_id.present?
        parent_comment = Comment.find_by(id: parent_id)
        unless parent_comment
          return MCP::Tool::Response.new([{
            type: "text",
            text: { error: "Parent comment not found with id: #{parent_id}" }.to_json
          }])
        end
      end

      # Create the comment
      comment = Comment.new(body: body, parent_id: parent_id)
      engagement = insight_item.engagements.build(
        user: user,
        engageable: comment
      )

      if engagement.save
        result = {
          success: true,
          comment: {
            id: comment.id,
            body: comment.body,
            parent_id: comment.parent_id,
            user: { id: user.id, name: user.name },
            created_at: engagement.created_at.iso8601
          }
        }
        MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
      else
        errors = engagement.errors.full_messages + comment.errors.full_messages
        MCP::Tool::Response.new([{
          type: "text",
          text: { error: "Could not create comment", messages: errors }.to_json
        }])
      end
    end
  end
end

