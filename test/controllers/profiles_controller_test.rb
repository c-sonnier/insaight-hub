require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:default)
    @identity = identities(:member)
    post session_path, params: { email_address: @identity.email_address, password: "password123" }
  end

  test "edit shows notification preference toggles" do
    get "/#{@account.external_id}/profile/edit"

    assert_response :success
    assert_includes response.body, "user[email_notifications]"
    assert_includes response.body, "user[in_app_notifications]"
  end

  test "update saves notification preferences" do
    patch "/#{@account.external_id}/profile", params: {
      user: { name: @identity.name, email_address: @identity.email_address, email_notifications: "0", in_app_notifications: "1" }
    }

    assert_redirected_to "/#{@account.external_id}/profile"
    @identity.reload
    assert_not @identity.email_notifications?
    assert @identity.in_app_notifications?
  end
end
