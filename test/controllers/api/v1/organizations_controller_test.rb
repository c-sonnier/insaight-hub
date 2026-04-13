require "test_helper"

module Api
  module V1
    class OrganizationsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @identity = identities(:owner)
        @other_identity = identities(:other_owner)
        @admin_identity = identities(:admin)
      end

      test "GET /api/v1/organizations without token returns 401" do
        get "/api/v1/organizations"
        assert_response :unauthorized
      end

      test "GET /api/v1/organizations with invalid token returns 401" do
        get "/api/v1/organizations", headers: { "Authorization" => "Bearer bogus" }
        assert_response :unauthorized
      end

      test "GET /api/v1/organizations returns identity's memberships" do
        get "/api/v1/organizations", headers: { "Authorization" => "Bearer #{@identity.api_token}" }
        assert_response :success

        body = JSON.parse(response.body)
        orgs = body.fetch("organizations")
        assert_kind_of Array, orgs
        assert_equal 1, orgs.length

        org = orgs.first
        assert_equal accounts(:default).external_id, org["id"]
        assert_equal accounts(:default).name, org["name"]
        assert_equal "owner", org["role"]
      end

      test "GET /api/v1/organizations scopes to the authenticated identity" do
        get "/api/v1/organizations", headers: { "Authorization" => "Bearer #{@other_identity.api_token}" }
        assert_response :success

        body = JSON.parse(response.body)
        orgs = body.fetch("organizations")
        assert_equal 1, orgs.length
        assert_equal accounts(:other_account).external_id, orgs.first["id"]
      end

      test "GET /api/v1/organizations does not require an account prefix" do
        # Sanity: the same path wrapped in an account UUID must not leak into this action
        get "/api/v1/organizations", headers: { "Authorization" => "Bearer #{@identity.api_token}" }
        assert_response :success
      end

      test "GET /api/v1/organizations works for super admins without memberships" do
        @admin_identity.users.destroy_all
        get "/api/v1/organizations", headers: { "Authorization" => "Bearer #{@admin_identity.api_token}" }
        assert_response :success

        body = JSON.parse(response.body)
        assert_equal [], body.fetch("organizations")
      end
    end
  end
end
