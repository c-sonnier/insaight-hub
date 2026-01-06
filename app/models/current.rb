class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :account

  # Identity is the authenticated person (from session)
  delegate :identity, to: :session, allow_nil: true

  # User is the membership for the current account
  # This is computed based on identity + account
  def user
    return nil unless identity && account
    @user ||= identity.users.find_by(account: account)
  end

  # Reset user cache when account changes
  def account=(value)
    @user = nil
    super
  end

  # Convenience methods for checking roles
  def owner?
    user&.owner?
  end

  def member?
    user&.member?
  end

  def super_admin?
    identity&.admin?
  end
end
