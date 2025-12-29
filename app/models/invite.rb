class Invite < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :used_by, class_name: "User", optional: true

  validates :token, presence: true, uniqueness: true
  validates :created_by_id, presence: true

  before_create :generate_token
  before_create :set_expiration

  scope :available, -> { where(used_at: nil).where("expires_at > ?", Time.current) }
  scope :used, -> { where.not(used_at: nil) }
  scope :expired, -> { where("expires_at <= ?", Time.current).where(used_at: nil) }

  def available?
    used_at.nil? && expires_at > Time.current
  end

  def use!(user)
    update!(used_by: user, used_at: Time.current)
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= 7.days.from_now
  end
end
