require "test_helper"

class RubyNativeTest < ActionDispatch::IntegrationTest
  NATIVE_UA = { "HTTP_USER_AGENT" => "Ruby Native/1.0" }

  setup do
    @account = accounts(:default)
    sign_in_as identities(:member)
  end

  test "web request shows sidebar and hides native tabs" do
    get "/#{@account.external_id}/dashboard"
    assert_response :success
    assert_select ".drawer"
    assert_select "[data-native-tabs]", count: 0
  end

  test "native request hides sidebar and shows native tabs" do
    get "/#{@account.external_id}/dashboard", headers: NATIVE_UA
    assert_response :success
    assert_select ".drawer", count: 0
    assert_select "[data-native-tabs]"
    assert_select "main.native-inset"
  end

  test "native request includes ruby_native stylesheet" do
    get "/#{@account.external_id}/dashboard", headers: NATIVE_UA
    assert_select "link[href*='ruby_native']"
  end

  test "unauthenticated native request does not show tabs" do
    delete session_path
    get new_session_path, headers: NATIVE_UA
    assert_response :success
    assert_select "[data-native-tabs]", count: 0
  end

  test "unprefixed tab paths redirect to the account-scoped path" do
    get "/dashboard", headers: NATIVE_UA
    assert_redirected_to "/#{@account.external_id}/dashboard"

    get "/insight_items", headers: NATIVE_UA
    assert_redirected_to "/#{@account.external_id}/insight_items"
  end

  test "native config endpoint returns tabs" do
    get "/native/config"
    assert_response :success
    tabs = response.parsed_body["tabs"]
    assert_equal [ "Dashboard", "Browse", "Profile" ], tabs.map { |t| t["title"] }
  end

  private

  def sign_in_as(identity)
    post session_path, params: { email_address: identity.email_address, password: "password123" }
  end
end
