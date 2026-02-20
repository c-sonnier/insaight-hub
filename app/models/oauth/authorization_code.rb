module Oauth
  class AuthorizationCode < ApplicationRecord
    self.table_name = "oauth_authorization_codes"

    belongs_to :oauth_client, class_name: "Oauth::Client"
    belongs_to :identity
    belongs_to :account

    validates :code_digest, presence: true, uniqueness: true
    validates :redirect_uri, presence: true
    validates :code_challenge, presence: true
    validates :expires_at, presence: true

    scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

    def expired?
      expires_at < Time.current
    end

    def used?
      used_at.present?
    end

    def use!
      update!(used_at: Time.current)
    end

    def self.create_for(client:, identity:, account:, redirect_uri:, scope:, code_challenge:, code_challenge_method:, resource:, state:)
      plaintext_code = SecureRandom.hex(32)

      code = create!(
        oauth_client: client,
        identity: identity,
        account: account,
        code_digest: Digest::SHA256.hexdigest(plaintext_code),
        redirect_uri: redirect_uri,
        scope: scope,
        code_challenge: code_challenge,
        code_challenge_method: code_challenge_method || "S256",
        resource: resource,
        state: state,
        expires_at: 10.minutes.from_now
      )

      { code: code, plaintext_code: plaintext_code }
    end

    def self.find_by_plaintext(code)
      find_by(code_digest: Digest::SHA256.hexdigest(code))
    end
  end
end
