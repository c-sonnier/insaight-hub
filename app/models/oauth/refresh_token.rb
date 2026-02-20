module Oauth
  class RefreshToken < ApplicationRecord
    self.table_name = "oauth_refresh_tokens"

    belongs_to :oauth_client, class_name: "Oauth::Client"
    belongs_to :identity
    belongs_to :account
    belongs_to :previous_token, class_name: "Oauth::RefreshToken", optional: true

    has_many :access_tokens, class_name: "Oauth::AccessToken", foreign_key: :oauth_refresh_token_id, dependent: :destroy

    validates :token_digest, presence: true, uniqueness: true
    validates :expires_at, presence: true

    scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

    def expired?
      expires_at < Time.current
    end

    def revoked?
      revoked_at.present?
    end

    def active?
      !expired? && !revoked?
    end

    def revoke!
      transaction do
        update!(revoked_at: Time.current)
        access_tokens.where(revoked_at: nil).update_all(revoked_at: Time.current)
      end
    end

    def self.create_for(client:, identity:, account:, scope:, resource:, previous_token: nil)
      plaintext_token = SecureRandom.hex(32)

      token = create!(
        oauth_client: client,
        identity: identity,
        account: account,
        token_digest: Digest::SHA256.hexdigest(plaintext_token),
        scope: scope,
        resource: resource,
        previous_token: previous_token,
        expires_at: 30.days.from_now
      )

      { token: token, plaintext_token: plaintext_token }
    end

    def self.find_by_plaintext(token)
      find_by(token_digest: Digest::SHA256.hexdigest(token))
    end
  end
end
