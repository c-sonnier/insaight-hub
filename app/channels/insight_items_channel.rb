class InsightItemsChannel < ApplicationCable::Channel
  def subscribed
    # Get account_id from params - client must pass the account they want to subscribe to
    account_id = params[:account_id]

    # Verify identity has access to this account
    if account_id.present? && current_identity.users.exists?(account_id: account_id)
      stream_from "insight_items:#{account_id}"
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def self.broadcast_new_insight_item(insight_item)
    ActionCable.server.broadcast("insight_items:#{insight_item.account_id}", {
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
