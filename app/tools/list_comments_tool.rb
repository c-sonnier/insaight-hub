# frozen_string_literal: true

class ListCommentsTool < MCP::Tool
  description "List comments on an insight"

  input_schema(
    properties: {
      slug: { type: "string", description: "The insight slug" },
      include_replies: { type: "boolean", description: "Include nested replies (default: true)" }
    },
    required: ["slug"]
  )

  class << self
    def call(slug:, include_replies: true, server_context:)
      # Find the insight
      insight_item = InsightItem.find_by(slug: slug)
      unless insight_item
        return MCP::Tool::Response.new([{
          type: "text",
          text: { error: "Insight not found with slug: #{slug}" }.to_json
        }])
      end

      # Fetch comments
      engagements = insight_item.engagements.comments.includes(:user, engageable: :replies).recent

      comments = engagements.map do |engagement|
        comment = engagement.engageable
        format_comment(comment, engagement, include_replies)
      end

      result = {
        insight: {
          id: insight_item.id,
          title: insight_item.title,
          slug: insight_item.slug
        },
        comments_count: insight_item.comments_count,
        comments: comments
      }

      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end

    private

    def format_comment(comment, engagement, include_replies)
      data = {
        id: comment.id,
        body: comment.body,
        user: { id: engagement.user.id, name: engagement.user.name },
        created_at: engagement.created_at.iso8601,
        updated_at: comment.updated_at.iso8601
      }

      if include_replies && comment.replies.any?
        data[:replies] = comment.replies.map do |reply|
          {
            id: reply.id,
            body: reply.body,
            user: reply.engagement ? { id: reply.engagement.user.id, name: reply.engagement.user.name } : nil,
            created_at: reply.engagement&.created_at&.iso8601,
            updated_at: reply.updated_at.iso8601
          }
        end
      end

      data
    end
  end
end

