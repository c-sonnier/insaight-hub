class InsightItemsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "insight_items"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def self.broadcast_new_insight_item(insight_item)
    ActionCable.server.broadcast("insight_items", {
      type: "new_insight",
      insight_item: {
        id: insight_item.id,
        slug: insight_item.slug,
        title: insight_item.title,
        description: insight_item.description,
        audience: insight_item.audience,
        tags: insight_item.tags,
        user_name: insight_item.user.name,
        published_at: insight_item.published_at&.iso8601
      }
    })
  end
end
