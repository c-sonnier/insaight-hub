# frozen_string_literal: true

class UpdateInsightTool < MCP::Tool
  description "Update an existing insight's metadata and/or files"

  input_schema(
    properties: {
      slug: { type: "string", description: "The insight slug to update" },
      title: { type: "string", description: "New title" },
      description: { type: "string", description: "New description" },
      audience: { type: "string", description: "New audience: developer, stakeholder, or end_user" },
      tags: { type: "array", items: { type: "string" }, description: "New tags (replaces existing)" },
      entry_file: { type: "string", description: "New entry file name" },
      files: { type: "array", description: "Files to add or update [{filename: string, content: string}]" }
    },
    required: ["slug"]
  )

  class << self
    def call(slug:, title: nil, description: nil, audience: nil, tags: nil, entry_file: nil, files: nil, server_context:)
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
          text: { error: "You can only update your own insights" }.to_json
        }])
      end

      # Update attributes
      insight.title = title if title.present?
      insight.description = description if description.present?
      insight.entry_file = entry_file if entry_file.present?

      if audience.present?
        unless InsightItem.audiences.keys.include?(audience)
          return MCP::Tool::Response.new([{
            type: "text",
            text: { error: "Invalid audience. Must be: developer, stakeholder, or end_user" }.to_json
          }])
        end
        insight.audience = audience
      end

      insight.tags = tags if tags.present?

      # Upsert files
      if files.present?
        files.each do |file_data|
          filename = file_data["filename"] || file_data[:filename]
          file_content = file_data["content"] || file_data[:content]
          content_type = detect_content_type(filename)

          existing_file = insight.insight_item_files.find_by(filename: filename)
          if existing_file
            existing_file.update(content: file_content, content_type: content_type)
          else
            insight.insight_item_files.build(
              filename: filename,
              content: file_content,
              content_type: content_type
            )
          end
        end
      end

      if insight.save
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
      else
        "text/plain"
      end
    end
  end
end
