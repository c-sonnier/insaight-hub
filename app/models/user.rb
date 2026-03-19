class User < ApplicationRecord
  # User is now a membership model linking Identity to Account

  belongs_to :account
  belongs_to :identity
  has_many :insight_items, dependent: :destroy
  has_many :engagements, dependent: :destroy
  has_many :comments, through: :engagements, source: :engageable, source_type: "Comment"
  has_many :created_invites, class_name: "Invite", foreign_key: "created_by_id"

  # Delegations for backward compatibility during transition
  delegate :email_address, :name, :admin?, :theme, :avatar, to: :identity
  delegate :external_id, to: :account, prefix: true

  enum :role, { member: "member", owner: "owner" }, default: :member

  validates :role, presence: true
  validates :account_id, uniqueness: { scope: :identity_id, message: "already has this identity as a member" }
  validates :api_token, uniqueness: true, allow_nil: true

  before_create :generate_api_token

  scope :owners, -> { where(role: :owner) }
  scope :members, -> { where(role: :member) }

  def owner?
    role == "owner"
  end

  def member?
    role == "member"
  end

  def regenerate_api_token!
    update!(api_token: SecureRandom.hex(32))
  end

  private

  def generate_api_token
    self.api_token ||= SecureRandom.hex(32)
  end
end
