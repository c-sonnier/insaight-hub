module Oauth
  class Client < ApplicationRecord
    self.table_name = "oauth_clients"

    has_many :authorization_codes, class_name: "Oauth::AuthorizationCode", foreign_key: :oauth_client_id, dependent: :destroy
    has_many :access_tokens, class_name: "Oauth::AccessToken", foreign_key: :oauth_client_id, dependent: :destroy
    has_many :refresh_tokens, class_name: "Oauth::RefreshToken", foreign_key: :oauth_client_id, dependent: :destroy

    validates :client_id, presence: true, uniqueness: true
    validates :client_name, presence: true
    validates :redirect_uris, presence: true
    validate :validate_redirect_uris

    before_validation :generate_client_id, on: :create

    def confidential?
      token_endpoint_auth_method == "client_secret_post" || token_endpoint_auth_method == "client_secret_basic"
    end

    def valid_redirect_uri?(uri)
      redirect_uris.include?(uri)
    end

    def self.authenticate(client_id, client_secret)
      client = find_by(client_id: client_id)
      return nil unless client&.client_secret_digest.present?
      return nil unless BCrypt::Password.new(client.client_secret_digest) == client_secret
      client
    end

    def self.register(params)
      client = new(
        client_name: params[:client_name],
        redirect_uris: params[:redirect_uris] || [],
        grant_types: params[:grant_types] || ["authorization_code"],
        token_endpoint_auth_method: params[:token_endpoint_auth_method] || "none"
      )

      if client.confidential?
        secret = SecureRandom.hex(32)
        client.client_secret_digest = BCrypt::Password.create(secret)
      end

      registration_token = SecureRandom.hex(32)
      client.registration_access_token_digest = Digest::SHA256.hexdigest(registration_token)

      if client.save
        { client: client, client_secret: secret, registration_access_token: registration_token }
      else
        { client: client, errors: client.errors }
      end
    end

    private

    def generate_client_id
      self.client_id ||= SecureRandom.uuid
    end

    def validate_redirect_uris
      return if redirect_uris.blank?

      redirect_uris.each do |uri|
        parsed = URI.parse(uri)
        unless parsed.is_a?(URI::HTTP) || parsed.is_a?(URI::HTTPS)
          errors.add(:redirect_uris, "must be HTTP or HTTPS URIs")
          break
        end
        if parsed.host != "localhost" && parsed.host != "127.0.0.1" && parsed.scheme != "https"
          errors.add(:redirect_uris, "must use HTTPS (except localhost)")
          break
        end
      rescue URI::InvalidURIError
        errors.add(:redirect_uris, "contains an invalid URI")
        break
      end
    end
  end
end
