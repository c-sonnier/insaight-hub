# frozen_string_literal: true

class ListOrganizationsTool < MCP::Tool
  description "List all organizations you belong to. Use this to find the organization name or ID to pass to other tools."

  input_schema(
    properties: {},
    required: []
  )

  class << self
    def call(server_context:)
      identity = server_context[:identity]

      organizations = identity.users.includes(:account).map do |user|
        {
          id: user.account.external_id,
          name: user.account.name,
          role: user.role,
          current: server_context[:account] == user.account
        }
      end

      result = { organizations: organizations }
      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end
  end
end
