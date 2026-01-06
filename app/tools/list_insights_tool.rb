# frozen_string_literal: true

class ListInsightsTool < MCP::Tool
  description "List insights with optional filtering by status, audience, tag, or search query"

  input_schema(
    properties: {
      status: { type: "string", description: "Filter by status: draft or published" },
      audience: { type: "string", description: "Filter by audience: developer, stakeholder, or end_user" },
      tag: { type: "string", description: "Filter by tag" },
      search: { type: "string", description: "Search in title and description" },
      page: { type: "integer", description: "Page number (default: 1)" },
      per_page: { type: "integer", description: "Items per page (default: 20, max: 100)" }
    },
    required: []
  )

  class << self
    def call(status: nil, audience: nil, tag: nil, search: nil, page: 1, per_page: 20, server_context:)
      account = server_context[:account]
      insights = account.insight_items.includes(user: :identity)

      # Apply filters
      insights = insights.where(status: status) if status.present?
      insights = insights.by_audience(audience) if audience.present?
      insights = insights.by_tag(tag) if tag.present?
      insights = insights.search(search) if search.present?

      # Order by most recent
      insights = insights.order(created_at: :desc)

      # Pagination
      current_page = [page.to_i, 1].max
      items_per_page = [[per_page.to_i, 1].max, 100].min
      items_per_page = 20 if items_per_page == 0

      total_count = insights.count
      total_pages = (total_count.to_f / items_per_page).ceil
      offset = (current_page - 1) * items_per_page

      insights = insights.offset(offset).limit(items_per_page)

      result = {
        insights: insights.map { |i| insight_summary(i) },
        meta: {
          current_page: current_page,
          total_pages: total_pages,
          total_count: total_count,
          per_page: items_per_page
        }
      }

      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end

    private

    def insight_summary(insight)
      {
        id: insight.id,
        title: insight.title,
        slug: insight.slug,
        description: insight.description,
        audience: insight.audience,
        status: insight.status,
        tags: insight.tags,
        file_count: insight.insight_item_files.count,
        author: {
          id: insight.user.id,
          name: insight.user.name
        },
        published_at: insight.published_at&.iso8601,
        created_at: insight.created_at.iso8601,
        updated_at: insight.updated_at.iso8601
      }
    end
  end
end
