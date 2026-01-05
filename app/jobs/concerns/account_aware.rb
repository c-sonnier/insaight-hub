# Concern for background jobs that need account context
#
# Usage:
#   class MyJob < ApplicationJob
#     include AccountAware
#
#     def perform(account_id:, **args)
#       with_account_context(account_id) do
#         # Current.account is now set
#         do_work(**args)
#       end
#     end
#   end
#
module AccountAware
  extend ActiveSupport::Concern

  private

  def with_account_context(account_id)
    return yield if account_id.blank?

    account = Account.find_by(id: account_id)
    return yield unless account

    Current.set(account: account) { yield }
  end

  def with_full_context(account_id:, identity_id:)
    account = Account.find_by(id: account_id)
    identity = Identity.find_by(id: identity_id)

    Current.set(account: account, identity: identity) do
      if account && identity
        Current.user = identity.users.find_by(account: account)
      end
      yield
    end
  end
end
