class Identity < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :accounts, through: :users
  has_one_attached :avatar

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :api_token, uniqueness: true, allow_nil: true

  before_create :generate_api_token

  def regenerate_api_token!
    update!(api_token: SecureRandom.hex(32))
  end

  private

  def generate_api_token
    self.api_token = SecureRandom.hex(32)
  end
end
