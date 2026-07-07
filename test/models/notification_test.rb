require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "unread scope excludes read notifications" do
    assert_includes Notification.unread, notifications(:unread_published)
    refute_includes Notification.unread, notifications(:read_comment)
  end

  test "read! marks notification as read" do
    notification = notifications(:unread_published)
    notification.read!
    assert notification.read?
  end
end
