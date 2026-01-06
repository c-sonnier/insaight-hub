class User < ApplicationRecord
  # User is now a membership model linking Identity to Account

  belongs_to :account
  belongs_to :identity
  has_many :insight_items, dependent: :destroy
  has_many :engagements, dependent: :destroy
  has_many :comments, through: :engagements, source: :engageable, source_type: "Comment"
  has_many :created_invites, class_name: "Invite", foreign_key: "created_by_id"

  # Delegations for backward compatibility during transition
  delegate :email_address, :name, :admin?, :api_token, :theme, :avatar, to: :identity
  delegate :external_id, to: :account, prefix: true

  enum :role, { member: "member", owner: "owner" }, default: :member

  validates :role, presence: true
  validates :account_id, uniqueness: { scope: :identity_id, message: "already has this identity as a member" }

  scope :owners, -> { where(role: :owner) }
  scope :members, -> { where(role: :member) }

  def owner?
    role == "owner"
  end

  def member?
    role == "member"
  end
end
