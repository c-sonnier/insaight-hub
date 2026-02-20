module Oauth
  class AccessToken < ApplicationRecord
    self.table_name = "oauth_access_tokens"

    belongs_to :oauth_client, class_name: "Oauth::Client"
    belongs_to :identity
    belongs_to :account
    belongs_to :oauth_refresh_token, class_name: "Oauth::RefreshToken", optional: true

    validates :token_digest, presence: true, uniqueness: true
    validates :expires_at, presence: true

    scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

    def expired?
      expires_at < Time.current
    end

    def revoked?
      revoked_at.present?
    end

    def revoke!
      update!(revoked_at: Time.current)
    end

    def active?
      !expired? && !revoked?
    end

    def self.create_for(client:, identity:, account:, scope:, resource:, refresh_token: nil)
      plaintext_token = SecureRandom.hex(32)

      token = create!(
        oauth_client: client,
        identity: identity,
        account: account,
        token_digest: Digest::SHA256.hexdigest(plaintext_token),
        scope: scope,
        resource: resource,
        oauth_refresh_token: refresh_token,
        expires_at: 1.hour.from_now
      )

      { token: token, plaintext_token: plaintext_token }
    end

    def self.find_by_plaintext(token)
      find_by(token_digest: Digest::SHA256.hexdigest(token))
    end
  end
end
