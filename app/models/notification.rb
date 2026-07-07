class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :account
  belongs_to :insight_item
  belongs_to :comment, optional: true

  enum :action, {
    insight_published: "insight_published",
    insight_updated: "insight_updated",
    comment_created: "comment_created"
  }

  validates :action, presence: true, inclusion: { in: actions.keys }

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_to_recipient

  def read?
    read_at.present?
  end

  def read!
    update!(read_at: Time.current) unless read?
  end

  private

  def broadcast_to_recipient
    broadcast_prepend_to "notifications_#{recipient_id}",
      target: "notifications_dropdown_list",
      partial: "notifications/notification",
      locals: { notification: self }
    broadcast_replace_to "notifications_#{recipient_id}",
      target: "notifications_badge",
      partial: "notifications/badge",
      locals: { user: recipient }
  end
end
