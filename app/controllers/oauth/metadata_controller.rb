module Oauth
  class MetadataController < BaseController
    def authorization_server
      render json: {
        issuer: root_url,
        authorization_endpoint: "#{root_url}oauth/authorize",
        token_endpoint: "#{root_url}oauth/token",
        registration_endpoint: "#{root_url}oauth/register",
        revocation_endpoint: "#{root_url}oauth/revoke",
        response_types_supported: ["code"],
        grant_types_supported: ["authorization_code", "refresh_token"],
        token_endpoint_auth_methods_supported: ["none", "client_secret_post"],
        code_challenge_methods_supported: ["S256"],
        scopes_supported: ["mcp:read", "mcp:write", "mcp:admin"]
      }
    end

    def protected_resource
      render json: {
        resource: request.original_url.sub("/.well-known/oauth-protected-resource", ""),
        authorization_servers: [root_url],
        scopes_supported: ["mcp:read", "mcp:write", "mcp:admin"],
        bearer_methods_supported: ["header"]
      }
    end
  end
end
