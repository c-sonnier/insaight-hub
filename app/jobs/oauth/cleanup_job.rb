module Oauth
  class CleanupJob < ApplicationJob
    queue_as :default

    def perform
      Oauth::AuthorizationCode.where("expires_at < ?", 1.hour.ago).delete_all
      Oauth::AccessToken.where("expires_at < ? OR revoked_at < ?", 1.day.ago, 1.day.ago).delete_all
      Oauth::RefreshToken.where("expires_at < ? OR revoked_at < ?", 1.day.ago, 1.day.ago).delete_all
    end
  end
end
