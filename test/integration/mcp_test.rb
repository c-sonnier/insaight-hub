require "test_helper"

class McpTest < ActionDispatch::IntegrationTest
  setup do
    @identity = identities(:owner)
    @account = accounts(:default)
  end

  test "rejects request without authorization header" do
    post_mcp rpc("tools/list"), token: nil

    assert_response :unauthorized
    assert_match "resource_metadata", response.headers["WWW-Authenticate"]
    assert_equal "Missing authorization header", response.parsed_body["error"]
  end

  test "rejects request with invalid token" do
    post_mcp rpc("tools/list"), token: "not-a-real-token"

    assert_response :unauthorized
    assert_equal "Invalid token", response.parsed_body["error"]
  end

  test "GET and DELETE are not supported" do
    get "/mcp"
    assert_response :method_not_allowed

    delete "/mcp"
    assert_response :method_not_allowed
  end

  test "initialize handshake returns server info" do
    post_mcp rpc("initialize", {
      protocolVersion: "2025-03-26",
      capabilities: {},
      clientInfo: { name: "test", version: "1.0" }
    })

    assert_response :success
    result = json_rpc_result
    assert_equal "digest-hub", result.dig("serverInfo", "name")
    assert result["instructions"].present?
  end

  test "tools/list returns all registered tools with schemas" do
    post_mcp rpc("tools/list")

    assert_response :success
    tools = json_rpc_result["tools"]
    names = tools.map { |t| t["name"] }

    %w[list_organizations_tool list_insights_tool get_insight_tool create_insight_tool
       update_insight_tool publish_insight_tool unpublish_insight_tool delete_insight_tool
       move_insight_tool get_tags_tool].each do |name|
      assert_includes names, name
    end

    get_insight = tools.find { |t| t["name"] == "get_insight_tool" }
    assert_equal [ "slug" ], get_insight.dig("inputSchema", "required")
    assert_equal %w[markdown html], get_insight.dig("inputSchema", "properties", "format", "enum")
  end

  test "tools/call executes a tool and returns text content" do
    post_mcp rpc("tools/call", { name: "get_tags_tool", arguments: {} })

    assert_response :success
    content = json_rpc_result["content"]
    assert_equal "text", content.first["type"]
    payload = JSON.parse(content.first["text"])
    assert_equal @account.name, payload["organization"]
  end

  test "tools/call with required and enum arguments" do
    post_mcp rpc("tools/call", {
      name: "get_insight_tool",
      arguments: { slug: "test-insight-one", format: "markdown" }
    })

    assert_response :success
    payload = JSON.parse(json_rpc_result["content"].first["text"])
    assert_equal "Test Insight One", payload.dig("insight", "title")
    assert_equal "markdown", payload.dig("insight", "format")
  end

  test "tools/call missing a required argument returns an error" do
    post_mcp rpc("tools/call", { name: "get_insight_tool", arguments: {} })

    assert_response :success
    body = response.parsed_body
    assert body["error"].present? || json_rpc_result["isError"],
      "expected a JSON-RPC error or isError result, got: #{body}"
  end

  test "account-prefixed endpoint scopes tools to that account" do
    post_mcp rpc("tools/call", { name: "get_tags_tool", arguments: {} }),
      path: "/#{@account.external_id}/mcp"

    assert_response :success
    payload = JSON.parse(json_rpc_result["content"].first["text"])
    assert_equal @account.name, payload["organization"]
  end

  test "non-member cannot use an account-prefixed endpoint" do
    post_mcp rpc("tools/list"),
      token: identities(:other_owner).api_token,
      path: "/#{@account.external_id}/mcp"

    assert_response :forbidden
  end

  private

  def post_mcp(body, token: @identity.api_token, path: "/mcp")
    headers = { "Content-Type" => "application/json" }
    headers["Authorization"] = "Bearer #{token}" if token
    post path, params: body.to_json, headers: headers
  end

  def rpc(method, params = {})
    { jsonrpc: "2.0", id: 1, method: method, params: params }
  end

  def json_rpc_result
    body = response.parsed_body
    assert_nil body["error"], "unexpected JSON-RPC error: #{body["error"].inspect}"
    body["result"]
  end
end
