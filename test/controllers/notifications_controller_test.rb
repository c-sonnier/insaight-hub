require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:default)
    sign_in_as identities(:member)
  end

  test "index lists current user's notifications" do
    get "/#{@account.external_id}/notifications"

    assert_response :success
    assert_includes response.body, insight_items(:one).title
  end

  test "read marks notification read and redirects to its insight" do
    notification = notifications(:unread_published)

    post "/#{@account.external_id}/notifications/#{notification.id}/read"

    assert notification.reload.read?
    assert_redirected_to "/#{@account.external_id}/insight_items/#{notification.insight_item.slug}"
  end

  test "read rejects another user's notification" do
    notification = notifications(:read_comment)   # belongs to owner_user

    post "/#{@account.external_id}/notifications/#{notification.id}/read"

    assert_response :not_found
  end

  test "read_all as turbo_stream refreshes badge and dropdown list" do
    post "/#{@account.external_id}/notifications/read_all", headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.body, 'target="notifications_badge"'
    assert_includes response.body, 'target="notifications_dropdown_list"'
    assert_equal 0, users(:member_user).notifications.unread.count
  end

  test "read_all marks all notifications read" do
    post "/#{@account.external_id}/notifications/read_all"

    assert_equal 0, users(:member_user).notifications.unread.count
    assert_redirected_to "/#{@account.external_id}/notifications"
  end

  private

  def sign_in_as(identity)
    post session_path, params: { email_address: identity.email_address, password: "password123" }
  end
end
