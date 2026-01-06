# frozen_string_literal: true

# Helper methods for generating account-scoped URLs and paths
# These are useful when you need to generate a path/URL for a specific account
# that may differ from the current request's account context
module AccountRoutingHelper
  # Generate a path prefixed with the account's external_id
  # account_path_for(account, :dashboard) => "/uuid/dashboard"
  # account_path_for(account, :insight_items) => "/uuid/insight_items"
  def account_path_for(account, path_name, *args)
    account_uuid = account.is_a?(Account) ? account.external_id : account
    path = public_send("#{path_name}_path", *args)
    "/#{account_uuid}#{path}"
  end

  # Generate a URL prefixed with the account's external_id
  def account_url_for(account, path_name, *args)
    account_uuid = account.is_a?(Account) ? account.external_id : account
    url = public_send("#{path_name}_url", *args)

    # Insert account UUID after the host
    uri = URI.parse(url)
    uri.path = "/#{account_uuid}#{uri.path}"
    uri.to_s
  end

  # Get the current account's external_id for use in paths
  def current_account_path_prefix
    Current.account&.external_id
  end

  # Helper to build account-scoped dashboard path
  def account_dashboard_path(account = Current.account)
    return dashboard_path if account.nil?
    "/#{account.external_id}/dashboard"
  end

  # Helper to build account-scoped root path (dashboard)
  def account_root_path(account = Current.account)
    return root_path if account.nil?
    "/#{account.external_id}/"
  end
end
