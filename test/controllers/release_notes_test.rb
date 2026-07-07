require "test_helper"

class ReleaseNotesTest < ActionDispatch::IntegrationTest
  test "release notes page is public" do
    get "/release-notes"

    assert_response :success
    assert_includes response.body, "Release Notes"
    assert_includes response.body, "Notifications"
  end

  test "release notes page renders for signed-in members" do
    post session_path, params: { email_address: identities(:member).email_address, password: "password123" }

    get "/release-notes"

    assert_response :success
  end
end
