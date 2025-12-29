class ReportsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "reports"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def self.broadcast_new_report(report)
    ActionCable.server.broadcast("reports", {
      type: "new_report",
      report: {
        id: report.id,
        slug: report.slug,
        title: report.title,
        description: report.description,
        audience: report.audience,
        tags: report.tags,
        user_name: report.user.name,
        published_at: report.published_at&.iso8601
      }
    })
  end
end
