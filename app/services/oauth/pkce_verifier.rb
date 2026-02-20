module Oauth
  class PkceVerifier
    def self.verify(code_verifier:, code_challenge:, method: "S256")
      return false if code_verifier.blank? || code_challenge.blank?
      return false unless method == "S256"

      expected = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
      ActiveSupport::SecurityUtils.secure_compare(expected, code_challenge)
    end
  end
end
