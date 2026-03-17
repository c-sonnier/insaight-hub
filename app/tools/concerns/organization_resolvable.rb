# frozen_string_literal: true

module OrganizationResolvable
  # Resolves the account from the organization param or falls back to server_context[:account].
  # Returns [account, user, error_response].
  # If error_response is present, the caller should return it immediately.
  def resolve_organization(organization: nil, server_context:)
    identity = server_context[:identity]

    if organization.present?
      # Look up by name or UUID
      account = identity.accounts.find_by(external_id: organization) ||
                identity.accounts.find_by(name: organization)

      unless account
        return [nil, nil, MCP::Tool::Response.new([{
          type: "text",
          text: { error: "Organization not found. Use list_organizations to see your available organizations." }.to_json
        }])]
      end

      user = identity.users.find_by(account: account)
      [account, user, nil]
    elsif server_context[:account]
      # Fall back to URL-based account context
      [server_context[:account], server_context[:user], nil]
    else
      [nil, nil, MCP::Tool::Response.new([{
        type: "text",
        text: { error: "Organization is required. Use list_organizations to see your available organizations." }.to_json
      }])]
    end
  end
end
