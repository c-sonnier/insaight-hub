# frozen_string_literal: true

class CreateInsightTool < MCP::Tool
  description "Create a new insight. Use 'content' for single-file insights or 'files' for multi-file insights"

  input_schema(
    properties: {
      title: { type: "string", description: "The insight title" },
      slug: { type: "string", description: "URL-friendly slug (auto-generated if not provided)" },
      description: { type: "string", description: "Brief description of the insight" },
      audience: { type: "string", description: "Target audience: developer, stakeholder, or end_user" },
      tags: { type: "array", items: { type: "string" }, description: "Array of tags for categorization" },
      content: { type: "string", description: "HTML content for single-file insights" },
      files: { type: "array", description: "Array of files [{filename: string, content: string}] for multi-file insights" },
      entry_file: { type: "string", description: "Entry file name for multi-file insights (default: index.html)" },
      publish: { type: "boolean", description: "Publish immediately (default: false)" }
    },
    required: ["title", "audience"]
  )

  class << self
    def call(title:, audience:, slug: nil, description: nil, tags: nil, content: nil, files: nil, entry_file: nil, publish: false, server_context:)
      user = server_context[:user]

      # Validate audience
      unless InsightItem.audiences.keys.include?(audience)
        return MCP::Tool::Response.new([{
          type: "text",
          text: { error: "Invalid audience. Must be: developer, stakeholder, or end_user" }.to_json
        }])
      end

      # Validate that either content or files is provided
      if content.blank? && (files.blank? || files.empty?)
        return MCP::Tool::Response.new([{
          type: "text",
          text: { error: "Either 'content' or 'files' must be provided" }.to_json
        }])
      end

      insight = InsightItem.new(
        user: user,
        title: title,
        slug: slug.presence,
        description: description,
        audience: audience,
        entry_file: entry_file.presence || "index.html",
        status: :draft
      )

      insight.tags = tags if tags.present?

      # Build files
      if content.present?
        # Single file mode
        insight.insight_item_files.build(
          filename: "index.html",
          content: content,
          content_type: "text/html"
        )
      elsif files.present?
        # Multi-file mode
        files.each do |file_data|
          filename = file_data["filename"] || file_data[:filename]
          file_content = file_data["content"] || file_data[:content]
          content_type = detect_content_type(filename)

          insight.insight_item_files.build(
            filename: filename,
            content: file_content,
            content_type: content_type
          )
        end
      end

      if insight.save
        insight.publish! if publish

        result = {
          success: true,
          insight: {
            id: insight.id,
            title: insight.title,
            slug: insight.slug,
            status: insight.status,
            file_count: insight.insight_item_files.count
          }
        }
        MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
      else
        MCP::Tool::Response.new([{
          type: "text",
          text: { error: "Validation failed", messages: insight.errors.full_messages }.to_json
        }])
      end
    end

    private

    def detect_content_type(filename)
      case File.extname(filename).downcase
      when ".html", ".htm"
        "text/html"
      when ".css"
        "text/css"
      when ".js"
        "text/javascript"
      when ".json"
        "application/json"
      when ".md", ".markdown"
        "text/markdown"
      else
        "text/plain"
      end
    end
  end
end
